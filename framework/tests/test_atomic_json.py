"""Shared JSON writes preserve existing documents and clean failed replacements."""
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SOURCE = Path(__file__).resolve().parents[2] / "project-source/tools/lib/atomic_json.py"
SPEC = importlib.util.spec_from_file_location("atomic_json_fixture", SOURCE)
atomic_json = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(atomic_json)


class AtomicJsonTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="yaya-atomic-json-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.path = self.root / "record.json"
        self.path.write_text('{"original": true}\n', encoding="utf-8", newline="\n")

    def test_replacement_is_utf8_json_and_leaves_only_the_destination(self):
        value = {"status": "pending", "description": "等待人工结果"}
        atomic_json.write_json(self.path, value)
        self.assertEqual(json.loads(self.path.read_text(encoding="utf-8")), value)
        self.assertNotIn(b"\r\n", self.path.read_bytes())
        self.assertEqual(list(self.root.iterdir()), [self.path])

    def test_failed_replacement_preserves_old_document_and_removes_temporary(self):
        original = self.path.read_bytes()
        with mock.patch.object(atomic_json.os, "replace", side_effect=OSError("replace failed")):
            with self.assertRaisesRegex(OSError, "replace failed"):
                atomic_json.write_json(self.path, {"updated": True})
        self.assertEqual(self.path.read_bytes(), original)
        self.assertEqual(list(self.root.iterdir()), [self.path])

    def test_serialization_failure_preserves_old_document_and_removes_temporary(self):
        original = self.path.read_bytes()
        with self.assertRaises(TypeError):
            atomic_json.write_json(self.path, {"unsupported": object()})
        self.assertEqual(self.path.read_bytes(), original)
        self.assertEqual(list(self.root.iterdir()), [self.path])


if __name__ == "__main__":
    unittest.main()
