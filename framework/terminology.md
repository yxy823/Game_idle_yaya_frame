# 框架与 Godot 项目术语

本页只收录 Yaya 框架特有、或在本框架中有特定含义的术语，两本手册共用这一份。通用开发常识、Godot 基础概念和一看就懂的名称不收录；操作要求和完成规则由所属规范维护。

游戏自身的业务术语不放这里，固定保存在生成项目的 `docs/terminology.md`，由 `project-terminology` 维护。

表格第三列「不用的说法」列出同一对象不再使用的写法，出现时改为正式名称；「术语」格中用 `/` 分开的写法都可以使用。含义见[项目术语规范](../project-source/methodology/14-project-terminology.md#不用的说法)，检查命令见[维护工具](maintenance/tools/README.md#检查术语用词)。

## 框架对象

| 术语 | 含义与边界 | 不用的说法 |
| --- | --- | --- |
| 分发源 / `project-source/` | 创建器按复制清单复制到新游戏项目的源材料；在维护仓库中只作为源材料阅读，不启动其中的开发流程 | 分发材料、分发源材料、分发包 |
| 复制清单 | `framework/project-creation/project-files.json`；只决定创建时复制什么、复制到哪里，不承担升级或已有项目的同步 |  |
| 生成项目 / 游戏项目 | 创建后独立拥有代码、配置、规则和记录的 Godot 项目，不再依赖框架仓库 |  |
| Project | 提示词 JSON 的顶层名称，只有「Yaya 框架维护」和「Godot 项目开发」两个；与 Product、Feature 无关 |  |
| Godot 项目手册 | `framework/godot-project-manual/`，按对象解释生成项目里的概念、文档、配置与工具；简称“手册” |  |
| 场景速查手册 | `framework/prompt-scenarios/scenarios/`，按“遇到什么情况”给出处理步骤，每篇对应一条同名提示词；单篇称“场景页” |  |

## 设计与交付

| 术语 | 含义与边界 | 不用的说法 |
| --- | --- | --- |
| GDD | 游戏设计正文，固定在 `docs/gdd/`；规划和实现依赖的设计必须先在这里真实存在 |  |
| Product | 依据 GDD 划定的可验收交付单元，可以是一个系统、系统的一部分或跨系统体验；只写交付范围，不重复游戏规则 |  |
| Product 总览 | `docs/product.md`，保存预拆分结果：交付范围、来源、依赖与建议顺序；不等于 GDD 的游戏总览 |  |
| 预拆分 | 在 Product 总览中粗分全部约定交付范围；轮到某个 Product 时才细化其正文并拆 Feature |  |
| Feature | 有范围、验收条件和状态的开发任务；Bug、重构和工程维护也可以按规范建为 Feature |  |
| Feature 记录 | [Feature 结构](../project-source/methodology/02-feature-list-schema.md#文件结构)规定的一组 JSON：索引、`docs/features/` 下的详情、修订记录、测试登记表与完成依据；“Feature 记录检查”指 `yaya/tools/checks/check-feature-list.py`。“不另建记录文件”指不为追踪某件事额外新建文件 |  |
| Stage | Feature 执行规范里的阶段编号，用于定位进度；不是逐阶段审批或自动状态机 |  |
| 技术验证 | 在真实引擎中确认既定做法能否实现，结论为可行、受限、不可行或未验证；不用于定位已实现功能的卡顿 |  |

来源：[需求与交付结构](../project-source/methodology/01-product-doc-structure.md)、[Feature 结构](../project-source/methodology/02-feature-list-schema.md)、[执行规范](../project-source/methodology/03-execute-loop.md)、[调试台与技术验证](../project-source/methodology/13-debug-console-and-validation.md)。

## 调试台

| 术语 | 含义与边界 | 不用的说法 |
| --- | --- | --- |
| 调试台 | 从调试入口 `dev/debug/debug_main.tscn` 启动真实游戏，在独立窗口中调参、比较候选并采纳到游戏的开发工具；依赖只从 `dev/` 指向游戏，游戏代码、`tests/` 和正式导出都不引用它 |  |
| 调试对象 | 游戏里的一个界面，或跨界面共用的 `global`；对应 `game/<对象>/` 与 `dev/debug/<对象>/`，键名与界面文档一致 |  |
| 插槽 | 调试对象中一个可调的部分，固定绑定一份调参资源，编号为 `<对象>/<资源相对路径>` |  |
| 候选 | 插槽的一种实现，例如一个特效场景、一个音效或一段规则脚本；没采纳时放在 `dev/debug/<对象>/slots/<插槽>/<候选>/`。替换规则实现的叫逻辑候选 |  |
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
| 游戏表现文档 | `docs/presentation/` 中描述一次具体表现的文档：过程、要求、候选方案、采用关系及实现与验收入口 |  |

来源：[游戏组织指南](../project-source/defaults/docs/game-organization.md)、[专业来源约定](../project-source/methodology/11-specialist-workflows.md)。

## 验证记录

| 术语 | 含义与边界 | 不用的说法 |
| --- | --- | --- |
| Registry / 测试登记表 | `docs/test-registry.json`，登记测试身份、组件、实现位置和生命周期；登记不等于执行通过 |  |
| 完成检查 | 任务正式完成前的整体核对；统一用这个词，不另称“交付检查”“收尾检查”，也不与一次人工验收混称 | 交付检查、收尾检查 |
| 人工验收 | 用户按清单实际运行、观察并给出结果的过程；结果可能是 accepted、rejected 或 pending |  |
| 人工接受 | 人工验收的通过结果（accepted），是 manual 模式 Feature 完成的条件之一；实现授权、自动测试通过或用户未表态都不算接受 |  |
| 完成记录 / 完成依据 | 每个 Feature 的 `docs/features/F0XX-evidence.json`，引用实际验证原件和人工验收清单；文件存在本身不证明条件满足 |  |
| 内容指纹 | 工具用来判断一条记录是否仍对应当前内容的标识；不是授权，也不是人工验收 |  |

来源：[测试策略](../project-source/methodology/08-test-traceability-and-evidence.md)、[人工验收文件](../project-source/methodology/contracts/manual-acceptance-files.md)。

## Analyzer

| 术语 | 含义与边界 | 不用的说法 |
| --- | --- | --- |
| Analyzer | 分析图像、音频源文件的命令行工具；结果不代替实际渲染、听感或性能测量 |  |

来源：[Analyzer 说明](../project-source/tools/analyzer/README.md)。
