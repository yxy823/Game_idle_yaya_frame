"""Backend-neutral, finite JSON measurements. No playback or Godot imports."""

from schema_validation import validate_result

SCHEMA_VERSION = 1
ANALYZER_VERSION = 2
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
    "luma_mean", "luma_stddev", "palette_sample_pixels",
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
    """The shared JSON Schema owns both cache and wire field constraints."""
    return validate_result(data)
