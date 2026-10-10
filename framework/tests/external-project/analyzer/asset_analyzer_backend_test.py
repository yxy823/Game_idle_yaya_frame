"""Opt-in real pinned backends in the designated project, with owned media fixtures."""

import json
import copy
import os
import shutil
import subprocess
import tempfile
import threading
import unittest
from concurrent.futures import ThreadPoolExecutor
from unittest.mock import patch

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

TOOLS = PROJECT_ROOT / "yaya/tools/analyzer"
sys.path.insert(0, str(TOOLS))
for variable in ("OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS"):
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
        path = self.root / "broken.png"
        path.write_bytes(b"not media")
        result = self.run_worker(path, "image")
        self.assertEqual(result["status"], "failed")
        self.assertTrue(all(m["status"] == "failed" for m in result["metrics"].values()))
        for kind in ("audio", "document"):
            rejected = self.run_worker(path, kind)
            self.assertEqual(rejected["errors"][0]["code"], "unsupported_type")
            self.assertEqual(rejected["analyzer"]["supported_types"], [])
            self.assertEqual(rejected["metrics"], {})

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
        result = self.run_worker(self.image(), "image", parameters={"palette_size": 100})
        self.assertEqual(result["status"], "failed")

    def test_missing_dependencies(self):
        missing = worker.importlib.metadata.PackageNotFoundError
        with patch.object(worker.importlib.metadata, "version", side_effect=missing("Pillow")):
            with self.assertRaises(ImportError):
                worker.backends()
        # 隔离副本只加入一个不存在的依赖，验证真实进程的缺包出口。
        isolated = self.root / "yaya/tools/analyzer"
        shutil.copytree(TOOLS, isolated, ignore=shutil.ignore_patterns("__pycache__"))
        pins = (isolated / "requirements.txt").read_text(encoding="utf-8").splitlines()
        (isolated / "requirements.txt").write_text(
            "\n".join(pins) + "\nyaya-missing-backend-fixture==0.0.0\n",
            encoding="utf-8")
        self.request.write_text(json.dumps({"path": str(self.image()), "asset_type": "image"}),
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
        import features.image_cvd_grid as module
        request = {"path": str(self.image()), "asset_type": "image", "force": True}
        with patch.object(module, "run", side_effect=RuntimeError("fixture")):
            result = worker.analyze(request, PROJECT_ROOT)
        self.assertEqual(result["status"], "partial")
        self.assertEqual(result["metrics"]["cvd_grid"]["status"], "failed")
        self.assertEqual(result["metrics"]["width"]["status"], "available")

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
            lambda data: data["parameters"].update(palette_size=2),
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

    def test_output_success_failure_and_stdout_compatibility(self):
        for source, expected in ((self.image(), "success"), (self.root / "missing.png", "failed")):
            with self.subTest(expected=expected):
                file_result = self.run_worker(source, "image", output=True, modules=[])
                self.assertEqual(file_result["status"], expected)
                stdout_result = self.run_worker(source, "image", modules=[])
                self.assertEqual(stdout_result["status"], expected)

    def test_invalid_requests_return_structured_failures_in_both_modes(self):
        schema = json.loads((TOOLS / "result.schema.json").read_text(encoding="utf-8"))
        cases = {"[]": "invalid_request", "null": "invalid_request",
                 '{"path": "a.png", "asset_type": []}': "invalid_request",
                 '{"path": 5, "asset_type": "image"}': "invalid_request",
                 '{"path": "' + "x" * (2 * 1024**2) + '", "asset_type": "image"}': "invalid_request"}
        for text, code in cases.items():
            self.request.write_text(text, encoding="utf-8")
            output = self.root / "invalid.result.json"
            for command in ([], ["--output", str(output)]):
                with self.subTest(request=text[:40], output=bool(command)):
                    process = subprocess.run([sys.executable, "-B", str(TOOLS / "worker.py"), "--request",
                                              str(self.request), *command], capture_output=True, timeout=60)
                    self.assertEqual(process.returncode, 0, process.stderr)
                    result = json.loads(output.read_bytes() if command else process.stdout)
                    jsonschema.validate(result, schema)
                    self.assertEqual(result["status"], "failed")
                    self.assertEqual(result["errors"][0]["code"], code)

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

    def test_module_selection_and_unknown_modules(self):
        path = self.image()
        default = self.run_worker(path, "image")
        self.assertEqual(default["analyzer"]["modules"], ["image_cvd_grid"])
        basic = self.run_worker(path, "image", modules=[])
        self.assertEqual(basic["analyzer"]["modules"], [])
        self.assertNotIn("cvd_grid", basic["metrics"])
        chosen = self.run_worker(path, "image", modules=["image_cvd_grid"])
        self.assertEqual(chosen["metrics"]["cvd_grid"]["status"], "available")
        self.assertEqual(self.run_worker(path, "image", modules=["unknown"])["errors"][0]["code"], "invalid_modules")

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
        self.request.write_text(json.dumps({"path": str(self.image()), "asset_type": "image", "modules": []}), encoding="utf-8")
        output = self.root / "lazy.result.json"
        script = ("import sys,runpy; sys.path.insert(0," + repr(str(TOOLS)) + "); "
                  "sys.argv=" + repr([str(TOOLS / "worker.py"), "--request", str(self.request), "--output", str(output)]) + "; "
                  "namespace=runpy.run_path(sys.argv[0]); assert namespace['main']()==0; "
                  "assert 'skimage' not in sys.modules")
        process = subprocess.run([sys.executable, "-B", "-c", script], capture_output=True, timeout=30)
        self.assertEqual(process.returncode, 0, process.stderr)
        self.assertEqual(process.stdout, b"")
        self.created_cache.append(json.loads(output.read_bytes())["cache"]["key"])

    def test_module_sets_and_missing_png_invalidate_cache(self):
        image = self.image()
        basic = self.run_worker(image, "image", modules=[])
        first = self.run_worker(image, "image", modules=["image_cvd_grid"])
        duplicate = self.run_worker(image, "image", modules=["image_cvd_grid", "image_cvd_grid"])
        self.assertNotEqual(basic["cache"]["key"], first["cache"]["key"])
        self.assertEqual(first["cache"]["key"], duplicate["cache"]["key"])
        self.assertTrue(duplicate["cache"]["hit"])
        Path(first["metrics"]["cvd_grid"]["value"]["path"]).unlink()
        rebuilt = self.run_worker(image, "image")
        self.assertFalse(rebuilt["cache"]["hit"])
        self.assertTrue(Path(rebuilt["metrics"]["cvd_grid"]["value"]["path"]).is_file())

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
        self.request.write_text(json.dumps({"path": str(self.image()), "asset_type": "image"}),
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
