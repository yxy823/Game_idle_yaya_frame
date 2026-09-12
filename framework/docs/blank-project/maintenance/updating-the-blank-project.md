# 修改空白项目与同步使用说明

[返回手册](../README.md) · [框架规则](../../../../AGENTS.md) · [维护工具](../../../README.md)

本页面向框架维护者。修改 `project-source/`、复制映射或相关使用方式前，先读手册入口和受影响专题，再核对实际源文件。修改后在同一项维护工作中更新对应使用说明，使下一位接手者能直接理解当前行为。

## 通过提示词开始维护

[提示词库](../../../prompts.json) 中的 6 条“Yaya 框架维护”提示词明确引用手册入口和本页。正文路径相对当前框架根目录，先读根规则与这两个入口，再按任务范围查阅受影响专题和实际源文件，不要求每次通读所有章节。

| 提示词用途 | 说明的处理范围 |
| --- | --- |
| 新增能力、借鉴外部设计、修复删减与整理 | 实际实施后，在同一项工作中同步受影响的章节、导航与必要 Mermaid 图；仅提供建议时只指出说明影响 |
| 只读设计复盘、按需验证 | 核对相关说明与当前实现是否一致，报告过期步骤、路径、参数或结果解释；不顺手修改手册 |
| 新线程交接 | 只读相关说明，将手册入口、本页和受影响专题写入交接阅读清单，指出尚待同步之处；本次交接不改文件 |

读取维护说明不会扩大提示词的实施授权。后续修复、运行检查和提交仍按当前用户范围与根规则处理；已生成项目中的开发任务读取项目自身文档，不新增对框架手册的依赖。

## 先判断修改属于哪里

| 内容 | 应维护的位置 |
| --- | --- |
| 新项目应携带的文件 | `project-source/`；需要调整目标位置时同时核对复制清单 |
| 创建项目如何复制 | `framework/commands/create_project.py` 与 `framework/project-files.json` |
| 详细使用导览、框架与项目边界 | 本手册 |
| 项目内简短入口 | `project-source/Project_README.md`，保持概括与项目自身导航 |
| 某条流程、Skill 或工程语义 | 对应源规范；只在任务明确涉及该行为时调整 |
| 给用户发送的正式操作提示词 | `framework/prompts.json` |
| 框架维护约束 | 根 `AGENTS.md` |
| 某个已有游戏的独有需求或修复 | 明确指定的外部项目，不顺带回灌或同步 |

`project-source/Project_AGENTS.md` 是待复制规则源文件，在维护仓库中不激活项目开发流程。阅读 Skill 源文档以核对手册，也不表示当前维护任务已经进入那项 Skill 的执行流程。

## 找到受影响的说明

按实际变化选择对应章节，不要求每次修改整本手册。

| 本次变化 | 优先核对的手册章节 | 同时查看的实际来源 |
| --- | --- | --- |
| 复制范围、目录、重命名、目标限制 | [创建项目](../getting-started/create-project.md)、[目录参考](../reference/project-layout.md) | 创建器、复制清单、默认文件 |
| 环境字段、工具路径、就绪或初始化 Git 行为 | [首次使用](../getting-started/first-use.md)、[配置参考](../reference/configuration.md)、[故障排查](../reference/troubleshooting.md) | 配置源、环境检查器、初始化提示词 |
| Product 结构、Feature 字段或依赖演进 | [需求与规划](../guides/product-and-planning.md)、[目录参考](../reference/project-layout.md) | methodology、模板、相关检查实现 |
| Stage、验收、复审、完成或续接 | [Feature 开发流程](../guides/feature-delivery.md)、[命令与验证](../reference/commands-and-validation.md) | 执行 Skill、执行规范、完成依据实现 |
| Bug、重构、维护、实验边界 | [工程变更](../guides/engineering-changes.md) | 对应 Skill 与方法总览 |
| 测试选择、命令参数、报告或错误语义 | [命令与验证](../reference/commands-and-validation.md)、[故障排查](../reference/troubleshooting.md) | 测试策略、实际 CLI、共享实现 |
| 架构、规则、资产记录、Progress 或历史 | [项目知识与交接](../guides/project-knowledge.md) | 架构/生命周期规范与工程规则 |
| Skill 名称、职责或提示词入口 | [Skill 导航](../reference/skills.md) | 实际 SKILL.md、prompts.json 和场景用途清单 |
| Godot / lint / 插件默认值 | [配置参考](../reference/configuration.md)、[命令与验证](../reference/commands-and-validation.md) | 默认配置、plugin.cfg、补丁记录 |

