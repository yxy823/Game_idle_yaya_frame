# Godot 项目手册

本册解释用框架创建的 Godot 项目：项目与框架的边界、游戏逻辑与表现、项目文档、配置、Skill 与工具。它回答“这是什么、怎么用”；“遇到某种情况该怎么处理”在场景速查手册。两本手册独立阅读，由[框架入口](../README.md)统一导航。

## 第一次阅读

想先跟着一个真实项目走一遍，从教程开始：

1. [从空白项目到第一份 Feature 计划](tutorial/01-blank-project-to-feature-plan.md)：创建项目、配置环境、整合 GDD、拆分 Product、定美术方向、做第一份计划。
2. [完成第一个 Feature](tutorial/02-first-feature-to-done.md)：视觉样例、等待验收期间并行推进、记录验收与收尾。
3. [修正时过时不过的测试](tutorial/03-fix-a-flaky-test.md)：交付后用维护任务修正不稳定的测试。

想先理解概念，按这个顺序读参考页：

1. [框架、创建器与项目边界](foundations/framework-and-project.md)：项目从哪里来，创建后和框架是什么关系。
2. [游戏逻辑、表现与协作](foundations/game-logic-and-presentation.md)：用一次商店购买理解一个功能由哪些职责组成。
3. [项目对象与目录](foundations/project-layout.md)：每类文档和代码放在哪里、谁来读写。
4. [需求、Feature 与规划基线](requirements-and-tasks/requirements-and-planning.md)：从 GDD 到 Feature 的规划方式。

之后按需要查阅其余专题。

## 全部专题

- **教程**：以三消示例项目串起主线的三篇教程，见[第一次阅读](#第一次阅读)。
- **框架基础**
  - [框架、创建器与项目边界](foundations/framework-and-project.md)：分发方式、创建器用法、环境就绪的含义，以及已有项目怎样采用框架。
  - [游戏逻辑、表现与协作](foundations/game-logic-and-presentation.md)：逻辑与表现的职责划分，以及怎样从设计找到实现与验收。
  - [项目对象与目录](foundations/project-layout.md)：GDD、Product、Feature、测试登记表、完成记录、代码与报告的位置和读写关系。
  - [配置参考](foundations/configuration.md)：工具路径、文档语言、Godot 默认配置、插件、lint 与文本格式。
- **需求与任务**
  - [需求、Feature 与规划基线](requirements-and-tasks/requirements-and-planning.md)：GDD 前提、交付预拆分、逐个细化 Product、AC、依赖、基线与需求修订。
  - [任务类型、开发阶段与完成语义](requirements-and-tasks/feature-lifecycle.md)：Bug、重构、维护与实验的区别，Stage、自动与人工验收、Git 和持续任务。
- **方法与工具**
  - [Skill、Agent 与提示词](methods-and-tools/skills-and-agents.md)：每个 Skill 的职责、专用角色、集中提示词与 advisor。
  - [命令与验证证据](methods-and-tools/commands-and-evidence.md)：每种结果能证明什么，命令参数、测试范围、运行报告、完成记录与内容指纹。
  - [错误与结果的含义](methods-and-tools/errors-and-results.md)：按现象查工具输出的含义和处理办法。
- **专业工作与记录**
  - [专业来源与资源](specialist-work-and-records/specialist-work.md)：各类专业规格的维护者、资源规格、画面演示台、接入、测量与独立审核。
  - [知识、设计与记录](specialist-work-and-records/knowledge-and-records.md)：术语、Feature 设计稿、架构、ADR、规则、调研、知识、报告与续接信息放在哪里。
- **公共参考**
  - [框架与 Godot 项目术语](../terminology.md)：框架特有或有特定含义的术语。游戏自身的业务词汇由项目自己维护。

## 阅读约定

- **路径**：本册中的 `docs/`、`yaya/tools/` 等路径都相对生成后的游戏项目根目录。示例里的 ID、路径和输出只是示意，使用时换成实际对象。
- **证据**：手册只解释工具和契约，不提供任何已运行的证据。各种结果分别能证明什么，见[命令与验证证据](methods-and-tools/commands-and-evidence.md#每种结果能证明什么)。
- **适用范围**：见[框架入口的使用范围](../README.md#使用范围)。
- **权威来源**：行为以项目自身的 [AGENTS 源](../../project-source/Project_AGENTS.md)、[方法总览](../../project-source/methodology/00-overview.md)、[Skill](../../project-source/skills/) 和[工具说明](../../project-source/tools/README.md)为准。本册与它们不一致时，以它们为准并修正本册。
- **分发**：本册、完整提示词库和维护文档都不复制到生成项目，也不与项目同步。
