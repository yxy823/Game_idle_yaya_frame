# Skill 与提示词导航

[返回手册](../README.md) · 相关：[需求与规划](../guides/product-and-planning.md)、[工程变更](../guides/engineering-changes.md)

本页用于选择任务入口。提示词表达本次目标与授权，Skill 提供方法，`methodology/` 定义流程和数据契约。当前项目携带 27 项 Skill，位于 `.agents/skills/`，另有独立审核与调研两个角色；完整提示词库留在框架，用户取出正文后在对应工作目录发送，advisor 仅携带下述精选表达参考。

## 从哪里取得操作提示词

不确定眼前问题属于哪个入口时，先看 [场景检查单索引](../guides/scenario-procedures.md)。各场景给出详细步骤、异常分支和对应 Prompt 名称；本页用于快速选取执行指令，不另存提示词正文。

所有可供用户发送给 Agent 的正式操作提示词都在 [framework/prompts.json](../../../../prompts.json)。顶层包含“Yaya 框架维护”和“Godot 项目开发”两个 Project，保留 `project`、`categories` 结构；分类下的叶子键是提示词名，字符串值是完整正文。

使用时选择当前任务对应的一条，有 `${1:说明}` 等占位内容时先填写，再在正确目录发送；GitHub 审核入口交给具有仓库读取权限的模型。以下列出查找位置，不复制正文。

Codex 输出、外部报告、需求原文和复现日志等可能较长的输入，在相关提示词末尾有独立材料区。先填写目标、范围等短信息，再将原文放入末尾占位处；前面的上下文字段只留摘要或路径。材料区后不再接本条任务要求，补充授权或输出要求放回前文，或在后续消息中明确提出。材料区用于区分指令与输入，不保证仅靠位置就能隔离材料中的干扰。

### 项目创建与接入

| 使用场景 | Project → 分类 → 提示词名称 |
| --- | --- |
| 创建输出目录 | Godot 项目开发 → 项目创建与接入 → 创建空白项目 |
| 保留成果并复制迁移旧项目 | Godot 项目开发 → 项目创建与接入 → 复制并迁移旧框架项目 |
| 确认工具路径与环境 | Godot 项目开发 → 项目创建与接入 → 准备 Godot 开发环境 |

### 需求设计

