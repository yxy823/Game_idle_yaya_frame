# 设计复盘

用于判断设计是否值得继续维护，不计算总分，也不作为项目的新增 Gate。
以 [AGENTS.md](../../AGENTS.md) 的奥卡姆剃刀、第一性原理和最小完整修改为依据。
场景责任另见 [scenario-coverage.md](scenario-coverage.md)。

## 当前基线

2026-09-12：原有修复先单独提交为 `af90887`，随后完成本轮结构删减。
上述删减保留了原有 11 项 Skill 的用途与主要开发职责，取消固定汇报协议；运行记录合并，
不恢复 Agent 动作 Hook。实际回归在指定外部测试项目完成，未重新生成项目。
原有 136 项回归属于 `af90887` 前一轮记录，不能当成本轮结果；
本轮最终工具回归 133 项通过，实际 Godot 正常/负向运行结果见下文。
不以具体游戏的业务复杂度、Feature 数量或旧项目问题为设计依据。

| 部分 | 当前职责与证据 |
| --- | --- |
| 维护源 | 根 AGENTS 约束维护；`framework/` 保存复制工具、提示词和按需复盘材料 |
| 项目创建 | [create_project.py](../commands/create_project.py) 读取 [project-files.json](../project-files.json)，检查目标后复制；不渲染、配置环境、初始化 Git 或运行测试 |
| 项目使用 | 项目独立维护其文件；`Project_AGENTS.md` 在复制时改名，维护规则与项目规则分开 |
| Skill | 当前 12 项；新增 `project-clarifier` 复用提问方法与 Product 写入入口，按需维护项目 CONTEXT，不增加脚本或问卷状态。专用脚本仍在所属 Skill 的 `scripts/` |
| 共享工具 | [tools/README.md](../../project-source/tools/README.md)：`checks/` 两个检查入口；`testing/` 测试入口与三个 Godot 脚本；`lib/` 六个共享实现模块 |
| 检查方式 | 显式调用成果检查；没有 Agent 的 PreToolUse、PostToolUse、Stop 注册或 `hooks/` 目录 |
| 测试选择 | [test_selection.py](../../project-source/tools/lib/test_selection.py) 直接读取当前 Feature/Catalog；没有独立计划命令、计划文件或计划哈希 |
| 静态检查 | Agent 按 `methodology/gdscript-lint.md` 直接调用 Godot 解析和插件 CLI；没有包装脚本、专用 manifest 或静态证据注册 |
| 提示词 | 仅 [prompts.json](../prompts.json) 按框架维护与项目开发两个 Project 保存完整正文，不进入项目；使用清单与正文对应，按需选用 |

gdUnit 的 `GdUnitTestSessionHook` 是测试生命周期扩展，用于关联诊断；
它仍通过项目 Godot 配置启用，与 Agent 动作拦截不同。

## 可重复使用的判断依据

每次只选与本次问题有关的维度。结论可写“保留”“简化/合并”“删除”
或“证据不足”，附当前文件或实际观察；这些词不是新的流程状态。

| 维度 | 判断依据 | 当前静态观察与后续关注 |
| --- | --- | --- |
| 必要性与简单性 | 能否指出真实问题、不处理的后果，以及不新增机制的替代方案？新增内容是否只服务于已有机制自身？ | 已撤去独立计划、摘要、状态汇总和归档命令。新增工具仍需比较直接读文件、已有命令或人工处理 |
| 职责边界 | 创建、维护、项目开发是否分开？是否存在不必要的跨项目依赖？ | 复制入口只搬运文件；项目不查询母版，没有发布资格、升级或同步系统 |
| 状态与一致性 | 同一事实由谁维护？哪些结果可重算，哪些历史必须保存？一次修改是否要求手工同步多份结果？ | 选择来自当前台账；每次只写一份 result.json，原始报告保留；完成字段引用结果，不复制测试集合和计数 |
| Agent 自主性 | 是否允许在现有授权内推进、纠错？是否用脚本逐动作确认流程？ | 自动动作拦截已删除。Skill 仍保留 Stage 0–8、Bug 5.5、批准/按需求适用的验收/独立复审；固定 Stage 汇报句式和逐阶段必发消息已取消 |
| 可理解性与使用成本 | 能否从一个入口找到工具？简单任务是否被迫读完整规则、填写无用报告或重复检查？ | tools 按检查/测试/共享实现分一层，说明集中在一个 README。Skill 与规则阅读成本仍需真实使用观察 |
| 可维护性与一致性 | 同一逻辑是否只有一份实现？改动后能否找到所有调用者、配置、模板和测试？ | 没有旧路径转发副本。路径同时出现在 Skill、说明、配置约定和回归源码中，迁移必须同步；不要为此新增路径登记系统 |
| 可靠性与可验证性 | 检查是否针对真实当前成果？失败、未执行和人工决定是否被如实区分？ | 保留源指纹、实际测试证据、直接静态输出及测试失败尝试记录。本轮相关工具回归已通过；完整 Feature 与真实游戏运行未在本轮验证 |
| 扩展与维护成本 | 新能力是否在固定技术栈和真实需求内？更简单的修改是否足够？是否引入旧项目兼容分支？ | Godot/Win11 是确定边界；不为其他引擎、平台、自动升级或兼容旧项目预留系统 |

