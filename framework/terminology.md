# 框架与 Godot 项目术语

本页只收录 Yaya 框架特有、或在本框架中有特定含义的术语，两本手册共用这一份。通用开发常识、Godot 基础概念和一看就懂的名称不收录；操作要求和完成规则由所属规范维护。

游戏自身的业务术语不放这里，固定保存在生成项目的 `docs/terminology.md`，由 `project-terminology` 维护。

## 框架对象

| 术语 | 含义与边界 |
| --- | --- |
| 分发源 / `project-source/` | 创建器按复制清单复制到新游戏项目的源材料；在维护仓库中只作为源材料阅读，不启动其中的开发流程 |
| 复制清单 | `framework/project-creation/project-files.json`；只决定创建时复制什么、复制到哪里，不承担升级或已有项目的同步 |
| 生成项目 / 游戏项目 | 创建后独立拥有代码、配置、规则和记录的 Godot 项目，不再依赖框架仓库 |
| Project | 提示词 JSON 的顶层名称，只有「Yaya 框架维护」和「Godot 项目开发」两个；与 Product、Feature 无关 |
| Godot 项目手册 | `framework/godot-project-manual/`，按对象解释生成项目里的概念、文档、配置与工具；简称“手册” |
| 场景速查手册 | `framework/prompt-scenarios/scenarios/`，按“遇到什么情况”给出处理步骤，每篇对应一条同名提示词；单篇称“场景页” |

## 设计与交付

| 术语 | 含义与边界 |
| --- | --- |
| GDD | 游戏设计正文，固定在 `docs/gdd/`；规划和实现依赖的设计必须先在这里真实存在 |
| Product | 依据 GDD 划定的可验收交付单元，可以是一个系统、系统的一部分或跨系统体验；只写交付范围，不重复游戏规则 |
| Product 总览 | `docs/product.md`，保存预拆分结果：交付范围、来源、依赖与建议顺序；不等于 GDD 的游戏总览 |
| 预拆分 | 在 Product 总览中粗分全部约定交付范围；轮到某个 Product 时才细化其正文并拆 Feature |
| Feature | 有范围、验收条件和状态的开发任务；Bug、重构和工程维护也可以按规范建为 Feature |
| Stage | Feature 执行规范里的阶段编号，用于定位进度；不是逐阶段审批或自动状态机 |

来源：[需求与交付结构](../project-source/methodology/01-product-doc-structure.md)、[Feature 结构](../project-source/methodology/02-feature-list-schema.md)、[执行规范](../project-source/methodology/03-execute-loop.md)。

## 游戏职责

| 术语 | 含义与边界 |
| --- | --- |
| 游戏逻辑 / 游戏表现 | 理解一个功能时的两类职责：逻辑负责规则、状态与有效结果，表现负责界面、动画、特效、声音和镜头等玩家感知。用于找到对应的文档和实现，不是必须拆开的任务类型 |
| 游戏表现文档 | `docs/presentation/` 中描述一次具体表现的文档：过程、要求、候选方案、采用关系及实现与验收入口 |

来源：[游戏组织指南](../project-source/defaults/docs/game-organization.md)、[专业来源约定](../project-source/methodology/11-specialist-workflows.md)。

## 验证记录

| 术语 | 含义与边界 |
| --- | --- |
| Registry / 测试登记表 | `docs/test-registry.json`，登记测试身份、组件、实现位置和生命周期；登记不等于执行通过 |
| 完成检查 | 任务正式完成前的整体核对；统一用这个词，不另称“交付检查”“收尾检查”，也不与一次人工验收混称 |
| 人工验收 | 用户按清单实际运行、观察并给出结果的过程；结果可能是 accepted、rejected 或 pending |
| 人工接受 | 人工验收的通过结果（accepted），是 manual 模式 Feature 完成的条件之一；实现授权、自动测试通过或用户未表态都不算接受 |
| 完成记录 / 完成依据 | `docs/feature-completion-evidence.json`，引用实际验证原件和接受结果；文件存在本身不证明条件满足 |
| 内容指纹 | 工具用来判断一条记录是否仍对应当前内容的标识；不是授权，也不是人工验收 |

来源：[测试策略](../project-source/methodology/08-testing-strategy.md)、[人工验收文件](../project-source/methodology/manual-acceptance-files.md)。

## 资源工作台

| 术语 | 含义与边界 |
| --- | --- |
| 工作台 | 编辑期查看、试听、比较和保存资源组合的工具；临时草稿与已保存的 Cue 分开 |
| Cue | 工作台保存的配置资源，记录所选素材与表现参数；不是素材本身 |
| 消费入口 | 运行时读取已保存 Cue 的场景或代码，区别于工作台的编辑入口 |
| Analyzer | 分析图像、音频源文件的工具；结果不代替实际渲染、听感或性能测量 |

来源：[工作台与消费示例](../project-source/asset_workbench/examples/README.md)。
