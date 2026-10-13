"""Fixed GAA result-file fixture, launched by the Godot service's test launcher."""

import argparse
import json
from pathlib import Path
import sys
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
    parser.add_argument("--result-file", required=True, type=Path)
    parser.add_argument("--case", choices=["completed", "failed", "missing"], default="completed")
    parser.add_argument("--release-file", type=Path)
    args = parser.parse_args()
    if args.release_file:
        args.release_file.with_suffix(args.release_file.suffix + ".ready").write_text("ready")
        deadline = time.monotonic() + 10
        while not args.release_file.exists():
            if time.monotonic() >= deadline:
                raise TimeoutError("Godot fixture did not release the stub")
            time.sleep(0.01)
    if args.case == "missing":
        return 1
    completed = args.case == "completed"
    data = {
        "status": args.case,
        "file": {"path": str(args.source.resolve())},
        "metrics": {key: {"value": value, "unit": unit, "status": state, "note": "Fixed fixture"}
                    for key, (value, unit, state) in VALUES.items()} if completed else None,
        "warnings": [],
        "error": None if completed else {"code": "decode_failed", "message": "Fixed fixture failure"},
    }
    args.result_file.parent.mkdir(parents=True, exist_ok=True)
    args.result_file.write_text(json.dumps(data, ensure_ascii=True, allow_nan=False), encoding="utf-8")
    print(args.result_file.resolve())
    return 0 if completed else 1


if __name__ == "__main__":
    sys.exit(main())
