"""Protect section-level search and Markdown-owned handbook navigation."""

from html.parser import HTMLParser
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from urllib.parse import unquote

from framework.commands import build_blank_project_handbook as handbook


class Links(HTMLParser):
    def __init__(self, source):
        super().__init__()
        self.anchors = []
        self.feed(source)

    def handle_starttag(self, tag, attrs):
        if tag == "a":
            self.anchors.append(dict(attrs))


class HandbookNavigationTests(unittest.TestCase):
    def setUp(self):
        area = tempfile.TemporaryDirectory(prefix="handbook_navigation_")
        self.addCleanup(area.cleanup)
        self.root = Path(area.name)
        self.manual = self.root / "manual"
        self.manual.mkdir()
        overrides = patch.multiple(handbook, ROOT=self.root, MANUAL=self.manual,
                                   OUTPUT=self.manual / "handbook.html")
        overrides.start()
        self.addCleanup(overrides.stop)

    def document(self, name, text):
        path = self.manual / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return handbook.parse_document(path)

    def test_body_and_tables_belong_to_nearest_heading_without_code_leakage(self):
        doc = self.document("guides/scenarios-resources.md", """# Resource scenarios

Chapter introduction.

## Assets

普通正文与 `UID`。

| 检查 | 结果 |
| --- | --- |
| 音效 | 循环接缝 |

### Playback

Child paragraph with "quotes" & symbols.

#### Detail

Lower heading detail.

```text
CODE_ONLY_SENTINEL
```

```mermaid
flowchart TD
    A[DIAGRAM_ONLY_SENTINEL]
```

    INDENTED_CODE_SENTINEL

## Assets

Second section only.
""")
        sections = handbook.section_search_text(doc)
        self.assertEqual(sections[""], "Chapter introduction.")
        self.assertIn("UID", sections["assets"])
        self.assertIn("音效 循环接缝", sections["assets"])
        self.assertIn("Lower heading detail.", sections["playback"])
        self.assertNotIn("Child paragraph", sections["assets"])
        self.assertNotIn("Second section", sections["playback"])
        self.assertEqual(sections["assets-1"], "Second section only.")
        self.assertNotIn("SENTINEL", " ".join(sections.values()))
        navigation, body = handbook.render_body([doc], [])
        anchors = Links(navigation).anchors
        playback = next(link for link in anchors if link.get("data-section", "").endswith("--playback"))
        self.assertEqual(playback["data-search-text"], sections["playback"])
        handbook.check_output(navigation + body, 0)

    def test_quick_start_follows_readme_links_and_new_scenario_h2s(self):
        self.document("README.md", """# Manual

## 第一次使用路线

1. [Setup](getting-started/setup.md).
2. [Develop](guides/development.md).

## Other

[Scenario index](guides/scenario-procedures.md)
[Resources](guides/scenarios-resources.md)
""")
        self.document("getting-started/setup.md", "# Setup\n\n## Environment\n")
        self.document("guides/development.md", "# Develop\n\n## Implement\n")
        self.document("guides/scenario-procedures.md", "# Index\n\n## Choose\n")
        scenario = self.document("guides/scenarios-resources.md", """# 场景处置：Resources

## Import & verify

### Details

## Newly added procedure
""")
        docs = handbook.load_documents()
        self.assertEqual([doc.group for doc in docs], ["", "getting-started", "guides", "scenarios", "scenarios"])
        handbook.rewrite_links(docs)
        quick = handbook.render_quick_start(docs)
        anchors = [unquote(link["href"]) for link in Links(quick).anchors]
        expected = ["#" + doc.key for doc in docs[1:3]]
        expected.extend("#" + scenario.key + "--" + slug for level, _, slug in scenario.headings if level == 2)
        self.assertEqual(anchors, expected)
        self.assertIn("Import &amp; verify", quick)
        navigation, body = handbook.render_body(docs, [])
        self.assertIn(">场景检查单</p>", navigation)
        handbook.check_output(quick + navigation + body, 0)

    def test_missing_first_use_section_reports_source_gap(self):
        entry = self.document("README.md", "# Manual\n\n## Other\n")
        with self.assertRaisesRegex(ValueError, "第一次使用路线"):
            handbook.render_quick_start([entry])


if __name__ == "__main__":
    unittest.main()
