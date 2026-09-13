# Skill 与提示词导航

[返回手册](../README.md) · 相关：[需求与规划](../guides/product-and-planning.md)、[工程变更](../guides/engineering-changes.md)

当前空白项目包含 12 项 Skill，复制后位于 `.agents/skills/`。它们提供任务方法；项目文件保存长期知识，显式脚本完成必要检查。

## 12 项 Skill 的职责

下表链接的是框架中的源文件。正式开发时读取目标项目 `.agents/skills/<name>/SKILL.md`，因为生成后的副本可能已经独立修改。

| Skill | 适合的任务 | 主要产物与边界 |
| --- | --- | --- |
| [project-clarifier](../../../../project-source/skills/project-clarifier/SKILL.md) | 讨论想法、设计取舍与领域概念 | 小步澄清；只讨论不写文件，获授权的术语交给现有写入入口 |
| [product-change-standardizer](../../../../project-source/skills/product-change-standardizer/SKILL.md) | 初始化、补充或改变 Product 意图；维护已确认术语 | 统一写入 Product 与 CONTEXT，处理对已有任务的影响；初次拆分只针对当前 Product |
| [product-init-elicitor](../../../../project-source/skills/product-init-elicitor/SKILL.md) | Product 为空，梳理游戏蓝图 | 结构化草案；自身不写 Product 文件 |
| [product-spec-elicitor](../../../../project-source/skills/product-spec-elicitor/SKILL.md) | 模块、行为修改或跨模块需求存在重要歧义 | 返回规格补丁；自身不写文件 |
| [product-ui-sketcher](../../../../project-source/skills/product-ui-sketcher/SKILL.md) | 界面与交互表达 | ASCII 线框和意图；可选 HTML/Tailwind 探索，不直接完成 Godot UI |
| [product-audio-sketcher](../../../../project-source/skills/product-audio-sketcher/SKILL.md) | 音效、音乐与触发要求 | Product 音频条目和 `_placeholder_` 文件名，不生成正式音频 |
| [generate-feature-list](../../../../project-source/skills/generate-feature-list/SKILL.md) | 初次拆分当前 Product，包括第一份和后续 Product | 当前 Product 的 Feature 与必要测试关系追加到同一台账；前一 Product 的 Feature 完成后再拆下一份，保留历史 |
| [sync-feature-list](../../../../project-source/skills/sync-feature-list/SKILL.md) | 需求或 Coding Rules 改变后增量对齐 | 分析 Git 来源差异，保存任务迁移、依赖与测试影响 |
| [engineering-change-standardizer](../../../../project-source/skills/engineering-change-standardizer/SKILL.md) | Bug、重构或工程维护 | 分类和诊断，提出并写入获批工程 Feature；执行交给对应 Skill |
| [execute-next-feature](../../../../project-source/skills/execute-next-feature/SKILL.md) | 开始或继续一个确定的 Feature | 实现、测试、适用验收、复审、完成记录、本地提交与交接 |
| [pick-refactor-smell](../../../../project-source/skills/pick-refactor-smell/SKILL.md) | 从已有记录中挑选重构候选 | 只读比较与推荐，返回工程标准化入口 |
| [yaya-next-step-advisor](../../../../project-source/skills/yaya-next-step-advisor/SKILL.md) | 理解现状、不知道下一步怎么说 | 只读现状并撰写适合现有流程的提示词；不运行检查或授予批准 |

项目规则与 [方法总览](../../../../project-source/methodology/00-overview.md) 负责完整路由。不要因用户问“当前进度”就执行环境探测或测试；也不要把明确实现请求降级成只提供下一步建议。

## 常见组合

- 先想清楚：project-clarifier → 对话结论；有术语落盘授权时交给 standardizer，按需更新 CONTEXT 或局部定义。
- 新游戏：Product standardizer → 按需 init/spec/UI/audio → 只拆当前 Product → 完成它的 Feature → 复核并按授权拆下一 Product。
- 改需求：Product standardizer → 同步对已有任务的影响；仅后续未拆分 Product 的变化先留在需求文档中。
- 修独立 Bug：工程 standardizer 的 bug 模式 → execute → 回归、适用验收与经验。
- 选择重构：pick-refactor-smell → 工程 standardizer 的 refactor 模式 → execute。
- 当前任务中断：读取 Progress 和原任务 → execute 从真实阶段继续。
- 只读调查：按明确问题读取资料并报告；调查本身不自动进入实现。

这些组合用于理解职责，不要求每个任务机械调用所有 Skill。当前用户明确范围和已有具体授权优先，重要未决问题仍需解决。

## 从哪里取得操作提示词

所有可供用户发送给 Agent 的正式操作提示词都在 [framework/prompts.json](../../../prompts.json)。顶层包含“Yaya 框架维护”和“Godot 项目开发”两个 Project，保留 `project`、`categories` 结构；分类下的叶子键是提示词名，字符串值是完整正文。

使用时选择当前任务对应的一条，有 `${1:说明}` 等占位内容时先填写，再在正确目录发送；压缩包审核入口随附件发送。以下列出查找位置，不复制正文。

