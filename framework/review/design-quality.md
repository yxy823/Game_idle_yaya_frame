# 设计复盘

用于判断设计是否值得继续维护，不计算总分，也不作为项目的新增 Gate。
以 [AGENTS.md](../../AGENTS.md) 的奥卡姆剃刀、第一性原理和最小完整修改为依据。
场景责任另见 [scenario-coverage.md](scenario-coverage.md)。

## 当前基线

2026-09-12：同步验收决策与静态入口删减；静态职责判断与实际回归结果分别记录。
范围是 Windows 11 / PowerShell 7、Godot 4.7 / GDScript / gdunit4。
未重新生成项目；按用户明确授权，将修复后的代码、模板和配套说明覆盖到指定测试项目。
真实 Godot lint 契约：修改前 108 项检查中 5 项失败，修改后 108 项全部通过。
项目工具 unittest 首轮 137 项出现 8 失败、1 错误；修正夹具与失效断言、删除一项文档措辞测试后，136 项通过。
原始失败报告保留。下文区分已经执行的回归与只读设计判断，不把工具回归等同于完整游戏验收。
不以具体游戏的业务复杂度、Feature 数量或旧项目问题为设计依据。

| 部分 | 当前职责与证据 |
| --- | --- |
| 维护源 | 根 AGENTS 约束维护；`framework/` 保存复制工具、提示词和按需复盘材料 |
| 项目创建 | [create_project.py](../commands/create_project.py) 读取 [project-files.json](../project-files.json)，检查目标后复制；不渲染、配置环境、初始化 Git 或运行测试 |
| 项目使用 | 项目独立维护其文件；`Project_AGENTS.md` 在复制时改名，维护规则与项目规则分开 |
| Skill | 保留 11 项 Skill；专用脚本在对应 Skill 的 `scripts/`，调用路径随工具整理同步 |
| 共享工具 | [tools/README.md](../../project-source/tools/README.md)：`checks/` 两个检查入口；`testing/` 测试入口与三个 Godot 脚本；`lib/` 七个共享实现模块 |
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
| 状态与一致性 | 同一事实由谁维护？哪些结果可重算，哪些历史必须保存？一次修改是否要求手工同步多份结果？ | 选择来自当前台账；完成数据引用真实运行。报告链仍有多种文件，不能称为“已无状态复杂度” |
| Agent 自主性 | 是否允许在现有授权内推进、纠错？是否用脚本逐动作确认流程？ | 自动动作拦截已删除。Skill 仍保留 Stage 0–8、Bug 5.5、批准/按需求适用的验收/独立复审；这是当前明确保留边界 |
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
| 本次运行事实 | 测试 manifest、JUnit、discovery、诊断/进程/session 工件；解析/lint 的原始输出 | 保留真实执行和必要关联；不能用手填数量、旧文件时间或对话摘要冒充新通过 |
| 完成结果与人工决定 | `docs/gate-evidence.json` 引用实际运行，记录明确验收/复审结论 | 显式校验成果，不监听每次状态编辑 |
| 失败或中断的验证尝试 | 项目 Git 目录内的 `yaya-verification-attempts.json` 及执行锁 | 只服务于真实测试调用；不扩成用户对话、Agent 动作或任务续接日志 |

提示词增加了用户常用任务入口，没有新增流程引擎；正文引用现有 Skill/规则。
外部借鉴与阶段复盘先核对真实收益和已有覆盖，再判断最小沉淀；不能因提示词已列出
某场景就宣称运行覆盖通过。后续关注正文是否重复复制流程规则，及时合并相同用途。

当前最值得继续观察的是运行证据链的维护成本、Skill/规则的阅读成本、
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


## 继续排查：仍然存在的过度设计

本次按职责检查根规则、复制/验证入口、提示词、项目规则、Skill、模板、台账、
测试选择、运行器、证据和完成消费者的关系。没有把所有 Godot API 逐条重新审计，
也没有执行新的完整 Feature。判断依据是重复状态和不必要的使用成本，不是文件数量。

**结论：删除静态包装器只解决了其中一条链，框架仍存在过重设计。**
下列发现除文档措辞测试已删除外，本轮只记录建议；不借此次扫描改写用户明确要求保留的 Skill。

