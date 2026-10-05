"""Malformed records and unreadable artifacts take the documented failure paths, not tracebacks."""
# 嵌套类型错误、不是对象的运行记录和读不了的原件，都要变成工具约定的错误，而不是 AttributeError。
from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from project_context import PROJECT_ROOT  # noqa: F401  (adds the project's yaya/ to sys.path)

import json
import tempfile
import unittest
from unittest import mock

from tools.lib import test_run_evidence
from tools.lib.test_selection import SelectionError, acceptance_mode
from tools.lib.verification_snapshot import EvidenceError, semantic_json


class MalformedRecordTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)

    def test_verification_that_is_not_an_object_is_a_selection_error(self) -> None:
        with self.assertRaisesRegex(SelectionError, "verification must be an object"):
            acceptance_mode({"verification": None})

    def test_meta_that_is_not_an_object_is_an_evidence_error(self) -> None:
        with self.assertRaisesRegex(EvidenceError, "meta must be an object"):
            semantic_json("docs/test-registry.json", {"meta": []})

    def test_run_result_that_is_not_an_object_is_reported_as_history_damage(self) -> None:
        run = self.root / "reports/gdunit-wrapper/focused/run-abc"
        run.mkdir(parents=True)
        (run / "result.json").write_text("[]", encoding="utf-8")
        records, errors = test_run_evidence._run_records(self.root, None)
        self.assertEqual(records, [])
        self.assertEqual(len(errors), 1)
        self.assertIn("expected JSON object", errors[0])

    def test_process_that_is_not_an_object_fails_the_run_check(self) -> None:
        with self.assertRaisesRegex(test_run_evidence.RunEvidenceError, "process record must be an object"):
            test_run_evidence._checked_cases(self.root, self.root, {"process": "bad", "artifacts": {}})

    def test_unreadable_artifact_still_finishes_the_run_as_failed(self) -> None:
        (self.root / "engine.log").write_text("log", encoding="utf-8")
        with mock.patch.object(test_run_evidence, "artifact_reference", side_effect=OSError("locked")):
            result = test_run_evidence.finish_run(self.root, self.root, {"snapshot": None})
        self.assertEqual(result["status"], "failed")
        self.assertTrue(any("cannot read run artifact engine.log" in error for error in result["errors"]))
        saved = json.loads((self.root / "result.json").read_text(encoding="utf-8"))
        self.assertEqual(saved["status"], "failed")


if __name__ == "__main__":
    unittest.main()
