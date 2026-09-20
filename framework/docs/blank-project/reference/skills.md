# Skill 与提示词导航

[返回手册](../README.md) · 相关：[需求与规划](../guides/product-and-planning.md)、[工程变更](../guides/engineering-changes.md)

本页用于选择任务入口。提示词表达本次目标与授权，Skill 提供执行方法，`methodology/` 定义流程和数据契约。当前项目携带 12 项 Skill，位于 `.agents/skills/`；集中提示词留在框架，用户取出正文后在对应工作目录发送。

## 从哪里取得操作提示词

所有可供用户发送给 Agent 的正式操作提示词都在 [framework/prompts.json](../../../prompts.json)。顶层包含“Yaya 框架维护”和“Godot 项目开发”两个 Project，保留 `project`、`categories` 结构；分类下的叶子键是提示词名，字符串值是完整正文。

使用时选择当前任务对应的一条，有 `${1:说明}` 等占位内容时先填写，再在正确目录发送；GitHub 审核入口交给具有仓库读取权限的模型。以下列出查找位置，不复制正文。

Codex 输出、外部报告、需求原文和复现日志等可能较长的输入，在相关提示词末尾有独立材料区。先填写目标、范围等短信息，再将原文放入末尾占位处；前面的上下文字段只留摘要或路径。材料区后不再接本条任务要求，补充授权或输出要求放回前文，或在后续消息中明确提出。材料区用于区分指令与输入，不保证仅靠位置就能隔离材料中的干扰。

