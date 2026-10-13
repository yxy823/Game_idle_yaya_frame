"""Static file dependency graph used to widen test selection from content changes."""
# 只做静态文本解析：可以多算依赖，不能少算；解析不到的写法仍由组件选择兜住。
from __future__ import annotations

import posixpath
import re
from collections import deque
from pathlib import Path

from tools.lib.verification_snapshot import project_paths

EXCLUDED_PREFIXES = (".godot/", "addons/", "reports/")
SCRIPT_SUFFIXES = (".gd",)
RESOURCE_SUFFIXES = (".tscn", ".tres")
SHADER_SUFFIXES = (".gdshader", ".gdshaderinc")

_CODE_TOKEN = re.compile(r'"""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\'|"(?:\\.|[^"\\\n])*"|\'(?:\\.|[^\'\\\n])*\'|#[^\n]*')
_SCRIPT_PATH = re.compile(
    r'''(?:\b(?:preload|load)\s*\(\s*|^[ \t]*(?:class_name[ \t]+\w+[ \t]+)?extends[ \t]+)(["'])([^"'\n]+)\1''',
    re.MULTILINE)
_IDENTIFIER = re.compile(r"[A-Za-z_]\w*")
_CLASS_NAME = re.compile(r"^[ \t]*class_name[ \t]+([A-Za-z_]\w*)", re.MULTILINE)
_HEADER_UID = re.compile(r'^\[gd_(?:scene|resource)\b[^\]\n]*\buid="(uid://[^"]+)"', re.MULTILINE)
_EXT_RESOURCE = re.compile(r"^\[ext_resource\b([^\n]*)\]", re.MULTILINE)
_ATTRIBUTE = re.compile(r'\b(path|uid)="([^"]+)"')
_PLACEHOLDER = re.compile(r'\binstance_placeholder="([^"]+)"')
_EMBEDDED_SOURCE = re.compile(r'script/source\s*=\s*"((?:[^"\\]|\\.)*)"', re.DOTALL)
_SHADER_INCLUDE = re.compile(r'^[ \t]*#include[ \t]+"([^"\n]+)"', re.MULTILINE)
_IMPORT_UID = re.compile(r'^uid="(uid://[^"]+)"', re.MULTILINE)
_AUTOLOAD_SECTION = re.compile(r"^\[autoload\]\s*$(.*?)(?=^\[|\Z)", re.MULTILINE | re.DOTALL)
_AUTOLOAD_ENTRY = re.compile(r'^([A-Za-z_]\w*)\s*=\s*"\*?([^"]+)"', re.MULTILINE)


def canonical(path: str) -> str:
    """A script and its .uid, or an asset and its .import, are one node."""
    path = path.replace("\\", "/")
    for suffix in (".uid", ".import"):
        if path.endswith(suffix):
            return path[: -len(suffix)]
    return path


def _without_comments(source: str) -> str:
    return _CODE_TOKEN.sub(lambda match: match.group() if match.group()[0] != "#" else "", source)


def _unescape(value: str) -> str:
    return re.sub(r"\\(.)", lambda match: {"n": "\n", "t": "\t"}.get(match[1], match[1]), value)


