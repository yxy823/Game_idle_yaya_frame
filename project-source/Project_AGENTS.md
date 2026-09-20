# Project instructions

本项目使用 Windows 11 / PowerShell 7、Godot 4.7 / GDScript / gdunit4。实际工具路径与环境就绪状态以 `docs/methodology-config.json` 为准，不从模板推断本机已安装的工具。

## Workflow and authority

| Need | Read and follow |
| --- | --- |
| Choose a workflow or the next authorized action | `methodology/00-overview.md`; Skills are under `.agents/skills/`, explicit commands under `tools/` and the calling Skill's `scripts/` |
| Product behavior or project terminology | `methodology/01-product-doc-structure.md`; optional `docs/terminology.md` owns vocabulary, not behavior |
| Feature planning, Product order or ledger evolution | `methodology/02-feature-list-schema.md` |
| Execute a Feature, approvals, optional independent review and completion | `methodology/03-execute-loop.md`, including **Authorization and continuation** |
| Rule responsibilities, interpretation or promotion | `methodology/04-coding-rules-4-layers.md` and `agent-rules/00-core/rule-precedence-and-routing.md` |
| Detailed Feature design | Optional `docs/features/F0XX-design.md` under `methodology/02-feature-list-schema.md`; JSON keeps AC and verification obligations |
| Document language or initial environment configuration | `methodology/05-document-language.md` |
| Bug, refactor or maintenance | `methodology/07-engineering-change.md` |
| Test impact, current-run evidence or completion helper use | `methodology/08-testing-strategy.md`; direct parsing/lint commands are in `methodology/gdscript-lint.md` |
| Report organization, temporary workspaces, Progress, history or cleanup | `methodology/09-artifact-lifecycle.md` |
| Optional architecture map and ADRs | `methodology/10-architecture-overview.md` |

These entries are task routes, not a mandatory reading sequence. Follow the
selected procedure and its applicable references; do not load every workflow.
There are no automatic tool events or Hooks to grant permission.

Apply relevant `docs/project-rules.md` hard constraints when defining Product intent, planning Features and designing or implementing changes. A local Product, Feature or ADR cannot silently waive them. Every proposed rule addition, removal or edit requires the conversational self-check in `methodology/04-coding-rules-4-layers.md`; reuse explicit decisions, and obtain any missing authority for a substantive change. Stage 3 checks useful terminology, design, architecture/ADR and rule updates before final verification; it does not require an artifact for every category.

Read relevant terminology definitions, Product sources and accepted architecture
decisions for the work. Do not create an empty terminology document or require a complete
Product for discussion. Source writing and implementation use their owning
workflows; a Skill return does not cancel a broader concrete authorization.

## Environment and Git

Before the first coding Feature, complete the Agent-led Project Environment
setup under the language/configuration contract above. Coding requires
`environment_bootstrap.status: ready`. Run
`python -B tools/checks/check-project-environment.py --require-ready` during
setup, after tool/configuration changes or to diagnose actual invocation
failures; ordinary Features reuse confirmed commands without version discovery.

Every modifying task follows
`agent-rules/00-core/git-worktree-and-commits.md`, including its clean-worktree
preflight, resumed-task ownership, automatic commits of validated logical changes
and Feature identification in commit messages.
Implementation approval and actual human acceptance remain distinct under the
execute loop; automated results cannot supply a missing human decision.

## Project knowledge and rule feedback

Before choosing an approach in planning, investigation, implementation, debugging
or review, consult `docs/knowledge/README.md` and relevant topic indexes/entries.
Narrow by task, module, symptom, API or tool; reuse prior reading unless scope or
evidence changed. Empty topics are normal. Check experience against current
intent, code and versions; it cannot override accepted decisions or rules.

During authorized task documentation, retain useful approaches and failure
lessons in the matching knowledge topic under its README. Update existing entries
and indexes, link the original Feature/evidence, and keep task history in its
owning record. No useful new knowledge requires no entry. Read-only tasks retain
their write boundary; Feature notes and knowledge belong before the Stage 7
commit, with Stage 8 linking them.

At completion, check whether reusable prescriptive learning is already covered
by `agent-rules/`. If valuable guidance is missing, propose one generalized rule,
its target module and a real example only when useful. Do not create a rule for
every defect, duplicate an existing rule, promote Product detail or edit rules
without explicit approval.

## Engineering rule routing

Workflow and traceability semantics belong to `methodology/`; concrete engine
and language semantics belong to `agent-rules/`. Use the root/Core precedence
protocol for a real conflict. Rule-module directories do not prescribe project
filesystem layout.

For modifications or relevant engineering decisions, use
`agent-rules/00-core/README.md` and each affected domain below. Read the matching
concrete sections and applicable validation documents, not the entire directory.
Modules are additive: a test `.gd` needs relevant GDScript and test rules.
Reuse already loaded, unchanged material on continuation; expand only when the
task or evidence requires it.

| Changed artifact or domain | Rule entry |
| --- | --- |
| GDScript | `agent-rules/10-gdscript/README.md` |
| Scene | `agent-rules/20-scenes/README.md` |
| Resource | `agent-rules/21-resources/README.md` |
| Shader | `agent-rules/30-shaders/README.md` |
| ProjectSettings | `agent-rules/40-project-config/README.md` |
| Export configuration/pipeline | `agent-rules/41-export-config/README.md` |
| Game data, schemas or data pipeline | `agent-rules/50-data-files/README.md` |
| Assets or import pipeline | `agent-rules/60-assets/README.md` |
| Tests, fixtures or runner | `agent-rules/70-tests/README.md` |
| UID, path, NodePath, business ID or RID identity | `agent-rules/00-core/godot-resource-references.md` |

If no dedicated module applies, use relevant Core rules and project conventions;
consult adjacent rules only where their semantics overlap. Verify target Godot
semantics when the change involves version-sensitive engine behavior, not for
ordinary Markdown or unrelated artifact work. Do not expand the rule system as
an incidental implementation task.

Scope, minimal complete changes and preservation follow
`agent-rules/00-core/change-scope-and-ownership.md`; vendor/generated ownership
follows `third-party-generated-and-temporary-files.md` in that directory.
Validation and truthful completion reporting follow `validation-policy.md` and
`completion-and-reporting.md` there. Preserve authoritative state, API, ownership
and lifecycle boundaries; test/debug tooling must not become an arbitrary
reflection or property-mutation backdoor.

## 本机 Godot 编辑器检查

以下约束只适用于本机 Windows / Codex 受限沙箱中的 Godot 编辑器检查；其他机器先核对真实权限与目录行为。它们不要求每个 Feature 额外启动编辑器。

| 触发条件 | 必须执行 |
| --- | --- |
| 启动编辑器检查，包括 `--headless --editor` | 直接通过 `require_escalated` 审批路径在沙箱外运行；审批未通过或不可用时报告未执行或受阻，不绕过审批 |
| 出现 `Could not create editor data directory`、`Could not create editor config directory` 或 `AppData/Roaming/Godot` 访问失败 | 按环境权限排查，停止依赖该次成功结果的后续验证；不报告通过，不据此修改业务代码或弱化门禁 |
| 编辑器检查前后 | 比较项目根目录列表，包含 Git 不记录的空目录；新增 `export_templates`、`feature_profiles`、`script_templates` 或 `text_editor_themes` 等异常目录时先核对来源，只对确认由本次运行产生且为空的目录按现有清理规则处理，保留已有同名目录 |
