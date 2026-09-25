# 操作手册

本册解释框架、概念、配置、职责和工具用法。按需要查阅专题，不要求按目录顺序执行；具体场景的处理步骤不在本册重复。两本手册独立阅读，整体选择由框架文档总入口提供。

| 查阅主题 | 内容 |
| --- | --- |
| [框架、创建器与项目边界](framework-and-project.md) | 分发、创建器参数、副作用、环境就绪和已有项目的独立性 |
| [项目对象与目录](project-layout.md) | Product、Feature、Registry、证据、代码与报告的职责及读写关系 |
| [需求、Feature 与规划基线](requirements-and-planning.md) | 模块身份、AC、当前模块覆盖、依赖、基线与历史演进 |
| [任务类型、开发阶段与完成语义](feature-lifecycle.md) | Bug/重构/维护/实验、Stage、授权、自动/人工验收、Git 和 Goal |
| [配置参考](configuration.md) | 工具路径、文档语言、Godot、插件、lint 和文本约定 |
| [Skill、Agent 与提示词](skills-and-agents.md) | 方法职责、角色、集中提示词与 advisor 表达参考 |
| [命令与验证证据](commands-and-evidence.md) | 命令参数、测试范围、报告、完成记录、指纹及退出码 |
| [错误与结果的含义](errors-and-results.md) | 环境、台账、运行和证据输出的解释边界 |
| [专业来源与资源](specialist-work.md) | 来源所有者、素材准备、原型、接入、测量与独立审核 |
| [资源工作台](asset-workbench.md) | 查看、试听、分析、A/B、组合、保存与消费工具用法 |
| [知识、设计与记录](knowledge-and-records.md) | 术语、设计、架构、ADR、规则、调研、知识、报告与续接信息 |

项目路径均相对生成后的游戏项目根目录，示例 ID、路径与结果必须换成真实对象。文件存在、工具成功、实际运行与人工接受分别表述，手册不提供已运行的证据。

框架只面向单人 Godot 项目，支持同目录暂停、切换和新对话续接。生成项目独立拥有自身文件；本册、完整提示词库和维护文档不复制给项目，也不建立自动同步。

行为依据为项目自身的 [AGENTS 源](../../../project-source/Project_AGENTS.md)、[方法总览](../../../project-source/methodology/00-overview.md)、[Skills](../../../project-source/skills/) 和 [工具](../../../project-source/tools/README.md)。本册解释现行契约，不能通过文字重排改写授权、状态或验证要求。
