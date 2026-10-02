"""Build and validate the two independent offline handbooks from Markdown."""

from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
from hashlib import sha256
from html import escape
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from tempfile import NamedTemporaryFile, TemporaryDirectory
from urllib.parse import quote, unquote, urlsplit
from xml.etree import ElementTree

from markdown_it import MarkdownIt


ROOT = Path(__file__).resolve().parents[3]
MANUAL = ROOT / "framework/docs/operation-manual"
QUICK_REFERENCE = ROOT / "framework/prompt_scenarios/scenarios"
OUTPUT = MANUAL / "operation-handbook.html"
QUICK_OUTPUT = QUICK_REFERENCE / "quick-reference-handbook.html"
TEMPLATE = Path(__file__).parent / "assets" / "blank-project-handbook-page.html"
INTERACTIONS = Path(__file__).parent / "assets" / "blank-project-handbook-interactions.js"
MERMAID_PACKAGE = "@mermaid-js/mermaid-cli@11.17.0"
DIAGRAM_CACHE = ROOT / "framework/docs/handbook/.cache/handbook-mermaid"
DIAGRAM_WIDTH = 1400
MERMAID_CONFIG = {
    "theme": "base", "htmlLabels": False, "deterministicIds": True,
    "deterministicIDSeed": "blank-project-handbook",
    "themeVariables": {"fontFamily": "Microsoft YaHei, sans-serif", "fontSize": "16px",
                       "primaryColor": "#edf6f2", "primaryTextColor": "#203c35",
                       "primaryBorderColor": "#79a595", "lineColor": "#62877a",
                       "secondaryColor": "#f5f0e4", "tertiaryColor": "#f5f7f6"},
}
MARKDOWN = MarkdownIt("commonmark", {"html": False}).enable("table").enable("strikethrough")


@dataclass
class Document:
    path: Path
    key: str
    tokens: list
    headings: list[tuple[int, str, str]]
    group: str = "阅读入口"
    is_scenario: bool = False

    @property
    def title(self) -> str:
        return self.headings[0][1]


def inline_text(token) -> str:
    return "".join(" " if child.type in {"softbreak", "hardbreak"} else child.content
                   for child in token.children or []
                   if child.type in {"text", "code_inline", "image", "softbreak", "hardbreak"})


def parse_document(path: Path) -> Document:
    tokens = MARKDOWN.parse(path.read_text(encoding="utf-8"))
    seen: set[str] = set()
    headings = []
    for index, token in enumerate(tokens):
        if token.type != "heading_open":
            continue
        title = inline_text(tokens[index + 1])
        slug = re.sub(r"[^\w\- ]", "", title.lower()).replace(" ", "-")
        unique = slug
        suffix = 0
        while unique in seen:
            suffix += 1
            unique = f"{slug}-{suffix}"
        seen.add(unique)
        token.attrSet("id", unique)
        headings.append((int(token.tag[1:]), title, unique))
    if not headings:
        raise ValueError(f"缺少标题：{path}")
    key = "doc-" + path.relative_to(ROOT).with_suffix("").as_posix().replace("/", "--")
    return Document(path, key, tokens, headings)


def child_tokens(document: Document):
    for token in document.tokens:
        yield token
        yield from token.children or []


def load_documents(*, quick_reference: bool = False) -> list[Document]:
    source = QUICK_REFERENCE if quick_reference else MANUAL
    documents = {path.resolve(): parse_document(path) for path in source.rglob("*.md")}
    # Both books embed the same authored glossary without depending on each other.
    terminology = (MANUAL.parent / "terminology.md").resolve()
    if terminology.is_file():
        documents[terminology] = parse_document(terminology)
    entry_path = source / ("scenario-index.md" if quick_reference else "README.md")
    if entry_path.resolve() not in documents:
        raise ValueError(f"缺少手册入口：{entry_path}")
    entry = documents[entry_path.resolve()]
    # The authored index owns both grouping and reading order; no second catalog.
    linked_order = [entry.path.resolve()]
    group, project, list_depth = "", "", 0
    for index, token in enumerate(entry.tokens):
        if token.type in {"bullet_list_open", "ordered_list_open"}:
            list_depth += 1
        elif token.type in {"bullet_list_close", "ordered_list_close"}:
            list_depth -= 1
        elif quick_reference and token.type == "heading_open":
            title = inline_text(entry.tokens[index + 1])
            if token.tag == "h2":
                project, group = title, ""
            elif token.tag == "h3":
                group = f"{project} / {title}"
        elif token.type == "inline":
            links = [child for child in token.children or [] if child.type == "link_open"]
            if not quick_reference and list_depth == 1 and not links:
                group = inline_text(token)
            for link in links:
                url = urlsplit(link.attrGet("href"))
                if url.scheme or url.netloc or not url.path:
                    continue
                target = (entry.path.parent / unquote(url.path)).resolve()
                if target not in documents or target in linked_order:
                    continue
                doc = documents[target]
                if target == terminology:
                    doc.group = "公共参考"
                elif quick_reference and target == (source / "README.md").resolve():
                    doc.group = "编写与维护"
                else:
                    if not group:
                        raise ValueError(f"入口中的文档链接缺少分类：{entry_path}: {url.path}")
                    doc.group = group
                    doc.is_scenario = quick_reference
                linked_order.append(target)
    missing = sorted(set(documents) - set(linked_order))
    if missing:
        raise ValueError(f"手册入口未收录文档：{missing}")
    return [documents[path] for path in linked_order]


