"""Opt-in boundary-size, concurrent-worker memory measurements in the test project."""

from concurrent.futures import ThreadPoolExecutor
import json
import subprocess
import tempfile
import time
import wave

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

sys.path.insert(0, str(PROJECT_ROOT / "reports/asset-analyzer/runtime"))
import numpy as np
from PIL import Image

TOOLS = PROJECT_ROOT / "tools/asset_analyzer"


def run(root, name, source, kind):
    request = root / (name + ".json")
    request.write_text(json.dumps({"path": str(source), "asset_type": kind, "force": True}))
    started = time.monotonic()
    process = subprocess.run([sys.executable, "-B", str(TOOLS / "worker.py"),
                              "--request", str(request)], capture_output=True, timeout=60)
    if process.returncode:
        raise AssertionError(process.stderr.decode(errors="replace"))
    data = json.loads(process.stdout)
    if data["status"] != "success":
        raise AssertionError(data)
    execution = data["execution"]
    if execution["peak_commit_bytes"] > execution["memory_limit_mib"] * 1024**2:
        raise AssertionError(execution)
    (PROJECT_ROOT / "reports/asset-analyzer/cache" / (data["cache"]["key"] + ".json")).unlink(missing_ok=True)
    return {"name": name, "seconds": round(time.monotonic() - started, 3), **execution,
            "metric_states": {key: value["status"] for key, value in data["metrics"].items()}}


def audio(path, frames):
    # Locally generated sine; fixed-size chunks, no unrelated media provenance.
    with wave.open(str(path), "wb") as stream:
        stream.setnchannels(2)
        stream.setsampwidth(2)
        stream.setframerate(48000)
        for start in range(0, frames, 8192):
            positions = np.arange(start, min(start + 8192, frames))
            samples = (np.sin(positions * (2 * np.pi * 440 / 48000)) * 12000).astype("<i2")
            stream.writeframes(np.repeat(samples[:, None], 2, axis=1).tobytes())


def main():
    output = PROJECT_ROOT / "reports/asset-analyzer/memory-check.json"
    with tempfile.TemporaryDirectory(prefix="memory 中文 ", dir=output.parent) as folder:
        root = Path(folder)
        image = root / "boundary image.png"
        pixels = np.random.default_rng(17).integers(0, 256, (2000, 4000, 4), dtype=np.uint8)
        Image.fromarray(pixels).save(image)
        del pixels
        long_audio, loudness_audio = root / "boundary audio.wav", root / "loudness audio.wav"
        audio(long_audio, 4000000)  # 8,000,000 channel samples: default input cap.
        audio(loudness_audio, 1000000)  # 2,000,000 channel samples: loudness cap.
        records = [run(root, "image-limit", image, "image"),
                   run(root, "audio-limit", long_audio, "audio"),
                   run(root, "loudness-limit", loudness_audio, "audio")]
        with ThreadPoolExecutor(max_workers=2) as pool:
            futures = [pool.submit(run, root, "concurrent-image-" + str(i), image, "image")
                       for i in range(2)]
            records.extend(future.result() for future in futures)
        # Verify the OS limit actually denies allocation, rather than merely reporting a budget.
        script = root / "allocation_check.py"
        script.write_text(
            "import sys\nsys.path.insert(0, " + repr(str(TOOLS)) + ")\n"
            "from memory_budget import limit_worker\n"
            "handle = limit_worker(64)\n"
            "try:\n    block = bytearray(128 * 1024**2)\n"
            "except MemoryError:\n    print('allocation_denied')\n"
            "else:\n    raise AssertionError('Memory limit was not enforced')\n")
        denied = subprocess.run([sys.executable, "-B", str(script)], capture_output=True, timeout=10)
        assert denied.returncode == 0 and b"allocation_denied" in denied.stdout, denied.stderr
        evidence = {"input_image_pixels": 8000000, "input_channel_samples": 8000000,
                    "pool_reservation_mib": 512, "allocation_limit_enforced": True,
                    "records": records}
        output.write_text(json.dumps(evidence, indent=2), encoding="utf-8")
        print(json.dumps(evidence, indent=2))


if __name__ == "__main__":
    main()
