---
name: content-data-authoring
description: "在已授权的 Feature 中，按已确认的 GDD 规则、数值公式和节奏目标，批量编写或生成游戏实际读取的具体内容数据，例如三消关卡、放置类的生产者、升级与解锁表，并为内容建立可机器检查的不变量。用于制作、扩充或重新生成内容数据，以及规划和编写内容校验。不用于新机制或规则（design-gdd）、公式与曲线推导（design-balance）、独立数值审核（review-balance）、和用户试调已实现的手感（debug-console-godot）或接入美术与音频资源（content-asset-integration），也不负责数据加载器和 schema 代码的实现。"
---

# 内容数据编写

把已确认的规则和公式，变成游戏实际读取的每一关、每一行数据。规则、公式和目标区间由 GDD 决定；本 Skill 决定具体内容写什么、怎样产出，并让对错明确的部分由机器检查。难度和手感由用户实际游玩判断。

## 前提与授权

- 写入 `res://` 下的内容数据属于实现，只在已授权的 Feature 中进行，通常在 Stage 3。它与 `yaya/methodology/11-specialist-workflows.md` 的 [设计、制作、接入与审核](../../../yaya/methodology/11-specialist-workflows.md#设计制作接入与审核) 中“把数值采纳到运行时资源或代码”走同一条路由。
- 没有这样的 Feature 时，按 `yaya/methodology/00-overview.md` 的 [任务路由表](../../../yaya/methodology/00-overview.md#任务路由表) 找入口：尚未规划交付的，先用 `product-author` 和 `feature-plan`；已完成的内容要修改，按 [编写与采纳](../../../yaya/methodology/11-specialist-workflows.md#编写与采纳) 的变化路由，由 `feature-sync` 建立新的 Feature。在此之前只给出内容方案和检查方案，不修改运行时文件。
- 内容数据的文件、格式、编写方式和要新增的检查，在 Stage 1 的批准材料中写明。新的内容检查作为不变量测试按 [登记表规则](../../../yaya/methodology/08-test-traceability-and-evidence.md#登记表规则) 登记。
- 需要的规则或目标缺失、互相冲突，或做内容时发现需要新元素、新目标类型：这部分停下，规则交给 `design-gdd`，公式和目标区间交给 `design-balance`，不在数据里悄悄补一条规则。不受影响的内容继续做。

## 输入

按 `yaya/methodology/01-product-doc-structure.md` 的 [GDD 文件名](../../../yaya/methodology/01-product-doc-structure.md#gdd-文件名) 找到：

- `systems/<system-key>.md`：内容种类目录、元素的行为和限制；
- `balance/<system-key>.md`：公式和目标区间，例如回本时间、解锁到达时间、关卡通过率的目标带；
- `progression.md`：内容投放顺序、教学顺序和节奏目标。

只使用已采用的规则。候选值和工作假设照原样标明，不当成已确认的要求。不要凭游戏类型推断出离线收益、转生或障碍这类机制。按当前要做的内容阅读对应参考：

| 当前内容 | 参考 |
| --- | --- |
| 放置类的生产者、升级、解锁、离线收益或转生 | 增量放置类参考的[通用约定](references/incremental-idle.md#通用约定)，再读对应小节 |
| 三消的关卡布局、目标与步数、障碍、关卡序列或可解性 | 三消参考的[通用约定](references/match-three.md#通用约定)，再读对应小节 |

其他类型按同样的分界判断：规则和公式归 GDD，具体实例归数据文件。

## 权威来源

- 每行数值以数据文件为准。`balance/` 只保留公式和目标区间，不复制行数据；GDD 主题链接数据文件的路径。
- 每个数据领域写明唯一的编写源和运行时表示，见 [权威来源](../../../yaya/agent-rules/50-data-files/data-lifecycle-and-authority.md#权威来源)。
- 用生成器产出时，生成器放在 `dev/tools/`，登记要求见[保存常用脚本](../../../yaya/methodology/09-records-reports-and-handoff.md#保存常用脚本)；生成参数（种子、数量、公式参数）和生成器放在一起，作为生成器的输入。生成产物提交到仓库，不手工修改；要改就改参数或生成器，再重新生成。
- 数据跟随所属的游戏模块，按 `docs/game-organization.md` 放在 `game/<module>/` 下；内容增多后再在模块内建 `data/` 或 `levels/`。
- `balance/` 中的公式或目标区间变化后，按新公式更新生成器或数据，并重跑全部受影响的检查。

## 编写或生成

- **格式**：每行一个实体的表格用 CSV，需要在检查器中编辑的定义用 `.tres`，嵌套结构用 JSON。规则见 CSV 规则的[编写](../../../yaya/agent-rules/50-data-files/csv.md#编写)、JSON 规则的[规范写出](../../../yaya/agent-rules/50-data-files/json.md#规范写出)和 Resource 角色、共享与复制中的[角色](../../../yaya/agent-rules/21-resources/roles-sharing-and-locality.md#角色)。
- **ID 与引用**：实体用稳定的业务 ID，互相引用写 ID，见 [业务 ID 与引用](../../../yaya/agent-rules/50-data-files/schema-identity-and-migration.md#业务-id-与引用)。字段、单位和取值范围按 [字段与取值](../../../yaya/agent-rules/50-data-files/schema-identity-and-migration.md#字段与取值) 写进 schema 需求，交给 Feature 实现。
- **手写还是生成**：数量少、每条都要单独设计的内容手写，例如教学关和最初几个生产者；数量多、能按公式或规则推出的内容生成。手写文件和生成产物分开存放。
- **确定性生成**：种子是生成器的输入参数；同样的输入连续生成两次，输出逐字节一致；先写临时文件并校验，再替换目标文件。其余要求见 [生成与派生数据](../../../yaya/agent-rules/50-data-files/data-lifecycle-and-authority.md#生成与派生数据)。
- **复用正式规则**：生成器和检查调用游戏正式的规则代码和加载器，不用另一种语言重写规则，否则会出现第二份规则正文，规则一变两边就不一致。

## 检查

分两层：

1. **结构层**：用生产加载器加载修改后的全部数据，没有错误；字段、类型、ID 或引用规则变化时补失败用例。见 50 数据文件规则的[验证](../../../yaya/agent-rules/50-data-files/README.md#验证)。
2. **内容层**：对错明确的内容约束，例如成本单调、前置条件不成环、目标在结构上可达、自动对局通过率落在目标带内。具体检查项见两份参考。

检查放在哪里：

- **gdUnit 不变量测试**：放在 `tests/invariants/content/`，通过生产加载器读取正式数据，逻辑 ID 写成 `INV-CONTENT-NN`。运行用 `run-gdunit-tests.py`，参数见 [run-gdunit-tests.py](../../../yaya/tools/README.md#run-gdunit-testspy)。
- **长耗时的检查**：大量模拟或求解在测试超时内跑不完时，做成 `dev/tools/` 下显式运行的无头脚本（`extends SceneTree`），参数固定，成功退出码为 0，失败为 1。诊断写出文件、实体 ID、字段、实际值和违反的约束，见 [错误](../../../yaya/agent-rules/50-data-files/data-lifecycle-and-authority.md#错误)。测试中保留一个能在超时内跑完的子集，例如少量固定种子。
- **何时固定下来**：按[保存常用脚本](../../../yaya/methodology/09-records-reports-and-handoff.md#保存常用脚本)的三条条件判断是否写成长期保留的测试或脚本。一次性的探索计算不保存为检查，结论写进 Feature 记录。
- **概率性检查**：自动对局或随机模拟的结果是计算证据，写明使用的策略、种子数量和局限。它不能证明真人玩家的难度感受。

## 需要人判断的部分

- 难度手感、节奏、新鲜感和数字增长的爽感，由用户实际游玩判断。Agent 列出值得用户重点体验的具体内容，例如自动对局通过率最低的几关，或长时间无物可买的时间段。每项同时给出进入它的测试存档或固定局面（见 `yaya/methodology/13-debug-console-and-validation.md`）；给不出时，写明要玩到哪里、预计要玩多久。
- 用户要调已实现的手感参数，用 `debug-console-godot`；要改目标区间或公式，交给 `design-balance`；要改规则或新增元素，交给 `design-gdd`。
- 用户试玩时说“这样可以”，不等于人工验收。正式验收按 Feature 的验收模式在 Stage 5 进行。

## 验证与返回

Agent 核对：

- 生产加载器能无错误地加载全部改动的数据；
- 内容不变量测试通过；
- 用生成器时，生成器连续两次输出一致，并且与已提交的文件一致；
- GDD 中的链接指向实际的数据文件。

返回改动的数据文件及其编写方式、新增或修改的检查及实际运行结果、未通过或没有检查的约束、需要用户试玩判断的具体内容，以及仍缺少的规则或目标。返回调用方；Skill 返回不会结束它所在的已授权任务（methodology 03 的 [授权与续接](../../../yaya/methodology/03-execute-loop.md#授权与续接)）。
