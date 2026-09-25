# 自研工具脚本职责全量审核

本页保留实施前基线的判断；文中行号和旧数量属于当时版本，阅读链接已指向迁移后的对应材料。实施及复验见[实际验证报告](framework-implementation-validation-2026-09-25.md)。

## 结论与检查范围

本次由独立子智能体 `audit_all_tool_scripts` 按[职责设计准则](../baselines/skill-script-prompt-design.md)完成静态审核。范围内 **55 个生产脚本及共享模块均已阅读全文**；公开命令、内部调用接口、Godot 生命周期和 DOM 事件路径分别检查，没有将抽样结论扩展为全量结论。

建议优先收窄完成记录 `show` 的职责；随后处理证据基础能力对完成聚合模块的反向依赖，以及资源分析两处重复规则。没有依据要求每个命令另建文件，也不建议把创建项目、一次分析任务或一次受管测试拆成多个要求使用者手工衔接的命令。HTML 工具仍使用旧目录，属于恢复阅读版前的已知适配工作，不应在本轮启用。

检查基线为 `8fe14d6e4f63fe824eef485d34ea6313f31ac65f`。开始检查时，生产脚本没有工作区修改；本轮新增的职责准则作为审核依据。审核者只新增本报告，没有修改被审核实现、Git 索引或提交。报告中的建议尚未实施，不自动授予实现修改权限。

范围分布：

| 位置 | 文件数 | 纳入内容 |
| --- | ---: | --- |
| `framework/commands/` | 5 | 4 个 Python 维护工具、1 个离线手册交互 JS |
| `project-source/tools/` 包入口 | 1 | 包初始化 |
| `project-source/tools/checks/` | 2 | 环境、Feature 台账检查 |
| `project-source/tools/features/` | 2 | 登记表合并、完成记录 CLI |
| `project-source/tools/lib/` | 8 | 7 个共享实现、包初始化 |
| `project-source/tools/testing/` | 4 | Python 测试入口和 3 个 GDScript 适配器 |
| `project-source/tools/asset_analyzer/` | 8 | 分析进程、算法、协议、资源限制 |
| `project-source/tools/asset_workbench/` | 25 | 工作台、预览、分析队列、界面与共享模块 |
| `project-source/skills/**/scripts/` | 0 | 实际没有此类脚本 |
| 合计 | **55** | 约 9,080 行生产实现 |

命令覆盖为下表的 **20 个 CLI 操作模式**；参数值组合不各算一个任务。另核对源码中 109 个 Python 非下划线函数/方法声明、104 个 GDScript 非下划线方法声明（含运行器内部类的两个重载）和 33 个 JS 具名函数。声明数含公共辅助实现，与 CLI 存在交集，不能相加当作场景数；匿名 DOM 回调、Godot 回调和私有实现也随所属文件阅读。

第三方插件原始实现、`project-source/components/` 的业务运行组件、测试夹具、采集脚本、`.uid` 文件不作为本专项独立审核对象。配置、HTML 模板、方法论、测试与调用方按契约判断需要查阅。**本报告不是仓库全部 GDScript、全部第三方或全部业务代码的审核报告。**

## 需要调整的职责边界

### S1：查看完成记录依赖整个完成判定，成功条件与入口名称不符

- **结论：收窄入口职责；保留同一 CLI 文件及已有 `validate` 命令。**
- 依据：[完成记录入口](../../../project-source/tools/features/record-feature-completion.py)，第 96–102 行。`_show` 先读取并打印 JSON，然后调用 `validate_completion_evidence`，根据全部适用完成条件返回 0 或 2。第 90–93 行已有专用 `_validate`。
- 影响：记录可读取，但人工验收尚未取得、测试引用失效、Git 或工作区快照不可取得时，`show` 会返回失败。该操作还会读取测试原件、Feature 定义并运行 Git 查询。与[命令说明](../../docs/operation-manual/方法与工具/commands-and-evidence.md)第 174 行的“只读查看已有记录”，以及[测试结果导入场景](<../../docs/quick-reference/Godot 项目开发/验证与收尾/测试已经通过，但填错报告路径导致导入失败.md>)中的查看步骤，存在职责表达差异。只读不等于仅查看：本项问题是查询被赋予整项验收的成功条件，并非发现了隐含写入。
- 最小改法：`show` 的输入是记录位置与预期 Feature，输出为该记录；成功以读取、结构及 Feature 身份满足查询约定为准。记录中的业务状态可显示，但待验收不构成读取失败。整项测试/人工接受的有效性继续由 `validate` 判定，不另建新的检查入口。
- 调用方影响：同步完成记录说明、两篇使用 `show` 的速查样稿；增加“可读取但未验收时 show 成功、validate 未就绪”的独立回归，并保留缺失/损坏/Feature 不符的查询失败。不能通过让 `validate` 放宽条件解决。

