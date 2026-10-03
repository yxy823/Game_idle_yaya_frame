# Project instructions

This project uses Windows 11, PowerShell 7, Godot 4.7, GDScript and gdUnit4. The actual tool paths are in `docs/methodology-config.json`. Whether a tool works depends on actual check results; do not infer installed tools from templates.

## 沟通与交付

默认采用 ADHD 友好的表达，让用户容易理解并立即行动。以下要求只约定表达方式，不改变任务授权、验收或完成标准。

- **直接表达与阅读顺序：** 开头先回答用户最关心的问题。分析、评估和建议类回答先给主要结论、优先建议及影响判断的必要边界，再展开理由；主要要求查找问题时先呈现关键发现，单纯解释概念时不强造建议或下一步。用日常用语讲清具体问题、改法和结果，必要术语就地解释；删除客套、绕句、空泛鼓励和无用比喻。
- **同题就近讲完整：** 同一主题的建议、必要理由和适用边界放在一起，不拆散到“优点、缺点、建议、另外”等位置让读者自行拼接。确需跨节提及时，用短提醒或明确引用，不重复完整论述。
- **主要判断与支撑细节：** 不影响当前判断的实现细节、背景和补充案例后置；会改变建议的重要风险、前提和不确定性就近说明或前置，不为简洁隐藏。保留必要证据和来源，用户要求详细解释时充分展开。
- **按内容组织：** 简单问题直接回答，不为凑结构增加章节；长回复用能直接说明主题的标题，每个段落或条目围绕一个主要问题。操作流程用编号步骤，每步写清执行者和一个可判断完成的动作；需要按相同维度对照对象或方案时，可使用表格；多项内容按主题或用途分组。向用户提问时，遵循个人沟通规则及当前 Skill 的具体提问要求。评估、解释类回答不必逐段套用“执行者、动作、完成标准”，不以固定字数、段落数或条目数代替可读性判断。
- **用场景说明关系：** 解释多文档、多职责或跨阶段关系时，优先用贴近当前任务的具体场景串起需求、设计、实现与验收，再补充抽象分工。只在有助于理解当前关系时使用，不强制每次套用。
- **有用重复与无效复述：** 保留帮助记住优先项、恢复上下文或避免遗漏的简短重复，以及已有的默认高频提示机制；只删没有新增作用的复述，不因出现频繁就删除。
- **状态与交付：** 多轮工作有进展时说明已完成、仍受阻和下一步，不编造总步骤数。完成后先给可用成果、文件入口和实际验证结果。只有需要用户行动时，结尾给一个能立即开始的具体动作；工作已结束不另造下一步。
- **错误与估算：** 客观说明错误位置、已知原因和修复或排查办法，分清事实、推测与未知。同样的失败不盲目重试，先核对关键假设，有新证据再试。耗时估算有依据时用分钟、小时等单位或范围，写明影响估算的条件。
- **提问与授权：** 沿用具体授权，Agent 能完成的工作继续完成；缺少关键信息、决定或实际人工验收时请用户介入，优先提出最关键的问题。可能造成重要数据损失且现有授权未覆盖的操作，执行前确认；已明确批准的同一动作不重复询问。

## 使用说明的可读性

编写、更新或整理项目文档时，使用本地 [technical-documentation-writing-godot](.agents/skills/technical-documentation-writing-godot/SKILL.md)，按本次文档类型读取其中的参考。适用于 README、使用说明及需求、设计、知识和报告中的自然语言文字。

所属规范继续决定字段、固定路径、文档语言、流程、授权、验收与完成条件；写作 Skill 不替代这些契约，也不改变机器可读结构。持久项目文档使用 `docs/methodology-config.json` 中的 `document_language`。

## Workflow and authority

One project user works with an Agent. The workflow does not cover multi-user collaboration or tracking who made which change.

- Pausing, switching and resuming tasks in the same directory are supported, including from a new conversation.
- Use a worktree only when the current task's scope and authorization call for one, under [Git changes and commits](agent-rules/00-core/git-worktree-and-commits.md). Tasks do not start in a worktree by default.
- Bounded research and independent review use their own roles through the routes below.

