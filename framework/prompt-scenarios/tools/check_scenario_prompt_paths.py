"""Compare prompt names with scenario paths without reading scenario contents."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DEFAULT_PROMPTS = (
    ROOT / "framework/prompt-scenarios/prompts/yaya-maintenance-prompts.json",
    ROOT / "framework/prompt-scenarios/prompts/godot-development-prompts.json",
)
NAVIGATION = {"README.md", "scenario-index.md"}
RESERVED = {"CON", "PRN", "AUX", "NUL", *(f"COM{i}" for i in range(1, 10)),
            *(f"LPT{i}" for i in range(1, 10))}


def unique_object(pairs: list[tuple[str, object]]) -> dict:
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def path_name(value: object) -> str:
    """Reject names that cannot retain their exact identity on Windows."""
    if not isinstance(value, str) or not value or value != value.strip():
        raise ValueError(f"Expected a nonempty exact path name: {value!r}")
    if (value in {".", ".."} or value.endswith(".")
            or re.search(r'[<>:"/\\|?*\x00-\x1f]', value)
            or value.split(".")[0].upper() in RESERVED):
        raise ValueError(f"Invalid path name: {value!r}")
    return value


def claim_name(seen: set[str], name: str, context: str) -> None:
    key = name.casefold()
    if key in seen:
        raise ValueError(f"Duplicate name in {context}: {name}")
    seen.add(key)


def expected_paths(data: object) -> set[str]:
    if not isinstance(data, list) or not data:
        raise ValueError("Expected a nonempty Project array")
    expected = set()
    projects: set[str] = set()
    for item in data:
        if not isinstance(item, dict) or set(item) != {"project", "categories"}:
            raise ValueError("Each Project must contain project and categories")
        project = path_name(item["project"])
        claim_name(projects, project, "Projects")
        categories = item["categories"]
        if not isinstance(categories, dict) or not categories:
            raise ValueError(f"Expected nonempty categories: {project}")
        category_names: set[str] = set()
        prompt_names: set[str] = set()
        for raw_category, prompts in categories.items():
            category = path_name(raw_category)
            claim_name(category_names, category, project)
            if not isinstance(prompts, dict) or not prompts:
                raise ValueError(f"Expected prompt entries: {project}/{category}")
            for raw_name, body in prompts.items():
                name = path_name(raw_name)
                claim_name(prompt_names, name, project)
                if not isinstance(body, str) or not body.strip():
                    raise ValueError(f"Expected prompt text: {project}/{category}/{name}")
                expected.add(f"{project}/{category}/{name}.md")
    return expected


def compare_paths(prompts_paths: list[Path] | tuple[Path, ...], scenarios_root: Path) -> dict:
    data = []
    for prompts_path in prompts_paths:
        project = json.loads(prompts_path.read_text(encoding="utf-8"), object_pairs_hook=unique_object)
        if not isinstance(project, list) or len(project) != 1:
            raise ValueError(f"Each prompt file must contain exactly one Project: {prompts_path}")
        data.extend(project)
    expected = expected_paths(data)
    if not scenarios_root.is_dir():
        raise ValueError(f"Scenario directory does not exist: {scenarios_root}")
    # Only names are inspected. Content, H1 and semantic quality belong to review.
    actual = {
        path.relative_to(scenarios_root).as_posix()
        for path in scenarios_root.rglob("*")
        if path.is_file() and path.suffix.lower() == ".md"
        and not (path.parent == scenarios_root and path.name in NAVIGATION)
    }
    return {"expected": len(expected), "matched": len(expected & actual),
            "missing": sorted(expected - actual), "unexpected": sorted(actual - expected)}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prompts", type=Path, nargs="+", default=DEFAULT_PROMPTS,
                        help="Prompt files, each containing one Project; defaults to both catalogs")
    parser.add_argument("--scenarios", type=Path, default=ROOT / "framework/prompt-scenarios/scenarios")
    args = parser.parse_args(argv)
    try:
        report = compare_paths(args.prompts, args.scenarios)
    except (OSError, UnicodeError, ValueError) as error:
        print(json.dumps({"error": str(error)}, ensure_ascii=False), file=sys.stderr)
        return 2
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return int(bool(report["missing"] or report["unexpected"]))


if __name__ == "__main__":
    raise SystemExit(main())