class _Builder:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.files = [path for path in project_paths(root)
                      if not path.startswith(EXCLUDED_PREFIXES) and (root / path).is_file()]
        self.texts: dict[str, str] = {}
        self.uids: dict[str, str] = {}
        self.classes: dict[str, set[str]] = {}
        self.autoloads: dict[str, str] = {}
        self.graph: dict[str, set[str]] = {canonical(path): set() for path in self.files}

    def text(self, path: str) -> str:
        if path not in self.texts:
            self.texts[path] = (self.root / path).read_text(encoding="utf-8", errors="replace")
        return self.texts[path]

    def resolve(self, owner: str, value: str) -> str | None:
        if value.startswith("uid://"):
            return self.uids.get(value)
        if value.startswith("res://"):
            target = value.removeprefix("res://")
        elif "://" in value or value.startswith("/"):
            return None
        else:
            target = posixpath.join(posixpath.dirname(owner), value)
        return canonical(posixpath.normpath(target))

    def index(self) -> None:
        for path in self.files:
            if path.endswith(".uid"):
                self.uids[self.text(path).strip()] = canonical(path)
            elif path.endswith(".import"):
                if match := _IMPORT_UID.search(self.text(path)):
                    self.uids[match[1]] = canonical(path)
            elif path.endswith(RESOURCE_SUFFIXES):
                if match := _HEADER_UID.search(self.text(path)):
                    self.uids[match[1]] = path
        for path in self.files:
            if path.endswith(SCRIPT_SUFFIXES):
                for name in _CLASS_NAME.findall(_without_comments(self.text(path))):
                    self.classes.setdefault(name, set()).add(path)
        if (self.root / "project.godot").is_file():
            section = _AUTOLOAD_SECTION.search(self.text("project.godot"))
            for name, value in _AUTOLOAD_ENTRY.findall(section[1] if section else ""):
                target = self.resolve("project.godot", value)
                if target:
                    self.autoloads[name] = target

    def add_script_edges(self, owner: str, source: str) -> None:
        code = _without_comments(source)
        for _, value in _SCRIPT_PATH.findall(code):
            self.add(owner, self.resolve(owner, value))
        identifiers = set(_IDENTIFIER.findall(code))
        for name in identifiers & self.classes.keys():
            for target in self.classes[name]:
                self.add(owner, target)
        for name in identifiers & self.autoloads.keys():
            self.add(owner, self.autoloads[name])
            self.add(owner, "project.godot")

    def add(self, owner: str, target: str | None) -> None:
        if target and target != owner:
            self.graph.setdefault(owner, set()).add(target)

    def build(self) -> dict[str, set[str]]:
        self.index()
        for path in self.files:
            if path.endswith(SCRIPT_SUFFIXES):
                self.add_script_edges(path, self.text(path))
            elif path.endswith(RESOURCE_SUFFIXES):
                text = self.text(path)
                for attributes in _EXT_RESOURCE.findall(text):
                    values = dict(_ATTRIBUTE.findall(attributes))
                    target = self.resolve(path, values["path"]) if "path" in values else None
                    self.add(path, target or self.resolve(path, values.get("uid", "")))
                for value in _PLACEHOLDER.findall(text):
                    self.add(path, self.resolve(path, value))
                for source in _EMBEDDED_SOURCE.findall(text):
                    self.add_script_edges(path, _unescape(source))
            elif path.endswith(SHADER_SUFFIXES):
                for value in _SHADER_INCLUDE.findall(self.text(path)):
                    self.add(path, self.resolve(path, value))
        return self.graph


def build_graph(root: Path) -> dict[str, set[str]]:
    """Return ``{file: files it depends on}`` for project files outside excluded trees.

    Edges may point at paths that no longer exist, so a deleted file still finds
    the files that reference it.
    """
    return _Builder(root.resolve()).build()


def dependents(graph: dict[str, set[str]], starts: list[str]) -> dict[str, dict[str, list[str]]]:
    """Breadth-first reverse search from each start.

    Each reached file keeps one shortest chain ``[dependent, ..., start]``; the
    visited set makes cycles terminate.
    """
    reverse: dict[str, set[str]] = {}
    for owner, targets in graph.items():
        for target in targets:
            reverse.setdefault(target, set()).add(owner)
    result = {}
    for start in starts:
        chains = {start: [start]}
        queue = deque([start])
        while queue:
            node = queue.popleft()
            for owner in sorted(reverse.get(node, ())):
                if owner not in chains:
                    chains[owner] = [owner, *chains[node]]
                    queue.append(owner)
        del chains[start]
        result[start] = chains
    return result
