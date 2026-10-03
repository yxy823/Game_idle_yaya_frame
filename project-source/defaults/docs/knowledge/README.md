# Project knowledge

Use this directory to reuse what actual project work has taught us: successful approaches, debugging methods and failure lessons. What belongs here rather than in Feature notes, Progress, ADRs or rules is defined in [Project knowledge](../../methodology/09-records-reports-and-handoff.md#project-knowledge).

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

The topic directories are:

```text
knowledge/
|-- README.md
|-- godot-runtime/
|-- gdscript/
|-- debugging-testing/
`-- tools-pipeline/
```

Each topic has its own README. Create further topics and entry files only when useful content exists. Keep paths stable; write new prose in the project's `document_language`.

## Keep the useful context

An entry should explain the situation, the approach or lesson and why it helped, the conditions where it applies, and its supporting Feature, commit, test, report, or reference links. Record versions, platform and reproduction details when they affect the conclusion. Successful approaches need observed benefits and limits, not a fabricated root cause. Distinguish observations, hypotheses, and verified conclusions in ordinary prose; uncertainty is not proof.

Link the original Feature, Progress or ADR record instead of copying its chronology. When guidance becomes an approved rule, link that rule instead of keeping a second copy here.

## Maintain during authorized work

When a task establishes a useful lesson or approach, first check for an existing entry and update or link it before creating another. Include task-owned knowledge and index edits in the task's normal documentation and commit work; no extra approval is needed for recording facts already within that authorized scope. A discussion-only or read-only task keeps its write boundary. Rule changes and cross-project reuse keep their existing authorization boundaries.

When creating or substantively updating an entry, apply [Organize entries](#organize-entries) and [Keep the useful context](#keep-the-useful-context).

Review entry accuracy and links before delivery. If evidence changes, correct the conclusion and its limits; do not silently turn an old result into a claim about a new version. No task must manufacture a new entry. Ordinary documentation review and the existing task workflow are sufficient.

Keep runnable helpers, fixtures, data and actual reports in their normal project locations and link them here. Correcting prose here is not a new verification run.