| 使用场景 | Project → 分类 → 提示词名称 |
| --- | --- |
| 创建输出目录 | Godot 项目开发 → 项目创建与接入 → 创建空白项目 |
| 保留成果并复制迁移旧项目 | Godot 项目开发 → 项目创建与接入 → 复制并迁移旧框架项目 |
| 确认工具路径与环境 | Godot 项目开发 → 项目创建与接入 → 准备 Godot 开发环境 |
| 先讨论，不写文档 | Godot 项目开发 → 需求设计 → 轻量讨论与澄清 |
| 澄清并保留术语定义 | Godot 项目开发 → 需求设计 → 澄清并记录项目术语 |
| 测试一个想法，或单独验证视觉布局与资源尺度 | Godot 项目开发 → 需求设计 → 验证玩法或技术假设 |
| 将想法或已有 GDD 整理为正式需求 | Godot 项目开发 → 需求设计 → 从想法或已有 GDD 整理 Product 并衔接规划 |
| 已有功能但缺少需求或任务记录 | Godot 项目开发 → 需求设计 → 从已有实现补齐需求与任务 |
| 只把外部文本或文档适配为需求草稿 | Godot 项目开发 → 需求设计 → 只读适配外部需求内容 |
| 改变玩法 | Godot 项目开发 → 需求设计 → 新增、删除或调整玩法需求 |
| 设计界面 | Godot 项目开发 → 需求设计 → 设计界面与交互 |
| 设计声音 | Godot 项目开发 → 需求设计 → 设计音效与音乐需求 |
| 拆分当前模块的任务 | Godot 项目开发 → 任务规划 → 拆分当前 Product 的 Feature |
| 增量同步 | Godot 项目开发 → 任务规划 → 需求变化后同步已有任务 |
| 了解现状、询问下一步或根据 Codex 输出起草回复 | Godot 项目开发 → 日常开发 → 判断当前状态与下一步 |
| 开发任务 | Godot 项目开发 → 日常开发 → 执行指定或下一项 Feature |
| 连续规划与开发，做到首个人工验收交接点 | Godot 项目开发 → 日常开发 → 以 Goal 逐个推进 Product 至人工验收；见 [Goal 使用说明](../guides/feature-delivery.md#用-goal-连续规划与开发) |
| 恢复工作 | Godot 项目开发 → 日常开发 → 继续中断的当前任务 |
| 架构调查 | Godot 项目开发 → 修复与改进 → 只读调查架构改进机会 |
| 缺陷修复 | Godot 项目开发 → 修复与改进 → 定位与修复 Bug |
| 重构 | Godot 项目开发 → 修复与改进 → 行为保持的重构 |
| 工程维护 | Godot 项目开发 → 修复与改进 → 工程维护与工具调整 |
| 审核通过后在当前项目替换框架 | Godot 项目开发 → 修复与改进 → 审核并原地替换项目框架 |
| 根据当前任务整理素材准备清单 | Godot 项目开发 → 资源、性能与数据 → 分析并整理任务资源清单；见 [准备与交接](../guides/product-and-planning.md#按清单准备资源再继续原型) |
| 素材处理 | Godot 项目开发 → 资源、性能与数据 → 接入或替换游戏资源；有清单时核对并更新同一份 |
| 性能工作 | Godot 项目开发 → 资源、性能与数据 → 定位并优化性能 |
| 数据迁移 | Godot 项目开发 → 资源、性能与数据 → 调整存档或迁移项目数据 |
| 手动编辑后的需求一致性检查 | Godot 项目开发 → 验证与收尾 → 检查手动修改与需求的一致性 |
| 补充验证 | Godot 项目开发 → 验证与收尾 → 单独验证某次变更 |
| 独立审查模块现状、文件快照或指定变更 | Godot 项目开发 → 验证与收尾 → 独立审查代码或指定变更 |
| 人工反馈 | Godot 项目开发 → 验证与收尾 → 整理人工验收与反馈 |
| 进度整理与新线程交接 | Godot 项目开发 → 验证与收尾 → 整理进度与任务交接 |
| 总结可复用经验 | Godot 项目开发 → 经验沉淀 → 阶段性总结与复用脚本沉淀 |

创建空白项目的提示词针对框架目录执行复制；[旧项目迁移](../getting-started/migrate-existing-project.md)只读原项目与框架、仅写独立目标；[原地框架替换](../guides/engineering-changes.md#原地替换项目框架)只读框架来源、更新当前项目；其他项目开发提示词针对目标游戏项目。不要因为 Project 分类名称相同就把命令执行在同一个目录。

框架维护入口位于“Yaya 框架维护”，涵盖设计、修改、审核、验证与交接。查找对应入口及输入、产物和只读/实施边界，统一见 [维护提示词说明](../maintenance/updating-the-blank-project.md#通过提示词开始维护)。项目换线程的具体步骤见 [任务交接](../guides/project-knowledge.md#换到新线程继续)。

手册中的名称用于定位提示词，实际授权以当前 JSON 正文和用户请求为准；已有 GDD 的读取、归属和后续规划见 [GDD 接入说明](../guides/product-and-planning.md#接入已有-gdd)。

### 根据 Codex 输出起草回复

在目标游戏项目中选择“Godot 项目开发 → 日常开发 → 判断当前状态与下一步”，填写原任务、疑问和已有决定，将 Codex 输出原文或文件路径放入末尾的“Codex 输出（可选）”材料区。只询问状态或下一步时，该处填“无”。

Agent 使用 `yaya-next-step-advisor`，结合当前项目规则、相关任务和可用证据，判断原输出的结论、建议与停点是否合理。需要回信时，先给简短判断，再提供一个可复制的回复代码块，说明应继续、纠正或补充核实的事项及适用流程；只问状态时直接回答事实。

分析只读进行，回复由你检查后发送。已有明确授权继续沿用；Codex 的总结不能替代原始验证证据，生成的回复也不替你作出未表达的产品决定或人工验收。若目的是判断框架本身是否需要改进，改用框架维护侧的 [开发反馈复盘入口](../maintenance/updating-the-blank-project.md#从实际开发反馈复盘框架)。

## 常见组合

| 你要完成的工作 | 操作关系 |
| --- | --- |
| 先想清楚 | 讨论并形成结论；需要保存已确认术语时，由需求整理入口写入 |
| 开始新游戏 | 整理需求，按需澄清界面与声音，拆分并交付当前模块；详细路线见 [需求指南](../guides/product-and-planning.md) |
| 改需求 | 更新正式需求，处理对已有任务的影响；后续未拆分模块先保留需求变化 |
| 修独立 Bug | 诊断与工程任务规划，然后实现、回归和适用验收 |
| 选择重构 | 只读比较候选，确定范围后进入工程规划与执行 |
| 继续中断任务 | 核对 Progress、原任务和实际差异，从真实阶段继续 |
| 手动修改后接回开发 | [先核对相关需求与实际差异](../guides/engineering-changes.md#手动修改后检查需求一致性)，再按明确的处理范围进入现有 Product 或工程路线 |
| 只读调查 | 回答明确问题并提供证据，不自动进入实现 |

Agent 按实际任务选择所需 Skill，复用已明确的信息和授权，只补问影响决定的缺口。界面草图与 HTML 探索用于表达需求；新界面等需要实际验证的情况按 [Godot 视觉原型](../guides/product-and-planning.md#先验证视觉原型再接入依赖它的逻辑) 衔接规划与执行。

## 12 项 Skill 的职责

下表链接的是框架中的源文件。正式开发时读取目标项目 `.agents/skills/<name>/SKILL.md`，因为生成后的副本可能已经独立修改。

| Skill | 适合的任务 | 主要产物与边界 |
| --- | --- | --- |
| [project-clarifier](../../../../project-source/skills/project-clarifier/SKILL.md) | 讨论想法、设计取舍与领域概念 | 小步澄清；只讨论不写文件，获授权的术语交给现有写入入口 |
| [product-change-standardizer](../../../../project-source/skills/product-change-standardizer/SKILL.md) | 初始化、补充或改变 Product 意图；维护已确认术语 | 统一写入 Product 与 CONTEXT，处理对已有任务的影响；初次拆分只针对当前模块 |
| [product-init-elicitor](../../../../project-source/skills/product-init-elicitor/SKILL.md) | Product 为空，梳理游戏蓝图 | 结构化草案；自身不写 Product 文件 |
| [product-spec-elicitor](../../../../project-source/skills/product-spec-elicitor/SKILL.md) | 模块、行为修改或跨模块需求存在重要歧义 | 返回规格补丁；自身不写文件 |
| [product-ui-sketcher](../../../../project-source/skills/product-ui-sketcher/SKILL.md) | 界面与交互表达、视觉基础规格 | ASCII 线框、已确认约束与原型待验证问题；可选 HTML 探索，Godot 场景交给执行入口 |
| [product-audio-sketcher](../../../../project-source/skills/product-audio-sketcher/SKILL.md) | 音效、音乐与触发要求 | 音频需求、真实样本引用和试听问题；缺少资源时给出占位命名，不生成音频或实现播放 |
| [generate-feature-list](../../../../project-source/skills/generate-feature-list/SKILL.md) | 初次拆分当前模块需求 | 先展示数量与逐项摘要，按 [预览确认约定](../guides/product-and-planning.md#写入前看拆分预览) 追加计划并保留历史；前一模块完成后再拆下一模块 |
| [sync-feature-list](../../../../project-source/skills/sync-feature-list/SKILL.md) | 需求或 Coding Rules 改变后增量对齐 | 分析 Git 来源差异，保存任务迁移、依赖与测试影响 |
| [engineering-change-standardizer](../../../../project-source/skills/engineering-change-standardizer/SKILL.md) | Bug、重构或工程维护 | 分类和诊断，提出并写入获批工程 Feature；执行交给对应 Skill |
| [execute-next-feature](../../../../project-source/skills/execute-next-feature/SKILL.md) | 开始或继续一个确定的 Feature | 实现、测试、适用验收、用户指定的可选评审、完成记录、本地提交与交接 |
| [pick-refactor-smell](../../../../project-source/skills/pick-refactor-smell/SKILL.md) | 从已有记录中挑选重构候选 | 只读比较与推荐，返回工程标准化入口 |
| [yaya-next-step-advisor](../../../../project-source/skills/yaya-next-step-advisor/SKILL.md) | 理解现状、不知道下一步怎么说 | 状态问题直接回答；需要续接或下一步操作时给提示词，不运行检查或授予批准 |

项目规则与 [方法总览](../../../../project-source/methodology/00-overview.md) 负责完整路由。不要因用户问“当前进度”就执行环境探测或测试；也不要把明确实现请求降级成只提供下一步建议。

Skill 保留本职操作步骤和独有工具用法，阶段流程、字段契约与语言规则分别引用对应权威规范。按任务读取相关章节，沿用仍有效的上下文；局部需求先从 Product 总览定位受影响模块和共享约定，再按实际依赖展开。工程规则由模块 README 按主题路由，例如单元测试不会自动要求读取场景测试和输入测试专题。

## Skill 未被自动识别时

先核对当前工作目录、项目 `.agents/skills/` 和目标 `SKILL.md` 是否存在，再核对所用 Agent 对项目 Skill 的加载方式。不要直接以“未自动出现”推断源文件丢失，也不要先改流程或生成替代 Skill。

这份手册不承诺所有 Agent 客户端都以相同方式自动加载 Skill；目标项目的实际文件与当前客户端行为需要分别确认。
