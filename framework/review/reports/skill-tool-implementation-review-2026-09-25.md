# Skill 与工具职责实现复核（2026-09-25）

本次独立静态复核发现的 **2 项 P2 均已修复并复核**：能力配置现在拒绝未支持的来源条目；生成项目的规则模板已同步单目录 Git 契约。当前范围内没有待修复的 P1／P2；静态复核不替代外部项目运行与人工验收。

## 范围与证据

- 审核者：子智能体 `/root/review_skill_tool_implementation`，未参与被审实现，只写本报告。
- 比较基准：`6c6ec2e1011d05a2a4e38c1365fe3256baab8c52` 与本轮工作区。按[职责设计准则](../baselines/skill-script-prompt-design.md)，对照此前的 [Skill 全量审核](skill-responsibility-audit-2026-09-25.md)和[脚本全量审核](script-responsibility-audit-2026-09-25.md)复核实施结果。
- 已核对全部 29 个 Skill 的本轮变更归属：2 个新增、10 个修改、17 个无正文差异。完整阅读新增正文与受影响正文、全部相关差异，追查方法论、生成项目 AGENTS／README、核心规则、模板、advisor 和复制映射。17 个未改 Skill 沿用原全量审核的职责结论，不声称本轮再次逐字重审其所有无关材料。
- 工具覆盖本轮全部被修改的完成记录、共享依据、测试运行和分析集合文件，两个新增共享模块、新增路径检查命令以及相关新增／修改回归。原审计中未改对象核对其保留理由和是否受到接口迁移影响；不把这次增量复核称作重新运行全部 55 个旧对象。
- 提示词／场景的完整语义和手册迁移另有专项审核；本报告只核对与 Skill、工具接口有关的调用方和路径工具契约。第三方库内部、用户个人安装的 Skill 不在范围内。

## 已修复发现

### P2-01：新格式分类遍历未校验的配置条目

位置：[analysis_source.gd](../../../project-source/tools/asset_workbench/analysis_source.gd)，`asset_type` 与 `_valid_capabilities`。

初次复核时，`asset_type()` 遍历 `capabilities.sources` 的全部键，并直接读取每项的 `extensions`，但是初始化只校验 `audio` 和 `image` 两项，未拒绝额外来源键。一个有效 JSON 在这两项之前包含 `"other": {}` 时，会通过初始化；分类过程访问 `other.extensions`，产生 GDScript 运行错误，而非向调用者返回可重试的配置错误。

新增的批次成员添加、目录扫描和改后的单项路径检查都依赖此函数，因此受到影响。原单项检查按已知类型访问配置，没有遍历不相关条目。此结论来自确定的源码路径，尚未运行引擎复现，不声称已有用户数据遭到破坏。

协调者已将来源字典限定为两项，配合原有 `audio`／`image` 必填内容校验，拒绝额外或替代来源。新增 `test_extra_source_type_is_rejected_before_classification_and_allows_retry` 检查有效 JSON 中的额外畸形项：成员添加和扫描返回配置错误，单项检查返回 `analyzer_config`，恢复原件后成员添加成功。已阅读修复与回归，静态缺陷关闭；该 GDScript 测试仍需在最终外部项目运行。

### P2-02：生成项目规则模板保留旧 Git 前置

位置：[project-rules.md.tmpl](../../../project-source/methodology/templates/project-rules.md.tmpl)，工作流约束中的 Git 段落。

初次复核时正文仍引用 `Git preflight, clean-worktree and task ownership`，而新的 AGENTS、Git 规则和执行循环已经改为保留实际差异、同目录续接和解决具体重叠。该模板通过[复制清单](../../project-files.json)直接成为生成项目 `docs/project-rules.md`，不是只供历史阅读的材料，因此遗漏会把旧前置继续分发给使用者。

协调者已改为检查并保留当前差异、同目录续接、暂存指定范围和创建合格逻辑提交，仍引用同一份 Git 权威正文。已读取最终段落，静态缺陷关闭；没有删掉状态检查、无关改动保护、验证或提交要求。

## Skill 审计建议逐项落实情况