| 使用场景 | Project → 分类 → 提示词名称 |
| --- | --- |
| 创建输出目录 | Godot 项目开发 → 项目初始化 → 创建空白项目 |
| 保留成果并复制迁移旧项目 | Godot 项目开发 → 项目初始化 → 复制并迁移旧框架项目 |
| 确认工具路径与环境 | Godot 项目开发 → 项目初始化 → 准备 Godot 开发环境 |
| 先讨论，不写文档 | Godot 项目开发 → 需求设计 → 轻量讨论与澄清 |
| 澄清并保留术语定义 | Godot 项目开发 → 需求设计 → 澄清并记录项目术语 |
| 测试一个想法 | Godot 项目开发 → 需求设计 → 验证玩法或技术假设 |
| 开始需求梳理 | Godot 项目开发 → 需求设计 → 从游戏想法整理初始 Product |
| 改变玩法 | Godot 项目开发 → 需求设计 → 新增功能或调整已有规则 |
| 设计界面 | Godot 项目开发 → 需求设计 → 设计界面与交互 |
| 设计声音 | Godot 项目开发 → 需求设计 → 设计音效与音乐需求 |
| 拆分第一份或后续当前 Product | Godot 项目开发 → 任务规划 → 拆分当前 Product 的 Feature |
| 增量同步 | Godot 项目开发 → 任务规划 → 需求变化后同步已有任务 |
| 了解现状 | Godot 项目开发 → 日常开发 → 判断当前状态与下一步 |
| 开发任务 | Godot 项目开发 → 日常开发 → 执行指定或下一项 Feature |
| 恢复工作 | Godot 项目开发 → 日常开发 → 继续中断的当前任务 |
| 架构调查 | Godot 项目开发 → 修复与改进 → 只读调查架构改进机会 |
| 缺陷修复 | Godot 项目开发 → 修复与改进 → 定位与修复 Bug |
| 重构 | Godot 项目开发 → 修复与改进 → 行为保持的重构 |
| 工程维护 | Godot 项目开发 → 修复与改进 → 工程维护与工具调整 |
| 素材处理 | Godot 项目开发 → 资源、性能与数据 → 接入或替换游戏资源 |
| 性能工作 | Godot 项目开发 → 资源、性能与数据 → 定位并优化性能 |
| 数据迁移 | Godot 项目开发 → 资源、性能与数据 → 调整存档或迁移项目数据 |
| 补充验证 | Godot 项目开发 → 验证与收尾 → 单独验证某次变更 |
| 单独复审 | Godot 项目开发 → 验证与收尾 → 独立审查指定修改 |
| 人工反馈 | Godot 项目开发 → 验证与收尾 → 整理人工验收与反馈 |
| 进度整理与新线程交接 | Godot 项目开发 → 验证与收尾 → 整理进度与任务交接 |
| 总结可复用经验 | Godot 项目开发 → 经验沉淀 → 阶段性总结与复用脚本沉淀 |

创建空白项目的提示词针对框架目录执行复制；[旧项目迁移](../getting-started/migrate-existing-project.md)只读原项目与框架、仅写独立目标；其他项目开发提示词针对目标游戏项目。不要因为 Project 分类名称相同就把命令执行在同一个目录。

框架维护提示词位于“Yaya 框架维护”的“设计与借鉴”“维护与复盘”分类，覆盖新增、外部设计借鉴、修复删减、复盘、压缩包审核、动态全流程审核、外部结果复核、按需验证和交接。正文要求先读根规则、手册入口与 [维护说明](../maintenance/updating-the-blank-project.md#通过提示词开始维护)，再查阅受影响专题；实施后同步对应说明，只读任务核对并报告差异。

需要整体检查框架与空白项目时，选“Yaya 框架维护 → 维护与复盘 → 复盘框架设计与场景”。它默认输出详细静态审查报告，也接受局部范围与历史对照；报告文件输出和实际运行的边界见 [整体重检与详细报告](../maintenance/updating-the-blank-project.md#整体重检与详细报告)。

将 `Game_idle_yaya_frame.zip` 交给其他模型时，选“Yaya 框架维护 → 维护与复盘 → 审核框架压缩包并输出报告”。该正文可直接随附件发送，要求基于包内可读材料按明确格式输出独立报告；用法见 [压缩包审核说明](../maintenance/updating-the-blank-project.md#把压缩包交给其他模型审核)。

需要用真实任务走通流程时，选“Yaya 框架维护 → 维护与复盘 → 通过实际任务动态审核框架流程”。该入口在指定的新建外部项目创建一个小 Product、拆一个 Feature 并完成适用 Stage；所需环境、实际执行授权和报告边界见 [动态流程审核说明](../maintenance/updating-the-blank-project.md#用一个实际任务动态审核流程)。

收到外部审核意见时，选“Yaya 框架维护 → 维护与复盘 → 复核外部审核结果并讨论取舍”。先核对问题与建议各自的合理性，列出保留、拒绝、必要修改和待讨论项；报告本身不授权实施，详见 [外部结果复核说明](../maintenance/updating-the-blank-project.md#复核外部审核结果与讨论取舍)。

框架任务换线程时，选“Yaya 框架维护 → 维护与复盘 → 生成新线程交接提示词”；项目任务选上表的“整理进度与任务交接”。两者均在原线程生成可直接复制的完整续接指令，操作说明见 [换到新线程继续](../guides/project-knowledge.md#换到新线程继续)。

提示词库不复制到新项目；使用者可以从这里取出正文在目标项目使用，项目本身不需要连接框架。手册中的名称是导航，授权细节以当前 JSON 正文和用户实际请求为准。

## Skill 未被自动识别时

先核对当前工作目录、项目 `.agents/skills/` 和目标 `SKILL.md` 是否存在，再核对所用 Agent 对项目 Skill 的加载方式。不要直接以“未自动出现”推断源文件丢失，也不要先改流程或生成替代 Skill。

这份手册不承诺所有 Agent 客户端都以相同方式自动加载 Skill；目标项目的实际文件与当前客户端行为需要分别确认。
