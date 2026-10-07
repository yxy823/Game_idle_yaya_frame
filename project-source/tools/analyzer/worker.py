"""One owned process per request; JSON goes to stdout or the --output file.

Runs in the dedicated Analyzer Python environment configured as analyzer_python_executable,
with the pinned wheels installed. This is a development tool, not an exported game
dependency. It starts no child processes.
"""

import argparse
import ctypes
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import sys
import threading

from protocol import ANALYZER_VERSION, SCHEMA_VERSION, failure, result, unavailable, validate
from source_probe import CAPABILITIES, AnalysisError, check_source
from atomic_output import OWNED_TEMPORARIES, WRITE_LOCK, encode_result, write_result
from feature_runner import artifacts_valid, describe, run_features, select_modules

DEFAULTS = CAPABILITIES["defaults"]
LIMITS = CAPABILITIES["limits"]


def parameters(given, selected):
    defaults, limits = dict(DEFAULTS), dict(LIMITS)
    for module in selected.values():
        defaults.update(getattr(module, "DEFAULTS", {}))
        limits.update(getattr(module, "LIMITS", {}))
    params = defaults | given
    for key, value in params.items():
        if key not in limits or isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ValueError("Invalid parameter: " + key)
        low, high = limits[key]
        if not low <= value <= high:
            raise ValueError("Parameter out of range: " + key)
        if isinstance(defaults[key], int) and not isinstance(value, int):
            raise ValueError("Integer parameter required: " + key)
    return params