## 保留状态的用途

此表用于识别重复事实，不要求新增文件或定期登记。

| 事实 | 当前来源 | 应守住的边界 |
| --- | --- | --- |
| 需求、任务与测试关系 | Product、Feature 索引/详情、Test Catalog | 各文件负责产品意图、任务记录或测试映射；不要再复制为独立机器计划 |
| 当前交接与必要历史 | `docs/progress.md`、`docs/progress/`、Feature notes | 普通 Markdown 与链接；不要求机器标记或自动归档 |
| 本项目环境 | `docs/methodology-config.json` | 记录实际路径和命令；ready 是配置记录，不能冒充本轮检查已通过 |
| 本次运行事实 | result.json、JUnit、discovery、诊断与引擎日志；解析/lint 的原始输出 | 保留真实执行和必要关联；不能用手填数量、旧文件时间或对话摘要冒充新通过 |
| 完成结果与人工决定 | `docs/gate-evidence.json` 引用实际运行，记录明确验收/复审结论 | 显式校验成果，不监听每次状态编辑 |
| 失败或中断的测试 | 同一 run 目录中的 result.json，状态为 running/failed | 不另设尝试日志或锁；保留未解决失败，不能选择旧成功将其隐去 |

提示词增加了用户常用任务入口，没有新增流程引擎；正文引用现有 Skill/规则。
外部借鉴与阶段复盘先核对真实收益和已有覆盖，再判断最小沉淀；不能因提示词已列出
某场景就宣称运行覆盖通过。后续关注正文是否重复复制流程规则，及时合并相同用途。

当前最值得继续观察的是剩余报告校验的维护成本、Skill/规则的阅读成本、
以及配置命令与调用说明的同步成本。保留这些内容不等于证明其未来永远必要；
也不能因暂未运行就判定设计无价值。

## 本次决策与记录的因果关系检查

| 范围 | 决策依据 | 记录的职责 | 本次结论 |
| --- | --- | --- | --- |
| 验收方式 | AC 所要求的能力及是否需要人工感知判断 | `acceptance_mode` 记录 Stage 1 决定，检查项是随后填写的执行内容 | 原来无条件要求人工接受，已改为按需求决定；不从空清单反推 |
| 静态验证 | 实际变更和所需代码检查 | Agent 读取 Godot/插件原始结果 | 删除强制导入、静态包装和专用证据链 |
| 测试范围 | 批准的影响分析、组件映射和必要 full 条件 | runner 记录实际选择与执行结果 | 未发现从“已经跑过哪些测试”倒推必须测试范围的实现 |
| 环境就绪 | 实际路径、命令入口和版本探测 | ready 记录配置情况，不证明测试通过 | 现有检查未仅凭 ready 字段放行，保持 |
| Feature 完成 | 已满足的当前验收、必要验证和复审 | done 记录结果，不供测试证明反向引用 | 当前测试证据仍核对实际报告；静态检查由 Agent 单独负责 |

这次检查覆盖维护入口、规则/Skill、配置、测试选择、运行证据和完成消费者；
未确认其他同类因果倒置。上述结论是静态设计判断，不是完整项目行为验收。


## 本轮过度设计的处理

这轮修改优先删除重复责任和状态，不以麻将业务、测试数量或评分为设计依据。
以下内容已落维护源，并同步真正的 Skill、模板、配置和回归消费者。

