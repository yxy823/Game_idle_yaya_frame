# 实际验证证据独立复核（2026-09-25）

本轮以只读方式核对外部项目的 Git 历史、测试原件和运行日志，未发现需要修复的 P1／P2。F001 的真实失败与修复后通过、第二 Product 追加规划不推进 R000、R001 来源同步及完成历史保护均有相互一致的原件支持。本文是证据复核，不是又一轮执行，也不把自动结果写成人工验收。

## 审核范围

审核者为未参与对应实现和验证执行的子智能体 `/root/review_skill_tool_implementation`。外部项目为 `D:/A_Games/Game_idle_yaya_frame_validation_20260925`，核对生命周期提交 `d0ffe842da246d6c1adbe0dbbf60c1ad992d2703` 至 `2534903`，以及本轮维护报告、工作台原件和新路径重建记录。规则依据为[职责准则](../baselines/skill-script-prompt-design.md)和当前维护约定。

外部项目全程只读；受限原件经正常审批读取。没有重新运行 unittest、Godot、Analyzer、Feature 完成命令或构建，没有改变被审项目、原始报告或提交。运行了只读 Git 比较、JSON／JUnit 解析和已有附件的 SHA-256 核对。

源码职责及已关闭问题沿用[上一份独立实现复核](skill-tool-implementation-review-2026-09-25.md)，此次只追查后续源格式测试拆分、规则模板环境说明和报告／导航差异。提示词与场景的全部语义沿用[专项独立审核](prompt-scenario-implementation-review-2026-09-25.md)，不冒称再次逐篇审核。

## F001 的原件链

已读取外部项目 `reports/maintenance/feature-lifecycle-20260925/result.md`、`docs/progress.md`、两份历史进度、Feature／Registry／revision 台账、完成依据，以及计数器实现和测试。新实例、封顶含最大整数输入、负数拒绝和零增量的 AC 与最终三个测试一致；纯逻辑范围采用 `automated` 有实际依据。人工接受保持 `pending`、时间与绑定为空，没有把自动通过伪造成人工结论。

下表中的路径均相对外部项目 `reports/gdunit-wrapper/`。

| 运行 | 原件状态与 JUnit | 复核结论 |
| --- | --- | --- |
| `focused/run-n03ryzc_` | 1 个测试，1 次断言失败，进程退出 100 | AC01 的真实 RED；后续 GREEN 时间晚于此运行 |
| `focused/run-rsjqx517` | 引擎退出 0、1 个测试通过；wrapper 为 failed，未发现指定 `res://` 目录身份 | 调用错误被如实保留，没有算作整次成功 |
| `focused/run-chg1gara` | 1 个测试，0 失败，退出 0 | AC01 GREEN |
| `focused/run-vxp17eeo` | 2 个测试，AC02 中 10 次断言失败，退出 100 | AC02 的真实行为性 RED，不是导入失败替代 |
| `focused/run-b9fpoa3y` | 2 个测试，0 失败，退出 0 | AC02 GREEN |
| `focused/run-met9b269` | 3 个测试，AC03 中 3 次断言失败，退出 100 | AC03 的真实行为性 RED |
| `focused/run-gl1or34l` | 3 个测试，0 失败，退出 0 | AC03 GREEN |
| `F001/run-hwifwsse` | scope 为 affected，3 个测试，0 失败／跳过／flaky，退出 0 | 最终 Feature 验证通过；完成记录引用此运行 |

这 8 次运行各自的 `engine.log`、`discovery.json`、JUnit 与诊断附件均与 `result.json` 中的哈希相符；完成记录引用的最终 `result.json` 哈希也相符。最终运行与完成记录的内容指纹均为 `sha256:6cf8beba4aaba20aeb0393b0781b89b4f90a77fcab013bd093359703ee91405d`，绑定提交为真实规划提交 `854818c`，没有把后来的提交时间伪写进旧运行。

