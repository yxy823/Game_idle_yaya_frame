# 框架文档入口

本页统一导航操作手册、场景速查手册、关系图和框架维护说明。

| 需要什么 | 入口 |
| --- | --- |
| 理解框架、游戏逻辑与表现、项目对象、配置和工具用法 | [操作手册](operation-manual/README.md) |
| 根据当前情况找到具体处理步骤和同名提示词 | [场景速查索引](../prompt-scenarios/scenarios/scenario-index.md) |
| 查看框架与游戏项目的文档职责、导航、来源和证据关系 | [文档关系图说明](relationship-maps/README.md#文档系统关系图) · [图 JSON](relationship-maps/document-system.readable.json) |
| 查看游戏项目开发场景之间的衔接关系 | [开发场景图说明](relationship-maps/README.md#游戏项目开发场景图) · [图 JSON](relationship-maps/game-development-workflow.readable.json) |
| 编写或修改单一场景 | [场景手册编写要求](../prompt-scenarios/scenarios/README.md) |
| 修改框架、同步说明或选择验证 | [框架维护](framework-maintenance/README.md) |
| 确认框架专用术语的含义和统一写法 | [术语](terminology.md) |

## 两本手册的分工

两本手册独立阅读、不互相引用，直接维护 Markdown。目录位置见[框架维护入口](../README.md#目录与职责)。

- **操作手册**：按对象与契约组织，分四个专题目录。
  - `foundations/`：项目边界、游戏逻辑与表现、目录与配置。
  - `requirements-and-tasks/`：需求与规划、阶段语义。
  - `methods-and-tools/`：Skill/Agent、命令与证据、错误含义。
  - `specialist-work-and-records/`：专业来源、资源工作台、知识记录。
- **场景速查手册**：与提示词同放在 `framework/prompt-scenarios/`，按“要处理什么事情”分组。
  - 场景名称：写清当前状态，方便从目录选择。
  - 单篇范围：一个目标，对应一条同名专用提示词；目录与文件名直接使用提示词库中的 Project、分类和提示词名称。
  - 信息栏目：保留 11 类分类规则，只展示有内容的栏目。编写要求见[场景手册编写要求](../prompt-scenarios/scenarios/README.md)。

## 使用范围

框架的适用范围按以下几类区分：

- **使用方式**：一位使用者与 Agent 配合开发，不包括多人协作或改动归属处理；worktree 使用按具体任务需要与授权判断，不作为通用前置。
- **任务续接**：支持同一目录中的暂停、切换与新对话恢复；按需调研与独立审核仍可使用。
- **素材工作**：覆盖准备要求、接收和检查；视觉美术、音乐与音效制作保持待扩展边界。

项目手册中的 docs/、tools/ 等相对生成后的游戏项目根目录；维护文档的框架路径相对本仓库。示例 ID、路径和输出必须换成实际对象，不能当作已经完成的验证或批准。

框架保存创建器、复制材料、手册与两份独立提示词库；生成项目独立维护自己的文件，advisor 通过固定绝对路径只读查询本机 Godot 开发提示词库。本目录不进入 [复制清单](../commands/project-files.json)，也不承担项目升级或自动同步。权威行为由项目自身规则、methodology、Skill 和实际工具定义，手册解释它们，不另建流程。

临时文档与当次报告保存在仓库根目录的 `tmp/`，保存与清理见[当次报告的保存与清理](framework-maintenance/responsibility-design-guidelines.md#当次报告的保存与清理)。
