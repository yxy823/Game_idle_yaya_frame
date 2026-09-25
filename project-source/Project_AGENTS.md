# Project instructions

本项目使用 Windows 11 / PowerShell 7、Godot 4.7 / GDScript / gdunit4。实际工具路径以 `docs/methodology-config.json` 为准，环境可用性以真实检查结果为准，不从模板推断本机已安装的工具。

## 沟通与交付

默认采用 ADHD 友好的表达，让用户容易理解并立即行动。以下要求只约定表达方式，不改变任务授权、验收或完成标准。

- **直接表达与阅读顺序：** 开头先回答用户最关心的问题。分析、评估和建议类回答先给主要结论、优先建议及影响判断的必要边界，再展开理由；主要要求查找问题时先呈现关键发现，单纯解释概念时不强造建议或下一步。用日常用语讲清具体问题、改法和结果，必要术语就地解释；删除客套、绕句、空泛鼓励和无用比喻。
- **同题就近讲完整：** 同一主题的建议、必要理由和适用边界放在一起，不拆散到“优点、缺点、建议、另外”等位置让读者自行拼接。确需跨节提及时，用短提醒或明确引用，不重复完整论述。
- **主要判断与支撑细节：** 不影响当前判断的实现细节、背景和补充案例后置；会改变建议的重要风险、前提和不确定性就近说明或前置，不为简洁隐藏。保留必要证据和来源，用户要求详细解释时充分展开。
- **按内容组织：** 简单问题直接回答，不为凑结构增加章节；长回复用能直接说明主题的标题，每个段落或条目围绕一个主要问题。操作流程用编号步骤，每步写清执行者和一个可判断完成的动作；短比较用表格，多项内容按主题或用途分组。评估、解释类回答不必逐段套用“执行者、动作、完成标准”，不以固定字数、段落数或条目数代替可读性判断。
- **有用重复与无效复述：** 保留帮助记住优先项、恢复上下文或避免遗漏的简短重复，以及已有的默认高频提示机制；只删没有新增作用的复述，不因出现频繁就删除。
- **状态与交付：** 多轮工作有进展时说明已完成、仍受阻和下一步，不编造总步骤数。完成后先给可用成果、文件入口和实际验证结果。只有需要用户行动时，结尾给一个能立即开始的具体动作；工作已结束不另造下一步。
- **错误与估算：** 客观说明错误位置、已知原因和修复或排查办法，分清事实、推测与未知。同样的失败不盲目重试，先核对关键假设，有新证据再试。耗时估算有依据时用分钟、小时等单位或范围，写明影响估算的条件。
- **提问与授权：** 沿用具体授权，Agent 能完成的工作继续完成；缺少关键信息、决定或实际人工验收时请用户介入，优先提出最关键的问题。可能造成重要数据损失且现有授权未覆盖的操作，执行前确认；已明确批准的同一动作不重复询问。

## 使用说明的可读性

适用于 README、使用手册和操作指南。整理表达不得改变既有流程、授权、验收或完成标准。

Markdown 普通段落和同一列表项不按固定字符数插入换行；保留段落分隔、列表项、表格行、代码块等必要结构。

- 操作单元写清适用条件、入口、执行者、动作、完成判据和下一步，用标题或步骤号帮助恢复停点。每步围绕一个可判断完成的目标；条件分支和角色切换就近分开说明，不把完整流程塞进长段落或表格单元。
- 可执行命令前就近说明工作目录、必要准备和覆盖、替换、清除等副作用。共用准备可链接到固定小节，不要求读者凭记忆补齐；需要替换的路径和参数明确标出。
- 先呈现当前动作，再给必要解释；背景、实现细节和历史放在参考位置。短比较用表格，先后操作用编号，长清单按职责分组；跨节引用链接到具体标题，不用含糊的“上表”“下文”代替。
- 同一细节只在一处完整说明，使用位置保留必要短提醒和链接。按实际操作价值保留入口、恢复提示和防漏提醒；出现频繁本身不能证明必需或多余，确有阅读负担、职责冲突或没有操作价值时才压缩、合并或调整。
- 修改后按“找到入口 → 执行动作 → 判断结果 → 继续或恢复”核对读者路径，确认关键条件仍在。生成成功不等于排版或交互已验收；不为表达整理增加台账、审批或独立报告。

