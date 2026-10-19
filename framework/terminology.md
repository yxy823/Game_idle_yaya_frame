# 框架术语

本页只收录 Yaya 框架特有、或在本框架中有特定含义的术语，两本手册共用这一份。通用开发常识、Godot 基础概念和一看就懂的名称不收录；操作要求和完成规则由所属规范维护。

游戏自身的业务术语不放这里，固定保存在生成项目的 `docs/terminology.md`，由 `terminology-register` 维护。

表格第三列「不用的说法」列出同一对象不再使用的写法，出现时改为正式名称；「术语」格中用 `/` 分开的写法都可以使用。含义见[术语文件的格式](../project-source/methodology/14-project-terminology.md#术语文件的格式)，检查命令见[检查术语用词](maintenance/tools/README.md#检查术语用词)。

## 框架对象

| 术语 | 含义与边界 | 不用的说法 |
| --- | --- | --- |
| 框架仓库 | 本仓库 `D:/A_Games/Game_idle_yaya_frame`，保存维护材料和分发源 | 维护仓库、框架维护仓库、框架维护源 |
| 根 `AGENTS.md` | 框架仓库根目录的 `AGENTS.md`，框架维护任务的规则入口；链接只指向文件时，链接文字用它的标题「框架维护约定」。不指生成项目的 `AGENTS.md`，也不指工程规则；「框架规则」既可能指它也可能指工程规则，所以不用 | 根规则、根约定、根维护约定、框架规则 |
| 工程规则 | `project-source/agent-rules/` 中按领域保存的 Godot 引擎与语言规则，创建项目时复制到 `yaya/agent-rules/`；入口是[工程规则目录](../project-source/agent-rules/README.md) |  |
| 分发源 / `project-source/` | 创建器按复制清单复制到新游戏项目的源材料；在框架仓库中只作为源材料阅读，不启动其中的开发流程 | 分发材料、分发源材料、分发包、空白项目源材料、待分发项目 |
| 复制清单 | `framework/project-creation/project-files.json`；只决定创建时复制什么、复制到哪里，不承担升级或已有项目的同步 |  |
| 复制映射 | 复制清单中的一条 `source` → `target` 对应关系；`source` 相对框架仓库根目录，`target` 相对生成项目根目录 |  |
| 生成项目 / 游戏项目 | 创建后独立拥有代码、配置、规则和记录的 Godot 项目，不再依赖框架仓库 |  |
| 项目规则 | 生成项目的 `docs/project-rules.md`，记录这个项目自己的开发约束和工程原则 | Project Rules |
| 外部项目 | 维护者指定、用来实际验证框架的 Godot 项目；回归和试用只在其中运行，不在框架仓库中运行 |  |
| 目标项目 | 工具或 Skill 实际作用的那个项目：创建器 `--output` 指定的输出目录、复制迁移建立的新项目，或分发 Skill 中路径所相对的生成项目；用作验证对象时称外部项目 |  |
| 推演 | 审核报告的主体方法：带 2–3 个具体任务，按实际文件逐步推演，记录每一步读到什么、卡在哪里 | 走查 |
| 预设提示词 / 预设提示词库 | `framework/prompt-scenarios/prompts/` 下按场景事先写好、集中维护的提示词，整份 JSON 称“预设提示词库”，共两份：Godot 项目开发和 Yaya 框架维护；不指派活给子智能体或 Codex 时当次写的提示词 | 集中提示词、集中提示词库 |
| Project | 提示词 JSON 的顶层名称，只有「Yaya 框架维护」和「Godot 项目开发」两个；与 Product、Feature 无关 |  |
| Godot 项目手册 | `framework/godot-project-manual/`，按对象解释生成项目里的概念、文档、配置与工具；简称“手册” |  |
| 场景速查手册 | `framework/prompt-scenarios/scenarios/`，按“遇到什么情况”给出处理步骤，每篇对应一条同名提示词；单篇称“场景页” |  |
| 主 Agent | 与用户对话、派出子智能体、审核实例或 Codex 这类外部 Agent 的一方，负责交代范围、核对交回的结果和提交；不指游戏代码里连接多个对象的协调者 | 协调 Agent |

## 设计与交付

| 术语 | 含义与边界 | 不用的说法 |
| --- | --- | --- |
| GDD | 游戏设计正文，固定在 `docs/gdd/`；规划和实现依赖的设计必须先在这里真实存在 |  |
| 设计原则 | GDD 中连接预期体验与设计取舍的原则，写在 `concept-and-experience.md`；用于说明选择或排除某种做法的理由 | 设计支柱 |
| Product | 依据 GDD 划定的可验收交付单元，可以是一个系统、系统的一部分或跨系统体验；只写交付范围，不重复游戏规则 |  |
| Product 总览 | `docs/product.md`，保存预拆分结果：交付范围、来源、依赖与建议顺序；不等于 GDD 的游戏总览 |  |
| 预拆分 | 在 Product 总览中粗分全部约定交付范围；轮到某个 Product 时才细化其正文并拆 Feature |  |
| Feature | 有范围、验收条件和状态的开发任务；Bug、重构和工程维护也可以按规范建为 Feature |  |
| Feature 记录 | 02 号规范的[文件结构](../project-source/methodology/02-feature-list-schema.md#文件结构)规定的一组 JSON：索引、`docs/features/` 下的详情、修订记录、测试登记表与完成证据；“Feature 记录检查”指 `yaya/tools/checks/check-feature-list.py`。“不另建记录文件”指不为追踪某件事额外新建文件 |  |
| 修订记录 | `docs/feature-list-revisions.json`，保存初始规划基线和后续源同步的修订条目及锚点；不指 Feature notes 中的修订笔记 | 修订日志 |
| Stage | [Stage 0–8 `feature-execute` 执行循环](../project-source/methodology/03-execute-loop.md)里的阶段编号，用于定位进度；不是逐阶段审批或自动状态机 |  |
| 独立审核 | Stage 6：用户明确要求时，在全新上下文中按用户指定的范围和时机审核变更，方法见[独立审核](../project-source/methodology/12-independent-review.md)；用户没要求时跳过 | 独立评审、独立审查 |
| 现状审核 | `review-code` 的一种模式：不依赖差异或 Feature，审核选定模块的当前状态；审核一次改动的模式称“改动审核” | 现状审计 |
| 代码坏味道 | 代码中提示可能存在维护问题的结构特征，是审核和挑选重构目标时的调查线索，本身不算违规 | 代码异味 |
| 备选方案 | 设计中并列比较的几种可选做法，最终采用其中一种或组合；调试台里插槽的一种实现另称“候选” | 候选方案、候选设计、候选模型 |
| 备选数值 | 设计中尚未采用的数字取值；保存、采纳和效果验证是不同的事。不指 Product、设计方案或工具路径 | 备选值、候选替代值 |
| 待决定事项 | Progress 中的同名一节，列出需要用户决定才能继续的事项；GDD 中设计层面没定下的问题称“开放问题” |  |
| Lessons | 记录 Agent 自己流程失误及出现次数的文件：生成项目的 `docs/lessons.md` 和框架的 `framework/lessons.md`；规则见 09 号的 [Lessons](../project-source/methodology/09-records-reports-and-handoff.md#lessons)。引擎、工具怎样运作的陷阱写项目知识，不写 Lessons | 教训台账、台账 |
| 技术验证 | 在真实引擎中确认既定做法能否实现，结论为可行、受限、不可行或未验证；不用于定位已实现功能的卡顿 |  |
| 制作项目 | 游戏项目之外、独立制作美术或音频的仓库，例如按媒体分开的音频制作项目；保存母版并交付成品，不随框架分发，交接方式见[在项目外制作](../project-source/methodology/11-specialist-workflows.md#在项目外制作) | 工坊 |

来源：[GDD 与 Product 文档结构](../project-source/methodology/01-product-doc-structure.md)、[Feature 列表与测试追溯结构](../project-source/methodology/02-feature-list-schema.md)、[Stage 0–8 `feature-execute` 执行循环](../project-source/methodology/03-execute-loop.md)、[调试台与技术验证](../project-source/methodology/13-debug-console-and-validation.md)。

## 调试台

| 术语 | 含义与边界 | 不用的说法 |
| --- | --- | --- |
| 调试台 | 从调试入口 `dev/debug/debug_main.tscn` 启动真实游戏，在独立窗口中调参、比较候选并采纳到游戏的开发工具；依赖只从 `dev/` 指向游戏，游戏代码、`tests/` 和正式导出都不引用它 | 调试控制台 |
| 调试入口 | `dev/debug/debug_main.tscn`，启动调试台的场景：先挂上调试窗口，再切到项目的主场景；平时运行主场景，调试时启动调试入口 |  |
| 调试对象 | 游戏里的一个界面，或跨界面共用的 `shared`；对应 `game/<对象>/` 与 `dev/debug/<对象>/`，键名与界面文档一致 |  |
| 设计 token | 给界面颜色、字号、间距、圆角、边框、阴影和按钮动效起名的取值，分原始值（例如“强调 500”）和引用原始值的语义值（例如主要按钮背景）；放在 `game/shared/tuning/ui/`，由 Autoload `UiTheme` 生成项目主题，在 `shared` 对象的插槽中调 |  |
| 样式总览 | `shared` 调试对象的主场景：按实际文件列出全部设计 token、控件与按钮变体示例，以及每种样式被哪些界面使用 | 展示台 |
| 插槽 | 调试对象中一个可调的部分，固定绑定一份调参资源，编号为 `<对象>/<资源相对路径>` |  |
| 候选 | 插槽的一种实现，例如一个特效场景、一个音效或一段规则脚本；没采纳时放在 `dev/debug/<对象>/slots/<插槽>/<候选>/`。替换规则实现的叫逻辑候选。只指调试台插槽的实现，设计中的几种可选做法称“备选方案” |  |
| 调试窗口 | 调试台在游戏窗口之外打开的独立窗口，调参、比较候选和采纳都在其中操作；在任一窗口按 F1 显示或隐藏 |  |
| 调参资源 | `game/<对象>/tuning/` 下游戏运行时读取的独立 `.tres`；只有调试台在运行中修改它，文档链接它而不抄数值 |  |
| 插槽预设 | 一个插槽的一套命名设定，保存在插槽的 `presets/` 下；只是候选设定，游戏和测试不读取，也不进内容指纹 |  |
| 组合 | 一个调试对象各插槽所用预设的引用集合，保存在 `combos/` 下；空引用表示游戏原值 |  |
| 游戏原值 | 游戏文件里保存的调参资源取值，也就是不开调试台时游戏使用的值；对比的默认对象，也是人工验收的对象 |  |
| 采纳到游戏 | 用户在调试台确认一次，把当前设定写进游戏文件，候选还在 `dev/` 时先移进 `game/`；之后由 Agent 收尾提交。采纳不等于人工接受 |  |
| 固定局面 | 按游戏存档格式保存、含随机种子的一份可重播状态，由调试对象登记，走游戏自己的读档路径进入 |  |
| 试播动作 | 插槽登记的“点一下就看到效果”的动作，免得在游戏里等效果自然出现 |  |
| 界面任务 | 按“想做的事”写下的一条界面操作路径：目标、步骤、应看到的反馈；游戏界面写在 UI 规格，调试台写在 `dev/debug/_shared/usage-scenarios.md` |  |
| 按界面任务试用 | 在改名的项目副本中用 `ui-trial` 程序驱动界面，逐条走界面任务并分级记录问题；不代替用户的人工验收 |  |

来源：[调试台与技术验证](../project-source/methodology/13-debug-console-and-validation.md)、[调试台共享代码](../project-source/defaults/dev/debug/_shared/README.md)、[按界面任务试用](../project-source/tools/ui-trial/README.md)。

## 游戏职责

| 术语 | 含义与边界 | 不用的说法 |
| --- | --- | --- |
| 游戏逻辑 / 游戏表现 | 理解一个功能时的两类职责：逻辑负责规则、状态与有效结果，表现负责界面、动画、特效、声音和镜头等玩家感知。用于找到对应的文档和实现，不是必须拆开的任务类型 |  |
| 游戏表现文档 | `docs/presentation/` 中描述一次具体表现的文档：过程、要求、备选方案、采用关系及实现与验收入口 |  |
| 使用方路径 | 游戏表现或资源被使用的位置，以实际文件或节点路径表示；与实现本身的路径区分 | 消费位置 |

来源：[游戏职责与项目组织指南](../project-source/defaults/docs/game-organization.md)、[专业工作与来源](../project-source/methodology/11-specialist-workflows.md)。

## 验证记录

| 术语 | 含义与边界 | 不用的说法 |
| --- | --- | --- |
| Registry / 测试登记表 | `docs/test-registry.json`，登记测试身份、组件、实现位置和生命周期；登记不等于执行通过 |  |
| 完成检查 | 任务正式完成前的整体核对；统一用这个词，不另称“交付检查”“收尾检查”，也不与一次人工验收混称 | 交付检查、收尾检查 |
| 人工验收 | 用户按人工验收清单实际运行、观察并给出结果的过程；结果可能是 accepted、rejected 或 pending | 用户验收 |
| 人工验收清单 | `manual` Feature 在 Stage 4 准备、用户在 Stage 5 填写结论的清单文件，例如 `reports/manual-acceptance/F001/manual-acceptance-checklist.json`；清单中的单条检查称“人工检查项” | 人工清单、人工检查清单、待验收清单 |
| 人工接受 | 人工验收的通过结果（accepted），是 manual 模式 Feature 完成的条件之一；实现授权、自动测试通过或用户未表态都不算接受 |  |
| 完成证据 | 每个 Feature 的 `docs/features/F0XX-evidence.json`，引用实际验证原件和人工验收清单；文件存在本身不证明条件满足。写入它的 `yaya/tools/features/record-feature-completion.py` 称“完成记录工具”，“完成记录”不作为这份文件的名称 | 完成依据 |
| 内容指纹 | 工具用来判断一条记录是否仍对应当前内容的标识；不是授权，也不是人工验收 | 快照指纹、验证指纹、全局来源指纹、源码指纹、工作区指纹、测试指纹 |
| 验证点 | 最近一个仍在当前 HEAD 历史上的已完成 Feature 的完成证据 `git_revision`；没有时是仓库的第一个提交。取法由 `yaya/tools/features/record-base-revision.py` 实现 |  |
| 起点 / `base_revision` | Feature 详情中测试选择的起点：Stage 2 写入的验证点，之后固定；选择比较它与当前工作区的内容差异。不指 Git 分支起点或修订记录的 `anchor_commit` |  |
| 反推组件 | 起点以来改动的文件按登记表 `source_paths` 对到的组件，与 `affected_components` 取并集后参与测试选择；不在声明中时列进 `inferred_components`，不是错误 |  |
| 夹具 / fixture | 测试运行前搭好的固定输入和环境，让每次运行都从同一个已知状态开始，例如临时 Git 仓库、合成的 Feature 记录、叠加了 GDD 和 Feature 计划的演练项目；夹具文件存在不证明测试已执行 |  |
| 行为模型 / 行为模型检查 / behavior model check | 行为模型是一个子系统当前行为的 TLA+ 模型，正式位置 `docs/architecture/models/<subsystem>.tla`；行为模型检查是 Stage 1C 用 `check-behavior-model.py` 运行 TLC 检查它，结果只算设计验证，不进入完成证据。只做模型检查、不做定理证明，所以不叫“形式化验证” | 形式化验证 |
| 正确版本 / 错误版本 / mutation | 行为模型检查的两类运行（mutation 指错误版本）：正确版本是常量 `Mutation` 取 `none` 的模型，必须完整跑完、没有违反；错误版本是故意改错一处、模拟一种合理实现错误的模型，必须被检查配置里写明的每条性质抓到 | 错误注入 |
| 可达性检查 / witness | 用一条期望被违反的不变量证明某条合法路径能走到，防止模型把要检查的行为限制掉，正确版本因此假通过；检查配置的 `witnesses` 字段列出它们 | 见证路径、见证不变量 |
| 检查配置 | 行为模型旁的同名 `.checks.json`，写明要检查的性质、错误版本及应抓到它的性质、可达性检查；字段见工具说明。不叫“检查清单”，因为容易和人工验收清单混淆 |  |

来源：[测试追溯与证据](../project-source/methodology/08-test-traceability-and-evidence.md)、[人工验收文件](../project-source/methodology/contracts/manual-acceptance-files.md)、[behavior-model-check](../project-source/skills/behavior-model-check/SKILL.md)。

## 外部分析工具

| 术语 | 含义与边界 | 不用的说法 |
| --- | --- | --- |
| Game Audio Analyzer / GAA | 本机安装的音频分析工具；调试台调用其后台模式、读取后台结果文件并显示指标，结果不代替实际听感 |  |
| Game Visual Analyzer / GVA | 本机安装的图像分析工具；用户可以把游戏截图交给它生成色觉四宫格；结果不代替实际观感 |  |

来源：[分析](../project-source/defaults/dev/debug/_shared/README.md#分析)。

## 动作用词

| 术语 | 含义与边界 | 不用的说法 |
| --- | --- | --- |
| 确认 | 用户做出的决定或授权，写作“用户确认”；Agent 自己检查不用这个词 |  |
| 核对 | Agent 对照来源或实际文件自查一致性；存量文字不全量改写，修改到哪一处就按这一行改用哪个词 |  |