def section_search_text(document: Document) -> dict[str, str]:
    """Attach prose/table text to the nearest H2/H3; omit fenced code and diagrams."""
    sections: dict[str, list[str]] = {"": []}
    current, skip_heading = "", False
    for token in document.tokens:
        if token.type == "heading_open":
            skip_heading = token.tag in {"h1", "h2", "h3"}
            if token.tag in {"h2", "h3"}:
                current = token.attrGet("id")
                sections[current] = []
        elif token.type == "heading_close":
            skip_heading = False
        elif token.type == "inline" and not skip_heading:
            sections[current].append(inline_text(token))
    return {anchor: " ".join(parts) for anchor, parts in sections.items()}


def render_quick_start(documents: list[Document], *, quick_reference: bool = False) -> str:
    """Link to topics or scene categories using the current index structure."""
    def links(items):
        return '<ul>' + "".join(f'<li><a href="{escape(href, quote=True)}">{escape(title)}</a></li>'
                                for href, title in items) + '</ul>'

    groups: dict[str, list[tuple[str, str]]] = {}
    if quick_reference:
        project = ""
        entry = documents[0]
        for level, title, slug in entry.headings:
            if level == 2:
                project = title
            elif level == 3:
                groups.setdefault(project, []).append(("#" + quote(entry.key + "--" + slug), title))
    else:
        for doc in documents[1:]:
            groups.setdefault(doc.group, []).append(("#" + quote(doc.key), doc.title))
    if not groups:
        raise ValueError("手册入口缺少专题或场景分类。")
    sections = [f'<div class="quick-start-group"><h3>{escape(group)}</h3>{links(items)}</div>'
                for group, items in groups.items()]
    title = "按要处理的事情选择场景" if quick_reference else "按主题查阅"
    return ('<nav class="quick-start" aria-labelledby="quick-start-title">'
            f'<h2 id="quick-start-title">{title}</h2><div class="quick-start-groups">'
            + "".join(sections) + '</div></nav>')


def rewrite_links(documents: list[Document], *, output: Path | None = None) -> int:
    output = output or OUTPUT
    by_path = {doc.path.resolve(): doc for doc in documents}
    heading_cache = {path: {item[2] for item in doc.headings} for path, doc in by_path.items()}
    count = 0
    for doc in documents:
        for token in child_tokens(doc):
            if token.type == "image":
                raise ValueError(f"图片尚未内嵌，不能生成独立阅读文件：{doc.path}")
            if token.type != "link_open":
                continue
            count += 1
            original = token.attrGet("href")
            url = urlsplit(original)
            if url.scheme or url.netloc:
                continue
            target = (doc.path.parent / unquote(url.path)).resolve() if url.path else doc.path.resolve()
            fragment = unquote(url.fragment)
            if not target.is_relative_to(ROOT):
                raise ValueError(f"链接超出仓库：{doc.path}: {original}")
            other_book = MANUAL if output.parent == QUICK_REFERENCE else QUICK_REFERENCE
            if target.is_relative_to(other_book.resolve()):
                raise ValueError(f"两本手册不得互相引用：{doc.path}: {original}")
            if target != output and not target.exists():
                raise ValueError(f"链接目标不存在：{doc.path}: {original}")
            if fragment and target.suffix == ".md":
                if target not in heading_cache:
                    heading_cache[target] = {item[2] for item in parse_document(target).headings}
                if fragment not in heading_cache[target]:
                    raise ValueError(f"标题锚点不存在：{doc.path}: {original}")
            if target in by_path:
                anchor = by_path[target].key + ("--" + fragment if fragment else "")
                token.attrSet("href", "#" + quote(anchor))
            elif target == output:
                token.attrSet("href", "#handbook-top")
            else:
                relative = Path(os.path.relpath(target, output.parent)).as_posix()
                token.attrSet("href", quote(relative, safe="/.-_") +
                              ("#" + quote(fragment) if fragment else ""))
                token.attrSet("class", "source-link")
                token.attrSet("title", "仓库文件：需与仓库一起保留，可能由浏览器下载或交给编辑器打开")
    return count


