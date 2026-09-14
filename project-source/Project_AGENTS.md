# Project instructions

本项目使用 Windows 11 / PowerShell 7、Godot 4.7 / GDScript / gdunit4。

## Development workflow

Canonical workflow specifications live in `methodology/`.
Repository Skills live in `.agents/skills/`.
Explicit workflow commands live in `tools/` and the calling Skill’s `scripts/`. No automatic tool events are registered.
Run needed commands as part of the current task; do not wait for a tool Hook to grant permission.

Route work as follows:

- Discussion, design clarification, or project vocabulary to clarify and record
  -> `$project-clarifier`; discussion alone writes nothing
  -> approved terminology writes use `$product-change-standardizer`

- Formalize new, changed, missing, or ambiguous Product intent
  -> `$product-change-standardizer`

- Implementation defect where Product intent is already explicit
  -> `$engineering-change-standardizer` in bug mode

- Behavior-preserving refactor
  -> `$engineering-change-standardizer` in refactor mode

- Dependency, build, tooling, testing infrastructure, migration,
  logging, performance, or other non-Product engineering work
  -> `$engineering-change-standardizer` in maintenance mode

- Initial decomposition of the current Product (first or subsequent)
  -> `$generate-feature-list`

- Product or Coding Rules changed after the initial Feature plan
  -> `$sync-feature-list`

- Execute an approved Feature
  -> `$execute-next-feature`

- Select one unresolved refactor candidate
  -> `$pick-refactor-smell`
  -> then return the selected candidate to
  `$engineering-change-standardizer`

Plan Products one at a time in their actual execution order. Decompose only the
current Product into Features; finish its required Features before decomposing
the next Product. Revisit later requirements when their turn arrives and append
to the existing ledger. Do not pre-plan all Products or rebuild prior tasks.
See `methodology/02-feature-list-schema.md` **Product-by-Product planning**.

Human control is mandatory:

- do not begin Feature implementation without Stage 1 explicit approval;
- decide acceptance from requirements in Stage 1; visual/audio/game-feel or other human judgment requires manual acceptance;
- automated-only Features omit Stage 5; automated tests never constitute a human acceptance decision;
- do not promote Bug Guardrails into Coding Rules without explicit approval;
- at Stage 8, continue only within existing concrete authorization; stop when the requested scope is complete or a necessary decision is missing.

Read relevant definitions in `docs/CONTEXT.md` when it exists during planning,
implementation and review. It stores optional project vocabulary; Product owns
behavior, architecture records own implementation choices. Do not require a
blank CONTEXT or a complete Product for discussion. Meaning-preserving terminology
maintenance does not create or synchronize Features; see
`methodology/01-product-doc-structure.md`.

Testing follows `methodology/08-testing-strategy.md`.
Do not invent test commands, components, Product requirements, or project
configuration.

Before the first coding Feature, complete the one-time Project Environment
setup in `docs/methodology-config.json`, following the environment configuration
contract in `methodology/05-document-language.md`.
This is Agent-led configuration, not a separate Bootstrap program. Normal Feature execution requires
`environment_bootstrap.status: ready` and uses the confirmed commands. Run
`python -B tools/checks/check-project-environment.py --require-ready` during setup,
after tool/configuration changes, or when diagnosing actual invocation failures;
do not repeat version discovery for every Feature.

Feature completion uses `docs/feature-completion-evidence.json`, written through
`.agents/skills/execute-next-feature/scripts/record-feature-completion.py`. Run its `validate --feature F0XX`
command and the Skill's explicit Feature checks before recording completion.
The helper checks tests, applicable human acceptance and review. The Agent separately
runs direct script parsing/lint and assesses their actual results before completion. There is no tool interception, patch-intent parser or Stop listener.

Git safety and local commits follow
`agent-rules/00-core/git-worktree-and-commits.md`.

- **[MUST]** Before the first file modification for a task, independently run
  `git status --porcelain`. A new modifying task in a project repository
  requires a clean worktree; do not mix, stash, restore, delete, or stage
  pre-existing user changes.
- **[MUST]** Before writing, identify task-owned changes using the actual Git
  diff and current task record; preserve unrelated work. Initial project setup
  follows the environment instructions in README.

- **[MUST]** After all applicable approval, validation, acceptance, and
  completion Gates pass, stage only task-owned paths/hunks and create the local
  commit unless the user explicitly requested no commit.

## Current project workflow

Read `methodology/00-overview.md` for the canonical routing table and current
support boundary. `yaya-next-step-advisor` supplies read-only guidance, without
starting tests, implementation, acceptance or commits.

Existing concrete user authorization remains effective across Stages and turns;
do not ask for the same approval again. Implementation approval never implies
human acceptance. Preserve actual accepted scope and historical evidence;
separate historical completion from verification on a migrated snapshot.

