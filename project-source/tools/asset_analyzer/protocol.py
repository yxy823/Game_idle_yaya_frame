"""Backend-neutral, finite JSON measurements. No playback or Godot imports."""

import math

SCHEMA_VERSION = 1
ANALYZER_VERSION = 1
METRIC_STATES = {"available", "not_applicable", "unsupported", "failed"}
AUDIO_METRICS = (
    "format", "codec", "duration", "sample_rate", "channels", "channel_layout",
    "bit_depth", "sample_peak", "rms", "crest_factor", "integrated_loudness",
    "loudness_range", "true_peak", "silence_intervals", "leading_silence",
    "trailing_silence", "pitch", "tempo",
)
IMAGE_METRICS = (
    "format", "width", "height", "aspect_ratio", "mode", "has_alpha",
    "transparent_ratio", "opaque_ratio", "translucent_ratio", "alpha_mean",
    "dominant_color", "palette", "color_count", "rgb_mean", "saturation_mean",
    "luma_mean", "luma_stddev",
)


def metric(value=None, unit="", *, status="available", reason=""):
    """Unavailable values are null, never numeric placeholders."""
    return {"status": status, "value": value if status == "available" else None,
            "unit": unit, "reason": reason}


def unavailable(status, reason, unit=""):
    return metric(unit=unit, status=status, reason=reason)


def sequence(x, y, x_unit, y_unit, kind="line"):
    return {"status": "available", "kind": kind, "x": x, "y": y,
            "x_unit": x_unit, "y_unit": y_unit}


def result(path, asset_type, backend=None):
    supported = {"audio": AUDIO_METRICS, "image": IMAGE_METRICS}.get(asset_type, ())
    supported = [name for name in supported if name not in {"true_peak", "pitch", "tempo"}]
    return {
        "schema_version": SCHEMA_VERSION, "status": "success",
        "asset": {"path": str(path), "type": asset_type},
        "analyzer": {"id": asset_type + "_basic", "version": ANALYZER_VERSION,
                     "backend": backend or {},
                     "supported_types": [asset_type] if supported else [],
                     "supported_metrics": supported},
        "metrics": {}, "series": {}, "warnings": [], "errors": [],
        "cache": {"hit": False, "key": ""},
    }


def failure(path, asset_type, code, message):
    data = result(path, asset_type)
    data["status"] = "failed"
    data["errors"] = [{"code": code, "message": message[:2000]}]
    data["metrics"] = {key: unavailable("failed", code)
                       for key in data["analyzer"]["supported_metrics"]}
    return data


def validate(data):
    """Validate cache/wire boundaries without another runtime dependency."""
    if not isinstance(data, dict) or data.get("schema_version") != SCHEMA_VERSION:
        raise ValueError("Unsupported analysis schema")
    if data.get("status") not in {"success", "partial", "failed", "cancelled"}:
        raise ValueError("Invalid task state")
    for key in ("asset", "analyzer", "metrics", "series", "cache"):
        if not isinstance(data.get(key), dict):
            raise ValueError("Missing object: " + key)
    for key in ("warnings", "errors"):
        if not isinstance(data.get(key), list):
            raise ValueError("Missing list: " + key)
        for entry in data[key]:
            if not isinstance(entry, dict) or not all(isinstance(entry.get(k), str) for k in ("code", "message")):
                raise ValueError("Invalid diagnostic")
    if not all(isinstance(data["asset"].get(k), str) for k in ("path", "type")):
        raise ValueError("Invalid asset identity")
    if not isinstance(data["analyzer"].get("backend"), dict):
        raise ValueError("Invalid backend versions")
    for entry in data["metrics"].values():
        if not isinstance(entry, dict) or entry.get("status") not in METRIC_STATES:
            raise ValueError("Invalid metric state")
        if not all(isinstance(entry.get(k), str) for k in ("unit", "reason")):
            raise ValueError("Invalid metric description")
        if entry["status"] == "available" and entry.get("value") is None:
            raise ValueError("Available metric has no value")
        if entry["status"] != "available" and entry.get("value") is not None:
            raise ValueError("Unavailable metric has a value")
    for entry in data["series"].values():
        if not isinstance(entry, dict) or entry.get("status") != "available":
            raise ValueError("Invalid series")
        if entry.get("kind") not in {"line", "histogram"}:
            raise ValueError("Invalid series kind")
        x, y = entry.get("x", []), entry.get("y", [])
        if not isinstance(x, list) or not isinstance(y, list):
            raise ValueError("Invalid series arrays")
        if len(x) != len(y) or len(x) > 2048:
            raise ValueError("Invalid series length")
        if not all(isinstance(v, (int, float)) and math.isfinite(v) for v in x + y):
            raise ValueError("Non-finite series value")
    return data
