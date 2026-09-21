"""Declared source-file capabilities and actionable errors, independent of playback."""

import json
from pathlib import Path

CAPABILITIES = json.loads(Path(__file__).with_name("capabilities.json").read_text(encoding="utf-8"))


class AnalysisError(Exception):
    def __init__(self, code, message):
        super().__init__(message)
        self.code = code


def check_source(path, kind):
    if kind not in CAPABILITIES["sources"]:
        raise AnalysisError("unsupported_type", "Supported types: audio, image")
    if not path.is_file() or path.suffix.lower() in {".tres", ".res", ".tscn"}:
        raise AnalysisError("source_not_file", "Analyze an existing source media file, not an embedded/indirect Godot resource")
    if path.suffix.lower().lstrip(".") not in CAPABILITIES["sources"][kind]["extensions"]:
        raise AnalysisError("unsupported_format", f"No {kind} source decoder declared for {path.suffix}")


def decode_error(error):
    """Only recognized backend conditions are classified as corruption/unsupported."""
    name = type(error).__name__
    if name in {"UnidentifiedImageError", "InvalidDataError", "EOFError"}:
        return AnalysisError("corrupt_file", str(error))
    if name in {"DecoderNotFoundError", "DemuxerNotFoundError", "NotImplementedError"}:
        return AnalysisError("unsupported_format", str(error))
    return AnalysisError("decode_failed", str(error))
