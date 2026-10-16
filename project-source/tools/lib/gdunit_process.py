"""Bound a test process and its descendants without touching other processes."""
from __future__ import annotations

import ctypes
import math
import os
import subprocess
import time
from ctypes import wintypes
from pathlib import Path
from typing import BinaryIO


class _StartupInfo(ctypes.Structure):
    _fields_ = [
        ("cb", wintypes.DWORD), ("reserved", wintypes.LPWSTR),
        ("desktop", wintypes.LPWSTR), ("title", wintypes.LPWSTR),
        ("x", wintypes.DWORD), ("y", wintypes.DWORD),
        ("x_size", wintypes.DWORD), ("y_size", wintypes.DWORD),
        ("x_chars", wintypes.DWORD), ("y_chars", wintypes.DWORD),
        ("fill", wintypes.DWORD), ("flags", wintypes.DWORD),
        ("show", wintypes.WORD), ("reserved_size", wintypes.WORD),
        ("reserved_bytes", ctypes.c_void_p),
        ("stdin", wintypes.HANDLE), ("stdout", wintypes.HANDLE),
        ("stderr", wintypes.HANDLE),
    ]


class _ProcessInfo(ctypes.Structure):
    _fields_ = [
        ("process", wintypes.HANDLE), ("thread", wintypes.HANDLE),
        ("pid", wintypes.DWORD), ("tid", wintypes.DWORD),
    ]


class _BasicLimits(ctypes.Structure):
    _fields_ = [
        ("process_time", ctypes.c_longlong), ("job_time", ctypes.c_longlong),
        ("flags", wintypes.DWORD), ("min_working_set", ctypes.c_size_t),
        ("max_working_set", ctypes.c_size_t), ("active_limit", wintypes.DWORD),
        ("affinity", ctypes.c_size_t), ("priority", wintypes.DWORD),
        ("scheduling", wintypes.DWORD),
    ]


class _ExtendedLimits(ctypes.Structure):
    _fields_ = [
        ("basic", _BasicLimits), ("io_counters", ctypes.c_ulonglong * 6),
        ("process_memory", ctypes.c_size_t), ("job_memory", ctypes.c_size_t),
        ("peak_process_memory", ctypes.c_size_t), ("peak_job_memory", ctypes.c_size_t),
    ]


class _Accounting(ctypes.Structure):
    _fields_ = [
        ("user_time", ctypes.c_longlong), ("kernel_time", ctypes.c_longlong),
        ("period_user_time", ctypes.c_longlong), ("period_kernel_time", ctypes.c_longlong),
        ("page_faults", wintypes.DWORD), ("total_processes", wintypes.DWORD),
        ("active_processes", wintypes.DWORD), ("terminated_processes", wintypes.DWORD),
    ]


def _windows_api():
    api = ctypes.WinDLL("kernel32", use_last_error=True)
    signatures = {
        "CreateJobObjectW": ([ctypes.c_void_p, wintypes.LPCWSTR], wintypes.HANDLE),
        "SetInformationJobObject": ([wintypes.HANDLE, ctypes.c_int, ctypes.c_void_p, wintypes.DWORD], wintypes.BOOL),
        "QueryInformationJobObject": ([wintypes.HANDLE, ctypes.c_int, ctypes.c_void_p, wintypes.DWORD, ctypes.c_void_p], wintypes.BOOL),
        "AssignProcessToJobObject": ([wintypes.HANDLE, wintypes.HANDLE], wintypes.BOOL),
        "TerminateJobObject": ([wintypes.HANDLE, wintypes.UINT], wintypes.BOOL),
        "CreateProcessW": ([wintypes.LPCWSTR, wintypes.LPWSTR, ctypes.c_void_p, ctypes.c_void_p,
                            wintypes.BOOL, wintypes.DWORD, ctypes.c_void_p, wintypes.LPCWSTR,
                            ctypes.POINTER(_StartupInfo), ctypes.POINTER(_ProcessInfo)], wintypes.BOOL),
        "ResumeThread": ([wintypes.HANDLE], wintypes.DWORD),
        "WaitForSingleObject": ([wintypes.HANDLE, wintypes.DWORD], wintypes.DWORD),
        "GetExitCodeProcess": ([wintypes.HANDLE, ctypes.POINTER(wintypes.DWORD)], wintypes.BOOL),
        "TerminateProcess": ([wintypes.HANDLE, wintypes.UINT], wintypes.BOOL),
        "CloseHandle": ([wintypes.HANDLE], wintypes.BOOL),
    }
    for name, (arguments, result) in signatures.items():
        function = getattr(api, name)
        function.argtypes = arguments
        function.restype = result
    return api


def _checked(result) -> None:
    if not result:
        raise ctypes.WinError(ctypes.get_last_error())