| When you need to | Read |
| --- | --- |
| Choose a workflow or the next allowed action | [Canonical task routing](methodology/00-overview.md#canonical-task-routing). Skills are under `.agents/skills/`; explicit commands are under `tools/` |
| Create or maintain the GDD, numerical models or Product delivery plans | `methodology/01-product-doc-structure.md` |
| Maintain project terminology | `methodology/14-project-terminology.md` |
| Build a visual or logic prototype | `methodology/13-prototypes.md` |
| Plan Features, order Products or change the Feature ledger | `methodology/02-feature-list-schema.md` |
| Execute a Feature, including approvals, optional independent review and completion | `methodology/03-execute-loop.md` |
| Interpret, apply or change project rules | `methodology/04-project-rules.md` and `agent-rules/00-core/rule-precedence-and-routing.md` |
| Prepare Feature design and implementation guidance | The `implementation-guidance-godot` Skill |
| Set the document language | `methodology/05-document-language.md` |
| Configure tools or prepare the project environment | `methodology/06-project-environment.md` |
| Fix a Bug, refactor or do maintenance | `methodology/07-engineering-change.md` |
| Select tests, record current-run evidence or use the completion helper | `methodology/08-test-traceability-and-evidence.md`. Direct parsing and lint commands are in `methodology/contracts/gdscript-lint.md` |
| Organize reports, temporary workspaces, Progress, history or cleanup | `methodology/09-records-reports-and-handoff.md` |
| Maintain the optional architecture map or ADRs | `methodology/10-architecture-overview.md` |
| Work on professional design, resources, localization, diagnostics or several requirement sources | `methodology/11-specialist-workflows.md` |
| Run a formal review the user requested | `methodology/12-independent-review.md` |
| Research external facts or approaches | **External research** in `methodology/00-overview.md` |

These rows are task routes, not a reading sequence. Follow the selected procedure and the references it needs; do not load every workflow. When a Skill returns, continue the task under [Authorization and continuation](methodology/03-execute-loop.md#authorization-and-continuation).

### Design prerequisite and sources to read

Game design can start from an idea through `design-gdd`. Delivery planning, implementation, engineering work and runnable experiments need substantive GDD content that makes the current scope clear; a placeholder page does not count. The full rule is [GDD prerequisite and authority](methodology/01-product-doc-structure.md#gdd-prerequisite-and-authority). Product documents organize delivery and link to the GDD instead of copying its design.

Before design discussion, planning, implementation or review, read what applies to the task:

- [Design scope and boundaries](methodology/01-product-doc-structure.md#design-scope-and-boundaries), the relevant [open design questions](methodology/01-product-doc-structure.md#open-design-questions) and the GDD topics that cover the subject.
- Relevant definitions in `docs/terminology.md`.
- Relevant Product and specialist sources, and accepted architecture decisions.
- Relevant engineering constraints in `docs/project-rules.md`. A Product, Feature or ADR cannot silently waive them.

Starter pages that only describe a directory's purpose or a pending state are not confirmed requirements or definitions. Design discussion does not have to wait for every future detail or for detailed Product documents.

## Environment and Git

Before the first coding Feature, complete the [Project Environment Bootstrap](methodology/06-project-environment.md#project-environment-bootstrap). Coding requires an environment confirmed by actual check results. Run `python -B tools/checks/check-project-environment.py --require-ready` during setup, after a tool or configuration change, or to diagnose a failed tool invocation. Ordinary Features reuse the confirmed commands without rediscovering versions.

Before starting a Godot editor check, including `--headless --editor`, read and follow [Windows editor checks](agent-rules/00-core/validation-policy.md#windows-editor-checks).

Every task that modifies files follows [Git changes and commits](agent-rules/00-core/git-worktree-and-commits.md): work in the task's designated checkout, preserve existing changes, stage only this task's paths and commit complete logical changes. A local commit does not establish completion or human acceptance.

## Project knowledge and rule feedback

Before choosing an approach in planning, investigation, implementation, debugging or review, consult [relevant project knowledge](docs/knowledge/README.md#find-relevant-knowledge-first). Empty topics do not block work. Knowledge cannot override accepted decisions or rules.

During authorized task documentation, record useful approaches and failure lessons under [knowledge maintenance](docs/knowledge/README.md#maintain-during-authorized-work). Read-only tasks keep their write boundary. When there is no useful new learning, no entry is needed. Finalize Feature notes and knowledge before the Stage 7 commit; Stage 8 links them.

When work shows reusable prescriptive guidance that `agent-rules/` or `docs/project-rules.md` does not cover, propose it at the points and with the self-check defined in [incremental rule maintenance](methodology/04-project-rules.md#incremental-rule-maintenance). Do not edit rules without that approval.

## Engineering rule routing

`methodology/` defines workflow and traceability. `agent-rules/` defines concrete engine and language rules. Resolve a real conflict with the Core precedence protocol in `agent-rules/00-core/rule-precedence-and-routing.md`. The numbered rule-module directories do not prescribe the project's own folder layout.

For a modification or a relevant engineering decision, read `agent-rules/00-core/README.md` and the README of each affected domain below:

- Read only the matching sections and the domain's validation document, not the whole directory.
- Modules add up. For example, a test `.gd` file needs both the GDScript rules and the test rules.
- On continuation, reuse rules already loaded if they have not changed. Read more only when the task or new evidence requires it.

| Changed artifact or domain | Rule entry |
| --- | --- |
| GDScript | `agent-rules/10-gdscript/README.md` |
| Scene | `agent-rules/20-scenes/README.md` |
| Resource | `agent-rules/21-resources/README.md` |
| Shader | `agent-rules/30-shaders/README.md` |
| ProjectSettings | `agent-rules/40-project-config/README.md` |
| Export configuration or pipeline | `agent-rules/41-export-config/README.md` |
| Game data, schemas or data pipeline | `agent-rules/50-data-files/README.md` |
| Assets or import pipeline | `agent-rules/60-assets/README.md` |
| Tests, fixtures or runner | `agent-rules/70-tests/README.md` |
| UID, path, NodePath, business ID or RID identity | `agent-rules/00-core/godot-resource-references.md` |

If no dedicated module applies, use the relevant Core rules and the project's existing conventions, and read adjacent modules only where their topics overlap. Check the target Godot version's behavior when a change depends on version-sensitive engine behavior; ordinary Markdown edits do not need this. Do not extend the rule system as a side task of implementation.

To decide where game logic and presentation responsibilities belong, where their design sources are, or where a module goes and what it is called, read the matching sections of `docs/game-organization.md`. It explains concepts and examples; naming and engine constraints stay in the rule modules above.

The Core directory also covers these topics:

- Scope, minimal complete changes and preserving existing work: `change-scope-and-ownership.md`.
- Vendor, generated and temporary files: `third-party-generated-and-temporary-files.md`.
- Validation and truthful completion reports: `validation-policy.md` and `completion-and-reporting.md`.

Preserve authoritative state, APIs, ownership and lifecycle boundaries. Test and debug tooling must not become a backdoor for arbitrary reflection or property changes.
