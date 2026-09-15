"""Build the offline handbook from its Markdown sources and rendered Mermaid SVGs."""

from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
from html import escape
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from tempfile import TemporaryDirectory
from urllib.parse import quote, unquote, urlsplit

from markdown_it import MarkdownIt


ROOT = Path(__file__).resolve().parents[2]
MANUAL = ROOT / "framework/docs/blank-project"
OUTPUT = MANUAL / "blank-project-handbook.html"
TEMPLATE = Path(__file__).with_name("blank-project-handbook-page.html")
INTERACTIONS = Path(__file__).with_name("blank-project-handbook-interactions.js")
MERMAID_PACKAGE = "@mermaid-js/mermaid-cli@11.17.0"
GROUPS = {
    "": "阅读入口",
    "getting-started": "开始使用",
    "guides": "开发与协作",
    "reference": "参考与排查",
    "maintenance": "框架维护",
}
MARKDOWN = MarkdownIt("commonmark", {"html": False}).enable("table").enable("strikethrough")


@dataclass
class Document:
    path: Path
    key: str
    tokens: list
    headings: list[tuple[int, str, str]]

    @property
    def title(self) -> str:
        return self.headings[0][1]


def inline_text(token) -> str:
    return "".join(child.content for child in token.children or []
                   if child.type in {"text", "code_inline", "image"})


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


def load_documents() -> list[Document]:
    documents = {path.resolve(): parse_document(path) for path in MANUAL.rglob("*.md")}
    entry = documents[(MANUAL / "README.md").resolve()]
    # README owns the reading order; directory labels must not interrupt it.
    linked_order = [entry.path.resolve()]
    for token in child_tokens(entry):
        if token.type == "link_open":
            url = urlsplit(token.attrGet("href"))
            if not url.scheme and url.path:
                target = (entry.path.parent / unquote(url.path)).resolve()
                if target in documents and target not in linked_order:
                    linked_order.append(target)
    linked_order.extend(sorted(set(documents) - set(linked_order)))
    result = [documents[path] for path in linked_order]
    for doc in result:
        group = doc.path.relative_to(MANUAL).parent.as_posix().replace(".", "")
        if group not in GROUPS:
            raise ValueError(f"新章节分组需要在生成器中命名：{group}")
    return result


def rewrite_links(documents: list[Document]) -> int:
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
            if target != OUTPUT and not target.exists():
                raise ValueError(f"链接目标不存在：{doc.path}: {original}")
            if fragment and target.suffix == ".md":
                if target not in heading_cache:
                    heading_cache[target] = {item[2] for item in parse_document(target).headings}
                if fragment not in heading_cache[target]:
                    raise ValueError(f"标题锚点不存在：{doc.path}: {original}")
            if target in by_path:
                anchor = by_path[target].key + ("--" + fragment if fragment else "")
                token.attrSet("href", "#" + quote(anchor))
            elif target == OUTPUT:
                token.attrSet("href", "#handbook-top")
            else:
                relative = Path(os.path.relpath(target, OUTPUT.parent)).as_posix()
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


def render_diagrams(documents: list[Document], browser: Path) -> list[str]:
    diagrams = []
    for doc in documents:
        for token in doc.tokens:
            if token.type == "fence" and token.info.strip() == "mermaid":
                token.meta["diagram"] = len(diagrams)
                diagrams.append(token.content)
    if not diagrams:
        return []
    npx = shutil.which("npx.cmd" if os.name == "nt" else "npx")
    if not npx or not browser.is_file():
        raise ValueError("生成图表需要 Node.js/npx 和 --browser 指定的现有 Chromium 浏览器。")
    with TemporaryDirectory(prefix="blank-project-handbook-") as temporary:
        folder = Path(temporary)
        source = folder / "diagrams.md"
        rendered = folder / "rendered.md"
        source.write_text("\n".join(f"```mermaid\n{item}```\n" for item in diagrams), encoding="utf-8")
        browser_config = folder / "browser.json"
        browser_config.write_text(json.dumps({"executablePath": str(browser.resolve())}), encoding="utf-8")
        config = folder / "mermaid.json"
        config.write_text(json.dumps({
            "theme": "base", "htmlLabels": False, "deterministicIds": True,
            "deterministicIDSeed": "blank-project-handbook",
            "themeVariables": {"fontFamily": "Microsoft YaHei, sans-serif", "fontSize": "16px",
                               "primaryColor": "#edf6f2", "primaryTextColor": "#203c35",
                               "primaryBorderColor": "#79a595", "lineColor": "#62877a",
                               "secondaryColor": "#f5f0e4", "tertiaryColor": "#f5f7f6"},
        }), encoding="utf-8")
        environment = os.environ.copy()
        environment["PUPPETEER_SKIP_DOWNLOAD"] = "true"
        command = [npx, "--yes", "--package", MERMAID_PACKAGE, "--", "mmdc",
                   "-i", str(source), "-o", str(rendered), "-e", "svg", "-j", "1",
                   "-w", "1400", "-p", str(browser_config), "-c", str(config)]
        subprocess.run(command, check=True, env=environment, cwd=ROOT)
        svg_paths = re.findall(r"!\[[^\]]*\]\(([^)]+\.svg)\)", rendered.read_text(encoding="utf-8"))
        if len(svg_paths) != len(diagrams):
            raise ValueError(f"图表产物数量不匹配：{len(svg_paths)} / {len(diagrams)}")
        return [scope_svg((folder / name).read_text(encoding="utf-8"), f"diagram-{index + 1}-")
                for index, name in enumerate(svg_paths)]