The test runner selects tests from the current Feature/Test Registry directly.
Completion evidence is derived from actual current-run discovery, JUnit,
process/session, hashes and source/Feature bindings. Caller-supplied counts and conversation summaries alone
cannot authorize completion. Direct script parsing and lint follow
`methodology/gdscript-lint.md`; no static wrapper or static manifest is required.

`docs/progress.md` holds current state and a history index. Detailed history
belongs under `docs/progress/`. Use `methodology/09-artifact-lifecycle.md`
for explicit report cleanup and history. Preserve unknown files and evidence
needed by open work; no report ownership registration or automatic cleanup is required.
The optional Architecture Overview follows
`methodology/10-architecture-overview.md`.

The project stack is fixed: Godot 4.7, GDScript and gdunit4 on Windows 11.
Do not infer installed tools, executable paths or readiness from a template.
Incomplete Bootstrap means the machine setup is unconfirmed; `--require-ready`
still blocks Feature execution until actual environment checks succeed.

## Project knowledge

- **[MUST]** At the start of planning, investigation, implementation, debugging
  or review, consult `docs/knowledge/README.md` and the relevant topic
  indexes and entries before choosing an approach or repeating external research.
  Use the current task, module, symptom, API or tool to narrow the reading; do not
  load every entry. On continuation, reuse prior reading unless scope or evidence
  changed. Empty topics are normal.
- **[MUST]** Treat project experience as contextual evidence.
  Check applicable conditions and current code/version; they do not override
  user intent, Product, accepted decisions or applicable rules. Report a material
  discrepancy rather than blindly applying an old workaround.
- **[MUST]** During authorized task documentation, capture useful successful
  approaches, debugging methods or failure lessons in the matching
  `docs/knowledge/` topic, following its README. Update existing entries and
  indexes where appropriate; keep concrete task history in Feature notes and
  link it. No new entry is required without useful knowledge. Read-only tasks
  retain their write boundary; rule changes and cross-project reuse still need
  their existing authorization. Feature knowledge edits belong before the
  Stage 7 commit, with Stage 8 reporting links.

## Agent Rules feedback

- **[MUST]** During Feature, Bug, Refactor, and Maintenance completion, identify
  reusable engineering learning and check whether `agent-rules/` already covers
  it.
- **[MUST]** If valuable reusable guidance is missing, propose one generalized
  candidate rule, its target `agent-rules/<module>/`, and only when useful one
  short real failure example.
- **[MUST]** Do not propose a rule for every defect, duplicate an existing rule,
  promote one-off Product detail, or modify `agent-rules/` without explicit
  user approval.

## Godot Project Agent Rules

### Yaya Loop integration

Yaya Loop remains authoritative for Product, Feature, engineering-change,
Test Impact Review, test traceability, human acceptance, and completion
workflows. The Godot rules are authoritative for concrete Godot/GDScript
implementation details, including scenes, resources, shaders, assets, project
configuration, and testing implementation.

When both apply, use workflow and traceability semantics from `methodology/`,
concrete engine semantics from `agent-rules/`, and report any real contradiction
instead of silently choosing. For test work, read both
`agent-rules/70-tests/README.md` and
`agent-rules/70-tests/feature-test-integration.md`.

This repository targets **Godot 4.7**. This file is the global rule router.
Detailed engineering rules live under `agent-rules/`.

### Global hard rules

1. **[MUST]** Target the project-approved Godot **4.7** version line. Do not introduce APIs or behavior from another Godot version without verifying compatibility with the actual target executable.
2. **[MUST]** Before editing, identify every affected rule domain and read the corresponding `agent-rules/<module>/README.md` plus the routed concrete rule documents.
3. **[MUST]** Applicable rule modules are additive by default. A test `.gd`, for example, follows both GDScript and testing rules.
4. **[MUST]** Core `[MUST]` rules may be refined by a narrower specialized rule inside its delegated scope, but may not be silently weakened.
5. **[MUST]** Make the smallest coherent change that completely satisfies the requested behavior. Minimal means minimal complete impact, not the fewest edited files.
6. **[MUST]** Preserve unrelated user/collaborator work. Do not perform opportunistic cleanup, formatting, renames, refactors, or deletions outside the required change.
7. **[MUST]** Determine ownership and authority before editing vendor, generated, tool-managed, cache, backup, or temporary artifacts.
8. **[MUST]** Do not change `AGENTS.md`, `agent-rules/**`, lint thresholds, ignores, warning suppressions, test skips, schema severity, or validation gates merely to obtain a green result.
9. **[MUST]** For version-sensitive Godot behavior, verify target Godot 4.7 semantics instead of guessing or copying examples from `latest`, Godot 3, or another minor version.
10. **[MUST]** Preserve authoritative state, API, ownership, and lifecycle boundaries. Test/debug tooling must not become an arbitrary reflection or property-mutation backdoor.
11. **[MUST]** Run every validation route applicable to the final change. One passing gate never erases another failing gate.
12. **[MUST]** Report what materially changed and what was actually validated. Never claim checks, platforms, performance, visual quality, or test scope that were not actually evaluated.