## Workflow and authority

This framework supports one project user working with an Agent in a single project directory. Multi-user collaboration, change-attribution workflows and worktree isolation/resumption are outside scope. Same-directory task pauses, switches and new-conversation continuation remain supported; bounded research and independent reviewer instances retain their existing contracts.

| Need | Read and follow |
| --- | --- |
| Choose a workflow or the next authorized action | `methodology/00-overview.md`; Skills are under `.agents/skills/`, explicit commands under `tools/` |
| Product behavior or project terminology | `methodology/01-product-doc-structure.md`; `product-author` owns behavior, `project-terminology` maintains confirmed definitions and links |
| Feature planning, Product order or ledger evolution | `methodology/02-feature-list-schema.md` |
| Execute a Feature, approvals, optional independent review and completion | `methodology/03-execute-loop.md`, including **Authorization and continuation** |
| Rule responsibilities, interpretation or promotion | `methodology/04-coding-rules-4-layers.md` and `agent-rules/00-core/rule-precedence-and-routing.md` |
| Detailed Feature design | Optional `docs/features/F0XX-design.md` under `methodology/02-feature-list-schema.md`; JSON keeps AC and verification obligations |
| Document language or initial environment configuration | `methodology/05-document-language.md` |
| Bug, refactor or maintenance | `methodology/07-engineering-change.md` |
| Test impact, current-run evidence or completion helper use | `methodology/08-testing-strategy.md`; direct parsing/lint commands are in `methodology/gdscript-lint.md` |
| Report organization, temporary workspaces, Progress, history or cleanup | `methodology/09-artifact-lifecycle.md` |
| Optional architecture map and ADRs | `methodology/10-architecture-overview.md` |
| Professional design, resources, localization, diagnostics or multiple requirement sources | `methodology/11-specialist-workflows.md`; specialists own their documents and return to existing task delivery |
| User-requested formal review | `methodology/12-independent-review.md`; fresh independent instance using `.codex/agents/independent-reviewer.toml` when supported and the applicable review Skills |
| External facts or approach research | **External research** in `methodology/00-overview.md`; the coordinating agent decides whether to search directly or delegate to `.codex/agents/researcher.toml` |

These entries are task routes, not a mandatory reading sequence. Follow the selected procedure and its applicable references; do not load every workflow. There are no automatic tool events or Hooks to grant permission.

Apply relevant `docs/project-rules.md` hard constraints when defining Product intent, planning Features and designing or implementing changes. A local Product, Feature or ADR cannot silently waive them. Every proposed rule addition, removal or edit requires the conversational self-check in `methodology/04-coding-rules-4-layers.md`; reuse explicit decisions, and obtain any missing authority for a substantive change. Stage 3 checks useful terminology, design, architecture/ADR and rule updates before final verification; it does not require an artifact for every category.

Read relevant terminology definitions, Product/professional sources and accepted architecture decisions for the work. Initial purpose/pending-state notices are not confirmed requirements or definitions; do not require a complete Product for discussion. Source writing and implementation use their owning workflows; a Skill return does not cancel a broader concrete authorization.

## Environment and Git

Before the first coding Feature, complete the Agent-led Project Environment setup under the language/configuration contract above. Coding requires confirmed environment preparation based on actual check results. Run `python -B tools/checks/check-project-environment.py --require-ready` during setup, after tool/configuration changes or to diagnose actual invocation failures; ordinary Features reuse confirmed commands without version discovery.

