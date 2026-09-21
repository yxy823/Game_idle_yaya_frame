"""Opt-in real pinned backends in the designated project, with owned media fixtures."""

import json
import copy
import math
import os
import shutil
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import wave

from project_context import PROJECT_ROOT

TOOLS = PROJECT_ROOT / "tools/asset_analyzer"
sys.path.insert(0, str(TOOLS))
sys.path.insert(0, str(PROJECT_ROOT / "reports/asset-analyzer/runtime"))

import jsonschema
from PIL import Image
import worker
from protocol import validate


class AnalyzerTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="analyzer 中文 ",
                                                     dir=PROJECT_ROOT / "reports/asset-analyzer")
        self.root = Path(self.directory.name)
        self.addCleanup(self.directory.cleanup)
        self.request = self.root / "request.json"
        self.created_cache = []
        self.addCleanup(self.clean_cache)

    def clean_cache(self):
        for key in self.created_cache:
            (PROJECT_ROOT / "reports/asset-analyzer/cache" / (key + ".json")).unlink(missing_ok=True)

    def audio(self, seconds=1.0, amplitude=0.5, padding=0.1):
        path = self.root / "音效 sample.wav"
        rate = 16000
        count = int(seconds * rate)
        values = [int(amplitude * 32767 * math.sin(2 * math.pi * 400 * i / rate))
                  if padding * rate <= i < count - padding * rate else 0 for i in range(count)]
        with wave.open(str(path), "wb") as stream:
            stream.setnchannels(1)
            stream.setsampwidth(2)
            stream.setframerate(rate)
            stream.writeframes(struct.pack("<" + "h" * len(values), *values))
        return path

    def image(self, mode="RGBA"):
        path = self.root / "颜色 sample.png"
        image = Image.new(mode, (4, 2), (255, 0, 0, 255) if mode == "RGBA" else (255, 0, 0))
        if mode == "RGBA":
            image.putpixel((0, 0), (0, 255, 0, 0))
            image.putpixel((1, 0), (0, 0, 255, 128))
        image.save(path)
        return path

    def run_worker(self, path, kind, **options):
        request = {"path": str(path), "asset_type": kind} | options
        self.request.write_text(json.dumps(request, ensure_ascii=False), encoding="utf-8")
        process = subprocess.run([sys.executable, "-B", str(TOOLS / "worker.py"),
                                  "--request", str(self.request)], capture_output=True, timeout=30)
        self.assertEqual(process.returncode, 0, process.stderr)
        result = json.loads(process.stdout)
        schema = json.loads((TOOLS / "result.schema.json").read_text(encoding="utf-8"))
        jsonschema.validate(result, schema)
        validate(result)
        if result["cache"]["key"]:
            self.created_cache.append(result["cache"]["key"])
        return result

    def test_audio_levels_metadata_silence_and_series(self):
        result = self.run_worker(self.audio(), "audio")
        self.assertEqual(result["status"], "success")
        metrics = result["metrics"]
        self.assertAlmostEqual(metrics["sample_peak"]["value"], -6.02, delta=0.02)
        self.assertAlmostEqual(metrics["rms"]["value"], -10, delta=0.08)
        self.assertEqual(metrics["bit_depth"]["value"], 16)
        self.assertEqual(metrics["sample_rate"]["value"], 16000)
        self.assertEqual(metrics["integrated_loudness"]["status"], "available")
        self.assertAlmostEqual(metrics["leading_silence"]["value"], .1, delta=.001)
        self.assertEqual(len(metrics["silence_intervals"]["value"]), 2)
        self.assertEqual(len(result["series"]["peak_envelope"]["x"]), 256)

    def test_short_audio_and_advanced_states(self):
        metrics = self.run_worker(self.audio(.01, padding=0), "audio")["metrics"]
        self.assertEqual(metrics["integrated_loudness"]["status"], "not_applicable")
        self.assertEqual(metrics["true_peak"]["status"], "unsupported")
        self.assertEqual(metrics["pitch"]["status"], "unsupported")
        self.assertIsNone(metrics["pitch"]["value"])

    def test_silence_has_no_fake_finite_loudness(self):
        metrics = self.run_worker(self.audio(4, amplitude=0), "audio")["metrics"]
        for key in ("sample_peak", "rms", "integrated_loudness", "loudness_range"):
            self.assertEqual(metrics[key]["status"], "not_applicable", key)
            self.assertIsNone(metrics[key]["value"])
        self.assertEqual(metrics["leading_silence"]["value"], 4)

    def test_near_silence_is_gated(self):
        metrics = self.run_worker(self.audio(amplitude=0.0001), "audio")["metrics"]
        self.assertEqual(metrics["rms"]["status"], "available")
        self.assertEqual(metrics["integrated_loudness"]["status"], "not_applicable")

    def test_long_audio_loudness_range(self):
        metrics = self.run_worker(self.audio(4), "audio")["metrics"]
        self.assertEqual(metrics["loudness_range"]["status"], "available")
        self.assertGreaterEqual(metrics["loudness_range"]["value"], 0)

    def test_alpha_visible_colors_and_histograms(self):
        result = self.run_worker(self.image(), "image")
        metrics = result["metrics"]
        self.assertEqual(metrics["transparent_ratio"]["value"], 1 / 8)
        self.assertEqual(metrics["translucent_ratio"]["value"], 1 / 8)
        self.assertEqual(metrics["color_count"]["value"], 2)
        self.assertEqual(metrics["dominant_color"]["value"], [255, 0, 0])
        self.assertAlmostEqual(sum(result["series"]["alpha_histogram"]["y"]), 1)

    def test_rgb_image_has_opaque_alpha(self):
        metrics = self.run_worker(self.image("RGB"), "image")["metrics"]
        self.assertFalse(metrics["has_alpha"]["value"])
        self.assertEqual(metrics["opaque_ratio"]["value"], 1)

    def test_fully_transparent_has_no_dominant_color(self):
        path = self.root / "transparent.png"
        Image.new("RGBA", (2, 2)).save(path)
        metrics = self.run_worker(path, "image")["metrics"]
        self.assertEqual(metrics["dominant_color"]["status"], "not_applicable")

    def test_corrupt_and_unsupported_files(self):
        path = self.root / "broken.wav"
        path.write_bytes(b"not media")
        for kind in ("audio", "image"):
            result = self.run_worker(path, kind)
            self.assertEqual(result["status"], "failed")
            self.assertTrue(all(m["status"] == "failed" for m in result["metrics"].values()))
        self.assertEqual(self.run_worker(path, "document")["errors"][0]["code"], "unsupported_type")

    def test_cache_hit_force_content_and_parameters_invalidation(self):
        path = self.image()
        first = self.run_worker(path, "image")
        self.assertFalse(first["cache"]["hit"])
        self.assertTrue(self.run_worker(path, "image")["cache"]["hit"])
        self.assertFalse(self.run_worker(path, "image", force=True)["cache"]["hit"])
        changed_params = self.run_worker(path, "image", parameters={"palette_size": 2})
        self.assertNotEqual(first["cache"]["key"], changed_params["cache"]["key"])
        original_time = path.stat().st_mtime_ns
        Image.new("RGBA", (4, 2), (0, 0, 255, 255)).save(path)
        os.utime(path, ns=(original_time, original_time))
        changed = self.run_worker(path, "image")
        self.assertFalse(changed["cache"]["hit"])
        self.assertNotEqual(first["cache"]["key"], changed["cache"]["key"])

    def test_broken_cache_is_rebuilt(self):
        path = self.image()
        first = self.run_worker(path, "image")
        cache = PROJECT_ROOT / "reports/asset-analyzer/cache" / (first["cache"]["key"] + ".json")
        cache.write_text("{broken", encoding="utf-8")
        self.assertFalse(self.run_worker(path, "image")["cache"]["hit"])

    def test_limits_and_invalid_parameters(self):
        result = self.run_worker(self.image(), "image", parameters={"max_image_pixels": 1})
        self.assertEqual(result["status"], "failed")
        result = self.run_worker(self.audio(), "audio", parameters={"silence_dbfs": 100})
        self.assertEqual(result["status"], "failed")

    def test_missing_dependencies(self):
        with self.assertRaises(ImportError):
            worker.backends(self.root / "missing", "audio")
        isolated = self.root / "tools/asset_analyzer"
        isolated.mkdir(parents=True)
        for source in TOOLS.iterdir():
            if source.suffix in {".py", ".json", ".txt"}:
                shutil.copyfile(source, isolated / source.name)
        self.request.write_text(json.dumps({"path": str(self.audio()), "asset_type": "audio"}),
                                encoding="utf-8")
        process = subprocess.run([sys.executable, "-B", str(isolated / "worker.py"),
                                  "--request", str(self.request)], capture_output=True, timeout=10)
        self.assertEqual(process.returncode, 0)
        self.assertEqual(json.loads(process.stdout)["errors"][0]["code"], "dependency_missing")

    def test_backend_and_schema_versions_invalidate(self):
        path = self.image()
        request = {"path": str(path), "asset_type": "image"}
        temporary = self.root / "cache.tmp"
        first = worker.analyze(request, PROJECT_ROOT, temporary)
        self.created_cache.append(first["cache"]["key"])
        with patch.object(worker, "ANALYZER_VERSION", worker.ANALYZER_VERSION + 1):
            changed = worker.analyze(request, PROJECT_ROOT, temporary)
        self.created_cache.append(changed["cache"]["key"])
        self.assertNotEqual(first["cache"]["key"], changed["cache"]["key"])
        versions = first["analyzer"]["backend"] | {"fixture_revision": "2"}
        with patch.object(worker, "backends", return_value=versions):
            changed_backend = worker.analyze(request, PROJECT_ROOT, temporary)
        with patch.object(worker, "SCHEMA_VERSION", 2):
            changed_schema = worker.analyze(request, PROJECT_ROOT, temporary)
        for changed in (changed_backend, changed_schema):
            self.created_cache.append(changed["cache"]["key"])
            self.assertNotEqual(first["cache"]["key"], changed["cache"]["key"])

    def test_metric_failure_retains_other_measurements(self):
        import audio_adapter
        request = {"path": str(self.audio()), "asset_type": "audio"}
        with patch.object(audio_adapter.pyloudnorm.Meter, "integrated_loudness", side_effect=ValueError("fixture")):
            result = worker.analyze(request, PROJECT_ROOT, self.root / "cache.tmp")
        self.assertEqual(result["status"], "partial")
        self.assertEqual(result["metrics"]["integrated_loudness"]["status"], "failed")
        self.assertEqual(result["metrics"]["sample_peak"]["status"], "available")

    def test_semantically_corrupt_cache_is_recomputed(self):
        path = self.image()
        first = self.run_worker(path, "image")
        cache = PROJECT_ROOT / "reports/asset-analyzer/cache" / (first["cache"]["key"] + ".json")
        mutations = [
            lambda data: data["analyzer"].pop("id"),
            lambda data: data["series"]["alpha_histogram"].pop("x_unit"),
            lambda data: data["cache"].update(hit="yes"),
            lambda data: data["warnings"][0].pop("code"),
            lambda data: data["analyzer"].update(version=99),
            lambda data: data["parameters"].update(silence_dbfs=-10),
            lambda data: data["asset"].update(path="wrong.png"),
            lambda data: data["series"]["alpha_histogram"]["y"].__setitem__(0, float("nan")),
            lambda data: data["metrics"]["width"].update(value=10**400),
        ]
        for mutate in mutations:
            broken = copy.deepcopy(first)
            mutate(broken)
            cache.write_text(json.dumps(broken), encoding="utf-8")
            rebuilt = self.run_worker(path, "image")
            self.assertEqual(rebuilt["status"], "success")
            self.assertFalse(rebuilt["cache"]["hit"])

    def test_source_preflight_distinguishes_legal_unsupported_and_corrupt(self):
        svg = self.root / "legal.svg"
        svg.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10"/></svg>')
        self.assertEqual(self.run_worker(svg, "image")["errors"][0]["code"], "unsupported_format")
        self.assertEqual(self.run_worker(self.root, "image")["errors"][0]["code"], "source_not_file")
        self.assertEqual(self.run_worker(self.root / "missing.png", "image")["errors"][0]["code"], "source_not_file")
        png = self.root / "corrupt.png"
        png.write_bytes(b"not an image")
        self.assertEqual(self.run_worker(png, "image")["errors"][0]["code"], "corrupt_file")

    def test_loudness_budget_preserves_streaming_basic_metrics(self):
        data = self.run_worker(self.audio(), "audio", parameters={"max_loudness_samples": 100})
        self.assertEqual(data["status"], "success")
        self.assertEqual(data["metrics"]["integrated_loudness"]["status"], "unsupported")
        self.assertEqual(data["metrics"]["rms"]["status"], "available")
        self.assertEqual(data["execution"]["memory_limit_mib"], 384)

    def test_large_palette_is_explicitly_sampled(self):
        path = self.root / "larger.png"
        Image.new("RGBA", (1024, 512), (20, 40, 80, 255)).save(path)
        data = self.run_worker(path, "image")
        self.assertEqual(data["status"], "success")
        self.assertEqual(data["metrics"]["color_count"]["status"], "unsupported")
        self.assertLessEqual(data["metrics"]["palette_sample_pixels"]["value"], 262144)
        self.assertEqual(data["metrics"]["dominant_color"]["value"], [20, 40, 80])
        self.assertAlmostEqual(data["metrics"]["rgb_mean"]["value"][0], 20)

    def test_shared_protocol_mutations_match_schema_and_python(self):
        from jsonschema import validators, ValidationError
        cases = json.loads(Path(__file__).with_name("analyzer_protocol_cases.json").read_text(encoding="utf-8"))
        def equal_lengths(validator, fields, instance, schema):
            if isinstance(instance, dict) and all(isinstance(instance.get(k), list) for k in fields):
                if len(instance[fields[0]]) != len(instance[fields[1]]):
                    yield ValidationError("Paired arrays differ")
        validator_type = validators.extend(jsonschema.Draft202012Validator, {"x-equal-lengths": equal_lengths})
        validator = validator_type(json.loads((TOOLS / "result.schema.json").read_text(encoding="utf-8")))
        for case in cases["cases"]:
            data = copy.deepcopy(cases["base"])
            parent = data
            for key in case["path"][:-1]:
                parent = parent[key]
            if case.get("remove"):
                del parent[case["path"][-1]]
            else:
                parent[case["path"][-1]] = case["value"]
            with self.subTest(case=case["name"]):
                self.assertEqual(validator.is_valid(data), case["valid"])
                try:
                    validate(data)
                    accepted = True
                except ValueError:
                    accepted = False
                self.assertEqual(accepted, case["valid"])
        data = copy.deepcopy(cases["base"])
        data["metrics"]["example"]["value"] = {"nested": [float("nan")]}
        with self.assertRaises(ValueError):
            validate(data)

    def test_parent_exit_terminates_worker_and_cleans_request(self):
        self.request.write_text(json.dumps({"path": str(self.audio()), "asset_type": "audio"}),
                                encoding="utf-8")
        with subprocess.Popen([sys.executable, "-c", "import time; time.sleep(30)"]) as parent:
            with subprocess.Popen([sys.executable, "-B", str(TOOLS / "worker.py"), "--parent-pid",
                                   str(parent.pid), "--request", str(self.request)],
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE) as process:
                parent.terminate()
                parent.wait(timeout=5)
                self.assertEqual(process.wait(timeout=5), 1)
        self.assertFalse(self.request.exists())

    def test_watched_normal_completion_does_not_hold_stdin_lock(self):
        self.request.write_text(json.dumps({"path": str(self.image()), "asset_type": "image"}),
                                encoding="utf-8")
        with subprocess.Popen([sys.executable, "-B", str(TOOLS / "worker.py"), "--parent-pid",
                               str(os.getpid()), "--request", str(self.request)], stdin=subprocess.PIPE,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE) as process:
            output, errors = process.communicate(timeout=5)
            self.assertEqual(process.returncode, 0, errors)
            data = json.loads(output)
            self.assertEqual(data["status"], "success")
            self.created_cache.append(data["cache"]["key"])


if __name__ == "__main__":
    unittest.main()