def backends(asset_type):
    expected_python = CAPABILITIES["runtime"]["python"]
    if tuple(map(int, expected_python.split("."))) != sys.version_info[:3]:
        raise ImportError(f"Expected Python {expected_python}, found {sys.version.split()[0]}")
    pins = dict(line.split("==") for line in Path(__file__).with_name("requirements.txt").read_text().splitlines())
    versions = {}
    for package in pins:
        try:
            actual = importlib.metadata.version(package)
        except importlib.metadata.PackageNotFoundError:
            actual = None
        if actual != pins[package]:
            raise ImportError(f"Expected {package}=={pins[package]} in the Analyzer environment "
                              f"{sys.executable}, found {actual}")
        versions[package] = actual
    if asset_type == "audio":
        import av
        versions["ffmpeg_libraries"] = {name: list(version) for name, version in av.library_versions.items()}
    return versions


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def configure_runtime(project):
    # These must be set before NumPy/SciPy/Numba import, including in-process tests.
    for name in ("OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "NUMBA_NUM_THREADS"):
        os.environ[name] = "1"
    pins = dict(line.split("==") for line in Path(__file__).with_name("requirements.txt").read_text().splitlines())
    tag = "py313-" + "-".join(name + pins[name] for name in ("librosa", "numba", "llvmlite"))
    directory = project / "reports/asset-analyzer/numba-cache" / tag
    directory.mkdir(parents=True, exist_ok=True)
    os.environ["NUMBA_CACHE_DIR"] = str(directory)


def analyze(request, project):
    configure_runtime(project)
    path = Path(request["path"]).resolve()
    kind = request["asset_type"]
    check_source(path, kind)
    selected = select_modules(request, kind)
    params = parameters(request.get("parameters", {}), selected)
    backend = backends(kind)
    content = digest(path)
    identity = {"path": str(path), "sha256": content, "parameters": params, "backend": backend,
                "schema": SCHEMA_VERSION, "analyzer": kind, "version": ANALYZER_VERSION,
                "modules": {name: module.VERSION for name, module in selected.items()}}
    key = hashlib.sha256(json.dumps(identity, sort_keys=True).encode()).hexdigest()
    cache = project / "reports/asset-analyzer/cache" / (key + ".json")
    if not request.get("force", False):
        cached = read_cache(cache, key, identity, selected)
        if cached:
            return cached
    if kind == "audio":
        from audio_adapter import analyze as run
    else:
        from image_adapter import analyze as run
    try:
        metrics, series, notes = run(path, params)
    except Exception as error:
        code = error.code if isinstance(error, AnalysisError) else "analysis_failed"
        if isinstance(error, MemoryError):
            code = "memory_limit"
        data = describe(failure(path, kind, code, str(error) or "Worker memory budget exceeded"), selected)
        data["metrics"].update({name: unavailable("failed", code, unit)
                                for module in selected.values() for name, unit in module.METRICS.items()})
        data["analyzer"]["backend"] = backend
        data["parameters"] = params
        return data
    data = describe(result(path, kind, backend), selected)
    data["analyzer"]["version"] = ANALYZER_VERSION
    data.update(metrics=metrics, series=series, warnings=notes, parameters=params)
    data["asset"]["sha256"] = content
    data["cache"] = {"hit": False, "key": key, "identity": identity}
    failed = [name for name, value in metrics.items() if value["status"] == "failed"]
    if failed:
        data["status"] = "partial"
        data["errors"] = [{"code": "metric_failed", "message": name} for name in failed]
    context = {"metrics": data["metrics"], "artifact_dir": cache.parent / key}
    run_features(selected, data, path, params, context)
    encode_result(data)
    if digest(path) != content:
        return failure(path, kind, "asset_changed", "Asset changed during analysis; retry")
    if data["status"] == "success":
        write_result(cache, data)
    return data


def read_cache(path, key, identity, selected):
    try:
        if path.stat().st_size > 2097152:
            return None
        data = validate(json.loads(path.read_text(encoding="utf-8")))
        expected = describe(result(identity["path"], identity["analyzer"], identity["backend"]), selected)
        expected["analyzer"]["version"] = identity["version"]
        valid_identity = (
            data["status"] == "success" and data["schema_version"] == identity["schema"]
            and data["asset"] == expected["asset"] | {"sha256": identity["sha256"]}
            and data["analyzer"] == expected["analyzer"]
            and data.get("parameters") == identity["parameters"])
        if (valid_identity and data["cache"]["key"] == key and data["cache"].get("identity") == identity
                and artifacts_valid(data, selected, path.parent / key)):
            data["cache"]["hit"] = True
            return data
    except (OSError, ValueError, TypeError, KeyError, AttributeError):
        return None
    return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--request", required=True, type=Path)
    parser.add_argument("--output", type=Path, help="Atomically write JSON here; stdout stays empty")
    parser.add_argument("--parent-pid", type=int)
    args = parser.parse_args()
    request = {}
    memory_mib = 0
    try:
        request = json.loads(args.request.read_text(encoding="utf-8"))
        if args.parent_pid:
            threading.Thread(target=watch_parent,
                             args=(args.parent_pid, args.request), daemon=True).start()
        check_source(Path(request["path"]), request["asset_type"])
        from memory_budget import limit_worker, process_memory
        memory_mib = CAPABILITIES["sources"][request["asset_type"]]["memory_mib"]
        try:
            _memory_handle = limit_worker(memory_mib)
        except OSError as error:
            raise AnalysisError("memory_budget_setup", str(error)) from error
        project = Path(__file__).resolve().parents[3]
        data = analyze(request, project)
        data["execution"] = {"memory_limit_mib": memory_mib} | process_memory()
    except AnalysisError as error:
        data = failure(request.get("path", ""), request.get("asset_type", "unknown"), error.code, str(error))
    except MemoryError:
        data = failure(request.get("path", ""), request.get("asset_type", "unknown"),
                       "memory_limit", f"Worker exceeded {memory_mib} MiB commit-memory budget")
    except ImportError as error:
        data = failure(request.get("path", ""), request.get("asset_type", "unknown"), "dependency_missing", str(error))
    except Exception as error:  # Process boundary: one bad asset must not terminate the workbench.
        data = failure(request.get("path", ""), request.get("asset_type", "unknown"), "analysis_failed", str(error))
    try:
        payload = encode_result(data)
    except AnalysisError as error:
        data = failure(request.get("path", ""), request.get("asset_type", "unknown"), error.code, str(error))
        payload = encode_result(data)
    if args.output:
        try:
            write_result(args.output, data)
        except OSError as error:
            diagnostic = failure(request.get("path", ""), request.get("asset_type", "unknown"),
                                 "output_write_failed", str(error))
            sys.stderr.buffer.write(encode_result(diagnostic))
            sys.stderr.buffer.flush()
            return 1
    else:
        sys.stdout.buffer.write(payload)
        sys.stdout.buffer.flush()
    return 0


def watch_parent(parent_pid, request):
    """Wait on the actual Windows parent handle without touching Python I/O locks."""
    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel.OpenProcess.argtypes = [ctypes.c_uint32, ctypes.c_int, ctypes.c_uint32]
    kernel.OpenProcess.restype = ctypes.c_void_p
    kernel.WaitForSingleObject.argtypes = [ctypes.c_void_p, ctypes.c_uint32]
    kernel.CloseHandle.argtypes = [ctypes.c_void_p]
    handle = kernel.OpenProcess(0x00100000, False, parent_pid)  # SYNCHRONIZE only.
    if handle:
        kernel.WaitForSingleObject(handle, 0xFFFFFFFF)
        kernel.CloseHandle(handle)
    with WRITE_LOCK:
        for path in (request, *OWNED_TEMPORARIES):
            try:
                path.unlink(missing_ok=True)
            except OSError:
                pass  # Owner also retries cleanup after terminating the worker.
        os._exit(1)


if __name__ == "__main__":
    sys.exit(main())
