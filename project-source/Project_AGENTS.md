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

编写或整理项目文档时，遵循本地 `agent-rules/00-core/documentation/writing-guide.md`，按本次需要读取其中链接的目录组织或流程专题。适用于 README、使用说明及需求、设计、知识和报告中的自然语言文字，无需另行调用写作 Skill。

所属规范继续决定字段、固定路径、文档语言、流程、授权、验收与完成条件；写作指南不替代这些契约，也不改变机器可读结构。只有流程与场景使用 11 类信息规则。

## Workflow and authority

This framework supports one project user working with an Agent in a single project directory. Multi-user collaboration, change-attribution workflows and worktree isolation/resumption are outside scope. Same-directory task pauses, switches and new-conversation continuation remain supported; bounded research and independent reviewer instances retain their existing contracts.

| Need | Read and follow |
| --- | --- |
| Choose a workflow or the next authorized action | `methodology/00-overview.md`; Skills are under `.agents/skills/`, explicit commands under `tools/` |
| Existing GDD, Product delivery scope or project terminology | `methodology/01-product-doc-structure.md`; `product-author` maintains GDD design and Product delivery documents, `project-terminology` maintains confirmed definitions and links |
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

Every project development entry requires an existing substantive GDD under `docs/gdd/`, as defined in `methodology/01-product-doc-structure.md#gdd-prerequisite-and-authority`. Without it, report the missing input and stop; placeholders, idea discussion, engineering work and experiments do not bypass this prerequisite. The framework does not initialize GDD. Once present, GDD is a normal maintained project source within existing authorization; Product documents organize delivery and reference its design rather than duplicating it.

Apply relevant `docs/project-rules.md` hard constraints when defining Product intent, planning Features and designing or implementing changes. A local Product, Feature or ADR cannot silently waive them. Every proposed rule addition, removal or edit requires the conversational self-check in `methodology/04-coding-rules-4-layers.md`; reuse explicit decisions, and obtain any missing authority for a substantive change. Stage 3 checks useful terminology, design, architecture/ADR and rule updates before final verification; it does not require an artifact for every category.

Read relevant terminology definitions, GDD, Product/professional sources and accepted architecture decisions for the work. Initial purpose/pending-state notices are not confirmed requirements or definitions. With an existing GDD, clarification need not wait for all future design details or detailed Product documents; dependent planning and implementation require sufficiently clear current-scope design. Source writing and implementation use their owning workflows; a Skill return does not cancel a broader concrete authorization.

## Environment and Git

Before the first coding Feature, complete the Agent-led Project Environment setup under the language/configuration contract above. Coding requires confirmed environment preparation based on actual check results. Run `python -B tools/checks/check-project-environment.py --require-ready` during setup, after tool/configuration changes or to diagnose actual invocation failures; ordinary Features reuse confirmed commands without version discovery.

Every modifying task follows `agent-rules/00-core/git-worktree-and-commits.md`: inspect and preserve actual differences, continue from current records in the same directory, and commit validated logical changes with the applicable Feature identity. Non-empty Git status alone does not block a task; actual overlapping edits or an inseparable commit require resolving the concrete conflict. Implementation approval and actual human acceptance remain distinct under the execute loop; automated results cannot supply a missing human decision.

## Project knowledge and rule feedback

Before choosing an approach in planning, investigation, implementation, debugging or review, consult [relevant project knowledge](docs/knowledge/README.md#find-relevant-knowledge-first). Empty topics do not block work; knowledge cannot override accepted decisions or rules.

During authorized task documentation, retain useful approaches and failure lessons under [knowledge maintenance](docs/knowledge/README.md#maintain-during-authorized-work). Read-only tasks retain their write boundary. If there is no useful new learning, no entry is required. Finalize Feature notes and knowledge before the Stage 7 commit; Stage 8 links them.

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

启动编辑器检查（包括 `--headless --editor`）时，直接通过 `require_escalated` 审批路径在沙箱外运行；审批未通过或不可用时报告未执行或受阻，不绕过审批。

启动前先读取[本机编辑器检查细则](agent-rules/00-core/validation-policy.md#windows-editor-checks)；检查前后的目录核对及权限异常处理按该节执行。