| 优先级 | 位置及当前行为 | 复杂度与实际代价 | 建议及需要保留的能力 |
| --- | --- | --- | --- |
| High | [run_evidence.py](../../project-source/tools/lib/run_evidence.py)、[execution_attempts.py](../../project-source/tools/lib/execution_attempts.py)、[gate_evidence.py](../../project-source/tools/lib/gate_evidence.py) | 一次测试的命令、执行身份、内容快照、结果集合被多个文件保存并交叉核对；完成前又读 Git 内的尝试链。维护一个结果格式需要同步多处，错误恢复要理解整条链 | 合并为一份运行摘要加原始测试报告；缩减重复收据和完成派生字段。保留真实退出码、漏测/零测试识别、失败记录、当前内容绑定和必要诊断 |
| Medium | [test_selection.py](../../project-source/tools/lib/test_selection.py) 的 maintenance + infrastructure 分支 | 仅凭任务分类自动要求 full；局部工具修改也被升级。已有批准的 full_suite_reasons 与组件范围足以表达真正的全局影响 | 删除分类本身触发 full 的分支，依据实际影响、组件约定或明确要求决定。相关测试仍必须执行，全局/不确定影响仍应 full |
| Medium | [execute Skill](../../project-source/skills/execute-next-feature/SKILL.md) 与 [03-execute-loop.md](../../project-source/methodology/03-execute-loop.md) | 每阶段固定更新，加上 Stage 4/6 不可翻译的精确字符串；已没有读取这些字符串授权完成的 Hook，却仍把自然语言汇报当作协议 | 保留必要进展、批准、适用的人工验收和交接，取消精确句式与不能合并汇报的要求。Skill 流程改动按用户后续选择处理 |
| Medium | [check-feature-list.py](../../project-source/tools/checks/check-feature-list.py) 的默认宽松分支与 --strict | 跨文件不一致在默认调用中降为 warning，strict 才失败；这是照顾编辑到一半/旧 Hook 的两套结论，当前调用已经是显式成果检查 | 默认执行完整检查，删除为自动逐文件 Hook 服务的降级分支和旧 Hook 测试。普通编辑过程无需每次调用它；依赖与引用检查继续保留 |
| Medium | [coding_rules.md.tmpl](../../project-source/methodology/templates/coding_rules.md.tmpl) §2.1/2.3 | 把“做一件事”默认映射为 Command 对象，并要求中间值放构造器状态、步骤拆方法。小任务容易膨胀成类与可变状态；与文件开头的避免过度设计原则冲突 | 普通操作先用清晰函数/现有方法；确有撤销、排队、重放或独立生命周期需求时再采用 Command。保留职责清楚与可测试性，不规定所有操作的对象形状 |

### 证据链为什么是首要问题

实际链路是运行器写 invocation、verdict、manifest，Godot 侧写 discovery、
session-receipt 和 diagnostics，另有 JUnit、engine.log 与 process-ownership。
项目还有 gate-evidence 与 Git 内的 yaya-verification-attempts。
文件不是因为名字不同就全部重复：JUnit 是实际断言结果，discovery 可发现漏执行，
诊断可识别引擎错误，Windows 进程控制用于超时收尾，这些有独立价值。

需要削减的是：同一命令、身份、集合和快照被反复复制，再靠多层哈希与资格判断
维持同步。该套本地文件均由同一 Agent 可写，不能据此宣称建立了独立的防伪安全边界。
保留“报告与当前内容对应、后来失败不可隐去”的目标，不等于必须保留当前文件链。
后续简化先合并记录责任，再删除失去用途的验证；不再往每层增加同步检查。

### 还需区分的两项重复

- 环境检查脚本有实际配置错误诊断价值，可以保留。但在每个 Feature 的 Stage 0
  重复启动 Godot --version，并不必然增加验证收益。建议初始化、配置/工具变化或
  真实调用失败时核对；平常读取现有路径。不要为此再建版本探测缓存。
- 同一 runner 已通过 --scope full 执行全量，full_test_cmd 仍可配置第二条“全量命令”。
  当前它由 Agent 读取、readiness 检查命令首段，runner 的选择分支并不消费它。
  这不是已证实的漏测，但造成两种全量入口的解释和配置成本。
  固定 gdunit4 范围内建议合并到现有 runner 的 scope；确有额外检查时按任务显式执行。

### 本轮发现但不应机械删除的内容

| 机制 | 判断与理由 |
| --- | --- |
| create_project.py + 相对路径清单 | KEEP：实现用户明确要求的复制/改名与目标检查；没有 Bootstrap、发布和升级系统 |
| validate_project.py | KEEP：可选地把明确的外部项目交给维护测试；不写运行资格/状态，不是每个 Feature 必经步骤。与测试上下文的少量输入检查重复优先级低 |
| gdlint.json 与插件分析器 | KEEP：提供真实 lint 配置和检查；删除包装器不等于删除检查本身 |
| gdUnit 退出/超时、进程归属与异常诊断 | KEEP 其运行责任：防止挂起、误杀无关进程及错误被成功横幅掩盖；持久化材料可随证据链简化 |
| 资源模块内对实际导入结果的检查 | KEEP：只有改资源/导入设置时才核对 Godot 实际结果；不恢复每个 Feature 的独立导入阶段 |
| 台账、Progress 与 Skills | KEEP 需求、测试映射、当前工作和必要历史；不因保留这些用途就保留精确措辞协议与重复状态 |

### 本轮覆盖与回归结果

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
用户只要求静态工作时，不因本文要求额外生成项目或执行全套检查。
旧评分只属于旧版本与旧口径，不回写旧审核，也不与当前清单进行数值排名。
用户要求保留的 Skill/流程不通过评分被动改写；确有新证据时再提出明确的改动建议。
