# 06 · Document-language smoke scenarios

> These scenarios verify Yaya Loop's initial internationalization contract without treating conversation language as durable project state or translating stable machine protocols.

## How to run the scenarios

Run each scenario in a disposable repository initialized from the current Kit. Record the agent's questions, the confirmed language, generated files, and validation output. A scenario passes only when every expected result and prohibited behavior below is satisfied.

The initially verified document languages are `en` and `zh-CN`. Other BCP 47 tags remain best-effort and must not be described as verified by these scenarios.

## Stable protocol fixture

The following paired projections describe the same pending Feature. They show language-sensitive fields only, not complete runnable Bootstrap configurations; use the actual project configuration for environment checks. Natural-language values change with `document_language`; keys, enums, IDs, dependencies, paths, timestamps, placeholder prefixes do not.

<!-- fixture: en -->
```json
{
  "config": {
    "document_language": "en",
    "test_framework": "gdunit4",
    "test_unit_root": "tests/unit",
    "test_feature_root": "tests/features",
    "test_invariant_root": "tests/invariants",
    "engine": "Godot 4.7",
    "language": "GDScript"
  },
  "feature": {
    "id": "F900",
    "title": "Add profile export",
    "status": "pending",
    "depends_on": ["F899"],
    "estimated_scope": "small",
    "completed_at": null
  },
  "detail": {
    "id": "F900",
    "description": "Let the user export a profile as JSON.",
    "affected_components": ["profile_export"],
    "acceptance_criteria": [{"id": "AC01", "text": "Selecting Export downloads one JSON file.", "verification": {"automated_tests": [], "manual_checks": []}}],
    "verification": {"acceptance_mode": null, "regression_tests": [], "manual_regression": null},
    "source": "product/01-profile.md#acceptance-criteria",
    "notes": "Keep the existing profile schema."
  },
  "protocol": {
    "detail_path": "docs/features/F900.json",
    "placeholder": "_placeholder_profile.json"
  }
}
```

<!-- fixture: zh-CN -->
```json
{
  "config": {
    "document_language": "zh-CN",
    "test_framework": "gdunit4",
    "test_unit_root": "tests/unit",
    "test_feature_root": "tests/features",
    "test_invariant_root": "tests/invariants",
    "engine": "Godot 4.7",
    "language": "GDScript"
  },
  "feature": {
    "id": "F900",
    "title": "增加用户资料导出",
    "status": "pending",
    "depends_on": ["F899"],
    "estimated_scope": "small",
    "completed_at": null
  },
  "detail": {
    "id": "F900",
    "description": "允许用户把资料导出为 JSON。",
    "affected_components": ["profile_export"],
    "acceptance_criteria": [{"id": "AC01", "text": "点击导出后下载一个 JSON 文件。", "verification": {"automated_tests": [], "manual_checks": []}}],
    "verification": {"acceptance_mode": null, "regression_tests": [], "manual_regression": null},
    "source": "product/01-profile.md#acceptance-criteria",
    "notes": "保持现有用户资料 schema。"
  },
  "protocol": {
    "detail_path": "docs/features/F900.json",
    "placeholder": "_placeholder_profile.json"
  }
}
```

## Scenario DL-01 · English conversation and English documents

### Setup

- Start with a new repository that has no `docs/methodology-config.json`.
- Speak English to the agent.
- Confirm `en` when the agent proposes the document language.

### Expected result

- The agent communicates in English.
- `document_language` is persisted as `en` before Product or Feature generation.
- Product headings and prose, Feature titles and details, and Progress entries use natural English.
- The English stable-protocol fixture above represents the generated protocol shape.

### Prohibited behavior

- Do not infer the document language from country, IP address, timezone, or operating-system locale.
- Do not translate JSON keys, enum values, IDs, paths, placeholders, or evidence.

## Scenario DL-02 · Chinese conversation and Simplified Chinese documents

### Setup

- Start with a new repository that has no `docs/methodology-config.json`.
- Speak Simplified Chinese to the agent.
- Confirm `zh-CN` when the agent proposes the document language.

### Expected result

- The agent communicates in Simplified Chinese.
- `document_language` is persisted as `zh-CN` before Product or Feature generation.
- Product headings and prose, Feature titles and details, and Progress entries use natural Simplified Chinese.
- The Chinese stable-protocol fixture above differs from the English fixture only in `document_language` and human-readable values.

### Prohibited behavior

- Do not persist conversation language as a second language setting.
- Do not create localized Methodology, Skill, Prompt, template, Project Rules library, or tool trees.

## Scenario DL-03 · Chinese conversation and English documents

### Setup

- Start with a project whose `docs/methodology-config.json` contains `"document_language": "en"`.
- Speak Simplified Chinese to the agent and request a Product change.

### Expected result

- The agent's questions, reports, and human-verification instructions use Simplified Chinese.
- New durable Product, Feature, revision, Progress, and handoff prose uses natural English.
- The stored `document_language` remains `en`.
- Stable protocol elements remain identical to Scenario DL-01.

### Prohibited behavior

- Do not change `document_language` to `zh-CN` because the conversation changed.
- Do not mix Chinese conversation text into durable project knowledge unless it is a quoted UI label, proper noun, code sample, or external reference.



## Scenario checks

Progress lifecycle scenarios also apply in every document language:

- Main `docs/progress.md` holds current state, blockers, decisions, next legal
  action and history links; read an archive only when it is relevant to the task.
- A completed Feature or approved batch moves its execution history to
  `docs/progress/`; the original prose and evidence links are preserved.
- Language migration updates only explicitly approved current content. It does
  not translate old archives or copy their bodies into Feature notes.
- Pure archival preserves the semantic business-test fingerprint; changing an AC
  or verification mapping still invalidates the corresponding evidence.

Record which of these checks actually ran; the checklist itself is not execution evidence:

1. all JSON fixtures in this document parse;
2. English and Chinese fixtures preserve identical machine projections;
3. Bootstrap and the document-language contract retain confirmation, preservation, and no-silent-translation rules;
4. every installed Skill preserves stable machine protocol values across document languages; and
5. test-layout/registry protocol fields remain stable across document languages; human summaries use natural language; and
6. repository tests, tool fixtures, and `git diff --check` pass without changing verification command strings.
