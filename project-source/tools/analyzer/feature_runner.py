"""Discover feature declarations without importing their calculation libraries."""

import importlib
from pathlib import Path

from protocol import unavailable
from source_probe import AnalysisError


def select_modules(request, kind):
    available = {}
    for path in sorted(Path(__file__).with_name("features").glob("*.py")):
        if not path.name.startswith("_"):
            module = importlib.import_module("features." + path.stem)
            if module.ASSET_TYPE == kind:
                available[path.stem] = module
    names = request.get("modules", list(available))
    if not isinstance(names, list) or any(not isinstance(name, str) for name in names):
        raise AnalysisError("invalid_modules", "modules must be an array of module names")
    unknown = set(names) - available.keys()
    if unknown:
        raise AnalysisError("invalid_modules", "Unknown/inapplicable modules: " + ", ".join(sorted(unknown)))
    return {name: available[name] for name in sorted(set(names))}


def describe(data, selected):
    data["analyzer"]["modules"] = list(selected)
    supported = data["analyzer"]["supported_metrics"]
    for module in selected.values():
        supported.extend(name for name in module.METRICS if name not in supported)
    return data


def run_features(selected, data, path, params, context):
    for name, module in selected.items():
        try:
            metrics, series, warnings = module.run(path, params, context)
            data["metrics"].update(metrics)
            data["series"].update(series)
            data["warnings"].extend(warnings)
        except Exception as error:
            code = error.code if isinstance(error, AnalysisError) else "module_failed"
            if isinstance(error, MemoryError):
                code = "memory_limit"
            if isinstance(error, ImportError):
                code = "dependency_missing"
            message = str(error)[:500] or code
            data["metrics"].update({key: unavailable("failed", message, unit)
                                    for key, unit in module.METRICS.items()})
            data["errors"].append({"code": code, "message": name + ": " + message})
            data["status"] = "partial"


def artifacts_valid(data, selected, directory):
    for module in selected.values():
        for metric_name, filename in getattr(module, "ARTIFACTS", {}).items():
            from PIL import Image
            value = data["metrics"][metric_name]["value"]
            expected = (directory / filename).resolve()
            if value["path"] != expected.as_posix():
                return False
            with Image.open(expected) as image:
                if image.format != "PNG" or list(image.size) != value["image_size"]:
                    return False
                image.verify()
    return True
