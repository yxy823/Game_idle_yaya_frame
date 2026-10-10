---
name: debug-console-godot
description: "在已授权的 Feature 或限定范围的实验中，用游戏内调试台和用户一起比较候选、做视觉决策、试调已实现的特效、反馈或操作手感，并在用户采纳到游戏后收尾提交；对话开始时发现已存在的 dev/debug/adoption-log.md，也用本 Skill 收尾，不需要另外授权；也负责为调试对象登记插槽、候选、固定局面和试播动作。用于骨架之后在调试台定画面，以及“太闪”“节奏拖沓”“打击感不够”“移动发飘”这类要实际看或操作才能判断的调整。不用于从零规划表现（design-game-presentation）、经济和成长数值（design-balance）、批量内容数据与难度曲线（content-data-authoring）、引擎可行性问题（technical-validation-godot）、修改调试台共享代码本身，也不用于记录验收结论（manual-acceptance-godot）。"
---

# 调试台：比较候选、调参与采纳

调试台从调试入口启动真实游戏，在独立窗口中修改游戏正在使用的调参资源。判断好坏的是用户；Agent 负责把要调的东西接进调试台、提出改哪些参数、记录每一轮，并在用户采纳后让改动成为正式文件。

- **原则与流程**：`yaya/methodology/13-debug-console-and-validation.md` 的[调试台](../../../yaya/methodology/13-debug-console-and-validation.md#调试台)、[界面的开发顺序](../../../yaya/methodology/13-debug-console-and-validation.md#界面的开发顺序)和[逻辑候选](../../../yaya/methodology/13-debug-console-and-validation.md#逻辑候选)。
- **机制**：插槽、预设、采纳与收尾的具体写法见[调试台共享代码](../../../dev/debug/_shared/README.md)；本项目的启动命令和已登记的调试对象见[本项目的调试台](../../../dev/debug/README.md)。

## 前提

- 调整属于一个已授权的 Feature（通常在 Stage 3），或用户要求的限定范围实验。没有这类授权时，只给出调整建议，不改文件。例外：收尾已存在的 `dev/debug/adoption-log.md` 不需要另外授权，依据是 `AGENTS.md` 的[开始修改前](../../../AGENTS.md#开始修改前)。
- 游戏里已经有要调的系统，哪怕只是最小的真实骨架。还没有时，按[界面的开发顺序](../../../yaya/methodology/13-debug-console-and-validation.md#界面的开发顺序)先建骨架 Feature，不在 `dev/` 里写假系统。
- **先查上游的定性词**：开调之前，看 GDD、Product 和表现文档里有没有限定这个参数的说法，例如“少量粒子”“轻微震动”。用户想要的方向可能超出它时，先问用户：只调参数、保留这个说法，还是改需求本身。改需求由 `design-gdd`、`product-author` 等负责方修改来源，再经 `feature-sync` 同步，不在调参中顺手改掉。
- 效果所属的 Feature 已经完成，用户之后才要调：按 13 号的[完成后再调值](../../../yaya/methodology/13-debug-console-and-validation.md#完成后再调值)执行。
- 用户在 Stage 5 人工验收时可以随意试调和另存预设；又采纳了新值时，按 `yaya/methodology/03-execute-loop.md` 的 [Stage 5 · 明确的人工验收（仅 manual 模式）](../../../yaya/methodology/03-execute-loop.md#stage-5--明确的人工验收仅-manual-模式) 作为拒绝处理：这份清单不记录结论，在 Progress 记下采纳内容。
- 修改调试台共享代码或界面本身不属于本 Skill，按 `yaya/methodology/07-engineering-change.md` 的[维护 Feature 契约](../../../yaya/methodology/07-engineering-change.md#维护-feature-契约)建维护 Feature。

## 把调整对象接进调试台

登记插槽、候选、固定局面和试播动作都是实现修改，在当前授权内完成，写法见[调试对象、插槽与候选](../../../dev/debug/_shared/README.md#调试对象插槽与候选)和[固定局面与播放](../../../dev/debug/_shared/README.md#固定局面与播放)：

1. **调参资源**：要调的参数放进 `game/<对象>/tuning/` 下的调参资源，一份资源就是一个插槽，游戏代码读取它、不引用 `dev/`。资源规则见 `yaya/agent-rules/21-resources/roles-sharing-and-locality.md` 的[调参资源](../../../yaya/agent-rules/21-resources/roles-sharing-and-locality.md#调参资源)。参数怎样提取见[调操作手感与普通参数](references/gameplay-tuning.md)。
2. **插槽说明与试播动作**：每个插槽和参数都要有中文名，写在 `dev/debug/<对象>/slots/<插槽路径>/slot.gd`；真实游戏里要等很久才出现的效果，登记“点一下就看到”的试播动作。
3. **固定局面**：需要反复看同一段流程时，在 `dev/debug/<对象>/debug_target.gd` 登记固定局面。原则见 13 号的[固定局面、试播与测试状态](../../../yaya/methodology/13-debug-console-and-validation.md#固定局面试播与测试状态)。
4. **调试存档**：项目还没按自己的存档系统改写 `dev/debug/debug_project.gd` 时，先改写它（见[入口与项目挂钩](../../../dev/debug/_shared/README.md#入口与项目挂钩)），否则调试会话会写进用户的真实存档。
5. **登记与测试**：在项目调试台说明的[调试对象与候选](../../../dev/debug/README.md#调试对象与候选)中登记调试对象、插槽、候选和固定局面；对象专有的测试放在 `dev/debug/<对象>/tests/`，并把这个目录加进 `debug_console` 的 `unit_test_paths`，见 `yaya/methodology/08-test-traceability-and-evidence.md` 的[调试台组件](../../../yaya/methodology/08-test-traceability-and-evidence.md#调试台组件)。

## 候选

候选是同一插槽的另一种实现，例如另一个音效文件、另一种特效场景或另一条规则。

- **位置**：每个候选一个目录 `dev/debug/<对象>/slots/<插槽路径>/<候选名>/`，放描述文件 `candidate.tres` 和候选自己的场景、脚本与素材。候选必须和游戏当前的实现同类，字段见[调试对象、插槽与候选](../../../dev/debug/_shared/README.md#调试对象插槽与候选)。
- **来源与许可**：外部提供或下载的素材，在 `candidate.tres` 的 `source_url` 和 `license_note` 写明来源与许可摘要；来自项目外制作项目的成品，`source_url` 写制作项目中的作品路径和成品所在的提交号，`license_note` 写自制或所用第三方素材的许可，以及一句生成方法（见 11 号的[在项目外制作](../../../yaya/methodology/11-specialist-workflows.md#在项目外制作)）；素材包自带的许可证原件放在同一个候选目录，采纳时随素材一起移进 `game/`。来源或许可不明是缺口，不编造许可；许可不清楚的素材可以在调试台试听试看，但不采纳到游戏。第三方素材的通用要求见[第三方素材的来源与许可证](../../../yaya/agent-rules/60-assets/source-and-derived-assets.md#第三方素材的来源与许可证)。
- **落选的候选**：从未采纳的候选留在 `dev/`，正式导出不包含它；用户要求时再删除，Git 历史可以找回。
- **对象测试**：`dev/debug/<对象>/tests/` 中的测试按 UID 定位候选（采纳移动后 UID 不变），不按候选目录名或显示名，否则采纳后测试就找不到候选。
- **逻辑候选**：会改变游戏结果的规则候选，按 13 号的[逻辑候选](../../../yaya/methodology/13-debug-console-and-validation.md#逻辑候选)让游戏通过调参资源持有规则实例。规则插槽在 `slot.gd` 声明 `LOGIC := true`，采纳确认框会提醒先写 GDD。请用户比较时优先把播放调到 0.1–0.5 倍速：一次结算的结果在画面上停留很短（例如三消单轮消除），正常速度下看不清两条规则的差别。

## 一轮怎么做

1. **听清感受**：请用户说出哪里不对，以及在什么情况下出现，例如“连续消除时闪得刺眼”。用户已经说清楚的不再追问。
2. **提出假设**：说明打算改哪一两个参数或换哪个候选、往哪个方向、改多少、为什么。一次只动一两个参数，否则看不出是哪个起了作用。对应关系拿不准时，读[感受与参数的对应](references/feel-to-parameters.md)。
3. **请用户在调试台比较**：告诉用户按[启动](../../../dev/debug/README.md#启动)中的命令打开调试台，选哪个插槽、改哪个参数或选哪个候选、试哪几个值。调试台自带“当前改动 ↔ 游戏原值”的对比，Agent 不另做 A/B 版本。问题只在特定情况下出现时，用固定局面或试播动作在同样的情况下比较。配合方式见[调操作手感与普通参数](references/gameplay-tuning.md)。
4. **记录这一轮**：在当前 Feature 的 notes 中记下改了什么、用户怎么说、留下了哪个预设或采纳了什么；独立实验记在 Progress。只写一两行，不另建调整记录文件。
5. **决定下一步**：用户满意后，把这套值保存为预设继续调别的插槽，或采纳到游戏。

## 什么时候停

- **用户满意并采纳**：进入收尾。
- **几轮下来没有接近目标**：例如来回改了两三轮，用户仍然觉得“哪里都不对”，先停下来，问题可能不在参数上。表现方案本身达不到目标时，交给 `design-game-presentation` 重新规划；缺少能达到目标的图像或声音时，标出资源缺口；改了参数后帧率下降时，交给 `diagnostics-performance` 测量。
- **用户的要求超出参数和已登记的候选**：例如要换一种技术或新增一个组成部分，这是表现设计的变化，按 `yaya/methodology/11-specialist-workflows.md` 的[编写与采纳](../../../yaya/methodology/11-specialist-workflows.md#编写与采纳)处理，不在调参中悄悄完成。

## 采纳与收尾

用户在调试台点“采纳到游戏”，调试台把参数写进游戏的调参资源，候选还在 `dev/` 时一并移进 `game/`，并在 `dev/debug/adoption-log.md` 记下待收尾的采纳。用户口头说定一个值时，Agent 也可以直接改调参资源，原值写在 notes 里备查。

1. **收尾**：存在 `dev/debug/adoption-log.md` 时，按[收尾步骤](../../../dev/debug/_shared/README.md#收尾步骤)让文件成为正式资源并提交。项目的 Godot 编辑器开着时，先请用户保存并关闭编辑器。第 5 步删除 `adopted.tres` 之前，把采纳的外部素材的来源与许可摘要写进使用它的设计文档的资源条目。
2. **文档只链接资源**：玩家能感知的表现参数，例如动画时长、节奏、缓动，所属的表现或 UI 文档按 13 号的[调参资源](../../../yaya/methodology/13-debug-console-and-validation.md#调参资源)链接资源、不抄数值；换了表现方案中的某个组成部分时，同时更新表现文档的“当前采纳与实现”。采纳的逻辑候选还改了代码结构或调用方式时，按 `AGENTS.md` 的[收尾时核对受影响的文档](../../../AGENTS.md#收尾时核对受影响的文档)核对 Feature 设计稿和架构。
3. **时机**：采纳和收尾在 Stage 3 的[3D. 最终验证前的文档检查点](../../../yaya/methodology/03-execute-loop.md#3d-最终验证前的文档检查点)完成，人工验收清单绑定之前不再改。Stage 4 之后再采纳，之前的验证证据就失效了，要重做受影响的验证和验收。
4. **已完成 Feature 的资源**：收尾提交后，按[完成后再调值](../../../yaya/methodology/13-debug-console-and-validation.md#完成后再调值)检查被写入的资源是否被已完成 Feature 的文档或 AC 链接。

预设和组合只在调试台里使用，不是游戏的值，也不进验收绑定；游戏和测试都不读取它们。

## 验证与交付

- Agent 核对：采纳的值在不开调试台时生效，资源格式检查和按测试影响评估选出的测试（至少包括写入资源所属组件的测试、依赖方向测试和 `dev/debug/<对象>/tests/` 下的对象测试）通过，没有留下只为对比加的临时代码或临时值。
- 观感和手感只能由用户实际看、实际操作来判断。截图和录像可以辅助对比，不能代替用户的判断。
- 用户在调试台说“这个好”或采纳到游戏，都不等于人工验收。正式验收按 Feature 的验收模式在 Stage 5 进行，检查的是游戏原值，也就是不开调试台时游戏使用的值。

返回调整结果、采纳的资源路径和提交、记录写在哪里，以及仍未解决的问题。返回调用方；Skill 返回不会结束它所在的已授权任务（methodology 03 的[授权与续接](../../../yaya/methodology/03-execute-loop.md#授权与续接)）。