`baseline.txt` 明确显示没有自动测试义务，返回 `not_required`，没有虚构 baseline PASS。两份解析日志、完成判定 PASS 日志和 lint JSON 已读取；lint 自身记录退出 0、59 文件、0 Critical、0 Warning、389 Info。解析命令退出码由执行者的任务记录保存，日志正文只包含引擎启动信息，不能单靠“没有错误文字”重新推断其退出码。

## 锚点、追加规划与历史

通过实际 `git show` 和数据比较独立确认：

- 首次规划前的 `d0ffe84` 中 `revision_log` 为空；`854818c` 建立 R000，其 `anchor_commit` 和 `synced_at_commit` 均为 `d0ffe842da246d6c1adbe0dbbf60c1ad992d2703`。
- `c0036c1` 追加 F002 时，完整 revision 文档与首次规划后的内容一致。最终 R001 加入后，R000 整项仍与原值相同。
- 第二 Product 先在 `dcb8f9a` 定义上限 3，再在 `ec1d9e3` 提交上限 5；`0a93270` 随后修订 pending F002。实际 diff 显示需求与 AC 的相应边界变化，而不是倒改 F001。
- R001 保留原全局锚点 `d0ffe84`，同步终点为实际来源提交 `ec1d9e3`；记录明确另核对 `c0036c1` 采用的 `dcb8f9a` 来源。没有把 R000 当作尚未存在的第二 Product 已被覆盖的证据。
- `docs/features/F001.json` 在 `376c9ad` 和 `2534903` 的字节完全相同，F001 索引条目也完全相同，保留 `done` 和完成时间。F002 仍为 `pending`，未填完成时间，未实现且未声明测试通过。

读取历史记录的 `show` 输出与“新语义快照使旧依据失效”的 `validate` 日志一致。后者明确为 `NOT READY - working tree changed after verification`。原 F001 已完成的历史没有因此自动重开，旧证据也没有被重绑或改写成当前通过。

## 其他实际记录

| 对象 | 独立读取结果与证据边界 |
| --- | --- |
| 工作台首次失败 | `focused/run-tqa7b3ap`：12 套、139 用例，`test_shared_schema_corpus_matches_godot_and_rejects_nonfinite` 有两条错误；wrapper failed、进程退出 100。失败原件仍存在。 |
| 工作台最终运行 | `focused/run-fvnab7xb`：13 套、139 用例，JUnit 无失败，wrapper passed、进程退出 0。两次运行全部附件哈希均与清单相符，没有用最后一份摘要掩盖前次失败。 |
| 源格式测试拆分 | 完整读取 `asset_analysis_source_contract_test.gd`：4 项共享来源／错误恢复／额外类型拒绝／历史加载用例和独立恢复夹具；集合套件保留原统计与界面职责。外部被测副本与框架此文件字节一致。 |
| 被测关键工具 | 证据复核时，外部 `analysis_source.gd`、`verification_snapshot.py`、`atomic_json.py`、`record-feature-completion.py` 与框架源字节一致；之后最终暂存仅删除两份新增 Python 文件的末尾多余空行，不改变被测语义。 |
| 环境与 Analyzer | 环境日志包含实际 Godot `4.7.1.stable.official.a13da4feb`；后端日志为 22 项、11.785 秒、OK。 |
| 工作台 lint | `final-lint.json` 为退出 0、57 文件、0 Critical、0 Warning、376 Info，与汇总一致。F001 后来的 59 文件／389 Info 属于另一次明确区分的运行。 |
| 新路径重建 | `clean-rebuild-results.json` 的创建、导入、main、single、composition、shader、effects 共 7 项均记录退出 0；同名日志存在，未发现脚本／解析／加载错误。该副本初始 Git 提交为 `e6ab3f7036f80345bc11d2469834e96505d64418`。headless 启动不能代表视觉或听感验收。 |
| 两组 unittest | 60／174 项来自协调者本任务工具会话 57874／13622，未另存文件。汇总已明确这一点；本审核者没有读取本地运行原件，也没有重跑，不能列为我独立执行或独立验证计数的测试。 |

