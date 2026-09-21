"""One owned background process per request; stdout is exactly one JSON result.

Install pinned wheels into reports/asset-analyzer/runtime. This is a development
tool, not an exported game dependency. It starts no child processes.
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

from protocol import ANALYZER_VERSION, SCHEMA_VERSION, failure, result, validate

DEFAULTS = {"silence_dbfs": -50.0, "silence_min_seconds": 0.05,
            "series_points": 256, "palette_size": 8,
            "max_audio_samples": 30_000_000, "max_image_pixels": 16_000_000}
LIMITS = {"silence_dbfs": (-120, 0), "silence_min_seconds": (0.001, 10),
          "series_points": (16, 512), "palette_size": (1, 32),
          "max_audio_samples": (1, 30_000_000), "max_image_pixels": (1, 16_000_000)}
CACHE_WRITE_LOCK = threading.Lock()


def parameters(given):
    params = DEFAULTS | given
    for key, value in params.items():
        if key not in LIMITS or isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ValueError("Invalid parameter: " + key)
        low, high = LIMITS[key]
        if not low <= value <= high:
            raise ValueError("Parameter out of range: " + key)
        if isinstance(DEFAULTS[key], int) and not isinstance(value, int):
            raise ValueError("Integer parameter required: " + key)
    return params


def backends(runtime, asset_type):
    if not runtime.is_dir():
        raise ImportError("Install tools/asset_analyzer/requirements.txt into " + str(runtime))
    sys.path.insert(0, str(runtime))
    pins = dict(line.split("==") for line in Path(__file__).with_name("requirements.txt").read_text().splitlines())
    packages = ("av", "numpy", "pyloudnorm", "scipy") if asset_type == "audio" else ("Pillow", "numpy")
    installed = {d.metadata["Name"].lower(): d.version
                 for d in importlib.metadata.distributions(path=[str(runtime)])}
    versions = {}
    for package in packages:
        actual = installed.get(package.lower())
        if actual != pins[package]:
            raise ImportError(f"Expected {package}=={pins[package]}, found {actual}")
        versions[package] = actual
    if asset_type == "audio":
        import av
        versions["ffmpeg_libraries"] = {name: list(version) for name, version in av.library_versions.items()}
    return versions


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def analyze(request, project, temporary):
    path = Path(request["path"]).resolve()
    kind = request["asset_type"]
    if kind not in {"audio", "image"}:
        return failure(path, kind, "unsupported_type", "Supported types: audio, image")
    params = parameters(request.get("parameters", {}))
    backend = backends(project / "reports/asset-analyzer/runtime", kind)
    content = digest(path)
    identity = {"path": str(path), "sha256": content, "parameters": params, "backend": backend,
                "schema": SCHEMA_VERSION, "analyzer": kind, "version": ANALYZER_VERSION}
    key = hashlib.sha256(json.dumps(identity, sort_keys=True).encode()).hexdigest()
    cache = project / "reports/asset-analyzer/cache" / (key + ".json")
    if not request.get("force", False):
        cached = read_cache(cache, key, identity)
        if cached:
            return cached
    if kind == "audio":
        from audio_adapter import analyze as run
    else:
        from image_adapter import analyze as run
    try:
        metrics, series, notes = run(path, params)
    except Exception as error:
        data = failure(path, kind, "analysis_failed", str(error))
        data["analyzer"]["backend"] = backend
        data["parameters"] = params
        return data
    data = result(path, kind, backend)
    data.update(metrics=metrics, series=series, warnings=notes, parameters=params)
    data["asset"]["sha256"] = content
    data["cache"] = {"hit": False, "key": key, "identity": identity}
    failed = [name for name, value in metrics.items() if value["status"] == "failed"]
    if failed:
        data["status"] = "partial"
        data["errors"] = [{"code": "metric_failed", "message": name} for name in failed]
    validate(data)
    if digest(path) != content:
        return failure(path, kind, "asset_changed", "Asset changed during analysis; retry")
    if not failed:
        cache.parent.mkdir(parents=True, exist_ok=True)
        with CACHE_WRITE_LOCK:
            temporary.write_text(json.dumps(data, ensure_ascii=False, allow_nan=False), encoding="utf-8")
            os.replace(temporary, cache)
    return data


def read_cache(path, key, identity):
    try:
        data = validate(json.loads(path.read_text(encoding="utf-8")))
        if data["cache"].get("key") == key and data["cache"].get("identity") == identity:
            data["cache"]["hit"] = True
            return data
    except (OSError, ValueError, TypeError, KeyError, AttributeError):
        return None
    return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--request", required=True, type=Path)
    parser.add_argument("--parent-pid", type=int)
    args = parser.parse_args()
    request = {}
    temporary = args.request.with_suffix(".cache.tmp")
    try:
        request = json.loads(args.request.read_text(encoding="utf-8"))
        if args.parent_pid:
            threading.Thread(target=watch_parent,
                             args=(args.parent_pid, args.request, temporary), daemon=True).start()
        project = Path(__file__).resolve().parents[2]
        data = analyze(request, project, temporary)
    except ImportError as error:
        data = failure(request.get("path", ""), request.get("asset_type", "unknown"), "dependency_missing", str(error))
    except Exception as error:  # Process boundary: one bad asset must not terminate the workbench.
        data = failure(request.get("path", ""), request.get("asset_type", "unknown"), "analysis_failed", str(error))
    finally:
        temporary.unlink(missing_ok=True)
    sys.stdout.buffer.write(json.dumps(data, ensure_ascii=False, allow_nan=False).encode("utf-8"))
    sys.stdout.buffer.flush()


def watch_parent(parent_pid, request, temporary):
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
    with CACHE_WRITE_LOCK:
        for path in (request, temporary):
            try:
                path.unlink(missing_ok=True)
            except OSError:
                pass  # Owner also retries cleanup after terminating the worker.
        os._exit(1)


if __name__ == "__main__":
    main()
