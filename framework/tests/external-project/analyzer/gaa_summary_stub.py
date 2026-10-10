"""Fixed GAA contract fixture, launched by the Godot service's test launcher."""

import argparse
import json
from pathlib import Path
import sys
import tempfile
import time

VALUES = {
    "f0_median_hz": (440.0, "Hz", "estimate"),
    "duration_s": (0.5, "s", "ok"),
    "peak_dbfs": (-2.0, "dBFS", "ok"),
    "true_peak_estimate_dbtp": (-1.5, "dBTP", "estimate"),
    "rms_dbfs": (-14.0, "dBFS", "ok"),
    "max_rms_20ms_dbfs": (-9.25, "dBFS", "estimate"),
    "attack_10_90_s": (0.002, "s", "estimate"),
    "decay_to_10_s": (0.21, "s", "estimate"),
    "spectral_centroid_hz": (3012.5, "Hz", "estimate"),
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["analyze"])
    parser.add_argument("source", type=Path)
    parser.add_argument("--json-only", required=True, action="store_true")
    parser.add_argument("--result-file", required=True, type=Path)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--parent-pid", required=True, type=int)
    parser.add_argument("--case", choices=["completed", "failed", "interrupted", "missing"], default="completed")
    parser.add_argument("--release-file", type=Path)
    args = parser.parse_args()
    if args.result_file.exists():
        return 4
    if args.release_file:
        args.release_file.with_suffix(args.release_file.suffix + ".ready").write_text("ready")
        deadline = time.monotonic() + 10
        while not args.release_file.exists():
            if time.monotonic() >= deadline:
                raise TimeoutError("Godot fixture did not release the stub")
            time.sleep(0.01)
    if args.case == "missing":
        print(json.dumps({"run_id": args.run_id, "status": "failed", "exit_code": 5,
                          "result_path": None, "error": {"code": "output_io_failed"}}))
        return 5
    completed = args.case == "completed"
    code = 0 if completed else 6 if args.case == "interrupted" else 3
    data = {
        "kind": "audio_summary", "contract_version": "2.0", "schema_version": "2.0",
        "tool_version": "0.5.0", "run_id": args.run_id, "status": args.case, "exit_code": code,
        "file": {"path": args.source.resolve().as_posix(), "sha256": "0" * 64},
        "metrics": {key: {"value": value if completed else None, "unit": unit,
                          "status": state if completed else "not_analyzed", "note": "Fixed fixture"}
                    for key, (value, unit, state) in VALUES.items()},
        "warnings": [], "error": None if completed else {
            "type": "FixtureError", "code": "parent_exited" if code == 6 else "decode_failed",
            "message": "Fixed fixture failure"},
    }
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=args.result_file.parent,
                                     suffix=".tmp", delete=False) as output:
        json.dump(data, output, ensure_ascii=True, allow_nan=False)
        temporary = Path(output.name)
    try:
        temporary.rename(args.result_file)
    finally:
        temporary.unlink(missing_ok=True)
    print(json.dumps({"run_id": args.run_id, "status": args.case, "exit_code": code,
                      "result_path": args.result_file.resolve().as_posix(), "error": data["error"]}))
    return code


if __name__ == "__main__":
    sys.exit(main())