def render_body(documents: list[Document], diagrams: list[str]) -> tuple[str, str]:
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
        group = doc.path.relative_to(MANUAL).parent.as_posix().replace(".", "")
        if group != last_group:
            # A topic can recur later in the reading order; filter each run separately.
            navigation_group = f"{group}-{number:02d}"
            navigation.append(f'<p class="nav-group" data-group="{navigation_group}">{GROUPS[group]}</p>')
            last_group = group
        outline = "".join(f'<a href="#{quote(doc.key + "--" + slug)}" '
                          f'data-section="{escape(doc.key + "--" + slug)}" data-level="{level}">'
                          f'{escape(title)}</a>' for level, title, slug in doc.headings if level in {2, 3})
        navigation.append(f'<div class="nav-chapter" data-group="{navigation_group}"><div class="nav-row">'
                          f'<a href="#{doc.key}" data-chapter="{doc.key}">'
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
        source_path = doc.path.relative_to(MANUAL).as_posix()
        pager = []
        for offset, label in ((-1, "← 上一章"), (1, "下一章 →")):
            target_index = number - 1 + offset
            if 0 <= target_index < len(documents):
                target = documents[target_index]
                pager.append(f'<a href="#{target.key}" class="{"previous" if offset < 0 else "next"}">'
                             f'<span>{label}</span><strong>{escape(target.title)}</strong></a>')
        articles.append(f'<article id="{doc.key}" class="chapter" data-number="{number:02d}" '
                        f'data-title="{escape(doc.title)}"><div class="chapter-meta">'
                        f'<span>{GROUPS[group]} / {number:02d}</span><a class="source-link" '
                        f'href="{quote(source_path)}" title="本章的 Markdown 源文件">Markdown 原文</a></div>\n'
                        + MARKDOWN.renderer.render(doc.tokens, MARKDOWN.options, {})
                        + '<nav class="chapter-pager" aria-label="章节翻页">' + "".join(pager) + '</nav></article>')
    return "\n".join(navigation), "\n".join(articles)


class OutputInspector(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = []
        self.links = []
        self.svg_count = 0

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if "id" in attrs:
            self.ids.append(attrs["id"])
        if tag == "a" and "href" in attrs:
            self.links.append(attrs["href"])
        # Mermaid roots receive this prefix in scope_svg; decorative UI icons do not count as diagrams.
        if tag == "svg" and attrs.get("id", "").startswith("diagram-"):
            self.svg_count += 1
        embedded_icon = (tag == "link" and attrs.get("rel") == "icon"
                         and attrs.get("type") == "image/svg+xml"
                         and attrs.get("href", "").startswith("data:image/svg+xml,"))
        if (tag in {"img", "iframe"} or (tag == "link" and not embedded_icon)
                or (tag == "script" and "src" in attrs)):
            raise ValueError(f"阅读文件含外置资源：{tag} {attrs}")


def check_output(page: str, expected_diagrams: int) -> None:
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


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--browser", required=True, type=Path, help="用于生成 SVG 的现有 Edge/Chromium 可执行文件")
    args = parser.parse_args()
    documents = load_documents()
    link_count = rewrite_links(documents)
    diagrams = render_diagrams(documents, args.browser)
    navigation, body = render_body(documents, diagrams)
    page = TEMPLATE.read_text(encoding="utf-8")
    # Reuse the brand SVG so the tab icon never needs a separately maintained image.
    brand = re.search(r'<svg\b[^>]*\bclass="brand-mark"[^>]*>.*?</svg>', page, re.DOTALL)
    if not brand:
        raise ValueError("页面模板缺少品牌 SVG，无法生成标签页图标。")
    replacements = {"@@NAVIGATION@@": navigation, "@@BODY@@": body,
                    "@@INTERACTIONS@@": INTERACTIONS.read_text(encoding="utf-8"),
                    "@@FAVICON@@": "data:image/svg+xml," + quote(brand[0], safe=""),
                    "@@DOCUMENT_COUNT@@": str(len(documents)), "@@DIAGRAM_COUNT@@": str(len(diagrams))}
    # A single substitution prevents source text from being treated as template syntax.
    page = re.sub("|".join(map(re.escape, replacements)), lambda match: replacements[match[0]], page)
    check_output(page, len(diagrams))
    OUTPUT.write_text(page, encoding="utf-8", newline="\n")
    print(f"Generated: {OUTPUT}\nDocuments: {len(documents)}; diagrams: {len(diagrams)}; source links checked: {link_count}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"Handbook build failed: {error}", file=sys.stderr)
        raise SystemExit(1)