`clean-copy-20260925` 未取得可靠退出码的尝试没有计入成功；保留另建新路径的重建记录，未以重复使用前次缓存替代新路径检查。首次导入前无 `.godot` 的观察属于执行者现场记录，现有导入后目录无法重新证明过去的不存在状态，不能把此观察冒称本审核者亲自见证。

## researcher 客户端证据

除读取 `researcher-events.jsonl`、`researcher-final.md` 和实际调研报告外，还按指定任务定位本机 rollout 原件：`C:/Users/89523/.codex/sessions/2026/09/25/rollout-2026-09-25T22-07-40-01a0d8e4-adb7-7cf2-88e2-6d4417467752.jsonl`。

调用 `call_m6Q8cHN1iAvWQwnyf4zvpkX9` 的真实 `function_call` 名称为 `spawn_agent`，参数包含 `agent_type: researcher`、`task_name: logger_callback_research`、`fork_turns: none`；关联工具返回实例 `/root/logger_callback_research`。因此角色选择有实际调用证据，不只依赖 Agent 的自述。最终事件与报告包含目标版本的直接来源及研究边界，汇总没有将它写成本地引擎测试。

本次没有重新检索并复审 Godot API 的全部外部事实，也没有鉴定实际模型内部提示或沙箱隔离实现。此项结论限于真实角色调用、对应返回和报告存在，不扩展为所有客户端、模型触发或权限配置的保证。

## 汇总与导航增量

[实施验证汇总](framework-implementation-validation-2026-09-25.md)已补充生命周期、无缓存新路径验证、失败尝试及 unittest 原件保留位置；所列关键计数、提交与本次读取的证据一致。旧审计页增加“实施前历史基线”说明并更新阅读链接，未将旧 27／55／50／8 数量改写为当前运行结果。

根 AGENTS 与各级导航移除“等待八篇样稿讨论”的过时阶段，继续保留两本 Markdown 手册分工、统一入口和 HTML 暂缓约束。生成项目规则模板的新环境说明也与既有方法论一致：配置保存语言和可执行路径，实际观察保存在报告／Progress，不新增长期 ready 标志或命令字段。

人工听感、节奏、截尾、分组抢占和保存后体验仍未由本次自动化代作接受。F002 实施明确不在本轮范围；完成的验证条目可以从待办删除，仍需用户体验确认的具体项应保留。本报告不增加新的验证门槛，也不因文件数量要求重跑已完成验证。

## 工具组最终暂存复核

独立读取本组完整暂存差异，共 21 个文件、564 行新增、272 行删除；`git diff --cached --check` 通过。13 个工具文件与 8 个测试文件均在上述实现／验证覆盖范围内，源格式契约的 4 项测试拆分与恢复逻辑完整，末尾空行清理没有引入语义变化。未发现新增 P1／P2，未重复执行测试。

## 职责与文档组最终暂存复核

工具组已提交为 `dfde449`。后续 220 个暂存文件的集合与本轮授权和各专项审核覆盖一致：两项新增 Skill 及受影响方法／规则／advisor、提示词与 123 篇同名场景、11 个操作专题、旧迁移材料和八篇旧样稿删除、路径校验器与测试、导航和审核记录。复用未变正文的专项阅读结果，另读取最终职责差异、脚本差异、导航、基线、各审核结论和验证汇总；没有将复用结论写成重新逐篇审核全部场景。暂存检查未发现额外业务代码、生成 HTML 或机器配置。

本阶段发现并关闭一项 P2：[生成项目 README](../../../project-source/Project_README.md) 的“开发环境”和对象表仍把观察到的版本／检查命令归入三字段配置。协调者修改后，本审核者重新读取暂存差异，确认两处均限定为文档语言与 Python／Godot 路径，实际发现归初始化报告及必要 Progress，与环境方法论和已修正模板一致。

最终导航指向现有手册、准则与四份独立审核报告；旧审计保留历史版本说明，没有冒充当前状态。`framework/progress.md` 仅保留用户尚未确认的具体工作台体验，已完成的职责、工具、迁移、流程抽样及研究委派不再列作待办。当前无未关闭 P1／P2；本阶段未重新运行测试或引擎。
