# 框架与 Godot 项目术语

本页只收录 Yaya 框架特有的对象与约定，或在本框架中具有特定含义和职责边界的术语。通用开发常识、日常动作、普通状态与修饰词、Godot 基础概念不收录；操作要求和完成规则由所属规范维护。

- **本页**：保存框架专用术语，由框架维护者更新，两本手册共用这一份正文。
- **游戏项目的 `docs/terminology.md`**：该游戏已确认业务名称、定义、关系与别名的固定唯一正文，由 `project-terminology` 维护；GDD 及其他文档引用，玩法数值和完整行为仍归 GDD。

## 框架对象

| 术语 | 本框架中的含义与边界 |
| --- | --- |
| 分发源 / `project-source/` | 创建器按清单复制到新游戏项目的源材料 |
| 复制清单 | `framework/commands/project/project-files.json` 中的选择与重命名规则；不承担升级或已有项目自动同步 |
| 创建器 | 根据复制清单创建独立项目及其本地 Git 初始提交的命令 |
| 生成项目 / 游戏项目 | 创建后独立拥有代码、配置、规则和记录的 Godot 项目 |
| Project | 提示词 JSON 中区分“Yaya 框架维护”和“Godot 项目开发”的顶层名称；不等于 Product 或 Feature |

来源：[维护约定](../../AGENTS.md)、[创建器与维护命令](../commands/README.md)、[复制清单](../commands/project/project-files.json)。

## 设计与交付

| 术语 | 本框架中的含义与边界 |
| --- | --- |
| GDD | Game Design Document，游戏设计正文；在 `docs/gdd/` 持续维护定位、体验与反馈目标、核心循环、系统规则、内容与版本设计范围，是项目开发前提 |
| Product | 依据 GDD 划定的可验收交付单元，可覆盖一个系统、其中一部分或跨系统体验；不重复定义游戏规则 |
| Product 总览 | `docs/product.md` 中的交付预拆分、来源、边界、依赖与建议顺序；不等于 GDD 游戏总览 |
| Feature | 具有范围、验收条件和状态的开发任务；工程 Bug、重构和维护也可按规范建为 Feature |
| Stage | Feature 执行规范中的阶段定位，不是新增的逐阶段审批或自动状态机 |
| 预拆分 | 在 Product 总览中安排约定交付范围、粗略边界、来源与依赖；不提前生成后续 Product 正文或 Feature |
| 当前 Product 细化 | 轮到该交付单元时，依据最新 GDD 和已完成工作确定本次交付边界与衔接 |

来源：[需求与交付结构](../../project-source/methodology/01-product-doc-structure.md)、[Feature 结构](../../project-source/methodology/02-feature-list-schema.md)、[执行规范](../../project-source/methodology/03-execute-loop.md)。

## 游戏职责

| 术语 | 本框架中的含义与边界 |
| --- | --- |
| 游戏逻辑层 | 负责游戏规则、业务状态与有效结果；可使用真实 Godot 能力，不要求所有逻辑脱离引擎 |
| 游戏表现层 | 负责玩家感知与交互反馈，包括界面、动画、特效、声音和镜头；可以维护显示过渡等自身状态 |
| 游戏表现文档 | 记录一次具体表现的过程、标准要求、候选方案、采用关系及实现与验收入口；不等于表现层全部资料 |
| 跨层功能 | 同时涉及游戏逻辑、表现及双方接入的功能范围；不新增任务类型、阶段或强制拆分方式 |

来源：[游戏组织指南](../../project-source/defaults/docs/game-organization.md)、[架构规范](../../project-source/methodology/10-architecture-overview.md)、[专业来源约定](../../project-source/methodology/11-specialist-workflows.md)。两层用于理解游戏职责；工具、环境、测试与构建仍按共同工程支持说明。

## 验证记录

| 术语 | 本框架中的含义与边界 |
| --- | --- |
| Registry / 测试登记表 | `docs/test-registry.json` 中的组件、测试身份、套件与生命周期记录；登记不等于执行通过 |
| 完成检查 | 所属任务正式完成前的整体核对；统一使用此词，不另称“交付检查”或“收尾检查”，也不与一次人工验收混称 |
| 完成记录 / 完成依据 | `docs/feature-completion-evidence.json` 中对实际验证原件和接受结果的引用及绑定；文件存在本身不证明条件满足 |
| 内容指纹 | 按工具契约判定记录所对应内容是否仍适用的标识；不是额外授权或人工验收 |

来源：[测试策略](../../project-source/methodology/08-testing-strategy.md)、[人工验收文件](../../project-source/methodology/manual-acceptance-files.md)、[验证政策](../../project-source/agent-rules/00-core/validation-policy.md)。

## 资源工作台

| 术语 | 在本项目资料中的使用方式 |
| --- | --- |
| Cue | 工作台及消费示例用于保存所选资源与表现参数的配置资源；不等于源素材本身 |
| 工作台 | 编辑期查看、试调、比较和保存资源组合的工具；临时草稿与已保存 Cue 分开 |
| Analyzer / 源资源分析器 | 对图像、音频源文件进行分析的工具；结果不替代渲染效果、听感或运行性能测量 |
| 消费入口 | 读取已保存 Cue 并在运行时使用它的场景或代码；区别于工作台编辑入口 |

来源：[工作台与消费示例](../../project-source/asset_workbench/examples/README.md)。
