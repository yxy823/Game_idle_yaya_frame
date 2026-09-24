"""Protect handbook navigation and incremental Mermaid rendering."""

from html import escape
from html.parser import HTMLParser
from io import StringIO
from pathlib import Path
import subprocess
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


class HandbookDiagramCacheTests(unittest.TestCase):
    def setUp(self):
        area = tempfile.TemporaryDirectory(prefix="handbook_diagrams_")
        self.addCleanup(area.cleanup)
        self.root = Path(area.name)
        self.cache = self.root / "cache"
        self.browser = self.root / "browser.exe"
        self.browser.write_bytes(b"browser-v1")
        output = patch("sys.stdout", new_callable=StringIO)
        output.start()
        self.addCleanup(output.stop)
        renderer = patch.object(handbook, "render_missing_diagrams", side_effect=self.render_svg)
        self.renderer = renderer.start()
        self.addCleanup(renderer.stop)

    @staticmethod
    def render_svg(sources, browser):
        return [f'<svg xmlns="http://www.w3.org/2000/svg" id="my-svg">'
                f'<g id="node"><text>{escape(source)}</text></g></svg>' for source in sources]

    def documents(self, sources, prose="Introduction"):
        source = "# Diagrams\n\n" + prose + "\n\n"
        source += "\n".join(f"```mermaid\n{item}\n```" for item in sources)
        return [handbook.Document(self.root / "diagrams.md", "diagrams",
                                 handbook.MARKDOWN.parse(source), [(1, "Diagrams", "diagrams")])]

    def render(self, sources, **kwargs):
        return handbook.render_diagrams(self.documents(sources), self.browser,
                                       cache_dir=self.cache, **kwargs)

    def test_cold_then_warm_and_prose_only_edits_do_not_launch_renderer(self):
        sources = ["flowchart TD\nA-->B", "flowchart TD\nC-->D"]
        original = self.render(sources)
        self.assertEqual(self.renderer.call_count, 1)
        self.renderer.reset_mock()
        with patch.object(handbook.shutil, "which", side_effect=AssertionError("npx lookup")), \
                patch.object(handbook.subprocess, "run", side_effect=AssertionError("renderer launch")):
            warm = handbook.render_diagrams(self.documents(sources, "Changed prose"), self.browser,
                                           cache_dir=self.cache)
        self.renderer.assert_not_called()
        self.assertEqual(warm, original)

    def test_only_changed_or_added_diagrams_are_rendered(self):
        self.render(["flowchart TD\nA-->B", "flowchart TD\nC-->D"])
        self.renderer.reset_mock()
        changed = "flowchart TD\nC-->E"
        added = "flowchart TD\nF-->G"
        self.render(["flowchart TD\nA-->B", changed, added])
        self.assertEqual(self.renderer.call_args.args[0], [changed + "\n", added + "\n"])

    def test_reordering_and_duplicates_reuse_raw_svg_with_fresh_ids(self):
        self.render(["flowchart TD\nA-->B", "flowchart TD\nC-->D"])
        self.renderer.reset_mock()
        svgs = self.render(["flowchart TD\nC-->D", "flowchart TD\nA-->B", "flowchart TD\nA-->B"])
        self.renderer.assert_not_called()
        self.assertIn("C--&gt;D", svgs[0])
        self.assertIn("A--&gt;B", svgs[1])
        for index, svg in enumerate(svgs, 1):
            self.assertIn(f'id="diagram-{index}-my-svg"', svg)
        handbook.check_output("".join(svgs), 3)

    def test_render_settings_and_browser_changes_invalidate_cache(self):
        sources = ["flowchart TD\nA-->B"]
        self.render(sources)
        changes = {"MERMAID_PACKAGE": "@mermaid-js/mermaid-cli@new",
                   "DIAGRAM_WIDTH": 800,
                   "MERMAID_CONFIG": {**handbook.MERMAID_CONFIG, "theme": "dark"}}
        for name, value in changes.items():
            with self.subTest(setting=name), patch.object(handbook, name, value):
                self.renderer.reset_mock()
                self.render(sources)
                self.renderer.assert_called_once()
        self.browser.write_bytes(b"browser-v2-with-different-size")
        self.renderer.reset_mock()
        self.render(sources)
        self.renderer.assert_called_once()

    def test_bad_or_missing_entry_only_rerenders_that_diagram(self):
        sources = ["flowchart TD\nA-->B", "flowchart TD\nC-->D"]
        self.render(sources)
        entry = next(path for path in self.cache.glob("*.svg")
                     if "A--&gt;B" in path.read_text(encoding="utf-8"))
        for damaged in (b"<svg", b"\xff", b"<html/>", None):
            with self.subTest(damaged=damaged):
                if damaged is None:
                    entry.unlink()
                else:
                    entry.write_bytes(damaged)
                self.renderer.reset_mock()
                self.render(sources)
                self.assertEqual(self.renderer.call_args.args[0], [sources[0] + "\n"])

    def test_forced_rebuild_renders_all_unique_sources(self):
        sources = ["flowchart TD\nA-->B", "flowchart TD\nC-->D"]
        self.render(sources)
        self.renderer.reset_mock()
        self.render(sources, rebuild=True)
        self.assertEqual(self.renderer.call_args.args[0], [item + "\n" for item in sources])

    def test_failed_render_preserves_cached_diagrams_and_existing_html(self):
        self.render(["flowchart TD\nA-->B"])
        before = {path: path.read_bytes() for path in self.cache.glob("*.svg")}
        output = self.root / "handbook.html"
        output.write_text("last successful build", encoding="utf-8")
        self.renderer.side_effect = subprocess.CalledProcessError(1, "mmdc")
        with patch.object(handbook, "DIAGRAM_CACHE", self.cache), \
                patch.object(handbook, "OUTPUT", output), \
                patch.object(handbook, "load_documents", return_value=self.documents(["flowchart TD\nC-->D"])), \
                patch("sys.argv", ["build", "--browser", str(self.browser)]):
            with self.assertRaises(subprocess.CalledProcessError):
                handbook.main()
        self.assertEqual(output.read_text(encoding="utf-8"), "last successful build")
        self.assertEqual({path: path.read_bytes() for path in self.cache.glob("*.svg")}, before)


if __name__ == "__main__":
    unittest.main()