| 原问题 | 处理 | 保留的能力 |
| --- | --- | --- |
| 多层测试证据链 | 合并为 result.json 加原始报告；删除 execution_attempts.py、独立日志/锁、invocation、verdict、manifest、进程文件和 session 收据；删除重复报告模板与运行器内置自检 | 当前源码绑定、真实退出码、漏测/零测试、原始诊断、失败与中断记录；进程归属在内存检查 |
| maintenance/infrastructure 自动 full | 删除按任务分类升级的分支 | 根据实际影响、组件约定、已批准理由或用户明确要求决定 full |
| 逐阶段发言与精确总结字符串 | 使用自然语言报告有意义的进展、失败、待决定事项和交接 | Stage 职责、实现前批准、适用人工验收与独立复审 |
| 台账默认宽松 / strict 双模式 | 显式调用统一检查完整台账，删除 --strict 与宽松降级 | 依赖、引用、演进、退休测试及完成契约检查 |
| 普通操作默认 Command | 普通函数/现有方法优先；撤销、排队、重放或独立生命周期需要时才采用 Command | 清晰输入输出、职责和可测试性；不把全部局部变量提升为成员状态 |
| 每 Feature 重复版本探测 | 初始化、工具/配置变化或排障时显式检查；日常读取已确认路径 | incomplete 仍不能开始编码，真实调用失败仍需解决 |
| 两条全量命令 | 删除 full_test_cmd，统一使用同一 runner 的 --scope full | 按配置测试根执行实际全量；额外检查按任务明确安排 |

本地结果和哈希用于识别误用旧结果及工件变化，不是对同一写入者的独立安全签名。
JUnit 证明断言结果，discovery 识别实际展开的用例，诊断覆盖 JUnit 未记录的引擎错误；
这三者没有因为合并元数据而删除。完成数据仍只引用本次结果，不复制派生通过字段。

### 本轮实际验证

环境：Windows 11 / PowerShell 7，指定 Python 3.12 环境，
Godot `4.7.1.stable.official.a13da4feb`。
对象：`D:\\A_Games\\Game_idle_yaya_frame_test`；没有重新生成项目、创建业务 Feature、
修改游戏或向项目写入人工接受记录。修复按逻辑分别提交：测试与流程删减为
`24303c9`，普通操作规则为 `0855672`，Skill 头部格式为 `d2df968`，
PowerShell 等待说明为 `0ab1cdb`；与原有基线 `af90887` 分开保留。

| 检查 | 结果及边界 |
| --- | --- |
| 工具回归 | 初轮 132 项通过；补充“缺 discovery 仍保留进程退出码”后，最终 133 项通过。包含合成报告负向用例和真实 Windows 进程清理，不等于 133 项真实游戏测试 |
| 真实 Godot 正常运行器 | 4 个用例通过，包含 2 个参数化实例及 1 个预期错误；discovery/JUnit/诊断/result 衔接成功 |
| 真实 Godot 负向运行器 | 故意在 suite before 注入原生错误，4 个断言仍通过、Godot 退出 0；运行器正确退出 1。该 run 保持 failed，不改报为业务通过 |
| 解析 / lint | 改动的引擎扩展直接解析退出 0；插件全项目 lint 检查 4 文件，Critical 0、Warning 0、Info 1，退出 0。Info 是 Logger 强制八参数接口说明 |
| 环境 / 台账 | 实际 require-ready 与默认完整台账命令均退出 0；台账仍为空，没有虚构业务完成 |
| 静态一致性 | 29 个 Python 源文件解析、8 份 JSON/无参数模板、10 个完整 JSON 示例通过；11 项 Skill 格式检查通过，未把它等同于执行 11 项 Skill |
| 未执行 | 新项目生成、完整业务 Feature、主场景体验、人工验收；不凭工具回归宣称这些通过 |

首轮真实运行的夹具误用 await，4 个断言虽通过，Godot 警告仍使运行器判失败。
根因是夹具把同步断言当成协程；修正夹具并澄清对应规则，未屏蔽警告。
运行摘要现在保留具体异常文字，而不是只写“存在诊断”。

直接 PowerShell 调用 GUI 版 Godot 时，最初未取得退出码。它生成的 lint 报告保留，
该次空退出码没有被当成通过。改为等待真实进程结束后分别取得解析/lint 退出 0；
文档示例使用 `| Out-Host` 等待，并已实测能取得该 GUI 程序退出码。不新增包装脚本。

静态收尾还发现原 Skill 头部的既有格式问题：4 份描述未转义冒号，5 份使用顶层
自定义属性。描述改为 YAML 折叠标量，自定义值原样放入 metadata；保留描述内容、
触发说明和正文。没有为此新增框架验证器，也没有更改未涉及流程的 Skill 职责。

