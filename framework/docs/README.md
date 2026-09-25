# 框架文档入口

本目录按读者目的分成三个并列目录：了解框架与工具、处理具体场景、维护框架。两本项目手册的正文不互相引用；本页统一导航。

## 从哪里进入

| 目的 | 入口 |
| --- | --- |
| 查框架边界、概念、配置与工具职责 | [操作手册](operation-manual/README.md) |
| 根据当前情况找到具体处理步骤 | [场景速查索引](quick-reference/scenario-index.md) |
| 编写或修改场景页 | [场景手册编写要求](quick-reference/README.md) |
| 查维护准则、核对文档同步与验证范围 | [框架维护](framework-maintenance/README.md) |
| 拆分旧专题，核对尚待迁入的内容 | [迁移原材料](framework-maintenance/migration-source/README.md) |

当前操作手册提供概念、配置与工具入口，速查手册包含八篇样稿。旧专题集中留在迁移原材料目录；讨论样稿后再按段落用途完成全量拆分，不把原材料视为另一套正式手册。当前只交付 Markdown，HTML 构建工具保留，恢复时再适配新目录。

## 整体目录

以下对应实际目录，只在已有内容时创建子目录，不用空文件夹预留分类。

```text
framework/docs/
├─ README.md                          统一导航与迁移范围
├─ operation-manual/
│  └─ README.md                       框架、概念、配置和工具入口
├─ quick-reference/
│  ├─ README.md                       编写要求
│  ├─ scenario-index.md               读者入口
│  ├─ requirements/                   需求与计划
│  ├─ interface-assets/               界面与资源
│  ├─ issues/                         问题修复
│  ├─ verification/                   测试与交付
│  └─ resumption/                     中断与续接
└─ framework-maintenance/
   ├─ README.md                       维护入口
   ├─ updating-the-blank-project.md    修改与同步说明
   ├─ validating-framework.md         验证边界
   └─ migration-source/               待拆分原材料
      ├─ README.md                    原材料索引与处理约定
      ├─ getting-started/
      ├─ guides/
      └─ reference/
```

上图保留当前尚未迁移的样稿位置。已确认的目标结构为 `quick-reference/<Project>/<分类>/<提示词名称>.md`，三层名称直接取自集中提示词库；分类按事项组织，状态写入场景名称，不额外增加状态目录。项目开发与框架维护场景分别进入对应 Project 文件夹。每篇一个目标、对应一条同名专用提示词，11 类信息只显示有内容的栏目；规范与审核依据见[职责设计准则](../review/baselines/skill-script-prompt-design.md)。

## 原材料与目标归属

迁移按段落用途拆分，不把原文件整篇机械搬入某一本手册。同一主题的概念与工具说明进入操作手册，所有具体情境处理进入速查手册。原检查单与八篇样稿中同用途的正文最终只保留一份。

| 原材料 | 后续处理 |
| --- | --- |
| [创建项目](framework-maintenance/migration-source/getting-started/create-project.md)、[首次使用](framework-maintenance/migration-source/getting-started/first-use.md)、[旧项目迁移](framework-maintenance/migration-source/getting-started/migrate-existing-project.md) | 创建器和配置说明归操作手册；创建、初始化、迁移分别成为具体场景 |
| [需求与规划](framework-maintenance/migration-source/guides/product-and-planning.md) | 需求对象与计划关系归概念；整理来源、首次/后续规划、接管已有实现分别拆场景 |
| [Feature 开发与交付](framework-maintenance/migration-source/guides/feature-delivery.md) | 生命周期与状态语义归概念；实现、验收、拒绝处理、完成与交接分别拆场景 |
| [工程变更](framework-maintenance/migration-source/guides/engineering-changes.md) | 工程任务分类归概念；Bug、重构、维护、实验及一致性核对按入口状态拆分 |
| [专业工作](framework-maintenance/migration-source/guides/specialist-workflows.md)、[资源工作台](framework-maintenance/migration-source/guides/asset-workbench.md) | 专业职责和工具用法归操作手册；设计、素材准备、接入、测量、审核及工作台应用归场景 |
| [项目知识与交接](framework-maintenance/migration-source/guides/project-knowledge.md) | 资料归属归操作手册；调研、术语、规则、经验与续接等操作归场景 |
| [原检查单索引](framework-maintenance/migration-source/guides/scenario-procedures.md)及四篇分组检查单 | 全部迁入速查手册；与样稿合并，按状态拆分，不保留第二套正文 |
| [目录参考](framework-maintenance/migration-source/reference/project-layout.md)、[Skill 参考](framework-maintenance/migration-source/reference/skills.md)、[配置参考](framework-maintenance/migration-source/reference/configuration.md) | 保留准确参考信息；其中具体维护或项目场景按读者和用途迁出 |
| [命令与验证](framework-maintenance/migration-source/reference/commands-and-validation.md)、[故障排查](framework-maintenance/migration-source/reference/troubleshooting.md) | 参数、输入输出和错误含义归工具说明；从现象出发的恢复操作归场景 |

原检查单覆盖的需求变化、插入模块、设计边界、共享修改、界面、声音、资源替换、Bug、验证失败、交付、人工拒绝、中断、恢复及文档一致性均在全量迁移范围内。首轮八篇不代表这些范围已经全部完成。

## 首轮样稿怎样讨论

先对照“交付前发现 Bug”和“交付后发现 Bug”，检查是否能从目录和前置条件选对入口。再看“测试通过但导入失败”，检查正文是否仍包含无关的环境或业务修复。

其余样稿分别检验首次规划、未开工计划变更、界面原型、已备音效接入和新对话续接。重点反馈场景是否仍过宽、第一步是否明确、步骤与产出是否容易对照、出口是否能客观核实。具体页面从[场景索引](quick-reference/scenario-index.md)进入。

## 使用约定与内容依据

项目场景中的 docs/、tools/ 等路径相对生成后的游戏项目根目录；维护文档中的框架路径相对本仓库。示例 ID、路径和结果均须替换为实际对象，不能当作已经运行或验证的证据。

框架维护仓库保存创建器、复制材料、文档和完整提示词库；project-source/ 是未初始化的可复制源材料；生成项目独立拥有自己的文件。两本手册和维护文档都不进入生成项目，也不承担自动同步职责。

权威行为以项目自身的规则、methodology、Skill 与实际工具为准。文档解释现有行为，不通过重排章节改变授权、任务状态、验证或提交规则。提示词正文集中维护在 [framework/prompts.json](../prompts.json)，只引用其名称和所需输入。

来源：[项目规则](../../project-source/Project_AGENTS.md)、[方法总览](../../project-source/methodology/00-overview.md)、[项目工具](../../project-source/tools/README.md)、[复制清单](../project-files.json)。