Rule-module organization does **not** prescribe the Godot project filesystem organization.

### Rule loading protocol

Before modifying project files:

1. Read this `AGENTS.md`.
2. Identify every affected file type and cross-cutting domain.
3. Read `agent-rules/00-core/README.md`.
4. Read each applicable specialized module `README.md`.
5. Follow those README files to the concrete documents relevant to the change.
6. Apply all applicable modules together.
7. Before completion, execute every validation route required by the affected modules.

If no dedicated module covers an artifact, apply all relevant Core rules, verify target Godot 4.7 semantics, inspect project conventions/tooling, and use the closest specialized rules only where their semantics genuinely overlap. Do not create or expand the rule system as an incidental implementation task.

### Routing table

| Change | Required rule entry |
|---|---|
| Every task | `agent-rules/00-core/README.md` |
| `.gd` | `agent-rules/10-gdscript/README.md` |
| `.tscn` / Scene | `agent-rules/20-scenes/README.md` |
| `.tres` / custom Resource | `agent-rules/21-resources/README.md` |
| `.gdshader` / `.gdshaderinc` | `agent-rules/30-shaders/README.md` |
| `project.godot` / ProjectSettings | `agent-rules/40-project-config/README.md` |
| `export_presets.cfg` / export pipeline | `agent-rules/41-export-config/README.md` |
| JSON / CSV / XLSX / YAML / canonical game data | `agent-rules/50-data-files/README.md` |
| textures / audio / fonts / `.import` / asset pipeline | `agent-rules/60-assets/README.md` |
| tests / fixtures / test helpers / test runner | `agent-rules/70-tests/README.md` |
| UID / path / NodePath / business ID / RID identity | `agent-rules/00-core/godot-resource-references.md` |

Examples:

- `tests/test_combat.gd` -> `10-gdscript` + `70-tests`.
- `tests/fixtures/item.tres` -> `21-resources` + `70-tests`.
- A generated JSON test fixture may require `50-data-files` + `70-tests`.
- An `EditorExportPlugin` script requires `10-gdscript` + `40-project-config` + `41-export-config`.

### Normative vocabulary

Use only `[MUST]`, `[REVIEW]`, and `[PREFER]` as defined in `agent-rules/00-core/rule-precedence-and-routing.md`.
Machine diagnostic severity such as Warning/Critical is separate from normative level.

### Validation and completion

Concrete checks are owned by each module's validation document and by `70-tests/test-selection-and-gates.md`.

- A gate is PASS only if it was actually executed successfully.
- Static validation, import, tests, runtime, export, and target-platform checks prove different contracts and do not substitute for each other.
- If an applicable required gate cannot run, report it as not executed with the reason and resulting residual risk.
- Visual composition, animation feel, and artistic quality use **manual acceptance in v1**. Screenshot/golden-image/pixel-diff regression is intentionally not part of the automated completion gate.

## 本机 Godot 编辑器检查与沙箱经验

本节仅适用于 Windows / Codex 受限沙箱中会访问 Godot 用户数据和配置目录的编辑器检查。
在本机执行该类命令时必须遵守以下约束；其他 Windows 11 机器或沙箱策略须先核对其真实权限、审批
和目录行为，不将本机现象推广为所有 Godot 环境的行为。

- **[MUST]** 启动 Godot 编辑器的检查，包括显式启动 `--headless --editor`，直接通过 `require_escalated` 审批路径在
  沙箱外执行，不先在受限沙箱内试跑。无窗口模式仍需要访问 Godot 用户数据与配置
  目录。审批未通过或不可用时，报告检查未执行或受阻，不绕过审批。
- **[MUST]** 出现 `Could not create editor data directory`、
  `Could not create editor config directory` 或 `AppData/Roaming/Godot` 访问失败时，
  按环境权限问题排查，停止依赖该次成功结果的后续验证；不得将该次运行报告为通过，
  也不得据此修改业务代码或弱化验证门禁。
- **[MUST]** 此类检查执行前后比较项目根目录列表，包含空目录；不能仅依赖
  `git status`，因为 Git 不记录空目录。若新增 `export_templates`、
  `feature_profiles`、`script_templates` 或 `text_editor_themes` 等异常目录，先报告
  并核对是否由本次运行生成；仅在确认属于本次运行且为空后，按现有清理规则处理，
  不自动删除已有同名目录。

历史触发场景：Godot 编辑器检查因沙箱内用户目录访问失败，在项目根目录留下上述
四个空目录。本节仅约束实际发生的编辑器操作，不要求每个 Feature 额外启动编辑器。