手册概括不能替代源文件核对。若发现规范、脚本与手册存在冲突，应分清当前实际行为和待修问题；在任务范围内修正，或如实报告尚未解决的差异。不要为了让文字一致顺手改写 Skill 流程或测试门槛。

## 文档同步应包含什么

行为或默认值变化后，更新对应操作步骤、参数、路径、初始状态、输出解释和必要故障说明。目录结构、阅读路线或职责关系改变时，同时修改入口索引、相关链接与 Mermaid 图。

以最终行为组织说明，不长期保留“旧方式/新方式”两套并行教程。需要历史原因时链接 Git 历史或现有补丁说明；不建立说明版本状态、同步收据、哈希清单或发布资格文件。

仅内部实现调整、使用契约完全不变时，核对相关说明仍适用即可，无需制造无意义的文档差异。涉及用户可见使用方式的修改，应在本次提交中同步完成说明。

## 保持初始化边界

本手册全部文件放在 `framework/docs/blank-project/`，不要加入 `project-files.json`，也不要复制或移动到 `project-source/`。不增加“先复制再删除手册”的动作。

`Project_README.md` 保持短入口，描述项目自身用法；不要求已生成项目访问本手册或查询框架版本。框架根 README 和 `framework/README.md` 负责引导维护者找到手册。

新增正式任务提示词仍只写入 `framework/prompts.json`。说明可以引用提示词名称和用途，正文不散落进 README、规则或本手册。

## 按修改选择验证范围

| 变化类型 | 合适的检查 |
| --- | --- |
| 仅使用文档、目录导航和 Mermaid 说明 | 对照当前源文件检查事实、路径、链接、代码围栏、示例与复制排除边界；检查 Git 差异 |
| 复制器或清单行为变化 | 检查源/目标映射与路径边界，按任务需要运行已有复制器回归 |
| 项目工具实现变化 | 静态审查相关实现与调用点；需要执行时在明确指定的外部项目运行相应回归 |
| GDScript / Godot / 插件行为变化 | 根据影响在指定外部项目进行真实引擎验证，保留实际输出 |
| 只读或只要求静态检查 | 仅做授权的静态范围，不生成项目、不启动 Godot、不运行测试 |

已有维护命令从框架根目录调用，使用本机已确认的解释器：

```powershell
# 复制器回归会使用临时目录；仅在本次任务需要实际回归时执行。
& 'C:\Users\89523\anaconda3\envs\codex-python\python.exe' -B -m unittest discover -s framework/tests -p test_*.py
$LASTEXITCODE
```

```powershell
# 替换成用户明确指定的外部验证项目。
& 'C:\Users\89523\anaconda3\envs\codex-python\python.exe' -B framework/commands/validate_project.py --project 'D:\Games\MyGodotGame'
$LASTEXITCODE
```

后一个入口运行现有项目工具 unittest，不替用户创建或更新目标项目，不启动 Godot，也不建立示例业务台账。读取测试源码、通过 Python 工具回归与执行真实引擎检查分别报告，不能互相替代。

手册改动无需为了证明排除边界创建一个真实游戏：静态读取清单、展开选中源路径并确认与本手册无交集即可。若只检查 Mermaid 源码，报告语法或静态核对范围；只有真正渲染过才声称完成视觉检查。

## 提交与交付

按根 `AGENTS.md` 在修改前检查已有差异，保护无关工作；完成本次必要验证后，只暂存本次逻辑变更。提交前检查暂存区 whitespace、统计与完整差异，再创建本地提交，除非用户明确要求不提交。

交付说明实际新增或改变的用法、文档入口、验证范围和任何未完成项。仅修改文档的任务不宣称项目运行或测试通过。框架提交不会更新已有游戏，也不自动触发发布或下一项工作。