| 原建议 | 本轮检查与结论 |
| --- | --- |
| S1：拆出术语维护 | 新增 [project-terminology](../../../project-source/skills/project-terminology/SKILL.md)，输入为已确认定义和授权范围，输出为唯一所属定义及链接；不改变行为、代码或 Feature。author 已删除独立术语流程并转交，方法论 01、Stage 3、两个 elicitor、advisor 和 README 同步。支持调用返回原任务，独立请求按 Git 规则完成，不制造再次授权。静态边界成立。 |
| S2：拆出本地化规格 | 新增 [design-localization-spec](../../../project-source/skills/design-localization-spec/SKILL.md)拥有语言覆盖和 locale 约定；[content-localization](../../../project-source/skills/content-localization/SKILL.md)消费已批准规格并实现资源和运行支持。方法论 00／11、review-localization 与 advisor 已分开路由；领域含义仍回到 Product／术语 owner。没有把规格通过当作译文、显示或人工语言验收。静态边界成立。 |
| S3：收窄澄清入口 | [project-clarifier](../../../project-source/skills/project-clarifier/SKILL.md)聚焦实质未决问题；已确定定义直接进入术语写入者。共享问法保留，同类独立问题按可理解的一轮收集并提供推荐，不强制多轮小问答。已有执行授权继续沿用。静态边界成立。 |
| S4：收窄 Product Bug 澄清 | [product-spec-elicitor](../../../project-source/skills/product-spec-elicitor/SKILL.md)的 description、triggers、Mode C 与常见陷阱一致限定意图缺失／矛盾／有意改变；已有明确预期的实现失败返回当前 Feature 或工程 Bug，不产生 Product 补丁、不放宽 AC。保留四模式的共同补丁协议有依据。 |
| S5：单人范围贯穿调用链 | Git 核心规则、方法论 00／03／04／07／11／12、author／plan／sync／engineering、AGENTS、README 和 advisor 已改为同目录工作，保留修改保护和独立审核安全副本。未把正常资源生命周期中的 ownership 混同为多人归属流程。P2-02 的模板遗漏已修复并复核。 |

29 个 Skill 的覆盖分组如下，各名称只计一次。

| 状态 | Skill | 本轮判断 |
| --- | --- | --- |
| 新增 2 | `project-terminology`、`design-localization-spec` | 已阅读完整正文，输入、输出、授权、写入归属及返回点明确。 |
| 实质调整 5 | `product-author`、`project-clarifier`、`product-spec-elicitor`、`content-localization`、`project-next-step-advisor` | 对照完整相关规则和调用者；沿上表 S1–S5 判断。 |
| 调用方同步 5 | `product-init-elicitor`、`feature-plan`、`feature-sync`、`engineering-change-plan`、`review-localization` | 术语／规格 owner 与同目录规则同步，来源提交前置、审批、人工接受和历史保护仍存在。 |
| 无正文差异 17 | `feature-execute`、`engineering-refactor-select`、`design-art-direction`、`design-audio-direction`、`design-ui-spec`、`design-visual-asset-spec`、`design-audio-asset-spec`、`content-asset-integration`、`diagnostics-instrumentation`、`diagnostics-performance`、`diagnostics-soak-test`、`review-code`、`review-ux`、`review-art`、`review-audio`、`review-assets`、`review-balance` | 原全量审核没有要求机械拆分；本次核对差异及相关路由影响。`feature-execute` 继续引用唯一 Stage 正文，无需复制新 Git 或术语规则。其余保留结论不等于运行或客户端触发已通过。 |

Skills 和 tools 在复制清单中均整目录复制；新增目录／模块无需追加逐项白名单。实际生成后的可用性仍需外部项目检查。

## 工具审计建议逐项落实情况

