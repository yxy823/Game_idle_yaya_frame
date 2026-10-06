"""A worker-only Windows commit-memory limit, plus measured process high-water marks.

Never attach the Godot or caller process. This module is invoked by worker.main,
not by the in-process adapter API used by tests. No child process is created.
"""

import ctypes as c
from ctypes import wintypes as w


class BasicLimit(c.Structure):
    _fields_ = [("process_time", c.c_int64), ("job_time", c.c_int64),
                ("flags", w.DWORD), ("minimum_ws", c.c_size_t), ("maximum_ws", c.c_size_t),
                ("active", w.DWORD), ("affinity", c.c_size_t),
                ("priority", w.DWORD), ("scheduling", w.DWORD)]


class ExtendedLimit(c.Structure):
    _fields_ = [("basic", BasicLimit), ("io", c.c_uint64 * 6),
                ("process_memory", c.c_size_t), ("job_memory", c.c_size_t),
                ("peak_process", c.c_size_t), ("peak_job", c.c_size_t)]


class MemoryCounters(c.Structure):
    _fields_ = [("size", w.DWORD), ("page_faults", w.DWORD)] + [
        (name, c.c_size_t) for name in ("peak_ws", "working_set", "peak_paged", "paged",
                                       "peak_nonpaged", "nonpaged", "commit", "peak_commit", "private")]


def limit_worker(mebibytes):
    kernel = c.WinDLL("kernel32", use_last_error=True)
    kernel.CreateJobObjectW.argtypes = [c.c_void_p, w.LPCWSTR]
    kernel.CreateJobObjectW.restype = w.HANDLE
    kernel.GetCurrentProcess.restype = w.HANDLE
    kernel.SetInformationJobObject.argtypes = [w.HANDLE, c.c_int, c.c_void_p, w.DWORD]
    kernel.AssignProcessToJobObject.argtypes = [w.HANDLE, w.HANDLE]
    kernel.CloseHandle.argtypes = [w.HANDLE]
    handle = kernel.CreateJobObjectW(None, None)
    if not handle:
        raise c.WinError(c.get_last_error())
    limits = ExtendedLimit()
    limits.basic.flags = 0x100  # JOB_OBJECT_LIMIT_PROCESS_MEMORY: committed virtual memory.
    limits.process_memory = mebibytes * 1024 * 1024
    if not kernel.SetInformationJobObject(handle, 9, c.byref(limits), c.sizeof(limits)):
        kernel.CloseHandle(handle)
        raise c.WinError(c.get_last_error())
    if not kernel.AssignProcessToJobObject(handle, kernel.GetCurrentProcess()):
        kernel.CloseHandle(handle)
        raise c.WinError(c.get_last_error())
    # Keep the job alive to process exit; no KILL_ON_JOB_CLOSE flag.
    return handle


def process_memory():
    kernel = c.WinDLL("kernel32", use_last_error=True)
    kernel.GetCurrentProcess.restype = w.HANDLE
    kernel.K32GetProcessMemoryInfo.argtypes = [w.HANDLE, c.c_void_p, w.DWORD]
    counters = MemoryCounters()
    counters.size = c.sizeof(counters)
    if not kernel.K32GetProcessMemoryInfo(kernel.GetCurrentProcess(), c.byref(counters), counters.size):
        raise c.WinError(c.get_last_error())
    return {"peak_working_set_bytes": counters.peak_ws,
            "peak_commit_bytes": counters.peak_commit}
