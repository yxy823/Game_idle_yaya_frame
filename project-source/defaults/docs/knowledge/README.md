# Project knowledge

Use this directory to reuse what actual project work has taught us: successful approaches, debugging methods, and failure lessons. It starts with navigation only; no entry claims that this project has already verified a technique or encountered a defect.

## Find relevant knowledge first

After understanding the current task and its governing rules, consult this index before choosing an approach, repeating an investigation, or searching external material. Follow the relevant topic indexes, then read the matching notes. Search by module, symptom, API, or tool when needed. Do not load the whole directory for every task; reuse already-read notes on continuation unless the task scope or relevant evidence changes.

| Topic | Use it for |
| --- | --- |
| [Godot runtime](godot-runtime/README.md) | SceneTree, resources, signals, UI, animation, audio, physics and runtime/export behavior |
| [GDScript](gdscript/README.md) | Types, language/API usage, code organization and script implementation techniques |
| [Debugging and testing](debugging-testing/README.md) | Reproduction, diagnosis, fixtures, regression coverage and validation methods |
| [Tools and pipelines](tools-pipeline/README.md) | PowerShell/Python helpers, data/import workflows, build and local tooling |

Prefer a demonstrated project approach when its conditions still fit. Knowledge is contextual evidence, not a new rule authority: current user intent, GDD design, Product delivery scope, accepted decisions, applicable engineering rules, and target-version API facts still govern the task. Verify a material conflict or version difference instead of repeating a historical workaround blindly. An empty topic or no matching entry is normal and does not block work.

## Organize entries

Keep one independently useful experience in a descriptively named Markdown file. Topic READMEs contain links and short descriptions, not all the entry bodies. Add a narrower subdirectory or a project-module topic when real content benefits from it; update the nearest index and its parent link when adding a topic. Do not create a folder for every Feature or copy the same entry into several topics. Cross-topic relevance uses links.

The initial hierarchy is:

```text
knowledge/
|-- README.md
|-- godot-runtime/
|-- gdscript/
|-- debugging-testing/
`-- tools-pipeline/
```

Each initial topic has its own README. Additional topic and entry files are created only when useful content exists. Paths remain stable; new prose follows the project's `document_language` setting.

## Keep the useful context

An entry should explain the situation, the approach or lesson and why it helped, the conditions where it applies, and its supporting Feature, commit, test, report, or reference links. Record versions, platform and reproduction details when they affect the conclusion. Successful approaches need observed benefits and limits, not a fabricated root cause. Distinguish observations, hypotheses, and verified conclusions in ordinary prose; uncertainty is not proof.

Feature notes retain the concrete incident, local decisions and TODOs; Progress retains current state and history links. Knowledge owns the extracted reusable explanation and links the original record instead of copying its chronology. Important technical choices belong in ADRs. Stable prescriptive guidance can be proposed for `agent-rules/` under its existing approval rules; then link that rule rather than maintaining another copy here.

## Maintain during authorized work

When a task establishes a useful lesson or approach, first check for an existing entry and update or link it before creating another. Include task-owned knowledge and index edits in the task's normal documentation and commit work; no extra approval is needed for recording facts already within that authorized scope. A discussion-only or read-only task keeps its write boundary. Rule changes and cross-project reuse keep their existing authorization boundaries.

Review entry accuracy and links before delivery. If evidence changes, correct the conclusion and its limits; do not silently turn an old result into a claim about a new version. No task must manufacture a new entry. Ordinary documentation review and the existing task workflow are sufficient.

Keep runnable helpers, fixtures, data and actual reports in their existing project locations and link them here. This directory's Markdown is explanatory knowledge, not executable input, GDD design, Product delivery requirements, rules or validation contracts. Correcting prose alone is not a new gameplay verification run; changes to code, tests or governing contracts still require their applicable checks.
