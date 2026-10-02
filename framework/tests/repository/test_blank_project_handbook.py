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

from framework.docs.handbook import build_blank_project_handbook as handbook


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
        self.manual = self.root / "docs/operation-manual"
        self.manual.mkdir(parents=True)
        self.quick = self.root / "prompt_scenarios/scenarios"
        self.quick.mkdir(parents=True)
        overrides = patch.multiple(handbook, ROOT=self.root, MANUAL=self.manual,
                                   QUICK_REFERENCE=self.quick,
                                   OUTPUT=self.manual / "operation-handbook.html",
                                   QUICK_OUTPUT=self.quick / "quick-reference-handbook.html")
        overrides.start()
        self.addCleanup(overrides.stop)

    def document(self, name, text, *, quick=False):
        path = (self.quick if quick else self.manual) / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return handbook.parse_document(path)

    def test_body_and_tables_belong_to_nearest_heading_without_code_leakage(self):
        doc = self.document("resources.md", """# Resources

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

    def test_topics_follow_readme_categories_and_order(self):
        self.document("README.md", """# Manual

- **框架基础**
  - [Setup](基础/setup.md).
- **需求与任务**
  - [Develop](任务/development.md).
- **方法与工具**
  - [Tools & evidence](tools.md).
""")
        self.document("基础/setup.md", "# Setup\n\n## Environment\n")
        self.document("任务/development.md", "# Develop\n\n## Implement\n")
        self.document("tools.md", "# Tools & evidence\n\n## Commands\n")
        docs = handbook.load_documents()
        self.assertEqual([doc.group for doc in docs], ["阅读入口", "框架基础", "需求与任务", "方法与工具"])
        handbook.rewrite_links(docs)
        quick = handbook.render_quick_start(docs)
        anchors = [unquote(link["href"]) for link in Links(quick).anchors]
        self.assertEqual(anchors, ["#" + doc.key for doc in docs[1:]])
        self.assertIn("Tools &amp; evidence", quick)
        navigation, body = handbook.render_body(docs, [])
        self.assertIn(">需求与任务</p>", navigation)
        self.assertNotIn('data-scenarios="true"', body)
        handbook.check_output(quick + navigation + body, 0)

    def test_missing_entry_or_unlisted_document_fails(self):
        with self.assertRaisesRegex(ValueError, "缺少手册入口"):
            handbook.load_documents()
        self.document("README.md", "# Manual\n")
        self.document("orphan.md", "# Unlisted topic\n")
        with self.assertRaisesRegex(ValueError, "未收录文档"):
            handbook.load_documents()

    def test_quick_reference_uses_its_index_and_keeps_source_links(self):
        self.document("README.md", "# Full manual\n")
        (self.root / "authority.md").write_text("# Authority\n\n## Checks\n", encoding="utf-8")
        self.document("README.md", "# Writing guide\n", quick=True)
        self.document("scenario-index.md", """# Quick guide

## Godot 项目开发
### 验证与收尾
- [Verify](<Godot 项目开发/验证与收尾/需要验证.md>)
### 修复与改进
- [Bug](<Godot 项目开发/修复与改进/发现 Bug.md>)

[Writing guide](README.md)
[Output](quick-reference-handbook.html)
""", quick=True)
        self.document("Godot 项目开发/验证与收尾/需要验证.md", """# Verify

[Bug result](<../修复与改进/发现 Bug.md#result>)
[Reference](../../../../authority.md#checks)

## Result
""", quick=True)
        self.document("Godot 项目开发/修复与改进/发现 Bug.md", "# Bug\n\n## Result\n", quick=True)
        full = handbook.load_documents()
        self.assertEqual([doc.title for doc in full], ["Full manual"])
        docs = handbook.load_documents(quick_reference=True)
        self.assertEqual([doc.title for doc in docs], ["Quick guide", "Verify", "Bug", "Writing guide"])
        self.assertEqual([doc.group for doc in docs[1:3]],
                         ["Godot 项目开发 / 验证与收尾", "Godot 项目开发 / 修复与改进"])
        output = handbook.QUICK_OUTPUT
        handbook.rewrite_links(docs, output=output)
        quick = handbook.render_quick_start(docs, quick_reference=True)
        self.assertEqual([unquote(link["href"]) for link in Links(quick).anchors],
                         ["#" + docs[0].key + "--" + slug for level, _, slug in docs[0].headings if level == 3])
        navigation, body = handbook.render_body(docs, [], output=output)
        hrefs = [unquote(link["href"]) for link in Links(body).anchors]
        self.assertIn("#" + docs[2].key + "--result", hrefs)
        self.assertIn("../../authority.md#checks", hrefs)
        self.assertIn("Godot 项目开发/验证与收尾/需要验证.md", hrefs)
        self.assertIn("#handbook-top", hrefs)
        self.assertEqual(body.count('data-scenarios="true"'), 2)
        handbook.check_output('<div id="handbook-top"></div>' + quick + navigation + body, 0,
                              output=output, documents=docs)

    def test_cross_book_links_are_rejected(self):
        self.document("README.md", "# Other book\n", quick=True)
        doc = self.document("README.md", "# Manual\n\n[Other](../../prompt_scenarios/scenarios/README.md)\n")
        with self.assertRaisesRegex(ValueError, "不得互相引用"):
            handbook.rewrite_links([doc])

    def test_shared_glossary_is_embedded_in_each_book_without_becoming_a_scenario(self):
        glossary = self.manual.parent / "terminology.md"
        glossary.write_text("# Terms\n\n## Feature\nA development task.\n", encoding="utf-8")
        self.document("README.md", "# Manual\n\n[Terms](../terminology.md#feature)\n")
        self.document("scenario-index.md", "# Scenarios\n\n[Terms](../../docs/terminology.md#feature)\n", quick=True)
        for quick_reference, output in ((False, handbook.OUTPUT), (True, handbook.QUICK_OUTPUT)):
            with self.subTest(quick_reference=quick_reference):
                docs = handbook.load_documents(quick_reference=quick_reference)
                self.assertEqual(docs[-1].path, glossary)
                self.assertEqual(docs[-1].group, "公共参考")
                self.assertFalse(docs[-1].is_scenario)
                handbook.rewrite_links(docs, output=output)
                navigation, body = handbook.render_body(docs, [], output=output)
                self.assertIn("#" + docs[-1].key + "--feature",
                              [unquote(link["href"]) for link in Links(body).anchors])
                self.assertNotIn('data-scenarios="true"', body)
                handbook.check_output(navigation + body, 0, output=output, documents=docs)

    def test_missing_source_anchor_and_html_target_are_rejected(self):
        doc = self.document("README.md", "# Manual\n\n[Missing](#missing)\n")
        with self.assertRaisesRegex(ValueError, "标题锚点不存在"):
            handbook.rewrite_links([doc])
        with self.assertRaisesRegex(ValueError, "HTML 本地链接无效"):
            handbook.check_output('<a href="missing.md">Source</a>', 0, output=handbook.OUTPUT)
        with self.assertRaisesRegex(ValueError, "HTML 锚点"):
            handbook.check_output('<a href="#missing">Section</a>', 0)
        with self.assertRaisesRegex(ValueError, "章节覆盖或顺序"):
            handbook.check_output('<article id="wrong" class="chapter"></article>', 0, documents=[doc])

    def test_second_book_failure_keeps_both_previous_outputs(self):
        for output in (handbook.OUTPUT, handbook.QUICK_OUTPUT):
            output.write_text("previous build", encoding="utf-8")
        with patch.object(handbook, "build_book", side_effect=[(handbook.OUTPUT, "new"), ValueError("bad link")]), \
                patch("sys.argv", ["build"]):
            with self.assertRaisesRegex(ValueError, "bad link"):
                handbook.main()
        for output in (handbook.OUTPUT, handbook.QUICK_OUTPUT):
            self.assertEqual(output.read_text(encoding="utf-8"), "previous build")


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
