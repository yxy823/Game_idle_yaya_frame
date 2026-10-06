# 框架入口

`framework/` 保存维护这套 Godot 起始框架所需的全部材料：Godot 项目手册、场景速查手册与提示词、关系图、框架维护文档、创建器和各类检查工具。这些材料不复制到生成项目；框架自用 Skill 在仓库根目录的 `.agents/skills/`，维护约定以根 [AGENTS.md](../AGENTS.md) 为准。

## 框架做什么

这套框架用创建器生成一个 Godot 项目，项目里带好开发流程、Agent 规则、Skill 和检查工具。你用场景速查找到提示词交给 Agent，Agent 按下图的主线把想法一步步做成经过验收的功能。图中方框里是负责这一步的 Skill。

```mermaid
flowchart TD
    creator["创建器<br/>create_project.py"] --> project["生成的 Godot 项目<br/>AGENTS.md、yaya/、.agents/skills/、docs/"]
    you(["你：在场景速查中找到提示词"]) --> gdd
    project --> gdd
    subgraph loop["项目内的开发主线"]
        gdd["游戏设计与专业规格<br/>design-gdd 等"] --> product["划分交付单元 Product<br/>product-author"]
        product --> plan["拆成 Feature 计划<br/>feature-plan"]
        plan --> execute["执行一个 Feature<br/>feature-execute，Stage 0–8"]
        execute --> accept{"自动测试通过；<br/>需要人工验收时由你确认"}
        accept -->|通过| done["Feature 完成"]
        accept -->|不通过| execute
        done -->|下一个 Feature| execute
        gdd -.->|设计改了| sync["同步计划<br/>feature-sync"]
        sync -.-> plan
    end
```

