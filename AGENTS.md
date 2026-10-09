# 框架维护约定

本仓库维护一套 Godot 起始框架：`framework/` 是维护材料，`.agents/skills/` 是框架自用 Skill，`project-source/` 是复制进生成项目的分发源。`project-source/` 里的规则、流程和 Skill 在本仓库只作为源材料阅读，不启用项目开发的 Stage。文本格式以 [.editorconfig](.editorconfig)、[.gitattributes](.gitattributes) 为准；术语按[框架术语](framework/terminology.md)。

## 基本约束

- **只面向 Godot**：只支持已确定的 Godot 技术栈，不为其他引擎、平台或旧项目预留兼容，也不做向后兼容。
- **只做 Windows PC**：生成的游戏只支持鼠标和键盘，不支持手柄、触屏和其他平台，不按项目单独设置平台。
- **单人项目**：一位使用者与 Agent 配合开发，多人协作和改动归属处理不在设计与场景范围内，不为此扩展流程、工具或配置。同一目录内的暂停、切换和换对话续接仍然支持；是否使用 worktree 由当前任务范围与授权决定，不因普通暂停或换对话默认创建。按需调研 Agent 和独立审核 Agent 仍可使用，独立审核按[正式审核的独立性](framework/maintenance/design-guidelines/reviews-and-reports.md#正式审核的独立性)执行。
- **不监督 Agent 的每个动作**：不增加重复状态、来源哈希清单、收据、评分或发布资格，只保留针对实际成果的验证；提交钩子可以检查提交内容，不记录或评价 Agent 的动作。
- **提问与授权**：沿用具体授权，Agent 能完成的工作继续完成；缺少关键信息、决定或实际人工验收时请用户介入，优先提出最关键的问题。可能造成重要数据损失且现有授权未覆盖的操作，执行前确认；已明确批准的同一动作不重复询问。生成项目的 `project-source/Project_AGENTS.md`「工作流程与授权」有同样一条，修改其中一份时同步另一份。

## 核心决策原则

- **目标驱动**：先从用户要完成的事识别关键决策和交付物，再看现有能力能否覆盖，最后决定复用、补充还是新增。
- **背景与场景核对**：讨论新增能力或文档前，先说明现有背景、已有职责、新增位置和上下游；收尾时用一个具体场景走一遍，确认能从需求找到设计、实现与验收。
- **唯一正文与集中维护**：同一事实只在职责所属位置写一份正文，其他位置引用；迁移时同步引用并删除旧正文。归属怎么定见[文档职责与固定归属](framework/maintenance/design-guidelines/document-responsibilities.md#文档职责与固定归属)。
- **按职责组织，权衡拆合成本**：按共同目标、变化原因和使用场景决定拆合，不单凭文件长短或数量，见[职责设计准则](framework/maintenance/design-guidelines/README.md)。
- **奥卡姆剃刀**：先比较复用、合并、删除与局部修正；现有文件、命令或 Agent 判断够用时，不加脚本、依赖或流程层；临时脚本是否保存见[何时把临时脚本做成工具](framework/maintenance/design-guidelines/skills-and-scripts.md#何时把临时脚本做成工具)。
- **第一性原理**：从当前需求和已知约束推导方案；现有实现或历史投入不是必须保留的理由。
- **最小完整修改**：在授权范围内选能完整解决问题的最小方案，保留必要的能力与约束，不以行数或文件数为目标，也不借修复扩大任务。

## 维护边界与查阅

下表列出“做这类工作前先读哪里”。只读本次用得到的行，不把整张表当成每轮前置阅读。

| 做这类工作前 | 先读 |
| --- | --- |
| 修改框架的任何文件 | [框架入口](framework/README.md)，再按[框架维护与说明同步](framework/maintenance/maintenance-and-sync.md)判断修改属于哪里；开始修改前读一遍其中的[修改时的联动检查](framework/maintenance/maintenance-and-sync.md#修改时的联动检查)，提交前再逐条核对。修改框架自己的工具时，同样按[修改分发源](framework/maintenance/maintenance-and-sync.md#修改分发源)中“代码或工具”一条先确认范围 |
| 修改 `project-source/` 下的文件 | [修改分发源](framework/maintenance/maintenance-and-sync.md#修改分发源)。生成项目的规则源文件是 `project-source/Project_AGENTS.md`，创建项目时复制为项目的 `AGENTS.md`，在本仓库只作为源材料阅读 |
| 框架维护任务开始或续接；修改 `framework/progress.md` 或提示词库 | [framework/AGENTS.md](framework/AGENTS.md)（Claude Code 读取 `framework/` 下的文件时会自动加载它；Codex 只在工作目录位于 `framework/` 时自动读到，所以这里显式要求先读） |
| 新增、移动、拆分、合并或命名文件 | [目录组织](framework/maintenance/design-guidelines/document-responsibilities.md#目录组织) |
| 选择验证范围，或派活时写验证要求 | [按修改选择验证范围](framework/maintenance/validation/validation-scope.md#按修改选择验证范围)，它优先于个人规则里的验证默认值 |
| 编写或整理框架文档；回复和文档要避开的写法 | [technical-documentation-writing-yaya](.agents/skills/technical-documentation-writing-yaya/SKILL.md)；[措辞检查](project-source/skills/technical-documentation-writing-godot/references/writing-guide.md#措辞检查)；两份写作 Skill 的分工见[两份写作 Skill 的分工](framework/maintenance/maintenance-and-sync.md#两份写作-skill-的分工) |
| 编写或修改 AGENTS.md、Skill、任务提示词 | [规则与提示词文件](framework/maintenance/design-guidelines/instruction-files.md) |
| 核实外部审核报告；用户要求独立审核 | [审核与报告](framework/maintenance/design-guidelines/reviews-and-reports.md) |
| 判断授权是否延续、何时停下问用户 | [授权在后续对话中的延续](framework/maintenance/maintenance-and-sync.md#授权在后续对话中的延续) |
| 讨论中用户的追问暴露出理解缺口，或问到以后还会用到的专业知识 | [Q&A](framework/qa/README.md)，按其中「什么时候添加」直接添加问答，不必先问 |
| 写草稿、当次方案、报告或交接材料 | 给用户看或用于交接的文档放在仓库根目录 `tmp/`，按任务建子目录；任务目录名或文件名带实际日期，例如 `tmp/idle-demo-trial-20261008/` 或 `demo-issue-list-20261004.md`。中间脚本和输出放会话自己的临时目录。不放进正式文档目录；长期有效的结论写回职责所属的正文后再删除，保存与清理见[当次报告的保存与清理](framework/maintenance/design-guidelines/reviews-and-reports.md#当次报告的保存与清理) |

## 本地提交

会修改文件的获准任务，按可验证的逻辑成果自动创建本地提交，不再询问；用户或派活的主 Agent 规定了不提交或提交条件时，按其范围执行。被派的子智能体被禁止 Git 写操作、又要连续完成多个成果时，每个成果做到可提交就停下，交回主 Agent 提交。

开始修改前读[本地提交的做法](framework/maintenance/maintenance-and-sync.md#本地提交的做法)，提交前再按它核对：开始时记录工作区状态、怎样暂存、钩子拒绝后怎么办、提交说明格式和交付时说明什么。

禁止：

- 不使用 `--no-verify`；不自动 push、tag、amend、rebase、reset、切换分支或修改远程配置；不用 stash 或 clean 整理提交。
- 提交后发现问题，新建修正提交，不改写历史。
- 非仓库、权限、身份、签名或钩子等原因阻止提交时，保留修改并报告，不擅自 init 或改配置；用户明确要求创建项目时，创建器仍按其契约初始化新仓库。