当前原始记录目录：
[D:/A_Games/Game_idle_yaya_frame_test/reports/framework-simplification-20260912](D:/A_Games/Game_idle_yaya_frame_test/reports/framework-simplification-20260912)。

- `unittest-first.log`、`unittest-final.log`：工具回归。
- `godot-normal.log`：首轮夹具失败；`godot-normal-after-fixture-fix.log`：修正后正常运行。
- `godot-native-failure.log`：受控真实引擎负向回归。
- `parse-waited.log`、`lint-waited.log`、`lint-waited.json`：实际进程退出与静态结果。
- 原始 run 目录保留 `run-6lyoth_s`（夹具警告失败）、`run-8m8rw37z`（正常通过）、
  `run-l8vwondv`（故意原生错误失败）。

### 前一轮基线验证记录（af90887，非本轮结果）



实际环境：Windows 11 / PowerShell 7，Python 使用
C:\Users\89523\anaconda3\envs\codex-python\python.exe，
Godot 4.7.1.stable.official.a13da4feb。
指定测试目录为 D:\A_Games\Game_idle_yaya_frame_test。
先修维护源，再覆盖测试目录的 30 个代码/模板/说明文件；删掉测试目录两个旧静态脚本，
仅从其配置移除 static_check_cmd，保留实际 Python/Godot 路径、ready 与业务台账。
没有重新运行生成器，没有更改原游戏或创建提交。

| 检查 | 实际结果与边界 |
| --- | --- |
| 魔法数字/度量/引擎参数契约 | 真实 Godot：108 项，0 失败；修改前 5 项误报记录保留 |
| 项目工具回归 | 136 项 unittest 通过；含合成报告负向用例与真实 Windows 子进程检查，不冒充完整游戏/gdUnit Feature 实测 |
| 脚本解析 | 直接 Godot --check-only：三个项目工具 GDScript 均退出 0 |
| 项目 lint | 插件 CLI 直接检查 3 文件：Critical 0、Warning 0、Info 1；Info 为 Logger 强制八参数的说明 |
| 环境与台账 | readiness 成功；空白 Feature/Catalog strict 退出 0。没有虚构业务 Feature 或验收记录 |
| 未运行 | 新项目生成、下一 Feature、游戏场景启动、完整人工体验验收；本轮不涉及它们 |

首轮 unittest 的 7 项失败来自两组临时夹具漏复制新增依赖，1 项失败来自把变化的
Git 来源也当成必须逐字一致的运行结论，1 项错误来自测试绑定已经变化的文档表格措辞。
已补夹具依赖，并让来源与内容断言各负其责；精确文档措辞测试直接删除。
没有为通过测试修改产品要求或放宽真实失败检查，没有 sleep 或不改代码反复重跑。

原始记录：
[修改前 lint](D:/A_Games/Game_idle_yaya_frame_test/reports/framework-fixes-20260912/lint-before.json)、
[修改后 lint 契约](D:/A_Games/Game_idle_yaya_frame_test/reports/framework-fixes-20260912/lint-after.json)、
[首轮 unittest 失败](D:/A_Games/Game_idle_yaya_frame_test/reports/framework-fixes-20260912/project-tests.log)、
[修正后 unittest](D:/A_Games/Game_idle_yaya_frame_test/reports/framework-fixes-20260912/project-tests-after-fixture-fix.log)、
[直接 lint 原始报告](D:/A_Games/Game_idle_yaya_frame_test/reports/framework-fixes-20260912/lint-project.json)、
[直接脚本解析日志](D:/A_Games/Game_idle_yaya_frame_test/reports/framework-fixes-20260912/direct-script-checks.log)。

## 复盘输出

记录实际问题、依据、影响和最小建议即可。区分设计价值、实现问题和本轮未验证项。
需要整体重检时，使用提示词库中的“复盘框架设计与场景”，在详细报告中列明当前检查基线、
模块覆盖、问题详情、跨文件关系、建议处理顺序与未验证项；也可按实际问题限定范围。
输入与报告输出方式见 [整体重检与详细报告](../docs/blank-project/maintenance/updating-the-blank-project.md#整体重检与详细报告)。
用户只要求静态工作时，不因本文要求额外生成项目或执行全套检查。
旧评分只属于旧版本与旧口径，不回写旧审核，也不与当前清单进行数值排名。
用户要求保留的 Skill/流程不通过评分被动改写；确有新证据时再提出明确的改动建议。