| 使用场景 | Project → 分类 → 提示词名称 |
| --- | --- |
| 先讨论，不写文档 | Godot 项目开发 → 需求设计 → 轻量讨论与澄清 |
| 查外部资料、比较技术方案并按需保存报告 | Godot 项目开发 → 需求设计 → 调研外部资料与技术方案；见 [搜索与调研](../guides/project-knowledge.md#按需搜索与保存调研) |
| 澄清并保留术语定义 | Godot 项目开发 → 需求设计 → 澄清并记录项目术语 |
| 测试一个想法，或单独验证视觉布局与资源尺度 | Godot 项目开发 → 需求设计 → 验证视觉、玩法或技术假设 |
| 将想法或已有 GDD 整理为正式需求 | Godot 项目开发 → 需求设计 → 从想法或已有 GDD 整理 Product 并衔接规划 |
| 已有功能但缺少需求或任务记录 | Godot 项目开发 → 需求设计 → 从已有实现补齐需求与任务 |
| 只把外部文本或文档适配为需求草稿 | Godot 项目开发 → 需求设计 → 只读适配外部需求内容 |
| 改变玩法 | Godot 项目开发 → 需求设计 → 新增、删除或调整玩法需求 |
| 设计界面 | Godot 项目开发 → 需求设计 → 设计界面与交互 |
| 确定共享美术方向 | Godot 项目开发 → 需求设计 → 确定或调整美术风格 |
| 确定共享声音方向 | Godot 项目开发 → 需求设计 → 确定或调整声音风格 |
| 设计声音 | Godot 项目开发 → 需求设计 → 设计音效与音乐需求 |

### 任务规划与日常开发

| 使用场景 | Project → 分类 → 提示词名称 |
| --- | --- |
| 拆分当前模块的任务 | Godot 项目开发 → 任务规划 → 拆分当前 Product 的 Feature |
| 增量同步 | Godot 项目开发 → 任务规划 → 需求变化后同步已有任务 |
| 了解现状、询问下一步或根据 Codex 输出起草回复 | Godot 项目开发 → 日常开发 → 判断当前状态与下一步 |
| 开发任务 | Godot 项目开发 → 日常开发 → 执行指定或下一项 Feature |
| 连续规划与开发，做到首个人工验收交接点 | Godot 项目开发 → 日常开发 → 以 Goal 逐个推进 Product 至人工验收；见 [Goal 使用说明](../guides/feature-delivery.md#用-goal-连续规划与开发) |
| 恢复工作 | Godot 项目开发 → 日常开发 → 继续中断的当前任务 |

### 修复与改进

| 使用场景 | Project → 分类 → 提示词名称 |
| --- | --- |
| 架构调查 | Godot 项目开发 → 修复与改进 → 只读调查架构改进机会 |
| 缺陷修复 | Godot 项目开发 → 修复与改进 → 定位与修复 Bug |
| 重构 | Godot 项目开发 → 修复与改进 → 行为保持的重构 |
| 工程维护 | Godot 项目开发 → 修复与改进 → 工程维护与工具调整 |
| 审核通过后在当前项目替换框架 | Godot 项目开发 → 修复与改进 → 审核并原地替换项目框架 |

### 资源、性能与数据

| 使用场景 | Project → 分类 → 提示词名称 |
| --- | --- |
| 根据当前任务整理素材准备清单 | Godot 项目开发 → 资源、性能与数据 → 分析并整理任务资源清单；见 [准备与交接](../guides/product-and-planning.md#按清单准备资源再继续原型) |
| 素材处理 | Godot 项目开发 → 资源、性能与数据 → 接入或替换游戏资源；有清单时核对并更新同一份 |
| 仅定位性能问题或测量后优化 | Godot 项目开发 → 资源、性能与数据 → 定位并优化性能；选择本次范围，见 [测量与优化](../guides/specialist-workflows.md#只定位性能问题还是继续优化) |
| 本地化设计或实现 | Godot 项目开发 → 资源、性能与数据 → 设计或实施本地化 |
| 补充诊断所需的信息 | Godot 项目开发 → 资源、性能与数据 → 补充运行观测信号 |
| 长时间运行验证 | Godot 项目开发 → 资源、性能与数据 → 执行长期运行验证 |
| 数据迁移 | Godot 项目开发 → 资源、性能与数据 → 调整存档或迁移项目数据 |

### 验证与收尾、经验沉淀

| 使用场景 | Project → 分类 → 提示词名称 |
| --- | --- |
| 手动编辑后的需求一致性检查 | Godot 项目开发 → 验证与收尾 → 检查手动修改与需求的一致性 |
| 补充验证 | Godot 项目开发 → 验证与收尾 → 单独验证某次变更 |
| 独立审查模块现状、文件快照或指定变更 | Godot 项目开发 → 验证与收尾 → 独立审查代码或指定变更 |
| 按领域独立审核设计、资源或专项证据 | Godot 项目开发 → 验证与收尾 → 独立审核专业成果 |
| 人工反馈 | Godot 项目开发 → 验证与收尾 → 整理人工验收与反馈 |
| 进度整理与新线程交接 | Godot 项目开发 → 验证与收尾 → 整理进度与任务交接 |
| 总结可复用经验 | Godot 项目开发 → 经验沉淀 → 阶段性总结与复用脚本沉淀 |

### 工作目录与写入范围

| 入口 | 工作目录与写入范围 |
| --- | --- |
| 创建空白项目 | 从框架目录运行创建器，只向指定外部空目录复制 |
| [复制迁移](../getting-started/migrate-existing-project.md) | 原项目与框架只读，目标是独立目录 |
| [原地框架替换](../guides/engineering-changes.md#原地替换项目框架) | 框架来源只读，更新当前项目 |
| 其他项目开发 | 在生成项目或已指定 worktree 中读取自身配置与规则 |
| 框架维护 | 在框架仓库内，按当前维护授权处理 |

原有操作材料中，首次读者查阅 [首次使用说明](../getting-started/first-use.md)，工程任务从 [工程变更](../guides/engineering-changes.md#按实际目标选择路线) 选择入口；这些具体场景将在样稿讨论后统一迁移。

框架维护入口位于“Yaya 框架维护”，涵盖设计、修改、审核、验证与交接。查找对应入口及输入、产物和只读/实施边界，统一见 [维护提示词说明](../../updating-the-blank-project.md#通过提示词开始维护)。项目换线程的具体步骤见 [任务交接](../guides/project-knowledge.md#换到新线程继续)。

手册中的名称用于定位提示词，实际授权以当前 JSON 正文和用户请求为准；已有 GDD 的读取、归属和后续规划见 [GDD 接入说明](../guides/product-and-planning.md#接入已有-gdd)。

### 根据 Codex 输出起草回复

在目标游戏项目中选择“Godot 项目开发 → 日常开发 → 判断当前状态与下一步”，填写原任务、疑问和已有决定，将 Codex 输出原文或文件路径放入末尾的“Codex 输出（可选）”材料区。只询问状态或下一步时，该处填“无”。

Agent 使用 `project-next-step-advisor`，结合当前项目规则、相关任务和可用证据，判断原输出的结论、建议与停点是否合理。需要回信时，先给简短判断，再提供一个可复制的回复代码块，说明应继续、纠正或补充核实的事项及适用流程；只问状态时直接回答事实。

分析只读进行，回复由你检查后发送。已有明确授权继续沿用；Codex 的总结不能替代原始验证证据，生成的回复也不替你作出未表达的产品决定或人工验收。若目的是判断框架本身是否需要改进，改用框架维护侧的 [开发反馈复盘入口](../../updating-the-blank-project.md#从实际开发反馈复盘框架)。

### advisor 的精选表达参考

`project-next-step-advisor` 按当前项目规范和目标 Skill 确定路线；需要起草回复时，才从 [精选索引](../../../../../project-source/skills/project-next-step-advisor/references/prompt-examples.md) 选择相关条目。12 条示例按需求、规划、开发、工程变更、验证与交接分为五个文件，不要求通读；只问状态时无需读取。

示例正文唯一来源仍是 `framework/prompts.json`，派生 Markdown 不手工维护。示例中的“我授权”、停止条件和占位符不构成当前指令；advisor 结合真实状态与已有授权重新组织措辞，示例过期或缺失时仍按项目自身规范回答。创建、迁移、框架替换、Goal 和 advisor 自身入口未选入。

维护者显式运行 [导出器](../../../../commands/export_advisor_prompt_examples.py) 更新源材料，创建器仅照常复制 Skill 中的静态参考。生成项目不读取框架 JSON、不执行导出或自动同步；命令见 [维护工具](../../../../README.md#导出-advisor-精选表达参考)。

## 27 项 Skill 的职责

下表链接的是框架中的源文件。正式开发时读取目标项目 `.agents/skills/<name>/SKILL.md`，因为生成后的副本可能已经独立修改。

Skill 按实际能力使用 `project-`、`product-`、`feature-`、`engineering-`、`design-`、`content-`、`diagnostics-`、`review-` 前缀，目录名与 frontmatter 的 `name` 一致。目录保持扁平；前缀用于聚合职责，不表示固定阶段、执行顺序或额外授权。方向、规格、内容接入与独立审核分别命名，产物文件仍使用各自契约规定的名称。

### 需求澄清与当前状态

| Skill | 适合的任务 | 主要产物与边界 |
| --- | --- | --- |
| [project-clarifier](../../../../../project-source/skills/project-clarifier/SKILL.md) | 讨论想法、设计取舍与领域概念 | 小步澄清；只讨论不写文件，获授权的术语交给现有写入入口 |
| [product-author](../../../../../project-source/skills/product-author/SKILL.md) | 初始化、补充或改变 Product 意图；维护已确认术语 | 统一写入 Product 与术语文档，核对项目约束并处理已有任务影响；Feature 内术语整理后返回原流程 |
| [product-init-elicitor](../../../../../project-source/skills/product-init-elicitor/SKILL.md) | Product 为空，梳理游戏蓝图 | 结构化草案；自身不写 Product 文件 |
| [product-spec-elicitor](../../../../../project-source/skills/product-spec-elicitor/SKILL.md) | 模块、行为修改或跨模块需求存在重要歧义 | 返回规格补丁；自身不写文件 |
| [project-next-step-advisor](../../../../../project-source/skills/project-next-step-advisor/SKILL.md) | 理解现状、不知道下一步怎么说 | 状态问题直接回答；需要续接或下一步操作时给提示词，不运行检查或授予批准 |

### 规划执行与工程变更

| Skill | 适合的任务 | 主要产物与边界 |
| --- | --- | --- |
| [feature-plan](../../../../../project-source/skills/feature-plan/SKILL.md) | 初次拆分当前模块需求 | 先展示数量与逐项摘要，按 [预览确认约定](../guides/product-and-planning.md#写入前看拆分预览) 追加计划并保留历史；前一模块完成后再拆下一模块 |
| [feature-sync](../../../../../project-source/skills/feature-sync/SKILL.md) | Product、专业要求或 Project Rules 改变后增量对齐 | 分析来源差异、共享约束与首次纳入历史覆盖，保存任务和测试影响 |
| [engineering-change-plan](../../../../../project-source/skills/engineering-change-plan/SKILL.md) | Bug、重构或工程维护 | 分类和诊断，提出并写入获批工程 Feature；执行交给对应 Skill |
| [feature-execute](../../../../../project-source/skills/feature-execute/SKILL.md) | 开始或继续一个确定的 Feature | 实现、测试、适用验收、用户指定的可选评审、完成记录、本地提交与交接 |
| [engineering-refactor-select](../../../../../project-source/skills/engineering-refactor-select/SKILL.md) | 从已有记录中挑选重构候选 | 只读比较与推荐，返回工程标准化入口 |

### 专业设计与资源接入

| Skill | 适合的任务 | 主要产物与边界 |
| --- | --- | --- |
| [design-art-direction](../../../../../project-source/skills/design-art-direction/SKILL.md) | 选择或调整美术风格 | 直接维护共享美术规范，按当前需要决定方向；不制作样张 |
| [design-audio-direction](../../../../../project-source/skills/design-audio-direction/SKILL.md) | 选择或调整声音方向 | 直接维护声音角色、情绪与反馈层次；不制作音乐或音效 |
| [design-visual-asset-spec](../../../../../project-source/skills/design-visual-asset-spec/SKILL.md) | 制定具体视觉素材规格 | 维护现有资源清单条目，区分要求与实测；不制作或接入 |
| [design-ui-spec](../../../../../project-source/skills/design-ui-spec/SKILL.md) | 界面与交互表达、视觉基础规格 | 直接维护 UI 规格、线框与原型问题；Godot/HTML 实现交给授权实验或执行任务 |
| [design-audio-asset-spec](../../../../../project-source/skills/design-audio-asset-spec/SKILL.md) | 具体音效、音乐与触发要求 | 直接维护资源条目、样本和试听问题；不负责共享声音风格或实际生产 |
| [content-asset-integration](../../../../../project-source/skills/content-asset-integration/SKILL.md) | 接入或替换现有素材 | 按原授权任务处理导入、引用与实际表现，返回原任务验证收尾 |
| [content-localization](../../../../../project-source/skills/content-localization/SKILL.md) | 本地化规格、翻译与语言支持 | 专业规范与运行资源分开，代码/资源修改由原任务承接 |

### 诊断与测量

| Skill | 适合的任务 | 主要产物与边界 |
| --- | --- | --- |
| [diagnostics-instrumentation](../../../../../project-source/skills/diagnostics-instrumentation/SKILL.md) | 补充诊断信息 | 最小必要日志、计数、计时或显示；区分临时埋点与保留支持 |
| [diagnostics-performance](../../../../../project-source/skills/diagnostics-performance/SKILL.md) | 性能测量与诊断 | 真实负载、版本、可比测量与原因判断；修复另按原任务授权 |
| [diagnostics-soak-test](../../../../../project-source/skills/diagnostics-soak-test/SKILL.md) | 长期运行与累积问题验证 | 明确预算、实际时长、采样和中止原因；不替代 gdUnit 结果 |

### 独立审核

| Skill | 适合的任务 | 主要产物与边界 |
| --- | --- | --- |
| [review-code](../../../../../project-source/skills/review-code/SKILL.md) | 独立审查代码与指定变更 | 分开判断需求符合性、代码质量与证据缺口 |
| [review-ux](../../../../../project-source/skills/review-ux/SKILL.md) | 独立审核交互体验 | 核对实际流程与界面状态；不设计界面或做通用试玩分析 |
| [review-art](../../../../../project-source/skills/review-art/SKILL.md) | 独立审核美术效果 | 核对实际显示与风格/规格；未显示不声称视觉通过 |
| [review-audio](../../../../../project-source/skills/review-audio/SKILL.md) | 独立审核声音效果 | 核对实际音频与场景播放；无听取证据不声称听觉通过 |
| [review-assets](../../../../../project-source/skills/review-assets/SKILL.md) | 独立审核资源技术条件 | 检查文件、引用、导入与来源记录；不接入或整理资源 |
| [review-localization](../../../../../project-source/skills/review-localization/SKILL.md) | 独立审核本地化 | 检查覆盖、含义、术语和呈现；不修改翻译 |
| [review-balance](../../../../../project-source/skills/review-balance/SKILL.md) | 独立审核规则与数值组合 | 核对策略与节奏目标，说明模型/证据限制；不调参或代替玩家验收 |

项目规则与 [方法总览](../../../../../project-source/methodology/00-overview.md) 负责完整路由。不要因用户问“当前进度”就执行环境探测或测试；也不要把明确实现请求降级成只提供下一步建议。

Skill 保留本职操作步骤和独有工具用法，阶段流程、字段契约与语言规则分别引用对应权威规范。按任务读取相关章节，沿用仍有效的上下文；局部需求先从 Product 总览定位受影响模块和共享约定，再按实际依赖展开。工程规则由模块 README 按主题路由，例如单元测试不会自动要求读取场景测试和输入测试专题。

## 调研角色与外部搜索 Skill

[researcher.toml](../../../../../project-source/agents/researcher.toml) 随项目复制到 `.codex/agents/`，定义调研方法、报告内容与默认保存位置。主 Agent 自主选择直接查询或委派；按需保存到 `docs/research/`，不增加 research Skill 或固定阶段。详细用法见 [搜索与调研](../guides/project-knowledge.md#按需搜索与保存调研)。

anysearch 是用户级搜索 Skill，不包含在上述 27 项中，也不随创建器复制。researcher 优先使用当前可用安装，不可用时自主回退其他搜索方式。客户端未提供角色选择能力时，由可用实例读取对应角色指令执行并说明实际方式，不声称配置已自动加载。

## Skill 未被自动识别时

专业内容、制作占位与独立审核的协作见 [专业工作指南](../guides/specialist-workflows.md)。 所有审核方法由独立实例按需选用，不默认逐项执行；角色源文件为 [independent-reviewer.toml](../../../../../project-source/agents/independent-reviewer.toml)， 复制到项目 `.codex/agents/`。实际加载、上下文和权限需核实，不能由文件存在推定。

先核对当前工作目录、项目 `.agents/skills/` 和目标 `SKILL.md` 是否存在，再核对所用 Agent 对项目 Skill 的加载方式。不要直接以“未自动出现”推断源文件丢失，也不要先改流程或生成替代 Skill。

这份手册不承诺所有 Agent 客户端都以相同方式自动加载 Skill；目标项目的实际文件与当前客户端行为需要分别确认。
