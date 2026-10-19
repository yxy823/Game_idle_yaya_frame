from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT

import importlib.util
import json
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location(
    "check_behavior_model", PROJECT_ROOT / "yaya/tools/checks/check-behavior-model.py"
)
assert SPEC is not None and SPEC.loader is not None
check_behavior_model = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(check_behavior_model)

# 一个计数器：Inc 只在 x < 2 时加一。"skip_guard" 去掉条件，"noop" 什么也不改。
COUNTER_MODEL = """---- MODULE Counter ----
EXTENDS Integers
CONSTANT Mutation
VARIABLE x
Init == x = 0
Inc == /\\ (x < 2 \\/ Mutation = "skip_guard") /\\ x < 3
       /\\ x' = IF Mutation = "noop" THEN x ELSE x + 1
Spec == Init /\\ [][Inc]_x
AtMostTwo == x <= 2
NeverDecreases == [][x' >= x]_x
WitnessReachesTwo == x # 2
====
"""


def manifest(mutations: list[dict]) -> dict:
    return {"invariants": ["AtMostTwo"], "properties": ["NeverDecreases"], "check_deadlock": False,
            "mutations": mutations, "witnesses": ["WitnessReachesTwo"]}


class OutputParsingTests(unittest.TestCase):
    def test_classifies_tlc_endings(self) -> None:
        cases = {
            "Model checking completed. No error has been found.\n10 states generated, 4 distinct states found":
                ("completed", None, 4),
            "Error: Invariant AtMostTwo is violated.\n1,204 distinct states found": ("violated", "AtMostTwo", 1204),
            "Error: Action property NeverDecreases is violated.": ("violated", "NeverDecreases", None),
            "Error: Temporal properties were violated.": ("violated", "temporal", None),
            "Error: Deadlock reached.": ("violated", "deadlock", None),
            "Error: Parsing or semantic analysis failed.": ("error", None, None),
        }
        for text, (outcome, violated, states) in cases.items():
            with self.subTest(text=text):
                parsed = check_behavior_model.parse_output(text)
                self.assertEqual((parsed["outcome"], parsed["violated"], parsed["distinct_states"]),
                                 (outcome, violated, states))

    def test_each_caught_by_name_runs_alone(self) -> None:
        # TLC 只报第一个违反；两条性质放进同一次运行，后一条是否起作用就验证不到。
        runs = check_behavior_model.plan_runs(
            manifest([{"name": "skip_guard", "caught_by": ["AtMostTwo", "NeverDecreases"]}]))
        checked = [(run["invariants"], run["properties"]) for run in runs if run["kind"] == "mutation"]
        self.assertEqual(checked, [(["AtMostTwo"], []), ([], ["NeverDecreases"])])


class ManifestTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.path = Path(self.temporary.name) / "Counter.checks.json"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_rejects_manifests_that_cannot_prove_the_checks_work(self) -> None:
        cases = {
            "no mutations": manifest([]),
            "caught_by not checked": manifest([{"name": "noop", "caught_by": ["Elsewhere"]}]),
            "mutation named none": manifest([{"name": "none", "caught_by": ["AtMostTwo"]}]),
            "duplicate mutation": manifest([{"name": "noop", "caught_by": ["AtMostTwo"]}] * 2),
            "no witnesses": {**manifest([{"name": "noop", "caught_by": ["AtMostTwo"]}]), "witnesses": []},
        }
        for label, value in cases.items():
            with self.subTest(label=label):
                self.path.write_text(json.dumps(value), encoding="utf-8")
                with self.assertRaises(check_behavior_model.ModelCheckError):
                    check_behavior_model.read_manifest(self.path)


class TlcRunTests(unittest.TestCase):
    """Runs the configured TLC on a three-state model."""

    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        project_config = json.loads((PROJECT_ROOT / "docs/methodology-config.json").read_text(encoding="utf-8"))
        (self.root / "docs/models").mkdir(parents=True)
        (self.root / "docs/methodology-config.json").write_text(json.dumps({
            "java_executable": str((PROJECT_ROOT / project_config["java_executable"]).resolve()),
            "tla_tools_jar": str((PROJECT_ROOT / project_config["tla_tools_jar"]).resolve()),
        }), encoding="utf-8")
        (self.root / "docs/models/Counter.tla").write_text(COUNTER_MODEL, encoding="utf-8")

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _run(self, mutations: list[dict]) -> tuple[int, dict]:
        (self.root / "docs/models/Counter.checks.json").write_text(json.dumps(manifest(mutations)), encoding="utf-8")
        code = check_behavior_model.main(["docs/models/Counter.tla", "--repo-root", str(self.root)])
        summary = next((self.root / "reports/model-checks/Counter").glob("run-*/summary.json"))
        return code, json.loads(summary.read_text(encoding="utf-8"))

    def test_all_expectations_met(self) -> None:
        code, summary = self._run([{"name": "skip_guard", "caught_by": ["AtMostTwo"]}])
        self.assertEqual(code, 0)
        self.assertEqual([run["passed"] for run in summary["runs"]], [True, True, True])
        self.assertEqual(summary["properties_without_mutation"], ["NeverDecreases"])

    def test_every_listed_property_must_catch_the_mutation(self) -> None:
        code, summary = self._run([{"name": "skip_guard", "caught_by": ["AtMostTwo", "NeverDecreases"]}])
        self.assertEqual(code, 1)
        self.assertEqual([run["passed"] for run in summary["runs"] if run["kind"] == "mutation"], [True, False])

    def test_uncaught_mutation_fails_the_whole_check(self) -> None:
        code, summary = self._run([{"name": "noop", "caught_by": ["AtMostTwo"]}])
        self.assertEqual(code, 1)
        mutation = summary["runs"][1]
        self.assertEqual((mutation["outcome"], mutation["passed"]), ("completed", False))


if __name__ == "__main__":
    unittest.main()
