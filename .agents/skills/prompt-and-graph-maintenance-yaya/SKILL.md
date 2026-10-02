---
name: prompt-and-graph-maintenance-yaya
description: 维护 Yaya 的集中提示词、同名场景及两张关系图。提示词入口变化时同步场景与导航；文档职责、路径或引用关系变化时同步文档系统图。正式指令审核、临时对话提示词与游戏项目内文档编辑不适用。
---

# Yaya 提示词与关系图维护

在框架仓库内完成本次提示词或文档体系变更的必要联动，保持正文、场景和图谱一致；本 Skill 不随游戏项目分发。复用现有图文件、工具与唯一复制清单，不维护并行正文或映射副本。

沿用当前任务的具体对象与授权，完成获准修改、维护自查、必要验证和交付。正式指令或提示词审核交给 [review-agent-instructions-yaya](../review-agent-instructions-yaya/SKILL.md)，不在本入口切换为审核模式。读取模板不表示执行其中任务，也不从模板的授权措辞取得当前写入权限。

## 定位本次入口

处理提示词时，按用途选择 [Godot 开发提示词库](../../../framework/prompt_scenarios/prompts/godot-development-prompts.json)或 [Yaya 框架维护提示词库](../../../framework/prompt_scenarios/prompts/yaya-maintenance-prompts.json)，再按分类、名称定位当前正文，核对目标、输入、执行仓库及出口。每份文件只含所属 Project。新增或合并前搜索相关用途，只合并目标与执行边界相同的入口。读取本次对象、相关候选和必要调用方；普通局部修改不通读整个提示词库或全量场景。

处理文档职责、路径、产物归属或实际引用关系时，读取[文档图维护约定](../../../framework/docs/workflow-maps/README.md#维护与检查)，定位本次涉及的节点及其实际源文件，完成对应图谱更新。只改文档图时，不加载无关提示词、场景或 advisor；普通正文措辞变化且上述关系未变时无需改图。

编写、修改和作者自查指令使用 [writing-for-agents-yaya](../writing-for-agents-yaya/SKILL.md)；说明文字使用[框架文档编写 Skill](../technical-documentation-writing-yaya/SKILL.md)。提示词的结构、命名、一对一关系、字段与内容判断以[提示词与场景准则](../../../framework/docs/framework-maintenance/baselines/skill-script-prompt-design.md#提示词与场景)为正文；运行、提交和持续授权沿用[根约定](../../../AGENTS.md)及本次明确例外，不在此重写通用流程。

## 按实际变化同步

| 本次变化 | 查阅与处理 |
| --- | --- |
| 提示词正文或入口范围变化 | 按[场景编写约定](../../../framework/prompt_scenarios/scenarios/README.md)核对同名场景的输入、方法、授权与出口，修改实际受影响内容；场景页不复制完整提示词。 |
| 新增、删除、重命名或调整 Project / 分类 | 沿准则的准确名称同步 JSON 与同名场景路径、一级标题，再核对[场景索引](../../../framework/prompt_scenarios/scenarios/scenario-index.md)及直接引用。正文变化也需核对导航描述，未失效处不制造修改，不维护第二份场景清单。 |
| Godot 场景集合、名称、分类或实际衔接变化 | 读取[场景图维护约定](../../../framework/docs/workflow-maps/README.md#阅读与维护)，更新唯一维护的可读版；保留已有 ID、布局与显示字段，按[保存格式](../../../framework/docs/workflow-maps/README.md#编写与保存格式)维护字段顺序，核对场景名称和相关连线，路径变化还需刷新场景链接。图只覆盖 Godot，框架场景不加入其中。仅修改提示词措辞且未改变这些关系时无需改图。 |
| Godot 场景的匹配条件或下一步入口变化 | 核对 [advisor](../../../project-source/skills/project-next-step-advisor/SKILL.md) 的状态判断与入口说明。advisor 直接读取同一份 Godot 提示词库，无需导出或同步副本；只修改实际失效的说明。 |
| 文档职责、文件名、路径、产物归属或实际引用关系变化 | 按[文档系统关系图](../../../framework/docs/workflow-maps/README.md#文档系统关系图)更新受影响节点的标题文件名、备注路径、链接及连线；保留稳定 ID 与无关布局。固定文件写准确名称，Feature 等同类产物使用既有命名模式，按需文件不伪装为已生成。已有类型内增添实例且路径模式仍覆盖时，不逐文件增加节点。 |
| 收录手册的 Markdown 变化 | 按[维护验证范围](../../../framework/docs/framework-maintenance/updating-the-blank-project.md#按修改选择验证范围)及[阅读版构建](../../../framework/docs/framework-maintenance/updating-the-blank-project.md#html-阅读版构建)处理相应手册。命令、环境与审批读取现有说明及根规则，不复制机器路径，不手改 HTML。 |

若变更实质影响任务路由、职责、授权或完成机制，按[维护与同步说明](../../../framework/docs/framework-maintenance/updating-the-blank-project.md#找到受影响的说明)继续核对相关规范、advisor 和同名场景。普通措辞修正不扩大成整套流程重审；发现范围外问题时说明具体缺口，不擅自改动。

## 核对与交付

提示词或同名场景发生变化时，按[提示词与场景路径检查](../../../framework/README.md#提示词与场景路径检查)运行现有配对工具；它只核对名称与文件路径，不检查正文 H1、语义、授权、图文件或实际执行。所需正式指令审核由审核入口承担，其他验证按上述维护规范选取；维护自查不冒充独立审核，区分已读范围、实际执行和未验证部分。

场景图变化按其[依据与检查](../../../framework/docs/workflow-maps/README.md#依据与检查)及[现有图工具](../../../framework/commands/README.md)核对名称集合、ID、端点、关系与场景文件链接。名称检查和链接检查不证明完整图格式或连线语义正确；手册构建也不能替代图文件检查或查看器中的布局体验。

文档图按其维护约定核对实际变化。用户明确要求排查未覆盖文档时，才运行[文档覆盖检查](../../../framework/docs/workflow-maps/README.md#按需检查文档覆盖)并报告结果；不把全仓覆盖扫描加入每次维护、提交或构建。覆盖表示文件符合某节点的路径登记，不证明正文引用或关系含义正确。

交付本次变更与联动文件、实际检查结果及尚未完成项。获准实施按根仓库规则提交；明确暂停或特定提交条件保持本次边界。尚有已授权工作时返回原任务继续，不因提示词、图谱或某项派生输出完成而提前结束。