这张图只画主线。不知道下一步该做什么时，项目里的 `project-next-step-advisor` 会根据当前状态给出建议。各文档和职责之间的完整关系见[文档系统关系图](relationship-maps/README.md#文档系统关系图)。

## 按需要找入口

| 需要什么 | 入口 |
| --- | --- |
| 理解生成的 Godot 项目：项目边界、游戏逻辑与表现、文档对象、配置、Skill 和工具用法 | [Godot 项目手册](godot-project-manual/README.md) |
| 根据当前情况找到具体处理步骤和同名提示词 | [场景速查索引](prompt-scenarios/scenarios/scenario-index.md) |
| 查看框架与游戏项目的文档职责、导航、来源和证据关系 | [文档系统关系图](relationship-maps/README.md#文档系统关系图) |
| 查看游戏项目开发场景之间的衔接关系 | [开发场景图](relationship-maps/README.md#游戏项目开发场景图) |
| 修改框架或分发材料，判断要同步哪些说明、选择哪种验证 | [框架维护](maintenance/README.md) |
| 新增或调整文档、Skill、脚本、提示词与场景的职责 | [职责设计准则](maintenance/design-guidelines/README.md) |
| 编写或修改单一场景 | [场景手册编写要求](prompt-scenarios/scenarios/README.md) |
| 编写或整理框架说明 | [Yaya 框架文档编写 Skill](../.agents/skills/technical-documentation-writing-yaya/SKILL.md) |
| 修改提示词、场景或关系图 | [提示词与关系图维护 Skill](../.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md) |
| 创建空白项目、运行检查或回归 | 下文[维护命令](#维护命令) |
| 确认框架专用术语的含义和统一写法 | [框架术语](terminology.md) |

## 目录与职责

本表是 `framework/` 的唯一目录说明；子目录 README 只说明自身内容，不再重画上层目录。顶层按材料讲述的对象划分：生成的 Godot 项目、提示词与场景、关系图、框架维护、项目创建和测试。

| 路径 | 职责 |
| --- | --- |
| [progress.md](progress.md) | 仍需推进的工作、验证缺口和必要决定；完成即删，历史查 Git |
| [terminology.md](terminology.md) | 框架与生成项目共用的术语写法 |
| [godot-project-manual/](godot-project-manual/README.md) | Godot 项目手册：生成项目的概念、文档对象、配置、Skill 与工具用法，按专题分四个子目录；`tutorial/` 是以三消示例串起主线的三篇教程 |
| [prompt-scenarios/](prompt-scenarios/scenarios/README.md) | `prompts/` 两份集中提示词库；`scenarios/` 每条提示词对应的同名场景页、场景索引与编写要求；`tools/` 提示词、场景与场景图的检查和链接脚本 |
| [relationship-maps/](relationship-maps/README.md) | 文档系统关系图、开发场景图、读图与维护说明、Graph_Map 文件格式；`tools/` 文档图覆盖检查脚本 |
| [maintenance/](maintenance/README.md) | 框架维护文档：维护与同步；`design-guidelines/` 职责设计准则；`validation/` 验证范围；`dependencies/` 第三方插件版本记录；`tools/` 全仓孤立文档扫描 |
| [project-creation/](project-creation/tools/README.md) | 唯一复制清单 `project-files.json`；`tools/` 创建器 |
| [tests/](tests/README.md) | `repository/` 从仓库根目录运行的维护回归；`external-project/` 需要指定外部项目的工具回归、Analyzer、插件与文档语言夹具，各子目录 README 说明放置与运行 |

两本手册独立阅读、不互相引用：Godot 项目手册讲“项目里的东西是什么、怎么用”，场景速查手册讲“现在遇到这种情况该怎么处理”。场景速查手册与提示词同放在 `prompt-scenarios/`，便于按名称一一对应；关系图同时服务两者，单独放在 `relationship-maps/`。

## 两本手册的分工

两本手册都直接维护 Markdown。

- **Godot 项目手册**：按对象与契约组织，分四个专题目录。
  - `foundations/`：项目边界、游戏逻辑与表现、目录与配置。
  - `requirements-and-tasks/`：需求与规划、阶段语义。
  - `methods-and-tools/`：Skill/Agent、命令与证据、错误含义。
  - `specialist-work-and-records/`：专业来源、知识记录。
- **场景速查手册**：按“要处理什么事情”分组，覆盖 Godot 项目开发与 Yaya 框架维护两个 Project。
  - 场景名称：写清当前状态，方便从目录选择。
  - 单篇范围：一个目标，对应一条同名专用提示词；目录与文件名直接使用提示词库中的 Project、分类和提示词名称。
  - 信息栏目：保留 11 类分类规则，只展示有内容的栏目。编写要求见[场景手册编写要求](prompt-scenarios/scenarios/README.md)。

## 使用范围

本节是框架适用范围的唯一说明，其他页面只链接到这里。

- **使用方式**：一位使用者与 Agent 配合开发，不包括多人协作或改动归属处理；worktree 使用按具体任务需要与授权判断，不作为通用前置。
- **任务续接**：支持同一目录中的暂停、切换与新对话恢复；按需调研与独立审核仍可使用。
- **素材工作**：覆盖准备要求、接收和检查；视觉美术、音乐与音效制作保持待扩展边界。
- **暂不覆盖**：打包发布流程尚未确定。

## 阅读约定

- **路径基准**：Godot 项目手册中的 `docs/`、`yaya/tools/` 等路径相对生成后的游戏项目根目录；维护文档中的 `framework/` 等路径相对本仓库。
- **示例**：示例 ID、路径和输出需换成实际对象，不代表已经完成的验证或批准。
- **权威来源**：行为以项目规则、methodology、Skill 和实际工具为准，手册只解释它们，不另建流程。

## 维护命令

脚本放在所属对象目录下的 `tools/`，用法写在同目录 README。命令都在仓库根目录、使用已确认的 Python 3.12+ 运行；`-B` 禁止生成字节码缓存，参数细节以各命令的 `--help` 为准。

| 命令 | 用途 | 用法 |
| --- | --- | --- |
| `project-creation/tools/create_project.py` | 按复制清单创建空白项目，建立独立 Git 仓库和初始提交 | [创建空白项目](project-creation/tools/README.md) |
| `prompt-scenarios/tools/check_scenario_prompt_paths.py` | 只读核对两份提示词库与场景文件路径是否一一对应 | [提示词与场景工具](prompt-scenarios/tools/README.md#提示词与场景路径检查) |
| `prompt-scenarios/tools/check_workflow_graph_names.py` | 只读核对开发场景图节点名与 Godot 提示词名称 | [提示词与场景工具](prompt-scenarios/tools/README.md#检查场景图名称与链接) |
| `prompt-scenarios/tools/link_workflow_graph_scenarios.py` | 为开发场景图节点写入或更新同名场景链接；`--check` 只读 | [提示词与场景工具](prompt-scenarios/tools/README.md#检查场景图名称与链接) |
| `relationship-maps/tools/check_document_graph_coverage.py` | 按文档系统图登记的路径检查文档覆盖 | [关系图工具](relationship-maps/tools/README.md) |
| `maintenance/tools/check_repository_links.py` | 检查维护侧与生成项目中的 Markdown 链接和锚点，以及提示词正文中的路径与标题引用 | [维护工具](maintenance/tools/README.md#检查链接与锚点) |
| `maintenance/tools/find_orphan_docs.py` | 扫描全仓文档的文本引用，列出孤立候选 | [维护工具](maintenance/tools/README.md) |
| `tests/` 下的回归入口 | 仓库回归与指定外部项目的工具回归 | [测试与夹具](tests/README.md) |

维护脚本只处理可重复的文件与数据操作，任务范围与结果意义由 Agent 判断；不增加逐动作监督、重复状态、发布资格或自动同步。总体取舍依据[根规则的核心原则](../AGENTS.md#核心决策原则)。