def scope_svg(svg: str, prefix: str) -> str:
    """Keep marker, CSS and label IDs separate across inline diagrams."""
    identifiers = set(re.findall(r'\bid="([^"]+)"', svg))
    for identifier in sorted(identifiers, key=len, reverse=True):
        scoped = prefix + identifier
        svg = svg.replace(f'id="{identifier}"', f'id="{scoped}"')
        svg = re.sub(r"#" + re.escape(identifier) + r"(?=[\s.,:>+~)\]\{\"']|$)",
                     lambda _: "#" + scoped, svg)
    svg = re.sub(r'\b(aria-labelledby|aria-describedby)="([^"]*)"',
                 lambda match: f'{match[1]}="' + " ".join(
                     prefix + value if value in identifiers else value
                     for value in match[2].split()) + '"', svg)
    return svg


def valid_svg(svg: str) -> bool:
    """A truncated or non-SVG cache entry must be rendered again."""
    try:
        return ElementTree.fromstring(svg).tag == "{http://www.w3.org/2000/svg}svg"
    except ElementTree.ParseError:
        return False


def write_generated_text(path: Path, text: str) -> None:
    """Publish complete output atomically, including across concurrent builds."""
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with NamedTemporaryFile(mode="w", encoding="utf-8", newline="\n", suffix=".tmp",
                                dir=path.parent, delete=False) as output:
            temporary = Path(output.name)
            output.write(text)
        # Close the handle before replacement on Windows.
        temporary.replace(path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def render_diagrams(documents: list[Document], browser: Path | None, *,
                    cache_dir: Path | None = None, rebuild: bool = False) -> list[str]:
    diagrams = []
    for doc in documents:
        for token in doc.tokens:
            if token.type == "fence" and token.info.strip() == "mermaid":
                token.meta["diagram"] = len(diagrams)
                diagrams.append(token.content)
    if not diagrams:
        return []
    if browser is None:
        raise ValueError("手册含 Mermaid 图表，请用 --browser 指定现有 Edge/Chromium 可执行文件。")
    browser = browser.resolve()
    if not browser.is_file():
        raise ValueError("生成图表需要 --browser 指定的现有 Chromium 浏览器。")
    browser_stat = browser.stat()
    # Cache raw render output; document order and page markup do not affect it.
    context = {"format": 1, "package": MERMAID_PACKAGE, "config": MERMAID_CONFIG,
               "width": DIAGRAM_WIDTH,
               "browser": [str(browser), browser_stat.st_size, browser_stat.st_mtime_ns]}
    keys = [sha256(json.dumps([context, source], sort_keys=True,
                             ensure_ascii=False).encode("utf-8")).hexdigest() for source in diagrams]
    cache_dir = DIAGRAM_CACHE if cache_dir is None else cache_dir
    cached: dict[str, str] = {}
    pending: dict[str, str] = {}
    for key, source in zip(keys, diagrams):
        if key in cached or key in pending:
            continue
        svg = ""
        if not rebuild:
            try:
                svg = (cache_dir / f"mermaid-{key}.svg").read_text(encoding="utf-8")
            except (FileNotFoundError, UnicodeError):
                pass
        if valid_svg(svg):
            cached[key] = svg
        else:
            pending[key] = source
    if pending:
        rendered = render_missing_diagrams(list(pending.values()), browser)
        for key, svg in zip(pending, rendered):
            write_generated_text(cache_dir / f"mermaid-{key}.svg", svg)
            cached[key] = svg
    print(f"Mermaid cache: reused {len(diagrams) - len(pending)}; rendered {len(pending)}")
    # Apply the current position even when a cached diagram moved or occurs twice.
    return [scope_svg(cached[key], f"diagram-{index + 1}-") for index, key in enumerate(keys)]


def render_missing_diagrams(diagrams: list[str], browser: Path) -> list[str]:
    npx = shutil.which("npx.cmd" if os.name == "nt" else "npx")
    if not npx:
        raise ValueError("生成新图表需要 Node.js/npx。")
    with TemporaryDirectory(prefix="blank-project-handbook-") as temporary:
        folder = Path(temporary)
        source = folder / "diagrams.md"
        rendered = folder / "rendered.md"
        source.write_text("\n".join(f"```mermaid\n{item}```\n" for item in diagrams), encoding="utf-8")
        browser_config = folder / "browser.json"
        browser_config.write_text(json.dumps({"executablePath": str(browser.resolve())}), encoding="utf-8")
        config = folder / "mermaid.json"
        config.write_text(json.dumps(MERMAID_CONFIG), encoding="utf-8")
        environment = os.environ.copy()
        environment["PUPPETEER_SKIP_DOWNLOAD"] = "true"
        command = [npx, "--yes", "--package", MERMAID_PACKAGE, "--", "mmdc",
                   "-i", str(source), "-o", str(rendered), "-e", "svg", "-j", "1",
                   "-w", str(DIAGRAM_WIDTH), "-p", str(browser_config), "-c", str(config)]
        subprocess.run(command, check=True, env=environment, cwd=ROOT)
        svg_paths = re.findall(r"!\[[^\]]*\]\(([^)]+\.svg)\)", rendered.read_text(encoding="utf-8"))
        if len(svg_paths) != len(diagrams):
            raise ValueError(f"图表产物数量不匹配：{len(svg_paths)} / {len(diagrams)}")
        svgs = [(folder / name).read_text(encoding="utf-8") for name in svg_paths]
        if not all(valid_svg(svg) for svg in svgs):
            raise ValueError("Mermaid 返回了无效 SVG，未更新图表缓存。")
        return svgs


def render_body(documents: list[Document], diagrams: list[str], *,
                output: Path | None = None) -> tuple[str, str]:
    output = output or OUTPUT
    def fence(tokens, index, options, env):
        token = tokens[index]
        if "diagram" in token.meta:
            number = token.meta["diagram"] + 1
            return (f'<figure class="diagram"><figcaption>图 {number:02d}'
                    '<button type="button" class="expand-diagram">展开图表</button></figcaption>'
                    f'<div class="diagram-canvas">{diagrams[number - 1]}</div></figure>\n')
        language = token.info.strip().split()[0] if token.info.strip() else "text"
        return ('<div class="code-block"><div class="code-toolbar">'
                f'<span>{escape(language)}</span><div class="code-actions">'
                '<button type="button" class="toggle-code-wrap" aria-pressed="false">自动换行</button>'
                '<button type="button" class="copy-code">复制代码</button></div>'
                f'</div><pre><code>{escape(token.content)}</code></pre></div>\n')

    def heading_close(tokens, index, options, env):
        tag = tokens[index].tag
        if tag in {"h2", "h3"}:
            anchor = escape(tokens[index - 2].attrGet("id"), quote=True)
            return (f'<button type="button" class="heading-link" data-anchor="{anchor}" '
                    f'aria-label="复制本小节链接" title="复制本小节链接">#</button></{tag}>\n')
        return f'</{tag}>\n'

    MARKDOWN.renderer.rules["fence"] = fence
    MARKDOWN.renderer.rules["heading_close"] = heading_close
    MARKDOWN.renderer.rules["table_open"] = lambda *args: '<div class="table-scroll"><table>\n'
    MARKDOWN.renderer.rules["table_close"] = lambda *args: '</table></div>\n'
    articles, navigation = [], []
    last_group = None
    navigation_group = ""
    for number, doc in enumerate(documents, 1):
        group = doc.group
        search_text = section_search_text(doc)
        if group != last_group:
            # A topic can recur later in the reading order; filter each run separately.
            navigation_group = f"{group}-{number:02d}"
            navigation.append(f'<p class="nav-group" data-group="{escape(navigation_group)}">{escape(group)}</p>')
            last_group = group
        outline = "".join(f'<a href="#{quote(doc.key + "--" + slug)}" '
                          f'data-section="{escape(doc.key + "--" + slug)}" data-level="{level}" '
                          f'data-search-text="{escape(search_text[slug], quote=True)}">'
                          f'{escape(title)}</a>' for level, title, slug in doc.headings if level in {2, 3})
        navigation.append(f'<div class="nav-chapter" data-group="{escape(navigation_group)}"><div class="nav-row">'
                          f'<a href="#{doc.key}" data-chapter="{doc.key}" '
                          f'data-search-text="{escape(search_text[""], quote=True)}">'
                          f'<span class="nav-number">{number:02d}</span><span class="nav-title">{escape(doc.title)}</span></a>'
                          f'<button type="button" class="nav-toggle" aria-expanded="true" '
                          f'aria-controls="outline-{doc.key}" aria-label="收起{escape(doc.title)}的小节">'
                          '<svg class="ui-icon" width="20" height="20" viewBox="0 0 24 24" '
                          'fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" '
                          'stroke-linejoin="round" aria-hidden="true" focusable="false">'
                          '<path d="m6 9 6 6 6-6"/></svg></button></div>'
                          f'<div class="nav-sections" id="outline-{doc.key}">{outline}</div></div>')
        heading_titles = {slug: title for _, title, slug in doc.headings}
        for token in doc.tokens:
            if token.type == "heading_open":
                token.attrSet("data-title", heading_titles[token.attrGet("id")])
                token.attrSet("id", doc.key + "--" + token.attrGet("id"))
        source_path = Path(os.path.relpath(doc.path, output.parent)).as_posix()
        pager = []
        for offset, label in ((-1, "← 上一章"), (1, "下一章 →")):
            target_index = number - 1 + offset
            if 0 <= target_index < len(documents):
                target = documents[target_index]
                pager.append(f'<a href="#{target.key}" class="{"previous" if offset < 0 else "next"}">'
                             f'<span>{label}</span><strong>{escape(target.title)}</strong></a>')
        articles.append(f'<article id="{doc.key}" class="chapter" data-number="{number:02d}" '
                        f'data-title="{escape(doc.title)}" '
                        f'data-scenarios="{str(doc.is_scenario).lower()}">'
                        '<div class="chapter-meta">'
                        f'<span>{escape(group)} / {number:02d}</span><a class="source-link" '
                        f'href="{quote(source_path)}" title="本章的 Markdown 源文件">Markdown 原文</a></div>\n'
                        + MARKDOWN.renderer.render(doc.tokens, MARKDOWN.options, {})
                        + '<nav class="chapter-pager" aria-label="章节翻页">' + "".join(pager) + '</nav></article>')
    return "\n".join(navigation), "\n".join(articles)


class OutputInspector(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = []
        self.links = []
        self.chapters = []
        self.svg_count = 0

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if "id" in attrs:
            self.ids.append(attrs["id"])
        if tag == "a" and "href" in attrs:
            self.links.append(attrs["href"])
        if tag == "article" and "chapter" in attrs.get("class", "").split():
            self.chapters.append(attrs.get("id"))
        # Mermaid roots receive this prefix in scope_svg; decorative UI icons do not count as diagrams.
        if tag == "svg" and attrs.get("id", "").startswith("diagram-"):
            self.svg_count += 1
        embedded_icon = (tag == "link" and attrs.get("rel") == "icon"
                         and attrs.get("type") == "image/svg+xml"
                         and attrs.get("href", "").startswith("data:image/svg+xml,"))
        if (tag in {"img", "iframe"} or (tag == "link" and not embedded_icon)
                or (tag == "script" and "src" in attrs)):
            raise ValueError(f"阅读文件含外置资源：{tag} {attrs}")


def check_output(page: str, expected_diagrams: int, *, output: Path | None = None,
                 documents: list[Document] | None = None) -> None:
    inspector = OutputInspector()
    inspector.feed(page)
    duplicates = [value for value, count in Counter(inspector.ids).items() if count > 1]
    if duplicates:
        raise ValueError(f"HTML 中有重复 ID：{duplicates[:5]}")
    known_ids = set(inspector.ids)
    missing = [link for link in inspector.links if link.startswith("#") and unquote(link[1:]) not in known_ids]
    if missing or inspector.svg_count != expected_diagrams:
        raise ValueError(f"HTML 锚点或图表数量不匹配：{missing[:5]}, SVG={inspector.svg_count}")
    if re.search(r"(?:@import\s|url\(\s*['\"]?(?:https?:|//))", page, re.IGNORECASE):
        raise ValueError("阅读文件含远程样式或字体资源。")
    if documents is not None and inspector.chapters != [doc.key for doc in documents]:
        raise ValueError("HTML 章节覆盖或顺序与 Markdown 不一致。")
    if output is not None:
        other_book = MANUAL if output.parent == QUICK_REFERENCE else QUICK_REFERENCE
        for link in inspector.links:
            url = urlsplit(link)
            if url.scheme or url.netloc or not url.path:
                continue
            target = (output.parent / unquote(url.path)).resolve()
            if not target.is_relative_to(ROOT) or not target.exists():
                raise ValueError(f"HTML 本地链接无效：{link}")
            if target.is_relative_to(other_book.resolve()):
                raise ValueError(f"HTML 含另一册的引用：{link}")


def build_book(browser: Path | None, *, quick_reference: bool = False,
               rebuild_diagrams: bool = False) -> tuple[Path, str]:
    """Prepare a checked book in memory; publish only after every selected book passes."""
    output = QUICK_OUTPUT if quick_reference else OUTPUT
    documents = load_documents(quick_reference=quick_reference)
    link_count = rewrite_links(documents, output=output)
    diagrams = render_diagrams(documents, browser, rebuild=rebuild_diagrams)
    quick_start = render_quick_start(documents, quick_reference=quick_reference)
    navigation, body = render_body(documents, diagrams, output=output)
    page = TEMPLATE.read_text(encoding="utf-8")
    # Reuse the brand SVG so the tab icon never needs a separately maintained image.
    brand = re.search(r'<svg\b[^>]*\bclass="brand-mark"[^>]*>.*?</svg>', page, re.DOTALL)
    if not brand:
        raise ValueError("页面模板缺少品牌 SVG，无法生成标签页图标。")
    book_title = "场景速查手册" if quick_reference else "操作手册"
    book_intro = ("先选择执行仓库，再按要处理的事情和当前状态查找场景。"
                  "每篇围绕一个目标，说明所需材料、实际步骤、阻塞和完成标准，并对应一条同名专用提示词。"
                  if quick_reference else
                  "按对象与契约查阅框架、目录、配置、需求与任务、Skill、Agent、命令和证据。"
                  "专题按需阅读，用来理解各项能力的职责、参数、副作用与结果含义。")
    replacements = {"@@NAVIGATION@@": navigation, "@@BODY@@": body, "@@QUICK_START@@": quick_start,
                    "@@PAGE_TITLE@@": book_title,
                    "@@BOOK_TITLE@@": book_title, "@@BOOK_INTRO@@": book_intro,
                    "@@SIDEBAR_TITLE@@": book_title,
                    "@@READING_KEY@@": "yaya.quick-reference.reading-anchor" if quick_reference else "yaya.operation-manual.reading-anchor",
                    "@@INTERACTIONS@@": INTERACTIONS.read_text(encoding="utf-8"),
                    "@@FAVICON@@": "data:image/svg+xml," + quote(brand[0], safe=""),
                    "@@DOCUMENT_COUNT@@": str(len(documents)), "@@DIAGRAM_COUNT@@": str(len(diagrams))}
    # A single substitution prevents source text from being treated as template syntax.
    page = re.sub("|".join(map(re.escape, replacements)), lambda match: replacements[match[0]], page)
    check_output(page, len(diagrams), output=output, documents=documents)
    print(f"Validated: {output}\nDocuments: {len(documents)}; diagrams: {len(diagrams)}; source links checked: {link_count}")
    return output, page


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--browser", type=Path, help="含 Mermaid 时指定现有 Edge/Chromium 可执行文件")
    parser.add_argument("--rebuild-diagrams", action="store_true", help="忽略图表缓存并重新渲染全部 Mermaid")
    parser.add_argument("--book", choices=("all", "operation", "quick-reference"), default="all",
                        help="默认构建两本手册，也可指定其中一本")
    args = parser.parse_args()
    choices = [False, True] if args.book == "all" else [args.book == "quick-reference"]
    pages = [build_book(args.browser, quick_reference=quick, rebuild_diagrams=args.rebuild_diagrams)
             for quick in choices]
    for output, page in pages:
        write_generated_text(output, page)
        print(f"Generated: {output}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"Handbook build failed: {error}", file=sys.stderr)
        raise SystemExit(1)