### S2：快照与通用原子写入处于完成聚合模块，造成反向依赖

- **结论：提取共享方法，调整实现模块归属；不拆公开工作流命令。**
- 依据：[完成依据模块](../../../project-source/tools/lib/feature_completion_evidence.py)第 28–165 行负责 Git/内容快照，第 201–214 行提供通用 JSON 原子写入，第 245–298 行聚合测试与人工接受。与此同时，[测试运行依据](../../../project-source/tools/lib/test_run_evidence.py)第 16 行、[人工验收模块](../../../project-source/tools/lib/manual_acceptance.py)第 8 行从它导入基础能力；完成聚合函数又在运行时导入这两类业务模块。
- 影响：完整完成判定本应依赖测试和人工依据，但底层运行记录、人工清单准备又依赖完成判定所在模块。当前延迟导入使代码能够组织起来；本次没有执行证据证明存在运行时循环导入故障。已存在的问题是层次方向不清：调整内容绑定或 JSON 写入，会牵涉不需要“完成判定”的调用者。
- 最小改法：将当前内容快照与通用 JSON 原子写入放到中立的共享实现，完成模块保留完成记录结构及聚合判断，运行记录和人工清单直接依赖基础能力。具体是否分为两个文件，按最终接口选择；不引入服务层、第二份状态或新证据格式。
- 保留约束：一次写入仍需关闭流后原子替换并清理临时文件；内容指纹的现有排除规则和状态语义不在本次职责调整中顺带改变。相关调用涉及完成记录 CLI、gdUnit 入口、运行记录和人工验收；需要同步[内容绑定回归](../../tests/test_documentation_fingerprint.py)、[Git 快照回归](../../tests/project/test_git_snapshot.py)、[完成依据回归](../../tests/project/test_feature_completion_evidence.py)及[人工文件回归](../../tests/test_manual_acceptance_files.py)。

### S3：分析集合在共享能力配置之外另存一份源格式规则

- **结论：合并重复规则，复用现有源文件能力模块。**
- 依据：[分组模块](../../../project-source/tools/asset_workbench/analysis_group.gd)第 16–22 行硬编码音频/图像扩展名；[能力配置](../../../project-source/tools/asset_analyzer/capabilities.json)已经声明同一组扩展名。[源文件能力模块](../../../project-source/tools/asset_workbench/analysis_source.gd)使用该配置，而[批次成员添加](../../../project-source/tools/asset_workbench/analysis_batch.gd)和[目录扫描](../../../project-source/tools/asset_workbench/analysis_group_scan.gd)调用分组模块的 `asset_type`。
- 影响：单项源检查、目录扫描和集合成员识别有两处维护源格式的事实。当前扩展名集合一致，**没有将未来可能发生的漂移写成当前已发生的格式故障**；但新增或收窄支持格式时必须同步两处，符合“同一事实重复维护”的调整信号。
- 最小改法：由 `analysis_source.gd` 基于已加载能力配置提供扩展名到类型的查询；新成员添加、扫描复用该查询。分组模块只负责成员/规则/历史结构。能力配置损坏时继续保留清楚、可重试的错误。
- 边界：历史快照校验不能因当前文件缺失或当前后端能力改变就把已有历史销毁；共享的是新来源识别，不能把“必须当前可分析”强加给所有历史记录。影响源模块、集合、扫描与[分组回归](../../tests/project/asset_analysis_group_test.gd)，需要覆盖配置改变后三个入口一致。

### S4：A/B 与集合统计分别定义可比身份

- **结论：提取共享方法，保留两个不同用途的界面与计算入口。**
- 依据：[分析结果](../../../project-source/tools/asset_workbench/analysis_result.gd)第 24–42 行定义 schema、资源类型、分析器、版本、后端、参数组成的比较身份；[集合统计](../../../project-source/tools/asset_workbench/analysis_group_statistics.gd)第 86–89 行重新组合同一组身份，再加入指标与单位。
- 影响：A/B 是否允许叠加和批量统计是否允许归为同组，应该对共同身份采用同一口径。当前两者字段一致，尚未发现现有结果被错误混组的运行证据；重复定义已使下一次身份字段调整需要两处同步。
- 最小改法：集合统计的 key 调用现有 `comparison_identity`，另追加本入口需要的指标和单位。A/B 的说明文字、图表单位检查、批量中位数与规则阈值仍各自保留。不需要为此新建一个比较服务或复制整个结果模块。
- 影响：[分析回归](../../tests/project/asset_analyzer_test.gd)中的 A/B 条件检查及[分组回归](../../tests/project/asset_analysis_group_test.gd)中的类型、版本、后端、参数和单位隔离检查；二者应共同覆盖身份变更。

### S5：保留的 HTML 生成器仍绑定旧目录，恢复前必须重新定义书籍输入