| 原建议 | 本轮检查与结论 |
| --- | --- |
| S1：查看与完成判定分离 | [record-feature-completion.py](../../../project-source/tools/features/record-feature-completion.py) 的 `show` 读取基本结构、核对 Feature 身份并输出记录，不再查询 Git 或调用完成判定。`validate` 继续执行快照、测试与适用人工依据核对。缺失、损坏、错误身份仍失败；CLI 帮助及工具说明同步。新增回归覆盖待接受记录、缺少原件／损坏 HEAD，以及错误记录不写回。 |
| S2：中立基础模块 | [verification_snapshot.py](../../../project-source/tools/lib/verification_snapshot.py)承接快照， [atomic_json.py](../../../project-source/tools/lib/atomic_json.py)承接原子写入。测试运行／人工验收直接依赖基础模块，完成聚合依赖业务依据，旧反向导入已移除。所有实际调用和测试引用已追查，没有留存 `write_evidence` 调用。 |
| S3：统一源格式规则 | 新增成员、扫描和单项来源判断均转向 `analysis_source` 的能力配置；`analysis_group` 不再硬编码扩展名。历史结构校验未加入当前来源存在／扩展名支持要求，保留历史查看。P2-01 已修复并增加明确的配置失败回归。 |
| S4：统一可比身份 | 集合统计 `_key` 调用 [comparison_identity](../../../project-source/tools/asset_workbench/analysis_result.gd)，再追加本职责所需的指标和单位。A/B 原入口保留。回归覆盖 schema、类型、分析器、版本、后端、参数、单位和字典键顺序；没有合并两个不同用途的界面。 |
| S5：HTML 输入仍是旧结构 | 本轮继续暂缓，保留生成器及相关实现符合用户决定。恢复时再适配输入、输出、导航和模板消费，不因 Markdown 迁移擅自恢复构建。这是明确未启用能力，不计作当前已验证 HTML。 |

对 S2 额外进行了内存 AST 比较：`EvidenceError`、`utc_now`、`_run_git`、`git_revision`、`_is_fingerprint_input`、`semantic_json`、`_hash_file`、`working_tree_fingerprint`、`current_snapshot` 共 9 项与 HEAD 原实现完全一致；原子写入除函数名从 `write_evidence` 改为 `write_json` 外也一致。因而本次抽取没有顺带变更原指纹排除、流程字段投影、流关闭、替换或临时文件清理逻辑。该比较是静态结构验证，不替代运行回归。

相关回归变更已阅读：`test_feature_completion_evidence.py`、`test_execution_recovery.py`、`test_git_snapshot.py`、`test_documentation_fingerprint.py`、`test_manual_acceptance_files.py`、`test_atomic_json.py` 和 `asset_analysis_group_test.gd`。新增测试检查行为或失败边界，未通过放宽 `validate` 或伪造人工接受来让 `show` 成功。

## 新路径校验工具

[check_scenario_prompt_paths.py](../../commands/check_scenario_prompt_paths.py)只从 JSON 的 Project、分类和提示词名计算 `Project/分类/名称.md`，与文件系统路径集合比较；没有读取场景正文、标题声明或元数据，也没有另存映射缓存。根级 README 和索引是仅有的导航排除项。

JSON 重复键在解码阶段被拒绝；Project／分类重复和同 Project 内跨分类同名按不区分大小写检查；非法路径名报错而不改名。输出缺少、多余、匹配数量，退出码区分一致、路径不符、输入错误。标题与正文单一职责继续由内容审核负责。

[8 项回归](../../tests/test_scenario_prompt_paths.py)覆盖不可解码正文仍可按路径匹配、错误分类／旧目录、导航排除边界、重复键、跨分类同名、非法名称、嵌套结构及退出码。其职责与用户要求一致；本审核仅阅读测试，没有把测试文件存在写成已运行通过。

## 实际运行与剩余验证

本审核没有运行 unittest／pytest、创建项目、启动 Godot、构建 HTML、调用本地化运行时或进行人工试听／体验验收。只运行了只读文件／差异检查及上述内存 AST 比较，没有修改被审原件。

协调者的独立外部目录验证应以最终源材料为准，尤其覆盖：生成项目包含两个新 Skill 和两个基础模块；查询成功但完成未就绪；严格完成条件和原件失效；配置错误恢复及历史加载；A/B 与集合身份；现有 runner、人工文件和快照回归。两项发现的修复已复核到最终源码及新增用例。

Skill 的静态路由正确不证明模型实际触发、角色客户端加载或用户语言体验通过。既有测试日志和过去的工作台运行只作历史依据；实际运行结果由对应验证报告独立记录。
