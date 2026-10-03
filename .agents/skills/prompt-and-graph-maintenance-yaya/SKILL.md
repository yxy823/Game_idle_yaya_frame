---
name: prompt-and-graph-maintenance-yaya
description: 维护 Yaya 的集中提示词、同名场景及两张关系图。提示词入口变化时同步场景与导航；文档职责、路径或引用关系变化时同步文档系统图。正式指令审核、临时对话提示词与游戏项目内文档编辑不适用。
---

# Yaya 提示词与关系图维护

在框架仓库中修改提示词或文档体系时，用本 Skill 完成必要的联动修改，让提示词正文、场景页和两张关系图保持一致。本 Skill 只供框架维护使用，不随游戏项目分发。

## 适用范围与边界

- **做什么**：在当前任务的具体对象和授权范围内，完成获准的修改、维护自查、必要的验证和交付。
- **复用现有材料**：使用现有的图文件、工具和唯一的复制清单，不另建并行的正文或映射副本。
- **正式审核时不用本 Skill 修改**：用户要求正式审核时，按[审核覆盖与结论](../../../framework/maintenance/design-guidelines/reviews-and-reports.md#审核覆盖与结论)只读核对，不做文件同步。
- **读模板不等于执行**：读取提示词模板不代表要执行其中的任务，也不能从模板里的授权措辞获得当前的写入权限。
- **依据**：提示词的结构、命名、一对一关系、字段和内容判断，以[提示词与场景准则](../../../framework/maintenance/design-guidelines/prompts-and-scenarios.md)为正文；规则与提示词文件的自查按[规则与提示词文件](../../../framework/maintenance/design-guidelines/instruction-files.md)；说明文字的写法使用[框架文档编写 Skill](../technical-documentation-writing-yaya/SKILL.md)。运行、提交和持续授权沿用[根约定](../../../AGENTS.md)和本次明确的例外，本 Skill 不重写通用流程。

## 找到本次要改的对象

**改提示词时**：

1. 按用途选择 [Godot 开发提示词库](../../../framework/prompt-scenarios/prompts/godot-development-prompts.json)或 [Yaya 框架维护提示词库](../../../framework/prompt-scenarios/prompts/yaya-maintenance-prompts.json)（每份只含所属的 Project）。
2. 按分类和名称找到当前正文，核对目标、输入、执行仓库和出口。
3. 新增或合并前，先搜索有没有用途相近的条目；只合并目标与执行边界都相同的入口。

只读取本次的对象、相关的候选条目和必要的调用方；普通的局部修改不需要通读整个提示词库或全部场景。

**改文档职责、路径、产物归属或实际引用关系时**：读取[文档图维护约定](../../../framework/relationship-maps/README.md#维护与检查)，找到本次涉及的节点及其实际源文件，更新图。只改文档图时，不加载无关的提示词、场景或 advisor；只是普通措辞变化、上述关系没变时，不需要改图。

## 按实际变化同步

| 本次变化 | 怎样处理 |
| --- | --- |
| 提示词正文或入口范围变化 | 按[场景编写要求](../../../framework/prompt-scenarios/scenarios/README.md)核对同名场景页的输入、方法、授权与出口，修改实际受影响的内容；场景页不复制完整的提示词 |
| 只读专项审核的模板或专题变化 | 按[专项审核的模板与专题](../../../framework/maintenance/design-guidelines/prompts-and-scenarios.md#专项审核的模板与专题)判断改哪里：影响全部专题的规则改「专项审核通用模板」，只影响一个专题的写进该专题；新增专题沿用现有专题的结构。专题页只说明拼接方法和完成标准，名称变化时同步 |
| 新增、删除、重命名 Project 或分类 | 按准则的准确名称同步 JSON、同名场景的路径和一级标题，再核对[场景索引](../../../framework/prompt-scenarios/scenarios/scenario-index.md)和直接引用。正文变化也要核对导航中的描述；没有失效的地方不改，也不另维护一份场景清单 |
| Godot 场景的集合、名称、分类或实际衔接变化 | 读取[场景图维护约定](../../../framework/relationship-maps/README.md#阅读与维护)，更新唯一维护的可读版图文件：保留已有的 ID、布局与显示字段，按[保存格式](../../../framework/relationship-maps/graph-map-format.md#编写与保存格式)维护字段顺序，核对场景名称和相关连线；路径变化时还要刷新场景链接。场景图只覆盖 Godot，框架维护场景不加入；只改了提示词措辞、关系没变时不改图 |
| Godot 场景的匹配条件或下一步入口变化 | 核对 [advisor](../../../project-source/skills/project-next-step-advisor/SKILL.md) 中的状态判断与入口说明。advisor 直接读取同一份 Godot 提示词库，不需要导出或同步副本；只修改实际失效的说明 |
| 文档职责、文件名、路径、产物归属或实际引用关系变化 | 按[文档系统关系图](../../../framework/relationship-maps/README.md#文档系统关系图)更新受影响节点的标题文件名、备注路径、链接和连线，保留稳定的 ID 和无关的布局。固定文件写准确的名称，Feature 等同类产物用已有的命名模式；按需生成的文件不写成已存在。同一类型里新增实例、路径模式仍能覆盖时，不逐个文件增加节点 |
| 提示词、场景或关系图检查脚本的参数、输出或位置变化 | 同步脚本所在的 `tools/README.md` 和[框架入口的维护命令索引](../../../framework/README.md#维护命令)，并运行对应的仓库回归 |
| 手册的 Markdown 变化 | 按[验证范围](../../../framework/maintenance/validation/validation-scope.md#按修改选择验证范围)核对受影响的正文、链接、锚点和导航 |

变化实质影响了任务路由、职责、授权或完成机制时，再按[维护与同步的「找到受影响的说明」](../../../framework/maintenance/maintenance-and-sync.md#找到受影响的说明)核对相关规范、advisor 和同名场景。普通的措辞修正不扩大成整套流程的重审；发现范围外的问题时，说明具体缺口，不擅自修改。

## 核对与交付

按本次实际改动选择检查：

- **提示词或场景页变化**：运行[提示词与场景路径检查](../../../framework/prompt-scenarios/tools/README.md#提示词与场景路径检查)。它只核对名称和文件路径，不检查一级标题、语义、授权、图文件或实际执行，这些由作者核对受影响的正文。
- **场景图变化**：按场景图的[依据与检查](../../../framework/relationship-maps/README.md#依据与检查)，用[场景图名称与链接检查](../../../framework/prompt-scenarios/tools/README.md#检查场景图名称与链接)核对名称集合、ID、端点、关系和场景链接。这两项检查不覆盖完整格式、连线含义或查看器中的布局效果。
- **文档图变化**：按文档图的维护约定核对实际改动。只有用户明确要求排查未覆盖的文档时，才运行[文档覆盖检查](../../../framework/relationship-maps/tools/README.md#检查文档图覆盖)并报告结果，不把它加入每次维护、提交或构建。覆盖只说明文件路径归入了某个节点，不说明正文引用或关系含义正确。

维护自查不能称为独立审核；报告时分清读过哪些、实际执行了什么、哪些没有验证。

交付本次修改与联动的文件、实际的检查结果和尚未完成的事项。获准实施的修改按根仓库规则提交；用户明确要求暂停或规定了提交条件时，按本次的边界执行。还有已授权的工作时，回到原任务继续，不因提示词、关系图或某项派生输出完成而提前结束。
