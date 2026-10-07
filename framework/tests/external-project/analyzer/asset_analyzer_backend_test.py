"""Opt-in real pinned backends in the designated project, with owned media fixtures."""

import json
import copy
import math
import os
import shutil
import struct
import subprocess
import tempfile
import threading
import unittest
from concurrent.futures import ThreadPoolExecutor
from unittest.mock import patch
import wave

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

TOOLS = PROJECT_ROOT / "yaya/tools/analyzer"
sys.path.insert(0, str(TOOLS))
for variable in ("OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "NUMBA_NUM_THREADS"):
    os.environ[variable] = "1"

import jsonschema
import numpy as np
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
        for key in set(self.created_cache):
            (PROJECT_ROOT / "reports/asset-analyzer/cache" / (key + ".json")).unlink(missing_ok=True)
            directory = PROJECT_ROOT / "reports/asset-analyzer/cache" / key
            if directory.is_dir():
                shutil.rmtree(directory)

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

    def run_worker(self, path, kind, *, output=False, request_path=None, **options):
        request = {"path": str(path), "asset_type": kind} | options
        request_file = request_path or self.request
        request_file.write_text(json.dumps(request, ensure_ascii=False), encoding="utf-8")
        command = [sys.executable, "-B", str(TOOLS / "worker.py"), "--request", str(request_file)]
        result_file = request_file.with_suffix(".result.json")
        if output:
            command += ["--output", str(result_file)]
        process = subprocess.run(command, capture_output=True, timeout=60)
        self.assertEqual(process.returncode, 0, process.stderr)
        if output:
            self.assertEqual(process.stdout, b"")
        result = json.loads(result_file.read_bytes() if output else process.stdout)
        self.last_stderr = process.stderr.decode("utf-8", errors="replace")
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
        self.assertEqual(metrics["true_peak"]["status"], "available")
        self.assertEqual(metrics["pitch"]["status"], "not_applicable")
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
        missing = worker.importlib.metadata.PackageNotFoundError
        with patch.object(worker.importlib.metadata, "version", side_effect=missing("av")):
            with self.assertRaises(ImportError):
                worker.backends("audio")
        # 隔离副本只加入一个不存在的依赖，验证真实进程的缺包出口。
        isolated = self.root / "yaya/tools/analyzer"
        shutil.copytree(TOOLS, isolated, ignore=shutil.ignore_patterns("__pycache__"))
        pins = (isolated / "requirements.txt").read_text(encoding="utf-8").splitlines()
        (isolated / "requirements.txt").write_text(
            "\n".join(pins) + "\nyaya-missing-backend-fixture==0.0.0\n",
            encoding="utf-8")
        self.request.write_text(json.dumps({"path": str(self.audio()), "asset_type": "audio"}),
                                encoding="utf-8")
        process = subprocess.run([sys.executable, "-B", str(isolated / "worker.py"),
                                  "--request", str(self.request)], capture_output=True, timeout=10)
        self.assertEqual(process.returncode, 0)
        self.assertEqual(json.loads(process.stdout)["errors"][0]["code"], "dependency_missing")

    def test_backend_and_schema_versions_invalidate(self):
        path = self.image()
        request = {"path": str(path), "asset_type": "image"}
        first = worker.analyze(request, PROJECT_ROOT)
        self.created_cache.append(first["cache"]["key"])
        with patch.object(worker, "ANALYZER_VERSION", worker.ANALYZER_VERSION + 1):
            changed = worker.analyze(request, PROJECT_ROOT)
        self.created_cache.append(changed["cache"]["key"])
        self.assertNotEqual(first["cache"]["key"], changed["cache"]["key"])
        versions = first["analyzer"]["backend"] | {"fixture_revision": "2"}
        with patch.object(worker, "backends", return_value=versions):
            changed_backend = worker.analyze(request, PROJECT_ROOT)
        with patch.object(worker, "SCHEMA_VERSION", 2):
            changed_schema = worker.analyze(request, PROJECT_ROOT)
        for changed in (changed_backend, changed_schema):
            self.created_cache.append(changed["cache"]["key"])
            self.assertNotEqual(first["cache"]["key"], changed["cache"]["key"])

    def test_metric_failure_retains_other_measurements(self):
        import audio_adapter
        request = {"path": str(self.audio()), "asset_type": "audio"}
        with patch.object(audio_adapter.pyloudnorm.Meter, "integrated_loudness", side_effect=ValueError("fixture")):
            result = worker.analyze(request, PROJECT_ROOT)
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

    def write_audio(self, samples, rate=48000):
        samples = np.asarray(samples)
        if samples.ndim == 1:
            samples = samples[:, None]
        path = self.root / "synthetic.wav"
        with wave.open(str(path), "wb") as stream:
            stream.setnchannels(samples.shape[1])
            stream.setsampwidth(2)
            stream.setframerate(rate)
            stream.writeframes((np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes())
        return path

    def test_output_success_failure_and_stdout_compatibility(self):
        for source, expected in ((self.image(), "success"), (self.root / "missing.png", "failed")):
            with self.subTest(expected=expected):
                file_result = self.run_worker(source, "image", output=True, modules=[])
                self.assertEqual(file_result["status"], expected)
                stdout_result = self.run_worker(source, "image", modules=[])
                self.assertEqual(stdout_result["status"], expected)

    def test_cross_volume_request_and_destination_temporaries(self):
        import atomic_output
        self.assertEqual(PROJECT_ROOT.drive.upper(), "D:")
        local_temp = Path(os.environ["LOCALAPPDATA"]) / "Temp"
        self.assertEqual(local_temp.drive.upper(), "C:")
        with tempfile.TemporaryDirectory(prefix="analyzer-cross-volume-", dir=local_temp) as directory:
            request = Path(directory) / "request.json"
            source = self.image()
            data = self.run_worker(source, "image", output=True, request_path=request)
            self.assertEqual(data["status"], "success")
            self.assertTrue((PROJECT_ROOT / "reports/asset-analyzer/cache" / (data["cache"]["key"] + ".json")).is_file())
            with patch.object(atomic_output.os, "replace", wraps=os.replace) as replace:
                worker.analyze({"path": str(source), "asset_type": "image", "force": True}, PROJECT_ROOT)
            self.assertGreaterEqual(replace.call_count, 2)
            for call in replace.call_args_list:
                temporary, target = map(Path, call.args)
                self.assertEqual(temporary.parent, target.parent)
                self.assertEqual(target.drive.upper(), "D:")

    def test_module_selection_unknown_and_failure_retains_basics(self):
        path = self.audio()
        default = self.run_worker(path, "audio")
        self.assertIn("audio_pitch", default["analyzer"]["modules"])
        basic = self.run_worker(path, "audio", modules=[])
        self.assertEqual(basic["analyzer"]["modules"], [])
        self.assertNotIn("max_rms_10ms", basic["metrics"])
        chosen = self.run_worker(path, "audio", modules=["audio_max_rms"])
        self.assertEqual(chosen["analyzer"]["modules"], ["audio_max_rms"])
        self.assertEqual(chosen["metrics"]["max_rms_10ms"]["status"], "available")
        self.assertEqual(self.run_worker(path, "audio", modules=["unknown"])["errors"][0]["code"], "invalid_modules")
        import features.audio_max_rms as module
        with patch.object(module, "run", side_effect=RuntimeError("synthetic module failure")):
            failed = worker.analyze({"path": str(path), "asset_type": "audio", "force": True,
                                     "modules": ["audio_max_rms"]}, PROJECT_ROOT)
        self.assertEqual(failed["status"], "partial")
        self.assertEqual(failed["metrics"]["sample_peak"]["status"], "available")
        self.assertEqual(failed["metrics"]["max_rms_10ms"]["status"], "failed")

    def test_concurrent_same_image_workers_publish_consistent_results(self):
        # Exercise the actual Windows replacement conflict for both artifact types.
        for suffix in ("png", "json"):
            with self.subTest(suffix=suffix):
                target = self.root / ("held." + suffix)
                target.write_bytes(b"old")
                marker = self.root / ("attempt." + suffix)
                script = (
                    "import sys; from pathlib import Path; sys.path.insert(0," + repr(str(TOOLS)) + "); "
                    "import atomic_output as a\n"
                    "original=a.os.replace\n"
                    "def observed(source,target):\n"
                    "    try: original(source,target)\n"
                    "    except PermissionError:\n"
                    "        Path(" + repr(str(marker)) + ").write_text('sharing conflict')\n"
                    "        raise\n"
                    "a.os.replace=observed\n"
                    "with a.atomic_target(" + repr(str(target)) + ") as temporary:\n"
                    "    temporary.write_bytes(b'new')\n")
                with target.open("rb") as held, subprocess.Popen(
                        [sys.executable, "-B", "-c", script], stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE) as child:
                    import time
                    deadline = time.monotonic() + 10
                    while not marker.exists() and child.poll() is None and time.monotonic() < deadline:
                        time.sleep(.01)
                    held.close()
                    stdout, stderr = child.communicate(timeout=10)
                self.assertTrue(marker.exists(), stderr)
                self.assertEqual(child.returncode, 0, stderr)
                self.assertEqual(stdout, b"")
                self.assertEqual(target.read_bytes(), b"new")
        source = self.image()
        with ThreadPoolExecutor(max_workers=2) as pool:
            futures = [pool.submit(self.run_worker, source, "image", output=True, force=True,
                                   request_path=self.root / f"parallel-{index}.json")
                       for index in range(2)]
            first, second = [future.result() for future in futures]
        self.assertEqual(first["status"], "success")
        self.assertEqual(second["status"], "success")
        for field in ("asset", "analyzer", "metrics", "series", "warnings", "errors", "cache"):
            self.assertEqual(first[field], second[field], field)

    def test_unselected_modules_do_not_import_calculation_libraries(self):
        for source, kind, excluded in ((self.audio(), "audio", ("librosa", "numba")),
                                       (self.image(), "image", ("skimage",))):
            self.request.write_text(json.dumps({"path": str(source), "asset_type": kind, "modules": []}), encoding="utf-8")
            output = self.root / "lazy.result.json"
            script = ("import sys,runpy; sys.path.insert(0," + repr(str(TOOLS)) + "); "
                      "sys.argv=" + repr([str(TOOLS / "worker.py"), "--request", str(self.request), "--output", str(output)]) + "; "
                      "namespace=runpy.run_path(sys.argv[0]); assert namespace['main']()==0; "
                      "assert not any(p in sys.modules for p in " + repr(excluded) + ")")
            process = subprocess.run([sys.executable, "-B", "-c", script], capture_output=True, timeout=30)
            self.assertEqual(process.returncode, 0, process.stderr)
            self.assertEqual(process.stdout, b"")
            self.created_cache.append(json.loads(output.read_bytes())["cache"]["key"])

    def test_module_sets_order_and_missing_png_invalidate_cache(self):
        path = self.audio()
        one = self.run_worker(path, "audio", modules=["audio_max_rms"])
        pair = self.run_worker(path, "audio", modules=["audio_max_rms", "audio_energy_duration"])
        reversed_pair = self.run_worker(path, "audio", modules=["audio_energy_duration", "audio_max_rms"])
        self.assertNotEqual(one["cache"]["key"], pair["cache"]["key"])
        self.assertEqual(pair["cache"]["key"], reversed_pair["cache"]["key"])
        self.assertTrue(reversed_pair["cache"]["hit"])
        image = self.image()
        first = self.run_worker(image, "image")
        Path(first["metrics"]["cvd_grid"]["value"]["path"]).unlink()
        rebuilt = self.run_worker(image, "image")
        self.assertFalse(rebuilt["cache"]["hit"])
        self.assertTrue(Path(rebuilt["metrics"]["cvd_grid"]["value"]["path"]).is_file())

    def test_max_rms_loudest_channel_complete_windows(self):
        signal = np.zeros((24000, 2))
        signal[4800:5280] = (.2, .8)
        metrics = self.run_worker(self.write_audio(signal), "audio", modules=["audio_max_rms"])["metrics"]
        for ms, amplitude in ((10, .8), (20, .8 / math.sqrt(2)), (50, .8 / math.sqrt(5))):
            self.assertAlmostEqual(metrics[f"max_rms_{ms}ms"]["value"], 20 * math.log10(amplitude), delta=.003)
        short = self.run_worker(self.write_audio(np.ones(240) * .5), "audio", modules=["audio_max_rms"])["metrics"]
        for name in ("max_rms_10ms", "max_rms_20ms", "max_rms_50ms"):
            self.assertEqual(short[name]["status"], "not_applicable")

    def test_known_envelope_crossings_and_energy_duration(self):
        envelope = np.r_[np.zeros(10), np.linspace(0, 1, 101), np.linspace(1, 0, 201), np.zeros(20)]
        source = self.write_audio(np.repeat(envelope * .8, 48))
        metrics = self.run_worker(source, "audio", modules=["audio_attack_decay", "audio_energy_duration"])["metrics"]
        self.assertAlmostEqual(metrics["attack_10_90"]["value"], .080, delta=.002)
        self.assertAlmostEqual(metrics["decay_to_10"]["value"], .181, delta=.002)
        # Analytic triangular-envelope energy quantiles, with 1 ms discretization.
        self.assertAlmostEqual(metrics["energy_duration_95"]["value"], .191, delta=.002)

    def test_spectrum_tones_bands_and_antiphase_stereo(self):
        time = np.arange(24000) / 48000
        mono = .5 * np.sin(2 * np.pi * 1000 * time)
        first = self.run_worker(self.write_audio(mono), "audio", modules=["audio_spectrum"])["metrics"]
        self.assertAlmostEqual(first["spectral_centroid"]["value"], 1000, delta=5)
        self.assertGreater(first["band_energy_ratios"]["value"][2]["ratio"], .995)
        antiphase = self.run_worker(self.write_audio(np.column_stack((mono, -mono))), "audio",
                                    modules=["audio_spectrum"])["metrics"]
        self.assertAlmostEqual(antiphase["spectral_centroid"]["value"], first["spectral_centroid"]["value"], delta=.01)
        dual = .25 * np.sin(2 * np.pi * 93.75 * time) + .5 * np.sin(2 * np.pi * 3000 * time)
        metrics = self.run_worker(self.write_audio(dual), "audio", modules=["audio_spectrum"])["metrics"]
        self.assertAlmostEqual(metrics["spectral_centroid"]["value"], 2031.25, delta=10)
        self.assertAlmostEqual(metrics["band_energy_ratios"]["value"][0]["ratio"], .2, delta=.01)
        self.assertAlmostEqual(metrics["band_energy_ratios"]["value"][3]["ratio"], .8, delta=.01)

    def test_true_peak_intersample_and_chunk_equivalence(self):
        from scipy.signal import resample_poly
        from features.audio_true_peak import true_peak_estimate
        signal = (.9 * np.sin(np.pi / 2 * np.arange(70000) + np.pi / 4)).astype(np.float32)[:, None]
        expected = max(float(np.abs(signal).max()), float(np.abs(resample_poly(signal, 4, 1, axis=0)).max()))
        actual = true_peak_estimate((signal[start:start + 1001] for start in range(0, len(signal), 1001)), 1)
        self.assertAlmostEqual(actual, expected, delta=1e-6)
        data = self.run_worker(self.write_audio(signal), "audio", modules=["audio_true_peak"])
        self.assertGreater(data["metrics"]["true_peak"]["value"], data["metrics"]["sample_peak"]["value"] + 2)

    def test_pyin_a4_d7_noise_short_and_two_periods(self):
        time = np.arange(16000) / 16000
        for frequency, note in ((440, "A4"), (2349.318, "D7")):
            with self.subTest(note=note):
                source = self.write_audio(.5 * np.sin(2 * np.pi * frequency * time), rate=16000)
                metrics = self.run_worker(source, "audio", modules=["audio_pitch"])["metrics"]
                self.assertEqual(metrics["pitch_note"]["value"], note)
                self.assertGreater(metrics["pitch_confidence"]["value"], .5)
                self.assertNotIn("less than two periods", self.last_stderr)
        noise = np.random.default_rng(31).normal(0, .15, 16000)
        for signal in (noise, np.ones(160) * .2):
            metrics = self.run_worker(self.write_audio(signal, rate=16000), "audio", modules=["audio_pitch"])["metrics"]
            self.assertEqual(metrics["pitch"]["status"], "not_applicable")
            self.assertIsNone(metrics["pitch"]["value"])

    def test_cvd_neutral_gray_panel_order_and_readable_png(self):
        path = self.root / "cvd.png"
        for color in ((128, 128, 128), (255, 0, 0)):
            Image.new("RGB", (32, 32), color).save(path)
            value = self.run_worker(path, "image")["metrics"]["cvd_grid"]["value"]
            self.assertEqual(value["panels"], ["normal", "gray", "protan", "deutan"])
            expected = [color] * 4 if color[0] == 128 else [(255, 0, 0), (127, 127, 127), (109, 95, 0), (163, 144, 0)]
            with Image.open(value["path"]) as grid:
                self.assertEqual(grid.format, "PNG")
                grid.load()
                for index, target in enumerate(expected):
                    pixel = grid.getpixel(((index % 2) * 32 + 16, (index // 2) * 56 + 40))[:3]
                    self.assertTrue(all(abs(a - b) <= 1 for a, b in zip(pixel, target)), (pixel, target))

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
            # 父进程在清理前可能一直开着 stdin；communicate() 会先关闭它，测不到 stdin 阻塞。
            # 输出要边运行边读走，否则结果写满 Windows 管道缓冲后 worker 会卡在写入上。
            streams = {}
            readers = [threading.Thread(target=lambda name=name: streams.__setitem__(
                name, getattr(process, name).read())) for name in ("stdout", "stderr")]
            for reader in readers:
                reader.start()
            try:
                returncode = process.wait(timeout=5)
            finally:
                process.stdin.close()
                for reader in readers:
                    reader.join(timeout=5)
            output, errors = streams.get("stdout", b""), streams.get("stderr", b"")
            self.assertEqual(returncode, 0, errors)
            data = json.loads(output)
            self.assertEqual(data["status"], "success")
            self.created_cache.append(data["cache"]["key"])


if __name__ == "__main__":
    unittest.main()
