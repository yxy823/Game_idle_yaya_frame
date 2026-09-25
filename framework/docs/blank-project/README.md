# Godot 项目文档入口与重构目录

本目录面向使用框架开发游戏的使用者。内容分为操作手册和场景速查手册；框架维护说明独立放在[维护文档目录](../framework-maintenance/README.md)。

当前完成首轮目录设计和八篇 Markdown 样稿。先讨论样稿的粒度与写法，再拆分、迁移其余正文。原有专题仍在原路径，作为待迁移材料保留，不表示整套重构已经完成。

## 从哪里进入

| 目的 | 入口与当前状态 |
| --- | --- |
| 根据实际情况找操作路径 | [场景速查索引](quick-reference/scenario-index.md)，八篇样稿已成稿 |
| 编写或修改场景 | [场景手册编写 README](quick-reference/README.md) |
| 查框架、概念、配置与工具用法 | 操作手册待重组，当前资料见[原材料与目标归属](#原材料与目标归属) |
| 修改框架本身或查验证边界 | [框架维护文档](../framework-maintenance/README.md) |

两本手册各自承担完整职责，正文不互相引用。这个总入口只负责导航与重构范围，不复制各场景的操作步骤。当前不提供 HTML 阅读版；保留的构建工具在 Markdown 结构确定后再适配。

## 整体目标目录

以下是全量重构的目录草案，未成稿部分不创建空文件。英文目录名表达职责，页面标题采用中文日常表达。

```text
framework/docs/
├─ blank-project/
│  ├─ README.md                         总入口
│  ├─ operation-manual/                 后续重组
│  │  ├─ README.md                      阅读入口
│  │  ├─ concepts/                      框架边界、任务与生命周期
│  │  ├─ project-structure/             文件、资料和职责归属
│  │  ├─ configuration/                 环境与配置字段
│  │  └─ tools/                         创建器、Skill 入口、验证与资源工具
│  └─ quick-reference/
│     ├─ README.md                      编写要求
│     ├─ scenario-index.md              按事项与状态查阅
│     ├─ project-setup/                 创建与接手
│     ├─ requirements/                  需求与计划
│     ├─ interface-assets/              界面与资源接入
│     ├─ issues/                        问题修复
│     ├─ engineering/                   工程调整、调查与审核
│     ├─ verification/                  测试、验收与交付
│     ├─ resumption/                    中断与续接
│     └─ project-knowledge/             资料与知识维护
└─ framework-maintenance/
   ├─ README.md                         维护者入口
   ├─ updating-the-blank-project.md      修改、文档同步与反馈复核
   └─ validating-framework.md            复制、工具与真实项目验证
```

场景目录按“要处理的事情 → 当前状态 → 具体场景”展开。八篇样稿已经在各事项目录的状态子目录中组织；其他目录在实际迁移内容时创建。每篇只展开一个目标的正常处理路径，11 类信息只展示有内容的栏目。

## 原材料与目标归属

迁移按段落用途拆分，不把原文件整篇机械搬入某一本手册。同一主题的概念与工具说明进入操作手册，所有具体情境处理进入速查手册。原检查单与八篇样稿中同用途的正文最终只保留一份。

| 原材料 | 后续处理 |
| --- | --- |
| [创建项目](getting-started/create-project.md)、[首次使用](getting-started/first-use.md)、[旧项目迁移](getting-started/migrate-existing-project.md) | 创建器和配置说明归操作手册；创建、初始化、迁移分别成为具体场景 |
| [需求与规划](guides/product-and-planning.md) | 需求对象与计划关系归概念；整理来源、首次/后续规划、接管已有实现分别拆场景 |
| [Feature 开发与交付](guides/feature-delivery.md) | 生命周期与状态语义归概念；实现、验收、拒绝处理、完成与交接分别拆场景 |
| [工程变更](guides/engineering-changes.md) | 工程任务分类归概念；Bug、重构、维护、实验及一致性核对按入口状态拆分 |
| [专业工作](guides/specialist-workflows.md)、[资源工作台](guides/asset-workbench.md) | 专业职责和工具用法归操作手册；设计、素材准备、接入、测量、审核及工作台应用归场景 |
| [项目知识与交接](guides/project-knowledge.md) | 资料归属归操作手册；调研、术语、规则、经验与续接等操作归场景 |
| [原检查单索引](guides/scenario-procedures.md)及四篇分组检查单 | 全部迁入速查手册；与样稿合并，按状态拆分，不保留第二套正文 |
| [目录参考](reference/project-layout.md)、[Skill 参考](reference/skills.md)、[配置参考](reference/configuration.md) | 保留准确参考信息；其中具体维护或项目场景按读者和用途迁出 |
| [命令与验证](reference/commands-and-validation.md)、[故障排查](reference/troubleshooting.md) | 参数、输入输出和错误含义归工具说明；从现象出发的恢复操作归场景 |

原检查单覆盖的需求变化、插入模块、设计边界、共享修改、界面、声音、资源替换、Bug、验证失败、交付、人工拒绝、中断、恢复及文档一致性均在全量迁移范围内。首轮八篇不代表这些范围已经全部完成。

## 首轮样稿怎样讨论

先对照“交付前发现 Bug”和“交付后发现 Bug”，检查是否能从目录和前置条件选对入口。再看“测试通过但导入失败”，检查正文是否仍包含无关的环境或业务修复。

其余样稿分别检验首次规划、未开工计划变更、界面原型、已备音效接入和新对话续接。重点反馈场景是否仍过宽、第一步是否明确、步骤与产出是否容易对照、出口是否能客观核实。具体页面从[场景索引](quick-reference/scenario-index.md)进入。

## 使用约定与内容依据

项目场景中的 docs/、tools/ 等路径相对生成后的游戏项目根目录；维护文档中的框架路径相对本仓库。示例 ID、路径和结果均须替换为实际对象，不能当作已经运行或验证的证据。

框架维护仓库保存创建器、复制材料、文档和完整提示词库；project-source/ 是未初始化的可复制源材料；生成项目独立拥有自己的文件。两本手册和维护文档都不进入生成项目，也不承担自动同步职责。

权威行为以项目自身的规则、methodology、Skill 与实际工具为准。文档解释现有行为，不通过重排章节改变授权、任务状态、验证或提交规则。提示词正文集中维护在 [framework/prompts.json](../../prompts.json)，只引用其名称和所需输入。

来源：[项目规则](../../../project-source/Project_AGENTS.md)、[方法总览](../../../project-source/methodology/00-overview.md)、[项目工具](../../../project-source/tools/README.md)、[复制清单](../../project-files.json)。