def _wait_for_job_cleanup(api, job, process) -> None:
    _checked(api.TerminateJobObject(job, 1))
    if api.WaitForSingleObject(process, 5000) != 0:
        raise TimeoutError("owned test process did not terminate within 5 seconds")
    deadline = time.monotonic() + 5
    while True:
        accounting = _Accounting()
        _checked(api.QueryInformationJobObject(job, 1, ctypes.byref(accounting), ctypes.sizeof(accounting), None))
        if accounting.active_processes == 0:
            return
        if time.monotonic() >= deadline:
            raise TimeoutError("owned test descendants did not terminate within 5 seconds")
        time.sleep(0.01)


def _job_process_ids(api, job) -> set[int]:
    """Read kernel-confirmed membership; an unobserved short-lived child fails closed."""
    size = 256
    while True:
        buffer = ctypes.create_string_buffer(size)
        if api.QueryInformationJobObject(job, 3, buffer, size, None):
            count = wintypes.DWORD.from_buffer(buffer, 4).value
            return set((ctypes.c_size_t * count).from_buffer(buffer, 8))
        if ctypes.get_last_error() != 234:  # ERROR_MORE_DATA
            raise ctypes.WinError(ctypes.get_last_error())
        size *= 2


def _run_windows(command: list[str], cwd: Path, output: BinaryIO, timeout: float,
                 ownership: dict) -> tuple[int, bool, int]:
    import msvcrt

    api = _windows_api()
    job = api.CreateJobObjectW(None, None)
    _checked(job)
    process = _ProcessInfo()
    assigned = False
    try:
        limits = _ExtendedLimits()
        limits.basic.flags = 0x2000  # JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
        _checked(api.SetInformationJobObject(job, 9, ctypes.byref(limits), ctypes.sizeof(limits)))
        with open(os.devnull, "rb") as closed_input:
            handles = [msvcrt.get_osfhandle(closed_input.fileno()), msvcrt.get_osfhandle(output.fileno())]
            inherited = [os.get_handle_inheritable(handle) for handle in handles]
            startup = _StartupInfo()
            startup.cb = ctypes.sizeof(startup)
            startup.flags = 0x100  # STARTF_USESTDHANDLES
            startup.stdin, startup.stdout, startup.stderr = handles[0], handles[1], handles[1]
            try:
                for handle in handles:
                    os.set_handle_inheritable(handle, True)
                # Attach before the first instruction: a console launcher cannot
                # spawn an engine child outside our job during an attach race.
                _checked(api.CreateProcessW(
                    command[0], ctypes.create_unicode_buffer(subprocess.list2cmdline(command)),
                    None, None, True, 0x08000004,
                    None, str(cwd),
                    ctypes.byref(startup), ctypes.byref(process),
                ))
            finally:
                for handle, previous in zip(handles, inherited):
                    os.set_handle_inheritable(handle, previous)
        _checked(api.AssignProcessToJobObject(job, process.process))
        assigned = True
        if api.ResumeThread(process.thread) == 0xFFFFFFFF:
            raise ctypes.WinError(ctypes.get_last_error())
        observed = {process.pid}
        deadline = time.monotonic() + timeout
        while True:
            observed.update(_job_process_ids(api, job))
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                wait = 258
                break
            wait_ms = math.ceil(min(remaining, 0.02) * 1000)
            wait = api.WaitForSingleObject(process.process, wait_ms)
            if wait != 258:
                break
        if wait not in (0, 258):
            raise ctypes.WinError(ctypes.get_last_error())
        ownership.update(source="windows-job", launcher_pid=process.pid, owned_pids=sorted(observed))
        timed_out = wait == 258
        exit_code = wintypes.DWORD()
        if not timed_out:
            _checked(api.GetExitCodeProcess(process.process, ctypes.byref(exit_code)))
        _wait_for_job_cleanup(api, job, process.process)
        if timed_out:
            _checked(api.GetExitCodeProcess(process.process, ctypes.byref(exit_code)))
        return exit_code.value, timed_out, process.pid
    finally:
        if process.process:
            if assigned:
                api.TerminateJobObject(job, 1)
            else:
                # Assignment failure leaves a suspended, exclusively owned child.
                api.TerminateProcess(process.process, 1)
            api.WaitForSingleObject(process.process, 5000)
        for handle in (process.thread, process.process, job):
            if handle:
                api.CloseHandle(handle)


def run_owned_process(command: list[str], cwd: Path, log_path: Path, timeout: float) -> tuple[int, bool, int, str, tuple[int, ...]]:
    if os.name != "nt":
        raise ValueError("Owned execution supports Windows 11 only")
    if isinstance(timeout, bool) or not isinstance(timeout, (int, float)) or not math.isfinite(timeout) or timeout <= 0:
        raise ValueError("process timeout must be finite and positive")
    # A shared file descriptor cannot fill a pipe or reorder stdout/stderr.
    ownership: dict = {}
    with log_path.open("wb") as output:
        code, timed_out, pid = _run_windows(command, cwd, output, timeout, ownership)
    return code, timed_out, pid, log_path.read_text(encoding="utf-8", errors="replace"), tuple(ownership["owned_pids"])