- **结论：暂缓工具保留；恢复时收窄书籍选择配置与输入契约。**
- 依据：[HTML 生成器](../../commands/build_blank_project_handbook.py)第 27–29 行指向已删除的 `framework/docs/blank-project`；`load_documents`、`Document.group`、`GROUPS` 和快速入口生成依赖旧目录及旧手册栏目，`--quick-reference` 只是旧父目录内的选择。
- 当时影响：它不能直接用于当时三类文档目录与新的 Project/分类/场景路径。按被审基线中的阅读版暂缓约定，该轮不执行构建；这不是该轮 Markdown 交付的运行失败。现行用法见[阅读版构建约定](../../docs/framework-maintenance/updating-the-blank-project.md#html-阅读版构建)，不据此改写本项历史结论。
- 恢复时最小改法：先明确每本书的输入根、输出和导航，再由一份共享 Markdown/Mermaid 渲染实现构建对应书籍。两本书的内容与导航要独立，但不需要复制渲染器和前端辅助算法。恢复工作需同步模板、JS 对场景标记的消费和[生成器回归](../../tests/test_blank_project_handbook.py)。

## CLI 操作覆盖

以下每行是一项操作模式，均检查输入、输出、允许的副作用、失败/重试与依赖。未标调整的入口结论为保留；这仅表示静态职责边界合理，不代表真实执行通过。

| # | 文件与入口 | 实际职责、终点与判断 |
| --- | --- | --- |
| C01 | [create_project.py](../../commands/create_project.py) `--output` | 检查复制映射、复制、初始化 Git 并提交，交付独立项目。失败保留现场并非回滚事务；再次执行不会覆盖非空目录。多步骤属于一个目标，保留。 |
| C02 | [export_advisor_prompt_examples.py](../../commands/export_advisor_prompt_examples.py) 默认 | 校验完整精选集合后生成示例；正文仍来源于 JSON。文件系统写入失败可部分更新，重试按内容补齐。保留。 |
| C03 | 同文件 `--check` | 只比较缺失/过期输出，不写文件；不一致返回失败。保留显式只读模式，不要求独立文件。 |
| C04 | [run_project_tool_tests.py](../../commands/run_project_tool_tests.py) `--project` | 验证外部项目边界后调用 unittest，沿用其退出码；不创建项目或示例 Feature。保留。 |
| C05 | [build_blank_project_handbook.py](../../commands/build_blank_project_handbook.py) 默认 | 解析原使用手册、链接、图表、导航，检查后写 HTML；Node/浏览器依赖仅在缺图时实际调用。保留共享构建目标，恢复前处理 S5。 |
| C06 | 同文件 `--quick-reference` | 选择原速查输入并构建独立输出；不是单次同时写两本书。恢复前处理 S5。 |
| C07 | [check-project-environment.py](../../../project-source/tools/checks/check-project-environment.py) 默认 | 只验证配置结构，不安装、不改配置、不声称真实工具已就绪。保留。 |
| C08 | 同文件 `--require-ready` | 配置校验后验证可执行文件、测试入口及 Godot 实际版本；有版本探针子进程，名称表达加强检查。保留。 |
| C09 | [check-feature-list.py](../../../project-source/tools/checks/check-feature-list.py) 默认 | 验证索引、详情、Registry 与演进引用整体一致性，只读。依赖这些文件是必要的跨文件契约，不拆成使用者手工汇总。 |
| C10 | 同文件 `--completion-feature` | 同一台账检查增加指定项当前完成约束，不导入运行证据、不写完成状态。保留，不能与完成依据 `validate` 等同。 |
| C11 | 同文件 `--eligible` | 先检查台账再列出依赖满足的 pending ID。拒绝在损坏台账上给可开工结论是本操作的必要前提；不同于单纯原文查看，保留。 |
| C12 | [merge-test-registry.py](../../../project-source/tools/features/merge-test-registry.py) `--components` | 校验候选和现有演进后只增添不冲突组件；已有相同项重试无变化；原子替换并清理临时文件。保留。 |
| C13 | [record-feature-completion.py](../../../project-source/tools/features/record-feature-completion.py) `prepare-manual` | 校验 Agent 已写的 pending 清单并绑定当前内容；不自动编写需求、不接受人工结果。重复绑定被拒绝，新的尝试使用新清单。保留。 |
| C14 | 同文件 `record-tests` | 验证整组原件并替换引用；导入失败清空旧引用、保留原件，是当前方法论明确的失效策略。保留；不能改名义上的拆分顺带取消该副作用。 |
| C15 | 同文件 `record-acceptance` | 记录明确口头决定或校验用户返回 JSON；两种输入提供同一人工决定产物，状态可以 pending/rejected，命令成功只表示记录成功。保留。 |
| C16 | 同文件 `show` | 读取与整项完成判定混合，按 S1 收窄。 |
| C17 | 同文件 `validate` | 重新核对当前内容、测试与适用人工接受，只读返回依据有效性。不是静态检查、评审或完整 Feature 交付的替代。保留。 |
| C18 | [run-gdunit-tests.py](../../../project-source/tools/testing/run-gdunit-tests.py) `--target`/默认 focused | 单次受管测试与原件记录，测试失败、超时和诊断失败统一保留失败记录；不登记完成。保留。 |
| C19 | 同文件 `--feature` | 从当前 Feature/Registry 选择 baseline/final、required/affected/full 范围，再使用同一次运行机制；合法无义务返回 not_required，不伪造通过报告。保留共享运行器。 |
| C20 | [worker.py](../../../project-source/tools/asset_analyzer/worker.py) `--request` | 一次源资源测量与缓存结果；图像/音频算法已分适配器并按类型加载依赖。退出 0 表示结构化响应成功，响应中的 failed/partial 为业务结果，由 Job 解析；不是把分析失败当测量成功。保留。 |

## 全部实现文件与接口覆盖

下表列出每个范围内文件及其接口。CLI 已在上表分项；界面上的独立动作在下一节补列。生命周期钩子与私有函数作为相关入口实现一起检查，不把它们简单计作新增任务。

### 框架维护与通用工具

| 文件 | 已核对的接口/实现 | 职责结论 |
| --- | --- | --- |
| [create_project.py](../../commands/create_project.py) | `relative_path`、`copy_project`、`create_project`、`main` | 保留；路径验证、复制和交付编排已有函数分工，CLI 只提供完整创建。 |
| [export_advisor_prompt_examples.py](../../commands/export_advisor_prompt_examples.py) | `unique_object`、`build_documents`、`export_examples`、`main` | 保留；构建内存内容和写入/检查分开，源名称变更需同步 `SELECTION`。 |
| [run_project_tool_tests.py](../../commands/run_project_tool_tests.py) | `main` | 保留；单一外部项目回归入口。 |
| [build_blank_project_handbook.py](../../commands/build_blank_project_handbook.py) | `Document.title/group`、`inline_text`、`parse_document`、`child_tokens`、`load_documents`、`section_search_text`、`render_quick_start`、`rewrite_links`、`scope_svg`、`valid_svg`、`write_cached_svg`、`render_diagrams`、`render_missing_diagrams`、`render_body`、`OutputInspector.handle_starttag`、`check_output`、`main` | S5；解析/链接/渲染/自检共同交付一本阅读版；缓存和临时目录已有明确所有者，不要求拆成多个手动命令。 |
| [blank-project-handbook-interactions.js](../../commands/blank-project-handbook-interactions.js) | `clamp/lastAt/matchesWords/searchRank/zoomAt`；`readPreference/savePreference/decodeAnchor`；`applyTypography`；`setExpanded/pinHeader/syncSidebar/closeSidebar/openSidebar/pauseSidebar/followActiveLink/filterNavigation`；`invalidateLayout/scheduleReadingUpdate/measureReading/rememberPosition/updateReading/navigateTo/followHash/captureReadingAnchor/restoreReadingAnchor`；`message/copyText/buttonFeedback`；`paintDiagram/fitDiagram/setDiagramScale/endDrag` 与 DOM 事件绑定 | 保留功能，恢复时可按排版、导航、图表生命周期封装初始化；目前同一静态页面、依赖单一、没有足够收益要求拆多个 JS 文件。S5 中的场景语义必须同步。 |
| [tools/__init__.py](../../../project-source/tools/__init__.py) | 包声明，无运行入口 | 保留；导入不执行命令。 |
| [check-project-environment.py](../../../project-source/tools/checks/check-project-environment.py) | `main` 与配置/路径/真实版本探针实现，C07–C08 | 保留；显式加强检查有明确副作用边界。 |
| [check-feature-list.py](../../../project-source/tools/checks/check-feature-list.py) | `main`、索引/详情/跨文件验证，C09–C11 | 保留；不同校验强度与资格查询明确，不写状态。 |
| [merge-test-registry.py](../../../project-source/tools/features/merge-test-registry.py) | `merge_registry`、`main`，C12 | 保留；同一对象的校验后合并，不为了只增组件而跳过演进一致性。 |
| [record-feature-completion.py](../../../project-source/tools/features/record-feature-completion.py) | `main` 与五个子命令 C13–C17 | `show` 按 S1 调整，其他入口保留；不拆成五个文件。 |
| [lib/__init__.py](../../../project-source/tools/lib/__init__.py) | 包声明，无运行入口 | 保留。 |
| [feature_evolution.py](../../../project-source/tools/lib/feature_evolution.py) | `test_identity`、`validate_registry_component`、`validate_registry`、`eligible_features`、`validate_revisions`、`validate_retirement_shape`、`referenced_test_ids`、`validate_retirements` | 保留纯计算/验证接口；Registry、Feature 演进与替代链在同一合约层交汇，不具有互相争用的写入生命周期。 |
| [feature_completion_evidence.py](../../../project-source/tools/lib/feature_completion_evidence.py) | `utc_now/git_revision/semantic_json/working_tree_fingerprint/current_snapshot`；`empty_evidence/load_evidence/write_evidence/evidence_for_snapshot`；`validate_completion_evidence` | S2；快照、存储和完成聚合已经有函数边界，但模块依赖方向应调整。 |
| [manual_acceptance.py](../../../project-source/tools/lib/manual_acceptance.py) | `report_path`、`prepare_checklist`、`read_result` | 保留清单准备与结果读取两个明确接口，前者写绑定，后者只核对原件；共享覆盖规则合理。基础能力引用受 S2 影响。 |
| [test_selection.py](../../../project-source/tools/lib/test_selection.py) | `read_json_value/read_json`、`normalized_path/deduplicate_selectors`、`acceptance_mode`、`build_selection`、`execution_selectors` | 保留选择与验收方式验证；JSON 解码已由多个台账入口复用，不另建第三份解析逻辑。 |
| [test_run_evidence.py](../../../project-source/tools/lib/test_run_evidence.py) | `file_hash/read_junit_cases/expected_gdunit_cases/verify_runtime_discovery/require_coverage`；`artifact_reference/run_history_directory/start_run/result_reference/finish_run`；`verify_run/derive_test_evidence` | 保留各接口及同一运行事实的生命周期；源码声明补查、实际发现和 JUnit 对照不互相冒充。处理 S2 的反向基础依赖。 |
| [gdunit_process.py](../../../project-source/tools/lib/gdunit_process.py) | `run_owned_process`、Windows Job 创建/归属/超时/清理实现 | 保留；启动与清理必须共用所创建的句柄，拆成无状态命令会丢失资源所有者。 |
| [gdunit_diagnostics.py](../../../project-source/tools/lib/gdunit_diagnostics.py) | `Diagnostic.describe`、`native_diagnostics`、`unexpected_diagnostics` | 保留；原生诊断解析与当前会话明确消费记录对照属于同一解释职责。 |
| [run-gdunit-tests.py](../../../project-source/tools/testing/run-gdunit-tests.py) | `main`、命令构建、单次运行/结束处理，C18–C19 | 保留；选择/进程/记录已分配给共享实现，入口只编排一次运行。 |
| [gdunit_evidence_runner.gd](../../../project-source/tools/testing/gdunit_evidence_runner.gd) | `_initialize/_finalize`；内部 `EvidenceCli.get_cmdline_args/discover_tests` 与原件写入 | 保留；适配 gdUnit 的真实发现，不重新实现测试执行。 |
| [gdunit_diagnostic_session.gd](../../../project-source/tools/testing/gdunit_diagnostic_session.gd) | `startup/shutdown`、测试阶段观察、断言消费匹配 | 保留；信号/Logger 的连接与解除由会话持有，不因开始/结束不同而拆所有者。 |
| [gdunit_diagnostic_logger.gd](../../../project-source/tools/testing/gdunit_diagnostic_logger.gd) | `open_log/write_event/close_log` 与 `_log_error` 正式回调、写锁 | 保留；只记录原始诊断，不决定 Feature 完成。 |

### 源资源分析后端

| 文件 | 已核对的接口/实现 | 职责结论 |
| --- | --- | --- |
| [worker.py](../../../project-source/tools/asset_analyzer/worker.py) | `parameters/backends/digest/analyze/read_cache/main/watch_parent` | 保留一次任务编排；参数、身份缓存、按类型适配和父进程失效清理围绕同一请求。算法不再拆进每个场景。 |
| [source_probe.py](../../../project-source/tools/asset_analyzer/source_probe.py) | `check_source/decode_error`、`AnalysisError` | 保留；事实来自共享能力配置，S3 应让 Godot 分组入口也遵循它。 |
| [schema_validation.py](../../../project-source/tools/asset_analyzer/schema_validation.py) | `finite_json/matches/validate_result` | 保留；解释现有 Schema 词汇，不另建字段规范。与 Godot 两端验证属于执行环境边界。 |
| [protocol.py](../../../project-source/tools/asset_analyzer/protocol.py) | `metric/unavailable/sequence/result/failure/validate` | 保留；统一结构化结果，缺失/不适用不填伪造数值。 |
| [memory_budget.py](../../../project-source/tools/asset_analyzer/memory_budget.py) | `limit_worker/process_memory` 与 Windows 结构 | 保留；仅绑定 worker，自身生命周期为进程，不限制调用者/Godot。 |
| [audio_adapter.py](../../../project-source/tools/asset_analyzer/audio_adapter.py) | `blocks/analyze/loudness/measure_loudness` | 保留；流式解码与独立响度预算已有算法接口，所有输出共同描述一个音频源。 |
| [audio_statistics.py](../../../project-source/tools/asset_analyzer/audio_statistics.py) | `AudioStatistics.feed/finish`、`db_metric/envelopes` 与初始化缓冲区 | 保留；累计状态与 finish 属于同一测量生命周期；第二遍包络避免保留全部信号。 |
| [image_adapter.py](../../../project-source/tools/asset_analyzer/image_adapter.py) | `analyze/measurements/palette_metrics/distribution` | 保留；分块像素统计、有限调色板采样共同输出图像测量，独立于音频依赖。 |

### Godot 工作台与分析共享层

| 文件 | 已核对的接口/实现 | 职责结论 |
| --- | --- | --- |
| [workbench.gd](../../../project-source/tools/asset_workbench/workbench.gd) | `stop_all`、场景初始化/退出与 `_dispatch_action` 全部动作 | 保留协调入口；预览、资源绑定、显式保存、独立分析已通过不同对象/动作区分，不能把协调器整体判作单一混合命令。 |
| [composition_workbench.gd](../../../project-source/tools/asset_workbench/composition_workbench.gd) | `stop_all`、父场景初始化、组合预览/当前对象/主题重载与会话切换 | 保留薄专用场景入口；复用父工作台控件而不再打开单对象场景。 |
| [composition_panel.gd](../../../project-source/tools/asset_workbench/composition_panel.gd) | `set_background/select_object/update_trial/object_name/current_object/refresh_state`；`select_all_alternatives/trigger_all/play_timeline/apply_gain/assets/save_all` | 保留独立动作；批量保存明确逐文件成功/失败，共享文件冲突先阻止该文件写入，未声称多文件事务。 |
| [preview_session.gd](../../../project-source/tools/asset_workbench/preview_session.gd) | `open/current/is_dirty/reset_current/copy_to_other/save_error/save_current/accept_matching_save` | 保留统一草稿生命周期；重置/复制只改内存，保存显式写目标并重读，文件冲突保留草稿。 |
| [asset_browser.gd](../../../project-source/tools/asset_workbench/asset_browser.gd) | `populate/stop/set_checker/selected_path/set_analysis_status/set_apply_target/audition`；绑定、分析、加入集合信号 | 保留；选择与试听不自动绑定 Cue，外部操作通过明确信号交给协调者。 |
| [cue_controls.gd](../../../project-source/tools/asset_workbench/cue_controls.gd) | `build/display/apply_to` | 保留；展示与应用分开，Shader/效果面板已有委派，只编辑支持字段。 |
| [shader_controls.gd](../../../project-source/tools/asset_workbench/shader_controls.gd) | `build/display/apply_to`、只读引用显示 | 保留；预设引用与 Cue 值区分，不写共享材质。 |
| [effect_controls.gd](../../../project-source/tools/asset_workbench/effect_controls.gd) | `build/display/apply_to`、粒子/片段可用性与只读引用显示 | 保留；两类效果共属当前 Cue 编辑，没有独立持久化或后台生命周期。 |
| [preview_backdrop.gd](../../../project-source/tools/asset_workbench/preview_backdrop.gd) | `checker_enabled`、`_ready/_draw` | 保留；局部透明网格绘制，不改变资源颜色。 |
| [workbench_layout.gd](../../../project-source/tools/asset_workbench/workbench_layout.gd) | `build/finish_preview/display_context`、响应布局、动作与外观信号 | 保留；只组织控件与呈现上下文，执行权在工作台。 |
| [workbench_theme.gd](../../../project-source/tools/asset_workbench/workbench_theme.gd) | `background/create` 与各控件样式构建 | 保留；共同开发界面主题，不混入资源测量或 Cue 数据。 |
| [workbench_widgets.gd](../../../project-source/tools/asset_workbench/workbench_widgets.gd) | `label/button/section/grid/field/show_text` | 保留；控件工厂和只读文本弹窗，无业务状态；对话框完成/取消均释放。 |
| [analysis_service.gd](../../../project-source/tools/asset_workbench/analysis_service.gd) | `submit/cancel/reserved_memory_mib`、队列推进与退出清理 | 保留；拥有任务 ID 与队列预算，明确只取消指定任务。 |
| [analysis_job.gd](../../../project-source/tools/asset_workbench/analysis_job.gd) | `start/poll/fail/cleanup`、管道/超时/输出上限/结果身份核对 | 保留；一次任务的进程、管道和短期文件由同一对象负责。 |
| [analysis_source.gd](../../../project-source/tools/asset_workbench/analysis_source.gd) | `initialize/describe/path_issue/memory_mib` | 保留源能力边界，按 S3 承接扩展名类型查询；加载失败不缓存、可重试。 |
| [analysis_schema.gd](../../../project-source/tools/asset_workbench/analysis_schema.gd) | `initialize/is_valid`、小词汇解释器与有限值检查 | 保留；执行与 Python 共用的 Schema，不能为了代码相似增加跨进程验证调用。 |
| [analysis_result.gd](../../../project-source/tools/asset_workbench/analysis_result.gd) | `failure/is_valid/comparison_identity/comparison_reason/metric_text/compare_rows/rule_messages` | S4 统一身份来源；协议辅助、显示与只读规则已有函数边界，目前无须为每个格式函数建模块。 |
| [analysis_panel.gd](../../../project-source/tools/asset_workbench/analysis_panel.gd) | `set_background/open_asset/open_results/source_status`、A/B 提交/重分析/取消/展示 | 保留专用 A/B 协调面板，结果与 Cue 草稿独立；关闭只取消它追踪的任务。 |
| [analysis_chart.gd](../../../project-source/tools/asset_workbench/analysis_chart.gd) | `display`、`_draw/_gui_input` 与图表几何函数 | 保留后端无关图表；不同单位/类型不叠加，缩放只影响本视图。 |
| [analysis_batch.gd](../../../project-source/tools/asset_workbench/analysis_batch.gd) | `busy/add_paths/remove_paths/load_group/run/cancel/snapshot/load_snapshot` | 保留批次所有权和内存集合；历史加载、运行、取消为明确接口，不取消别的单项任务。类型识别受 S3 影响。 |
| [analysis_group.gd](../../../project-source/tools/asset_workbench/analysis_group.gd) | `empty/asset_type/project_path/validation_error/read_json/write_json/snapshot_error` | S3 移出重复源格式规则；成员/规则/快照序列化保持相关。JSON 写入为显式操作，不宣称原子多文件保存。 |
| [analysis_group_scan.gd](../../../project-source/tools/asset_workbench/analysis_group_scan.gd) | `start/cancel`、分帧目录遍历、退出清理 | 保留独立有界扫描，排除链接/生成目录并保留部分发现；类型规则按 S3 复用。 |
| [analysis_group_statistics.gd](../../../project-source/tools/asset_workbench/analysis_group_statistics.gd) | `columns/checks/summary`、可比 key 与规则计算 | S4 共享身份，统计与用户阈值仍与测量分离。 |
| [analysis_group_rules.gd](../../../project-source/tools/asset_workbench/analysis_group_rules.gd) | `display`、添加/移除规则与 `edited` 信号 | 保留规则编辑器，只改集合规则，不改算法或素材。 |
| [analysis_batch_panel.gd](../../../project-source/tools/asset_workbench/analysis_batch_panel.gd) | `set_background/open_assets`、扫描/分析/比较/成员/规则/保存/历史等 UI 动作 | 保留集合面板的独立动作；复用批次、扫描、统计与现有 A/B 窗口，不引入第二个资源浏览器或任务队列。 |

## 界面与事件入口的独立判断

这些入口虽有些实现为私有回调，仍是使用者可以独立发起的操作。表中分开说明副作用，避免用“一个面板”掩盖不同动作。

| 所属界面 | 独立操作 | 判断 |
| --- | --- | --- |
| 单对象工作台 | 切 A/B；复制当前草稿；恢复当前草稿；确认后重载 | 分别修改内存选择/草稿；重载明确丢弃草稿。保留动作分工及统一 Session。 |
| 单对象工作台 | 触发一次；普通循环；快速循环；停止 | 同一播放目标的模式参数，停止沿用持有的 Timer/播放器；无需三个播放脚本。 |
| 单对象工作台 | 保存当前 Cue；打开消费场景 | 保存操作写目标并重读；打开场景只用已保存数据并独立启动实例。现有按钮已分开，不应将“打开”改为自动保存。 |
| 候选浏览器 | 筛选/选择；试听/停止；应用到对象；分析；加入批量集合 | 浏览/试听与绑定有独立入口；分析通过信号交接，不写 Cue。保留。 |
| 组合工作台 | 选择对象；全场景切 A/B；统一增益；触发全部；播放编排 | 前三者分别控制选择/草稿；后二者编排运行组件，未保存到素材。保留不同动作。 |
| 组合工作台 | 收集源资源用于分析；保存全部 | 只读收集与逐文件写入分开；保存报告部分成功并处理同一目标的不同草稿，不扩大为多人改动归属流程。 |
| 单项分析 | 打开候选；提交 A/B；强制重分析；取消；打开已有双结果 | 后者直接展示历史而不新建任务；取消只取消本面板 ID。保留。 |
| 单项分析 | 修改分析参数；修改判定阈值；选择序列/缩放 | 参数改变使已有测量提示过期，阈值只重新解释结果，图表只变视图；不要求为这些动作拆文件。 |
| 集合分析 | 加成员；移除；扫描文件夹；取消扫描 | 列表和扫描分别由 Batch/Scan 持有；扫描增量反馈有界，取消保留已有成员。保留。 |
| 集合分析 | 分析/强制重分析；取消批次；选两项对比 | 分析共用 Service；对比发送已有结果而不重复提交；取消不清理别的单项任务。保留。 |
| 集合分析 | 保存/加载集合；保存/加载历史快照 | 明确不同文件内容，加载先验证再替换，快照标示历史而不当作当前测量。继续使用相关但不同接口。 |
| 集合分析 | 添加/删除阈值规则；统计与问题显示 | 只修改/消费显式规则，不改原始 measurements，S3/S4 收拢共同事实。 |
| 离线 HTML | 排版设置/恢复默认 | localStorage 失败只影响保存，仍可本次使用；阅读锚点保持属于排版改动后的必要恢复。保留。 |
| 离线 HTML | 搜索/导航；侧栏开闭；恢复阅读位置 | 三者同用章节身份，但各有操作和状态；布局更新与阅读跟随有暂停条件。恢复时保留明确的初始化边界。 |
| 离线 HTML | 复制代码/标题链接；代码换行 | Clipboard 失败提供选择/手工复制，换行只改变布局。共享 `copyText` 合理。 |
| 离线 HTML | 展开图表；缩放/拖动；关闭 | 同一 SVG 移入后再归还，避免重复 ID；关闭释放指针捕获并恢复源高度。保留同一查看器所有者。 |

## 横向比较与不建议拆分的理由

1. **过程结果与完整完成结果需分开。** `record-acceptance` 在记录 rejected 时仍返回成功是合理契约；worker 输出结构化 failed 仍以成功响应退出也是合理契约。它们的消费者明确读取业务状态。`show` 则在已有 `validate` 的前提下把另一目标变成自己的退出码，故按 S1 调整，不能仅凭出现非零或包含状态就一律判错。
2. **现有资源所有者应保留。** `gdunit_process` 管理本次创建的进程树，`analysis_job` 管单进程/管道/短期文件，`analysis_service` 管队列，`analysis_batch` 只管自己的任务 ID。这些责任已经分层。worker 内存限制和测试进程树归属虽然都使用 Windows Job，目标与所有权不同，不宜为减少相似结构强行合并。
3. **分析算法不混在播放里。** `audio_adapter`/`image_adapter` 的依赖按类型导入；Godot UI 只接收结构化协议，不解析第三方私有输出。多个来源类型共用 worker 响应机制合理，不需要按音频/图像复制缓存、父进程监控和失败包装。
4. **共用事实应集中，跨环境执行仍可分别实现。** Python 与 GDScript 的 Schema 解释器共同读取一份 JSON、使用共同变异夹具，属于两种运行环境所需实现，不等于两份字段规范。分组扩展名规则、可比身份则在同一环境中重复定义，应按 S3/S4 合并。
5. **轻量控件函数无需逐个拆文件。** 三个属性面板的 `_number` 构建代码相似，边界均是 UI 辅助且数值约束来自 `FeedbackCue`；目前收益低于新增抽象成本，保留。不能将所有文本、格式或一行计算都提升为跨域工具。
6. **测试选择与证据核对不可互相替代。** `build_selection` 计算应执行集合；runner 产生事实；`derive_test_evidence` 核对事实与当前义务；最终完成聚合再判断适用人工接受。这些接口应保留，不合并为一个“测试成功即任务完成”的万能命令。
7. **HTML 共用代码不等于两本书互相引用。** 两个独立内容输入可用同一渲染器和交互实现；是否解耦应检查内容、导航、输出和运行依赖，不按工具文件是否共用判断。

## 按需查阅与验证边界

为核实职责，额外查阅了[项目工具说明](../../../project-source/tools/README.md)、[分析后端说明](../../../project-source/tools/asset_analyzer/README.md)、能力配置、方法论中的完成/测试/人工验收契约，以及必要的场景调用。测试文件只按相关契约读取，包括导出、复制、完成依据、分组与 worker 响应案例；**读取测试代码不等于执行测试，也不宣称全部测试已审核。**

本次未运行 unittest、pytest、Godot、资源分析 worker、项目创建或 HTML 构建，未生成外部项目，未做浏览器或人工体验验收。因此：

- S1 的结论来自函数调用和退出码的静态确定行为；未补做实际命令回归。
- S2–S4 是职责归属/重复事实的源码证据，不声称已经造成线上故障。
- 工作台停止/清理、原子替换、worker 内存约束和算法测量只核对实现，未把旧报告的通过状态当作本次运行结果。
- 上游 gdUnit、PyAV、Pillow、NumPy 等依赖内部实现未全量审核；业务运行组件的播放正确性不在本次范围。
- 全部 55 个范围内对象均已有静态职责结论；后续重构或新增脚本需重新核对受影响部分，本报告不会自动更新。

实施顺序建议为 S1 → S2 → S3/S4；S5 随已暂缓的 HTML 恢复任务处理。任何实际拆分都应同步调用方与相应回归，再据真实运行结果更新结论，不能把本次报告当作实现已完成。