Every modifying task follows `agent-rules/00-core/git-worktree-and-commits.md`: inspect and preserve actual differences, continue from current records in the same directory, and commit validated logical changes with the applicable Feature identity. Non-empty Git status alone does not block a task; actual overlapping edits or an inseparable commit require resolving the concrete conflict. Implementation approval and actual human acceptance remain distinct under the execute loop; automated results cannot supply a missing human decision.

## Project knowledge and rule feedback

Before choosing an approach in planning, investigation, implementation, debugging or review, consult `docs/knowledge/README.md` and relevant topic indexes/entries. Narrow by task, module, symptom, API or tool; reuse prior reading unless scope or evidence changed. Empty topics are normal. Check experience against current intent, code and versions; it cannot override accepted decisions or rules.

During authorized task documentation, retain useful approaches and failure lessons in the matching knowledge topic under its README. Update existing entries and indexes, link the original Feature/evidence, and keep task history in its owning record. No useful new knowledge requires no entry. Read-only tasks retain their write boundary; Feature notes and knowledge belong before the Stage 7 commit, with Stage 8 linking them.

At completion, check whether reusable prescriptive learning is already covered by `agent-rules/`. If valuable guidance is missing, propose one generalized rule, its target module and a real example only when useful. Do not create a rule for every defect, duplicate an existing rule, promote Product detail or edit rules without explicit approval.

## Engineering rule routing

Workflow and traceability semantics belong to `methodology/`; concrete engine and language semantics belong to `agent-rules/`. Use the root/Core precedence protocol for a real conflict. Rule-module directories do not prescribe project filesystem layout.

When creating modules or choosing file locations/names, consult `docs/game-organization.md` for the starter skeleton, ownership examples and genre-specific expansion. Reuse unchanged guidance; concrete naming and engine constraints remain in the relevant rule modules below.

For modifications or relevant engineering decisions, use `agent-rules/00-core/README.md` and each affected domain below. Read the matching concrete sections and applicable validation documents, not the entire directory. Modules are additive: a test `.gd` needs relevant GDScript and test rules. Reuse already loaded, unchanged material on continuation; expand only when the task or evidence requires it.

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

If no dedicated module applies, use relevant Core rules and project conventions; consult adjacent rules only where their semantics overlap. Verify target Godot semantics when the change involves version-sensitive engine behavior, not for ordinary Markdown or unrelated artifact work. Do not expand the rule system as an incidental implementation task.

Scope, minimal complete changes and preservation follow `agent-rules/00-core/change-scope-and-ownership.md`; vendor/generated ownership follows `third-party-generated-and-temporary-files.md` in that directory. Validation and truthful completion reporting follow `validation-policy.md` and `completion-and-reporting.md` there. Preserve authoritative state, API, ownership and lifecycle boundaries; test/debug tooling must not become an arbitrary reflection or property-mutation backdoor.

## 本机 Godot 编辑器检查

以下约束只适用于本机 Windows / Codex 受限沙箱中的 Godot 编辑器检查；其他机器先核对真实权限与目录行为。它们不要求每个 Feature 额外启动编辑器。

| 触发条件 | 必须执行 |
| --- | --- |
| 启动编辑器检查，包括 `--headless --editor` | 直接通过 `require_escalated` 审批路径在沙箱外运行；审批未通过或不可用时报告未执行或受阻，不绕过审批 |
| 出现 `Could not create editor data directory`、`Could not create editor config directory` 或 `AppData/Roaming/Godot` 访问失败 | 按环境权限排查，停止依赖该次成功结果的后续验证；不报告通过，不据此修改业务代码或弱化门禁 |
| 编辑器检查前后 | 比较项目根目录列表，包含 Git 不记录的空目录；新增 `export_templates`、`feature_profiles`、`script_templates` 或 `text_editor_themes` 等异常目录时先核对来源，只对确认由本次运行产生且为空的目录按现有清理规则处理，保留已有同名目录 |
