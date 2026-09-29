# 124 场景能力与 Skill 入口审核（2026-09-29）

本次完整检查了提示词库中的 **124 个场景**：**105 条保留、14 条补充既有 Skill 引用、5 条保留为待讨论项**。大多数共同能力已经有负责人；主要可直接改进的是把已有入口写清楚。没有专门 Skill 不等于功能缺失，也不要求每个场景对应一个新 Skill。

本报告记录入口与职责匹配结论，不新增 Skill、工作流或台账，不启用 worktree。问卷、wizard 和个人教学能力不在本轮引入范围。

## 1. 版本、范围与方法

| 项目 | 本次记录 |
| --- | --- |
| 审核起点 | `0b52a5711814ffcf1385ee8d81c4ebe6222fb57e`（`0b52a57`） |
| 本轮入口补充的变更前基线 | `94eedcc`；该版本已包含同轮先完成的 Git 规则调整 |
| 生产入口 | [framework/prompts.json](../../prompts.json) 的两个 Project，按 JSON 原顺序连续编号 1–124 |
| 覆盖数量 | `Yaya 框架维护` 16 条、`Godot 项目开发` 108 条；每条均读提示词全文及同名速查页 |
| 独立审核 A | `deferred_topics`：第 1–69 条，共 69 条；独立形成逐条结论 |
| 独立审核 B | `scenario_skill_audit_b`：第 70–124 条，共 55 条；独立形成逐条结论 |
| 汇总职责 | 协调者核对范围和安全引用；本报告合并两份原始逐条结论，不把两位审核者的分区审查说成同一内容经过双重独立复核 |

审核对象是完整提示词库，**不是 advisor 的 15 条精选表达参考**。精选参考只服务建议表达，不能代表全部使用场景，也没有用于抽样或限制此次覆盖。

两位审核者先完整读取各自范围的提示词和同名页面，再按实际职责查阅 Skill 正文、必要参考和权威规范。判断包括：要交付什么、谁负责、是否已有匹配能力、是否明确点名，以及补名是否会改变只读限制、授权、执行者或完成条件。没有以名称、目录列表或关键词命中代替正文审核。

分区结果以系统临时 JSON 传给协调者；临时文件只用于本轮合并。以下逐条结论、来源链接和范围说明已完整归档，不依赖临时文件长期存在。14 条“补引用”记录相对上述基线的最小调整范围，不表示新增能力或重新授权。

## 2. 共同能力与本轮最小调整

### 已有能力如何覆盖不同场景

| 共同能力 | 场景编号 | 当前负责人及结论 |
| --- | --- | --- |
| 原型验证 | 29–31、52 | `prototype-godot` 已覆盖视觉、玩法和技术可行性；52 保留 `feature-execute` 的所属任务职责。29–31 补名字即可，不按实验类型再建三个 Skill。 |
| 素材接入与替换 | 72–77、87–89 | 统一复用 `content-asset-integration`；音效、图片、动画、音乐和场景各有输入与运行检查，替换还要保护实际消费者。保留不同提示词，不复制共同方法。 |
| 反馈分流与原因调查 | 5、12、62–64、69 | 框架与项目各用自己的 `feedback-triage-*`、`bug-diagnosis-*`。是否成立、原因是什么、是否修复是不同目标；69 补项目分流入口，62 补原 Feature 的执行负责人。 |
| 观测、长测与性能 | 80–84 | 现有 diagnostics 系列负责取证，工程计划和执行入口负责已授权实现。临时观测、持久指标、只测量与实际优化不因使用相同工具而合并。 |
| 来源、规划与执行 | 25、32–35、45–47、51、53–58、63、65–66、81、85–86、124 | `product-author`、`feature-plan`、`feature-sync`、`engineering-change-plan`、`feature-execute` 已形成职责链，必要时使用 `product-spec-elicitor`。只补缺失名称，不新建 Goal 总流程，也不重复建立已存在的任务。 |
| 暂停、续接与交接 | 16、111–112、114–121 | `task-handoff-*` 保存停点或准备交接；接收方继续由原任务的 Skill 执行。研究续接仍用原研究方式，审核续接保留原独立审核范围，不能用交接入口代替执行。 |
| 专业规格与独立审核 | 36–43、78–79、90、94–101、110 | 设计、内容接入和 review 系列各自已有入口；审核不接管制作。`review-code` 已支持无 Feature、无差异的模块现状审核，不需要另建一个泛泛的“主动找坏代码”入口。 |
| 文档、知识与术语 | 28、67、113、123 | 项目写作和术语 Skill 已有职责；113、123 补写作入口，状态历史、知识条目和术语的正式规范继续拥有正文。67 的行为规则修改不能仅由普通技术写作 Skill 决定。 |
| 复盘与后续固化 | 13、122、124 | `development-retro-*` 基于证据提出改进；确认后的知识写入或工具实施交回原有负责者。复盘返回不自动授权规则修改或创建脚本。 |

框架维护没有一个专门覆盖所有审核的通用 Skill，这本身不是缺陷。8–10 的框架静态审核已有范围和规范；不能为了补齐名称，把 Godot 项目的 `review-code` 套到框架维护仓库。`project-source/` 在框架中是分发源，只有11明确到外部项目验证时才使用项目开发流程。

### 14 条入口补充

| 编号 | 最小补充 | 必须保留的边界 |
| --- | --- | --- |
| 29、30、31 | 点名 `prototype-godot`，同名场景页补相应链接 | 仍是指定问题的最小原型；保留范围、预算、环境和真实观察要求 |
| 47 | 由 `feature-execute` 承接人工结果，再沿原 Goal 的来源、规划与执行入口继续 | 不把一个 Feature 的执行入口当作整个 Goal 的唯一负责人 |
| 62 | 点名 `feature-execute` 在原 Feature 内修复 | 保留原因调查、用户实际验收及本场景明确提交许可，不另建交付前 Bug 任务 |
| 69 | 点名 `feedback-triage-godot`，同名场景页补链接 | 只读判断冲突应修复在哪里，不自动修改文档或实现 |
| 70 | 按缺口分别点名视觉、音频 asset-spec Skill | 已有规格直接引用，不重新设计共享方向 |
| 81 | 持久指标确需独立 maintenance 规划时点名 `engineering-change-plan` | 复用已有任务，不因补名重复立项 |
| 85、86 | 点名已有任务的 `feature-execute` | 分别保留不需旧数据与必须转换旧数据的契约，不擅加兼容义务或放宽数据保护 |
| 113、123 | 点名 `technical-documentation-writing-godot` | 只改善已授权文档，状态和知识正文仍归现有规范 |
| 121 | 代码范围条件式点名 `review-code`，其他范围沿原专业审核方法 | 不把全部审核改成代码审核，不因续接丢失独立性 |
| 124 | 未规划时用 `engineering-change-plan`，已有任务或规划后用 `feature-execute` | 不重复规划，不改变已确认的固化范围和真实工具验证 |

## 3. 只保留四类后续讨论

这些是可能改善调用便利性的入口候选，现有功能均已有规范或工具承接；本报告不把建议当作创建授权。

| 讨论项 | 对应场景 | 值得讨论什么 | 不能借此改变什么 |
| --- | --- | --- | --- |
| 环境维护入口 | 20–23 | 是否用一个轻量入口按配置、更新、失效恢复、首次资源扫描读取已有环境规范 | 不新增自动探测或配置台账，不把首次扫描设为每轮前置，不重复已有工具契约 |
| 限定验证入口 | 91、92、93、109 | 是否提供只执行所请求解析/lint、既有测试或真实场景检查的入口 | 不建立 Feature，不自动修复或标记完成，也不是每次强制跑三类验证 |
| 人工验收与验证证据维护 | 102–108 | 是否需要窄入口；人工清单/结果记录和测试原件/过期证据恢复是否应分开 | 不伪造用户接受，不因修复报告路径就全量重跑，不因恢复证据就完成整个 Feature |
| 架构调查的执行者 | 60 | 保留当前 Agent 的专项调查，还是采用 `review-code` 的独立现状审核 | `review-code` 要求 fresh 独立审核者，不能仅补名称而静默换执行者；也不能把只读调查改为重构实施 |

逐条表中的5条“待讨论”对应20–23和60，因为这两组直接影响是否采用新入口或更换执行者。91–93、102–109当前窄任务仍准确，因此结论为“保留”；把它们列为将来可讨论的入口便利性，不等于现有场景有缺陷。

## 4. 124 条逐项结论

编号沿提示词 JSON 原顺序，仅用于本次报告定位，不新增场景 ID 或运行台账。场景名称链接到实际同名速查页；“无专门 Skill”表示由现有规范、工具或当前 Agent 判断承接，并不表示能力缺失。“补引用”说明本次最小调整，“待讨论”不授权实施。

### Yaya 框架维护 / 设计与借鉴

| 编号 | 同名场景 | 能力与已有 Skill | 决定 | 具体理由 |
| --- | --- | --- | --- | --- |
| 1 | [想给框架增加一项能力，先判断是否值得做](<../../docs/quick-reference/Yaya 框架维护/设计与借鉴/想给框架增加一项能力，先判断是否值得做.md>) | 框架能力取舍与职责设计；现有规范／命令（无专门 Skill） | 保留 | 先判断能力是否必要、归属和最小做法；尚无既定方案时不强行调用 plan-review-yaya，也不把讨论转成实施。 |
| 2 | [新增能力的方案已确定，现在修改框架](<../../docs/quick-reference/Yaya 框架维护/设计与借鉴/新增能力的方案已确定，现在修改框架.md>) | 框架能力实施与分发维护；现有规范／命令（无专门 Skill） | 保留 | 方案已确认，按框架维护规范修改和验证；项目分发源只作为被维护材料，不能用 feature-execute 启动生成项目流程。指令改动已由根入口按条件路由 writing-for-agents-yaya。 |
| 3 | [看到外部框架的一个设计，先判断是否适合借鉴](<../../docs/quick-reference/Yaya 框架维护/设计与借鉴/看到外部框架的一个设计，先判断是否适合借鉴.md>) | 外部设计适配判断；现有规范／命令（无专门 Skill） | 保留 | 比较外部设计解决的问题与本框架边界，尚未授权引入；不将普通借鉴评估改为执行或强制独立方案审核。 |
| 4 | [已经选定外部设计，现在引入框架](<../../docs/quick-reference/Yaya 框架维护/设计与借鉴/已经选定外部设计，现在引入框架.md>) | 已确认外部设计的框架适配；现有规范／命令（无专门 Skill） | 保留 | 引入已选设计并核对实际职责、分发与验证；仍由框架维护入口承接，不以项目开发 Skill 替代框架流程。 |

### Yaya 框架维护 / 维护与复盘

| 编号 | 同名场景 | 能力与已有 Skill | 决定 | 具体理由 |
| --- | --- | --- | --- | --- |
| 5 | [框架出现可复现问题，需要修复](<../../docs/quick-reference/Yaya 框架维护/维护与复盘/框架出现可复现问题，需要修复.md>) | 框架异常诊断与修复；[bug-diagnosis-yaya](<../../../.agents/skills/bug-diagnosis-yaya/SKILL.md>) | 保留 | 提示词已在原因未明时引用诊断入口；诊断交付证据后仍按原授权继续框架修复，不把 Skill 返回当成任务结束。 |
| 6 | [框架中两套机制重复，需要合并或删减](<../../docs/quick-reference/Yaya 框架维护/维护与复盘/框架中两套机制重复，需要合并或删减.md>) | 框架重复机制合并；现有规范／命令（无专门 Skill） | 保留 | 目标是已识别重复机制的合并或删减，属于框架实施；受影响指令按根入口使用 writing-for-agents-yaya，无需另造重构 Skill 或启用 Godot Feature。 |
| 7 | [框架文件位置混乱，需要整理目录](<../../docs/quick-reference/Yaya 框架维护/维护与复盘/框架文件位置混乱，需要整理目录.md>) | 框架目录及引用迁移；现有规范／命令（无专门 Skill） | 保留 | 已有明确整理目标，需追踪全部读写方、复制路径和引用；现有维护规范负责这些边界，缺少专门 Skill 不是缺陷。 |
| 8 | [框架里的例外越来越多，先找能从源头删掉的冗余设计](<../../docs/quick-reference/Yaya 框架维护/维护与复盘/框架里的例外越来越多，先找能从源头删掉的冗余设计.md>) | 框架简化专项静态审核；现有规范／命令（无专门 Skill） | 保留 | 审核对象是例外和冗余机制，当前只读调查与独立审核要求足够；plan-review-yaya 检验既有方案，review-code 属于 Godot 项目，都不应硬套。 |
| 9 | [想检查本地框架是否自洽，先做静态审核](<../../docs/quick-reference/Yaya 框架维护/维护与复盘/想检查本地框架是否自洽，先做静态审核.md>) | 框架本地自洽静态审核；现有规范／命令（无专门 Skill） | 保留 | 检查本地当前框架的一致性，保持既有独立审核和只读边界；不能用生成项目的 review-code 代替框架审核。 |
| 10 | [想请独立 Agent 审核 GitHub 上的框架快照](<../../docs/quick-reference/Yaya 框架维护/维护与复盘/想请独立 Agent 审核 GitHub 上的框架快照.md>) | 框架远程快照独立静态审核；现有规范／命令（无专门 Skill） | 保留 | 固定远程快照和实际读取范围，与本地工作区审核的输入边界不同；不能假定远端审核 Agent 拥有当前本地 Skill。 |
| 11 | [想用一个小任务实际验证框架流程](<../../docs/quick-reference/Yaya 框架维护/维护与复盘/想用一个小任务实际验证框架流程.md>) | 外部项目真实流程验证；[product-author](<../../../project-source/skills/product-author/SKILL.md>)、[feature-plan](<../../../project-source/skills/feature-plan/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 已明确通过指定外部项目的小任务验证完整项目流程；这些 Skill 只在外部项目执行，未把其流程启用到框架维护仓库。 |
| 12 | [收到外部审核意见，先核实哪些值得修改](<../../docs/quick-reference/Yaya 框架维护/维护与复盘/收到外部审核意见，先核实哪些值得修改.md>) | 外部审核反馈核实；[feedback-triage-yaya](<../../../.agents/skills/feedback-triage-yaya/SKILL.md>) | 保留 | 已有反馈核实入口，区分问题是否成立、证据和改法，不把外部报告直接视为修改授权。 |
| 13 | [实际开发遇到问题，想判断框架是否需要改进](<../../docs/quick-reference/Yaya 框架维护/维护与复盘/实际开发遇到问题，想判断框架是否需要改进.md>) | 框架维护开发复盘；[development-retro-yaya](<../../../.agents/skills/development-retro-yaya/SKILL.md>) | 保留 | 已有基于实际执行证据的复盘入口；仅提出最小改法和归属，不自动加规则、脚本或新报告。 |
| 14 | [框架刚改完，只检查文件和引用](<../../docs/quick-reference/Yaya 框架维护/维护与复盘/框架刚改完，只检查文件和引用.md>) | 框架变更静态验证；现有规范／命令（无专门 Skill） | 保留 | 文件、路径和引用检查是限定验证任务；现有规范和工具已足够，不应借诊断或原型 Skill 扩大到运行项目。 |
| 15 | [框架刚改完，在指定外部项目验证工具行为](<../../docs/quick-reference/Yaya 框架维护/维护与复盘/框架刚改完，在指定外部项目验证工具行为.md>) | 外部项目工具回归验证；现有规范／命令（无专门 Skill） | 保留 | 在指定外部项目核对本次版本后执行授权的工具回归；测试与构建规范是权威正文，无需强制走交付或新 Skill。 |
| 16 | [框架任务还没做完，准备换一个对话继续](<../../docs/quick-reference/Yaya 框架维护/维护与复盘/框架任务还没做完，准备换一个对话继续.md>) | 框架未完成任务交接；[task-handoff-yaya](<../../../.agents/skills/task-handoff-yaya/SKILL.md>) | 保留 | 已显式调用交接入口并核对真实停点、授权和恢复动作；不自动创建新对话或替接收方继续执行。 |

### Godot 项目开发 / 项目创建与接入

| 编号 | 同名场景 | 能力与已有 Skill | 决定 | 具体理由 |
| --- | --- | --- | --- | --- |
| 17 | [旧项目想采用当前框架，先评估复制迁移方案](<../../docs/quick-reference/Godot 项目开发/项目创建与接入/旧项目想采用当前框架，先评估复制迁移方案.md>) | 旧项目复制迁移评估；现有规范／命令（无专门 Skill） | 保留 | 评估复制迁移范围与保护项，保留只读和未获执行授权的边界；不同于原地替换，不合并为含糊通用入口。 |
| 18 | [复制迁移方案已确定，现在迁移旧项目](<../../docs/quick-reference/Godot 项目开发/项目创建与接入/复制迁移方案已确定，现在迁移旧项目.md>) | 旧项目复制迁移实施；现有规范／命令（无专门 Skill） | 保留 | 已确认复制迁移后按实际新旧目录和保留边界实施；现有专用场景足够，不要求建立额外 Skill 或项目 Feature。 |
| 19 | [准备开始新游戏，先创建空白项目](<../../docs/quick-reference/Godot 项目开发/项目创建与接入/准备开始新游戏，先创建空白项目.md>) | 空白项目创建；现有规范／命令（无专门 Skill） | 保留 | 现有创建器拥有复制与初始仓库职责，提示词直接指向工具；一次创建动作不需要新增一层 Skill。 |
| 20 | [空白项目已经创建，现在配置开发环境](<../../docs/quick-reference/Godot 项目开发/项目创建与接入/空白项目已经创建，现在配置开发环境.md>) | Godot 项目环境配置；现有规范／命令（无专门 Skill） | 待讨论 | 与21–23共享环境维护能力，当前由 methodology/05 与现有配置工具承接且可用；可讨论一个按子任务读取规范的环境入口，不能因没有 Skill 就认定流程有缺陷。 |
| 21 | [工具位置或版本变了，需要更新项目环境](<../../docs/quick-reference/Godot 项目开发/项目创建与接入/工具位置或版本变了，需要更新项目环境.md>) | Godot 项目环境更新；现有规范／命令（无专门 Skill） | 待讨论 | 与20、22、23形成可复用环境维护组；若建入口须保留只更新实际变更工具、复用有效配置与验证的边界，不新增探测或状态台账。 |
| 22 | [配置中的工具路径失效了，需要恢复可用环境](<../../docs/quick-reference/Godot 项目开发/项目创建与接入/配置中的工具路径失效了，需要恢复可用环境.md>) | Godot 项目环境恢复；现有规范／命令（无专门 Skill） | 待讨论 | 与环境配置和更新共用规范，但触发是已失效路径；可讨论同一环境 Skill 的恢复分支，不能擅自扩大搜索、换工具或重置配置。 |
| 23 | [第一次运行项目，Godot 还没有完成资源扫描](<../../docs/quick-reference/Godot 项目开发/项目创建与接入/第一次运行项目，Godot 还没有完成资源扫描.md>) | Godot 首次资源扫描；现有规范／命令（无专门 Skill） | 待讨论 | 可作为环境维护入口的明确分支，仍遵循真实首次扫描和既有工具契约；不能把首次扫描变成每个任务的固定前置。 |

### Godot 项目开发 / 需求设计

| 编号 | 同名场景 | 能力与已有 Skill | 决定 | 具体理由 |
| --- | --- | --- | --- | --- |
| 24 | [方案有一个外部问题没确定，需要查资料](<../../docs/quick-reference/Godot 项目开发/需求设计/方案有一个外部问题没确定，需要查资料.md>) | 按需外部研究；现有规范／命令（无专门 Skill） | 保留 | 现有 researcher 是 Agent 角色而非 Skill；当前 Agent 或 researcher 按问题范围查证即可，不因目录中没有同名 Skill 新增重复研究入口。 |
| 25 | [功能已经写出来，需要补齐需求和任务记录](<../../docs/quick-reference/Godot 项目开发/需求设计/功能已经写出来，需要补齐需求和任务记录.md>) | 已有实现的来源与计划补录；[product-author](<../../../project-source/skills/product-author/SKILL.md>)、[feature-plan](<../../../project-source/skills/feature-plan/SKILL.md>)、[feature-sync](<../../../project-source/skills/feature-sync/SKILL.md>) | 保留 | 已分别使用来源写作、首次规划或已有计划同步；补记录不冒充补验收，也不重建虚假的执行历史。 |
| 26 | [拿到一份外部需求，先整理成项目可用的草稿](<../../docs/quick-reference/Godot 项目开发/需求设计/拿到一份外部需求，先整理成项目可用的草稿.md>) | 外部需求只读整理；现有规范／命令（无专门 Skill） | 保留 | 任务明确只形成可讨论草稿，禁止正式写入或启动流程；可阅读相关 Skill 理解归属，但不能补 product-author 调用而改变只读边界。 |
| 27 | [有一个项目问题没想清楚，先讨论](<../../docs/quick-reference/Godot 项目开发/需求设计/有一个项目问题没想清楚，先讨论.md>) | 项目普通需求澄清；[project-clarifier](<../../../project-source/skills/project-clarifier/SKILL.md>) | 保留 | 已显式调用普通澄清入口，输出结论后交由权威文档负责者处理，不代替 Product 或 Feature 规划。 |
| 28 | [项目里同一个词有不同理解，需要统一并记录](<../../docs/quick-reference/Godot 项目开发/需求设计/项目里同一个词有不同理解，需要统一并记录.md>) | 项目术语澄清与维护；[project-clarifier](<../../../project-source/skills/project-clarifier/SKILL.md>)、[project-terminology](<../../../project-source/skills/project-terminology/SKILL.md>) | 保留 | 已有含义未定时先澄清、确定后维护术语的分工；术语归项目 docs/terminology.md，不复制为其他台账。 |
| 29 | [界面效果还没确定，先用真实素材试一下](<../../docs/quick-reference/Godot 项目开发/需求设计/界面效果还没确定，先用真实素材试一下.md>) | 视觉原型验证；[prototype-godot](<../../../project-source/skills/prototype-godot/SKILL.md>) | 补引用 | 现有原型 Skill 明确覆盖真实素材下的布局、尺寸和色彩验证，提示词和场景页尚未点名；补入口即可，保留实验范围和用户实际观察。 |
| 30 | [玩法效果还没确定，先做小实验](<../../docs/quick-reference/Godot 项目开发/需求设计/玩法效果还没确定，先做小实验.md>) | 玩法原型验证；[prototype-godot](<../../../project-source/skills/prototype-godot/SKILL.md>) | 补引用 | 原型 Skill 已覆盖小型逻辑与玩法实验；补名称即可复用按需方法，不增加正式 Feature 交付或默认生产代码保留。 |
| 31 | [技术方案是否可行还不确定，先做验证](<../../docs/quick-reference/Godot 项目开发/需求设计/技术方案是否可行还不确定，先做验证.md>) | 技术可行性原型验证；[prototype-godot](<../../../project-source/skills/prototype-godot/SKILL.md>) | 补引用 | prototype-godot 正文明确接受技术可行性问题，methodology/01 有 scoped logic prototypes；可安全补引用，保留版本、环境和失败标准。 |
| 32 | [已有 GDD，需要预拆分 Product 交付范围](<../../docs/quick-reference/Godot 项目开发/需求设计/已有 GDD，需要预拆分 Product 交付范围.md>) | 从 GDD 预拆 Product；[product-author](<../../../project-source/skills/product-author/SKILL.md>)、[product-spec-elicitor](<../../../project-source/skills/product-spec-elicitor/SKILL.md>) | 保留 | 已由 product-author 维护交付范围、按需 elicitor 深入检验；本场景只预拆轮廓，不提前详细化未来全部 Product。 |
| 33 | [Product 已预拆分，准备细化当前交付范围](<../../docs/quick-reference/Godot 项目开发/需求设计/Product 已预拆分，准备细化当前交付范围.md>) | 当前 Product 需求细化；[product-author](<../../../project-source/skills/product-author/SKILL.md>)、[product-spec-elicitor](<../../../project-source/skills/product-spec-elicitor/SKILL.md>) | 保留 | 现有职责是细化当前交付范围，深问方法已有条件入口；与预拆和 Feature 规划区别清楚。 |
| 34 | [已有模块的玩法要求变了，需要更新需求](<../../docs/quick-reference/Godot 项目开发/需求设计/已有模块的玩法要求变了，需要更新需求.md>) | 已有玩法需求变更；[product-author](<../../../project-source/skills/product-author/SKILL.md>)、[product-spec-elicitor](<../../../project-source/skills/product-spec-elicitor/SKILL.md>) | 保留 | 先更新当前权威玩法来源并核对实际影响，已通过原有作者和按需澄清方法处理；不直接改 Feature 执行状态。 |
| 35 | [想增加一个独立玩法模块，需要确定边界和顺序](<../../docs/quick-reference/Godot 项目开发/需求设计/想增加一个独立玩法模块，需要确定边界和顺序.md>) | 新独立玩法模块的范围与顺序；[product-author](<../../../project-source/skills/product-author/SKILL.md>)、[product-spec-elicitor](<../../../project-source/skills/product-spec-elicitor/SKILL.md>) | 保留 | 新增模块由原有来源和 Product 负责者确认边界顺序，按需检验拆分；保留只细化当前范围的原则。 |
| 36 | [当前资产的美术方向不明确，需要定下来](<../../docs/quick-reference/Godot 项目开发/需求设计/当前资产的美术方向不明确，需要定下来.md>) | 美术方向确立；[design-art-direction](<../../../project-source/skills/design-art-direction/SKILL.md>) | 保留 | 专职方向 Skill 已明确引用并拥有相应权威文档；不让资产规格或原型验证替代方向决定。 |
| 37 | [当前模块的声音风格不明确，需要定下来](<../../docs/quick-reference/Godot 项目开发/需求设计/当前模块的声音风格不明确，需要定下来.md>) | 声音方向确立；[design-audio-direction](<../../../project-source/skills/design-audio-direction/SKILL.md>) | 保留 | 已用声音方向入口，按当前模块确定风格与边界；后续文件清单另有 asset-spec 负责者。 |
| 38 | [玩家要做什么已确定，需要设计界面和交互](<../../docs/quick-reference/Godot 项目开发/需求设计/玩家要做什么已确定，需要设计界面和交互.md>) | 界面与交互规格设计；[design-ui-spec](<../../../project-source/skills/design-ui-spec/SKILL.md>) | 保留 | 已有 UI 规格作者，输入是确定的玩家任务；规格产物和后续可点击原型职责分离且无入口缺失。 |
| 39 | [已确认的界面要求要变，需要更新规格并明确影响](<../../docs/quick-reference/Godot 项目开发/需求设计/已确认的界面要求要变，需要更新规格并明确影响.md>) | 界面与交互规格变更；[design-ui-spec](<../../../project-source/skills/design-ui-spec/SKILL.md>) | 保留 | 继续由原作者更新已确认规格并说明影响；不会因同属 UI 就转去原型或执行 Skill。 |
| 40 | [声音用途已确定，需要列出音频文件准备要求](<../../docs/quick-reference/Godot 项目开发/需求设计/声音用途已确定，需要列出音频文件准备要求.md>) | 音频文件规格准备；[design-audio-asset-spec](<../../../project-source/skills/design-audio-asset-spec/SKILL.md>) | 保留 | 已使用音频资产规格入口，声音用途与方向已有来源；不重复创建风格文档或实际生产音频。 |
| 41 | [图片用途已确定，需要列出视觉文件准备要求](<../../docs/quick-reference/Godot 项目开发/需求设计/图片用途已确定，需要列出视觉文件准备要求.md>) | 视觉文件规格准备；[design-visual-asset-spec](<../../../project-source/skills/design-visual-asset-spec/SKILL.md>) | 保留 | 已使用视觉资产规格入口，按确认用途准备文件要求；与美术方向和界面规格分工一致。 |
| 42 | [已确认的美术方向要调整，需要更新规范并检查影响](<../../docs/quick-reference/Godot 项目开发/需求设计/已确认的美术方向要调整，需要更新规范并检查影响.md>) | 美术方向变更；[design-art-direction](<../../../project-source/skills/design-art-direction/SKILL.md>) | 保留 | 仍由美术方向 Skill 更新权威规范和影响范围；不把规范变更直接当成资产返工执行授权。 |
| 43 | [已确认的声音方向要调整，需要更新规范并检查影响](<../../docs/quick-reference/Godot 项目开发/需求设计/已确认的声音方向要调整，需要更新规范并检查影响.md>) | 声音方向变更；[design-audio-direction](<../../../project-source/skills/design-audio-direction/SKILL.md>) | 保留 | 仍由声音方向 Skill 更新规范并说明影响；既有来源更新和任务同步边界正确。 |
| 44 | [实现前发现设计边界不清，先确定最小方案](<../../docs/quick-reference/Godot 项目开发/需求设计/实现前发现设计边界不清，先确定最小方案.md>) | 实现前的最小技术方案；现有规范／命令（无专门 Skill） | 保留 | methodology/10 已负责模块边界、调用者义务和最小方案；这里要形成必要设计，不是只审核一份既有方案，不能直接换成 plan-review-godot。 |

### Godot 项目开发 / 日常开发

| 编号 | 同名场景 | 能力与已有 Skill | 决定 | 具体理由 |
| --- | --- | --- | --- | --- |
| 45 | [已有实现和任务已对齐，现在补验证并办理交付](<../../docs/quick-reference/Godot 项目开发/日常开发/已有实现和任务已对齐，现在补验证并办理交付.md>) | 已有实现的验证与正式交付；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 已明确进入执行入口补当前真实验证和交付证据；不伪造过去阶段，不重复做有效工作。 |
| 46 | [Product 范围已确定，想自动推进到首次人工验收](<../../docs/quick-reference/Godot 项目开发/日常开发/Product 范围已确定，想自动推进到首次人工验收.md>) | 跨入口连续推进 Goal；[product-author](<../../../project-source/skills/product-author/SKILL.md>)、[product-spec-elicitor](<../../../project-source/skills/product-spec-elicitor/SKILL.md>)、[feature-plan](<../../../project-source/skills/feature-plan/SKILL.md>)、[feature-sync](<../../../project-source/skills/feature-sync/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 已有来源、规划、同步和执行职责链；Goal 是持续目标而非另一套执行 Skill，首次人工验收停点仍来自现有规范。 |
| 47 | [人工验收已有结果，继续原 Goal](<../../docs/quick-reference/Godot 项目开发/日常开发/人工验收已有结果，继续原 Goal.md>) | 人工验收后续接 Goal；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>)、[feature-plan](<../../../project-source/skills/feature-plan/SKILL.md>)、[product-author](<../../../project-source/skills/product-author/SKILL.md>) | 补引用 | 场景页已有 feature-execute 承接当前 Feature、再按原 Goal 继续的分工，提示词未点名；补执行入口同时保留后续原有来源和规划入口。 |
| 48 | [想知道项目现在做到哪里](<../../docs/quick-reference/Godot 项目开发/日常开发/想知道项目现在做到哪里.md>) | 项目状态查询与下一步建议；[project-next-step-advisor](<../../../project-source/skills/project-next-step-advisor/SKILL.md>) | 保留 | 已有只读状态入口，按实际记录报告进展；查询授权不转为实现。 |
| 49 | [想了解项目当前进度，并确定下一步](<../../docs/quick-reference/Godot 项目开发/日常开发/想了解项目当前进度，并确定下一步.md>) | 项目状态与下一步选择；[project-next-step-advisor](<../../../project-source/skills/project-next-step-advisor/SKILL.md>) | 保留 | 已有建议入口，读取来源后给可执行下一步及边界；不把建议当实施许可。 |
| 50 | [收到 Codex 的回复，想判断并写出下一条指令](<../../docs/quick-reference/Godot 项目开发/日常开发/收到 Codex 的回复，想判断并写出下一条指令.md>) | 判断 Codex 回复并拟下一条指令；[project-next-step-advisor](<../../../project-source/skills/project-next-step-advisor/SKILL.md>) | 保留 | 已有 advisor 负责解释回复和给可复制指令；不承担目标任务执行或建立新协调流程。 |
| 51 | [Feature 已规划并可开始，现在实施这一项](<../../docs/quick-reference/Godot 项目开发/日常开发/Feature 已规划并可开始，现在实施这一项.md>) | 已规划 Feature 实施；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 执行 Skill 已明确引用，负责当前 Feature 逐行为实现、验证及适用交付；没有重复新入口的必要。 |
| 52 | [界面布局已经确定，想先做一个能点击的原型](<../../docs/quick-reference/Godot 项目开发/日常开发/界面布局已经确定，想先做一个能点击的原型.md>) | Feature 内可点击 UI 原型；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>)、[prototype-godot](<../../../project-source/skills/prototype-godot/SKILL.md>) | 保留 | 已明确由 feature-execute 保持当前 Feature 归属，prototype-godot 提供原型方法；不是脱离已规划任务另建实验。 |

### Godot 项目开发 / 任务规划

| 编号 | 同名场景 | 能力与已有 Skill | 决定 | 具体理由 |
| --- | --- | --- | --- | --- |
| 53 | [当前模块的需求已确认，准备做项目的第一份 Feature 计划](<../../docs/quick-reference/Godot 项目开发/任务规划/当前模块的需求已确认，准备做项目的第一份 Feature 计划.md>) | 第一份 Feature 计划；[feature-plan](<../../../project-source/skills/feature-plan/SKILL.md>) | 保留 | 已由 feature-plan 从当前已确认模块来源规划可验证工作；不会预拆尚未确认的后续需求。 |
| 54 | [前一个模块已完成，准备规划下一个 Product](<../../docs/quick-reference/Godot 项目开发/任务规划/前一个模块已完成，准备规划下一个 Product.md>) | 下一个 Product 的来源与规划；[product-author](<../../../project-source/skills/product-author/SKILL.md>)、[product-spec-elicitor](<../../../project-source/skills/product-spec-elicitor/SKILL.md>)、[feature-plan](<../../../project-source/skills/feature-plan/SKILL.md>) | 保留 | 已区分下一 Product 的必要来源细化与后续 Feature 规划；不跳过当前交付范围的确定。 |
| 55 | [要求已经改好，开工前需要同步 Feature 计划](<../../docs/quick-reference/Godot 项目开发/任务规划/要求已经改好，开工前需要同步 Feature 计划.md>) | 开工前同步 Feature 计划；[feature-sync](<../../../project-source/skills/feature-sync/SKILL.md>) | 保留 | 已有同步入口，适用未开工计划的来源变化；职责与重新从零规划、直接实现不同。 |
| 56 | [Feature 正在开发，已确认要求发生变化](<../../docs/quick-reference/Godot 项目开发/任务规划/Feature 正在开发，已确认要求发生变化.md>) | 开发中同步 Feature 计划；[feature-sync](<../../../project-source/skills/feature-sync/SKILL.md>) | 保留 | 已有同步入口处理进行中 Feature 的已确认来源变化，并保留真实已完成工作和后续执行边界。 |
| 57 | [Feature 已交付，后来确认要改变要求](<../../docs/quick-reference/Godot 项目开发/任务规划/Feature 已交付，后来确认要改变要求.md>) | 已交付后同步需求变化；[feature-sync](<../../../project-source/skills/feature-sync/SKILL.md>) | 保留 | 已有同步入口区分历史交付与新变更，不回写历史为新需求早已存在；必要新任务沿既有规则处理。 |
| 58 | [已有计划，但采用的来源基线无法核实](<../../docs/quick-reference/Godot 项目开发/任务规划/已有计划，但采用的来源基线无法核实.md>) | 来源基线不可核实的计划对齐；[feature-sync](<../../../project-source/skills/feature-sync/SKILL.md>) | 保留 | feature-sync 正文支持未知历史基线时与当前权威来源对齐；保留未知，不虚构采用记录或追溯性通过。 |

### Godot 项目开发 / 修复与改进

| 编号 | 同名场景 | 能力与已有 Skill | 决定 | 具体理由 |
| --- | --- | --- | --- | --- |
| 59 | [已经选定新框架，检查适用后在当前项目替换](<../../docs/quick-reference/Godot 项目开发/修复与改进/已经选定新框架，检查适用后在当前项目替换.md>) | 已选框架的项目内替换；现有规范／命令（无专门 Skill） | 保留 | 这是已授权的有保护范围的原地替换，区别于17–18复制迁移；任务明确不建立 Feature，不应补 engineering-change-plan 改变机制。 |
| 60 | [某处代码总是难改，先调查是否值得重构](<../../docs/quick-reference/Godot 项目开发/修复与改进/某处代码总是难改，先调查是否值得重构.md>) | 代码结构困难的只读调查；[review-code](<../../../project-source/skills/review-code/SKILL.md>)（衔接候选，未改用独立审核） | 待讨论 | 与 review-code 的现状审核目标相近，但该 Skill 按 methodology/12 必须 fresh 独立审核者，当前场景由当前 Agent 调查；不能以补名字静默改变执行者。可讨论是否接入独立审核，未见必须新增 Skill 的证据。 |
| 61 | [已经记录了几个代码问题，想选一个值得重构的](<../../docs/quick-reference/Godot 项目开发/修复与改进/已经记录了几个代码问题，想选一个值得重构的.md>) | 已记录重构候选选择；[engineering-refactor-select](<../../../project-source/skills/engineering-refactor-select/SKILL.md>) | 保留 | 已有重构候选选择入口，输入是现存问题记录，负责比较证据和收益；不同于从代码主动发现问题或直接实施。 |
| 62 | [Feature 交付前发现 Bug](<../../docs/quick-reference/Godot 项目开发/修复与改进/Feature 交付前发现 Bug.md>) | 交付前 Bug 修复；[bug-diagnosis-godot](<../../../project-source/skills/bug-diagnosis-godot/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 补引用 | 原因未定时已有诊断入口，修复仍归原 Feature；页面已指明 feature-execute，提示词补名即可，不新增工程任务。用户实际验收和明确提交许可保持本场景约束。 |
| 63 | [Feature 交付后发现 Bug](<../../docs/quick-reference/Godot 项目开发/修复与改进/Feature 交付后发现 Bug.md>) | 交付后 Bug 修复；[bug-diagnosis-godot](<../../../project-source/skills/bug-diagnosis-godot/SKILL.md>)、[engineering-change-plan](<../../../project-source/skills/engineering-change-plan/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 已有 Bug 工程计划与执行入口，必要诊断先交因果证据；用户实际验收和明确提交许可属于本场景约束，不构成入口冲突。 |
| 64 | [发现异常，先定位原因，不修改实现](<../../docs/quick-reference/Godot 项目开发/修复与改进/发现异常，先定位原因，不修改实现.md>) | 异常只诊断不修改；[bug-diagnosis-godot](<../../../project-source/skills/bug-diagnosis-godot/SKILL.md>) | 保留 | 已有诊断专职入口，输出复现与原因证据；保持只定位、不修改实现的限定，不接入修复计划或执行。 |
| 65 | [重构目标已经选定，现在调整结构并保持行为](<../../docs/quick-reference/Godot 项目开发/修复与改进/重构目标已经选定，现在调整结构并保持行为.md>) | 确定重构目标后的实现；[engineering-change-plan](<../../../project-source/skills/engineering-change-plan/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 已有 refactor 工程计划与执行入口，保持可观察行为并完成必要验证；不与候选选择或只读调查混用。 |
| 66 | [项目工具需要修改，按工程任务完成](<../../docs/quick-reference/Godot 项目开发/修复与改进/项目工具需要修改，按工程任务完成.md>) | 项目工具工程维护；[engineering-change-plan](<../../../project-source/skills/engineering-change-plan/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 已有 maintenance 工程计划与执行入口，目标是工具实现变化；不同于只更新工具路径的环境维护场景。 |
| 67 | [项目约束已确认要改，现在维护规则文档](<../../docs/quick-reference/Godot 项目开发/修复与改进/项目约束已确认要改，现在维护规则文档.md>) | 已确认项目规则修改；现有规范／命令（无专门 Skill） | 保留 | methodology/04 的增量规则维护已有权威正文；技术文档写作 Skill 不能替代行为规则归属，writing-for-agents-yaya 也不分发给项目。当前单场景不足以证明必须新增项目规则维护 Skill。 |
| 68 | [共享能力准备修改，先明确契约和影响范围](<../../docs/quick-reference/Godot 项目开发/修复与改进/共享能力准备修改，先明确契约和影响范围.md>) | 共享契约与影响分析；现有规范／命令（无专门 Skill） | 保留 | 先核对实际调用者、状态和责任，已有变更准备及 architecture 规则承接；只读影响分析不应因提到计划而启动写计划或实施 Skill。 |
| 69 | [文档和实际状态对不上，先确定应该修复哪里](<../../docs/quick-reference/Godot 项目开发/修复与改进/文档和实际状态对不上，先确定应该修复哪里.md>) | 文档与现状冲突核实；[feedback-triage-godot](<../../../project-source/skills/feedback-triage-godot/SKILL.md>) | 补引用 | 现有反馈分流 Skill 明确比较已确认意图、当前行为和历史，能只读判断应改文档、实现还是记录；补入口后继续保留原场景的证据和处理归属要求，不转成自动修复。 |

### Godot 项目开发 / 资源、性能与数据

| 编号 | 同名场景 | 能力与已有 Skill | 决定 | 具体理由 |
| --- | --- | --- | --- | --- |
| 70 | [任务已经明确，需要列出要准备的素材](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/任务已经明确，需要列出要准备的素材.md>) | 素材需求盘点；[design-visual-asset-spec](<../../../project-source/skills/design-visual-asset-spec/SKILL.md>)、[design-audio-asset-spec](<../../../project-source/skills/design-audio-asset-spec/SKILL.md>) | 补引用 | 场景已明确两种规格方法；提示词只有含糊的 asset-spec，可按缺少的视觉或音频规格点名，已有规格继续引用。 |
| 71 | [素材文件已经收到，先登记来源并核对是否齐全](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/素材文件已经收到，先登记来源并核对是否齐全.md>) | 素材接收登记；现有规范／命令（无专门 Skill） | 保留 | 只核对实物、版本、来源并登记；现有资源清单契约足够，不能用接入或独立审核 Skill 扩大写入。 |
| 72 | [音效文件和播放位置都已确定，现在要把声音接进游戏](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/音效文件和播放位置都已确定，现在要把声音接进游戏.md>) | 素材新增接入；[content-asset-integration](<../../../project-source/skills/content-asset-integration/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 音效接入与所属任务完成明确分工，真实播放和用户体验单列，已点名入口。 |
| 73 | [图片和消费位置已确定，现在接入界面](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/图片和消费位置已确定，现在接入界面.md>) | 素材新增接入；[content-asset-integration](<../../../project-source/skills/content-asset-integration/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 图片接入与显示验证边界完整，已点名共同能力，不需按图片另建 Skill。 |
| 74 | [动画资源已确定，现在接到对应动作](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/动画资源已确定，现在接到对应动作.md>) | 素材新增接入；[content-asset-integration](<../../../project-source/skills/content-asset-integration/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 动画轨道及动作状态是同一接入能力的具体输入，已有入口适用。 |
| 75 | [已有图片要替换，需要保留界面引用](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/已有图片要替换，需要保留界面引用.md>) | 素材替换与消费者保护；[content-asset-integration](<../../../project-source/skills/content-asset-integration/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 明确共享消费者、UID/路径与运行回归，和新增接入共享方法但保留替换场景。 |
| 76 | [已有音频要替换，需要保留播放关系](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/已有音频要替换，需要保留播放关系.md>) | 素材替换与消费者保护；[content-asset-integration](<../../../project-source/skills/content-asset-integration/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 音频替换追踪全部播放关系，已有入口完整，不把同名覆盖当接入完成。 |
| 77 | [已有动画要替换，需要保留动作衔接](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/已有动画要替换，需要保留动作衔接.md>) | 素材替换与消费者保护；[content-asset-integration](<../../../project-source/skills/content-asset-integration/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 动画替换保留状态和事件时序，当前 Skill 能处理，无需重复包装。 |
| 78 | [准备增加语言支持，先确定本地化要求](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/准备增加语言支持，先确定本地化要求.md>) | 专业规格维护；[design-localization-spec](<../../../project-source/skills/design-localization-spec/SKILL.md>) | 保留 | 只确认本地化要求、不写翻译实现；已明确唯一规格所有者。 |
| 79 | [本地化要求已确定，现在接入目标语言](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/本地化要求已确定，现在接入目标语言.md>) | 本地化运行接入；[content-localization](<../../../project-source/skills/content-localization/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 已确定语言规则后接入译文及运行消费者，实际显示与语言质量不混淆。 |
| 80 | [问题缺少证据，先加临时观测信号](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/问题缺少证据，先加临时观测信号.md>) | 临时观测；[diagnostics-instrumentation](<../../../project-source/skills/diagnostics-instrumentation/SKILL.md>) | 保留 | 假设、插入、运行和清理权限明确；不把诊断扩展为持久指标或业务修复。 |
| 81 | [已经确定需要长期保留某项运行指标](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/已经确定需要长期保留某项运行指标.md>) | 持久指标实现；[diagnostics-instrumentation](<../../../project-source/skills/diagnostics-instrumentation/SKILL.md>)、[engineering-change-plan](<../../../project-source/skills/engineering-change-plan/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 补引用 | 专业方法与交付已有名称；独立 maintenance 规划仅写类别，可条件式点名工程入口且复用已有任务。 |
| 82 | [短测看不出问题，需要按约定负载持续运行](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/短测看不出问题，需要按约定负载持续运行.md>) | 长时验证；[diagnostics-soak-test](<../../../project-source/skills/diagnostics-soak-test/SKILL.md>)、[diagnostics-instrumentation](<../../../project-source/skills/diagnostics-instrumentation/SKILL.md>) | 保留 | 已有专用长测入口与缺信号条件调用；时长、预算、中断和真实证据边界完整。 |
| 83 | [运行出现卡顿，先测量并定位瓶颈](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/运行出现卡顿，先测量并定位瓶颈.md>) | 性能测量诊断；[diagnostics-performance](<../../../project-source/skills/diagnostics-performance/SKILL.md>) | 保留 | 只测量不优化，实际瓶颈与推断边界明确；已有匹配 Skill。 |
| 84 | [性能瓶颈已确认，现在优化并对比结果](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/性能瓶颈已确认，现在优化并对比结果.md>) | 性能优化及对比；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>)、[diagnostics-performance](<../../../project-source/skills/diagnostics-performance/SKILL.md>) | 保留 | 实现和测量分工已点名，比较基线及收益要求清楚，不另建优化流程。 |
| 85 | [存档结构需要修改，旧数据不需要继续使用](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/存档结构需要修改，旧数据不需要继续使用.md>) | 存档结构工程实现；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 补引用 | 已有正式任务已承接，可点名执行入口；不重新规划、不增加迁移义务或放宽真实数据保护。 |
| 86 | [存档结构变了，需要保留并转换已有数据](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/存档结构变了，需要保留并转换已有数据.md>) | 受控存档转换；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 补引用 | 已确认保留契约和样本授权，补已有任务执行入口即可，不重复创建 maintenance 或增加历史兼容。 |
| 87 | [音乐文件和切换时机已确定，现在接入背景音乐](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/音乐文件和切换时机已确定，现在接入背景音乐.md>) | 素材新增接入；[content-asset-integration](<../../../project-source/skills/content-asset-integration/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 背景音乐与音效复用接入能力，特有循环和状态过渡仍留具体场景。 |
| 88 | [场景文件及依赖已准备好，现在接入当前游戏](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/场景文件及依赖已准备好，现在接入当前游戏.md>) | 素材新增接入；[content-asset-integration](<../../../project-source/skills/content-asset-integration/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 场景资源及依赖接入已映射现有方法，复制范围和机器配置保护明确。 |
| 89 | [已有场景需要替换，必须保留游戏中的调用关系](<../../docs/quick-reference/Godot 项目开发/资源、性能与数据/已有场景需要替换，必须保留游戏中的调用关系.md>) | 素材替换与消费者保护；[content-asset-integration](<../../../project-source/skills/content-asset-integration/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 新场景替换追查实际节点及信号契约，现有接入入口准确。 |

### Godot 项目开发 / 验证与收尾

| 编号 | 同名场景 | 能力与已有 Skill | 决定 | 具体理由 |
| --- | --- | --- | --- | --- |
| 90 | [我手动改过项目，想确认是否仍符合要求](<../../docs/quick-reference/Godot 项目开发/验证与收尾/我手动改过项目，想确认是否仍符合要求.md>) | 独立一致性审核；[review-code](<../../../project-source/skills/review-code/SKILL.md>) | 保留 | 手改范围和基线明确且只读；已有当前差异及需求一致性方法，不触发修复。 |
| 91 | [代码刚改完，只检查解析和 lint](<../../docs/quick-reference/Godot 项目开发/验证与收尾/代码刚改完，只检查解析和 lint.md>) | 限定静态验证；现有规范／命令（无专门 Skill） | 保留 | 直接读取 gdscript-lint 规范执行解析/lint；无匹配窄 Skill，不应调用完整 Feature 执行流程。 |
| 92 | [已有变更需要重新运行相关自动测试](<../../docs/quick-reference/Godot 项目开发/验证与收尾/已有变更需要重新运行相关自动测试.md>) | 限定自动验证；现有规范／命令（无专门 Skill） | 保留 | 只运行现有 Feature 测试并报告，直接规范/命令有精确出口；不强行引用会推进完成的执行入口。 |
| 93 | [场景或资源刚改完，需要实际启动检查](<../../docs/quick-reference/Godot 项目开发/验证与收尾/场景或资源刚改完，需要实际启动检查.md>) | 限定真实场景检查；现有规范／命令（无专门 Skill） | 保留 | 仅运行选定场景及观察；现有环境规则足够，接入 Skill 不适用于只验证。 |
| 94 | [界面已经做出，需要独立检查交互体验](<../../docs/quick-reference/Godot 项目开发/验证与收尾/界面已经做出，需要独立检查交互体验.md>) | 独立专业审核；[review-ux](<../../../project-source/skills/review-ux/SKILL.md>) | 保留 | 已用独立上下文和交互真实证据；不与 UI 设计或人工接受混淆。 |
| 95 | [视觉成果已准备好，需要独立检查美术效果](<../../docs/quick-reference/Godot 项目开发/验证与收尾/视觉成果已准备好，需要独立检查美术效果.md>) | 独立专业审核；[review-art](<../../../project-source/skills/review-art/SKILL.md>) | 保留 | 实际显示条件与美术方向核对由现有方法承担，已点名，不扩大制作。 |
| 96 | [音频成果已准备好，需要独立检查听觉效果](<../../docs/quick-reference/Godot 项目开发/验证与收尾/音频成果已准备好，需要独立检查听觉效果.md>) | 独立专业审核；[review-audio](<../../../project-source/skills/review-audio/SKILL.md>) | 保留 | 真实听取证据和未听取限制明确，现有方法匹配。 |
| 97 | [素材已收到，需要独立检查技术规格](<../../docs/quick-reference/Godot 项目开发/验证与收尾/素材已收到，需要独立检查技术规格.md>) | 独立专业审核；[review-assets](<../../../project-source/skills/review-assets/SKILL.md>) | 保留 | 技术规格、来源和隔离验证归现有素材审核，区别于接收登记和体验评价。 |
| 98 | [翻译已接入，需要独立检查语言与显示](<../../docs/quick-reference/Godot 项目开发/验证与收尾/翻译已接入，需要独立检查语言与显示.md>) | 独立专业审核；[review-localization](<../../../project-source/skills/review-localization/SKILL.md>) | 保留 | 语义和显示检查匹配方法，保持原件只读与人工体验边界。 |
| 99 | [数值方案已有样本，需要独立检查平衡](<../../docs/quick-reference/Godot 项目开发/验证与收尾/数值方案已有样本，需要独立检查平衡.md>) | 独立专业审核；[review-balance](<../../../project-source/skills/review-balance/SKILL.md>) | 保留 | 实际或明确模拟样本支持数值判断，现有方法不替代试玩体验或调参实现。 |
| 100 | [这次变更已准备好，需要独立代码审核](<../../docs/quick-reference/Godot 项目开发/验证与收尾/这次变更已准备好，需要独立代码审核.md>) | 独立代码变更审核；[review-code](<../../../project-source/skills/review-code/SKILL.md>) | 保留 | 差异审核基线、AC、调用者和证据清楚；已有独立入口。 |
| 101 | [想检查某个模块现状，不依赖 Feature 或差异](<../../docs/quick-reference/Godot 项目开发/验证与收尾/想检查某个模块现状，不依赖 Feature 或差异.md>) | 独立代码现状审核；[review-code](<../../../project-source/skills/review-code/SKILL.md>) | 保留 | 现有 Skill 明确支持无差异、无 Feature 的模块现状审查，不需另建找坏代码入口。 |
| 102 | [Feature 已能体验，需要准备人工验收清单](<../../docs/quick-reference/Godot 项目开发/验证与收尾/Feature 已能体验，需要准备人工验收清单.md>) | 人工验收材料准备；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>)（所属任务；当前子任务直接使用人工验收规范） | 保留 | 直接 prepare-manual 只准备 pending 清单，不能为点名 Skill 把准备任务扩为完整执行/验收。 |
| 103 | [人工验收 JSON 已填好，需要导入结果](<../../docs/quick-reference/Godot 项目开发/验证与收尾/人工验收 JSON 已填好，需要导入结果.md>) | 人工结果导入；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>)（所属任务；当前子任务直接使用人工验收规范） | 保留 | 有效用户 JSON 是具体范围接受；直接记录入口已足够，不启动额外实现阶段。 |
| 104 | [已经实际体验，需要记录我的明确验收结论](<../../docs/quick-reference/Godot 项目开发/验证与收尾/已经实际体验，需要记录我的明确验收结论.md>) | 人工口头结果记录；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>)（所属任务；当前子任务直接使用人工验收规范） | 保留 | 只记录真实当前用户决定，继续/沉默不算接受；无需强行加载完整执行流程。 |
| 105 | [测试已经通过，但填错报告路径导致导入失败](<../../docs/quick-reference/Godot 项目开发/验证与收尾/测试已经通过，但填错报告路径导致导入失败.md>) | 验证证据恢复；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>)（所属任务；当前子任务直接使用测试证据规范） | 保留 | 仅修正错误引用且原件有效，不重跑；不存在匹配窄 Skill，当前直接契约更准确。 |
| 106 | [测试摘要还在，但原始报告找不到了](<../../docs/quick-reference/Godot 项目开发/验证与收尾/测试摘要还在，但原始报告找不到了.md>) | 验证证据恢复；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>)（所属任务；当前子任务直接使用测试证据规范） | 保留 | 先查原件再必要重验；与单纯路径恢复不同，保留场景并复用权威证据契约。 |
| 107 | [实现又改过了，需要更新已经过期的验证证据](<../../docs/quick-reference/Godot 项目开发/验证与收尾/实现又改过了，需要更新已经过期的验证证据.md>) | 验证证据更新；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>)（所属任务；当前子任务直接使用测试证据规范） | 保留 | 只补失效义务，自动重测不能替代新人工体验；不要由 Skill 名称扩大授权。 |
| 108 | [测试运行中断了，需要从真实结果恢复验证](<../../docs/quick-reference/Godot 项目开发/验证与收尾/测试运行中断了，需要从真实结果恢复验证.md>) | 验证运行恢复；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>)（所属任务；当前子任务直接使用测试证据规范） | 保留 | 实际进程、日志、停止权限先核对，再补验证；专用任务边界比完整执行 Skill 更窄。 |
| 109 | [没有 Feature，只想运行指定组件的自动测试](<../../docs/quick-reference/Godot 项目开发/验证与收尾/没有 Feature，只想运行指定组件的自动测试.md>) | 限定自动验证；现有规范／命令（无专门 Skill） | 保留 | 实际 --target 组件测试，无 Feature 和完成记录；完整执行 Skill 不匹配。 |
| 110 | [测量数据已经取得，需要独立核实结论是否成立](<../../docs/quick-reference/Godot 项目开发/验证与收尾/测量数据已经取得，需要独立核实结论是否成立.md>) | 独立测量结论审核；[review-code](<../../../project-source/skills/review-code/SKILL.md>)（仅采集/统计代码） | 保留 | 审核已有证据与推导，不重新诊断；代码部分已条件引用 review-code，其余依据共同独立审核契约。 |

### Godot 项目开发 / 项目恢复与交接

| 编号 | 同名场景 | 能力与已有 Skill | 决定 | 具体理由 |
| --- | --- | --- | --- | --- |
| 111 | [换了一个对话，想继续上次没做完的 Feature](<../../docs/quick-reference/Godot 项目开发/项目恢复与交接/换了一个对话，想继续上次没做完的 Feature.md>) | Feature续接；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 接收方核对真实停点后执行，不能使用只准备交接的 Skill 替代续接。 |
| 112 | [仍在原对话，想继续暂停的 Feature](<../../docs/quick-reference/Godot 项目开发/项目恢复与交接/仍在原对话，想继续暂停的 Feature.md>) | Feature续接；[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 保留 | 原对话续接复用有效上下文及授权，已引用正确入口。 |
| 113 | [进度记录太长，需要整理当前状态和历史](<../../docs/quick-reference/Godot 项目开发/项目恢复与交接/进度记录太长，需要整理当前状态和历史.md>) | 进度文档整理；[technical-documentation-writing-godot](<../../../project-source/skills/technical-documentation-writing-godot/SKILL.md>) | 补引用 | 可直接复用现有项目写作 Skill 改善组织，09仍负责状态/历史归属，不触发暂停或新交接。 |
| 114 | [Feature 还没做完，准备换一个对话继续](<../../docs/quick-reference/Godot 项目开发/项目恢复与交接/Feature 还没做完，准备换一个对话继续.md>) | 任务交接准备；[task-handoff-godot](<../../../project-source/skills/task-handoff-godot/SKILL.md>) | 保留 | 已点名交接入口，当前明确暂停和可复制文本边界完整。 |
| 115 | [当前 Feature 需要暂停，先保存真实停点](<../../docs/quick-reference/Godot 项目开发/项目恢复与交接/当前 Feature 需要暂停，先保存真实停点.md>) | 暂停停点保存；[task-handoff-godot](<../../../project-source/skills/task-handoff-godot/SKILL.md>) | 保留 | 只保存停点、不强制交接文本，匹配现有 Skill 的分支。 |
| 116 | [当前任务已经暂停，准备切换到另一项工作](<../../docs/quick-reference/Godot 项目开发/项目恢复与交接/当前任务已经暂停，准备切换到另一项工作.md>) | 同目录任务切换；现有规范／命令（无专门 Skill） | 保留 | 目标任务类型未知，沿其所属 Skill；现有入口不应硬编码交接或执行方法，保留当前同目录任务切换边界。 |
| 117 | [当前工作没有 Feature，需要先暂停并保存停点](<../../docs/quick-reference/Godot 项目开发/项目恢复与交接/当前工作没有 Feature，需要先暂停并保存停点.md>) | 暂停停点保存；[task-handoff-godot](<../../../project-source/skills/task-handoff-godot/SKILL.md>) | 保留 | 非 Feature 工作可使用现有停点能力，不创建任务ID或额外台账。 |
| 118 | [当前工作没有 Feature，准备换一个对话继续](<../../docs/quick-reference/Godot 项目开发/项目恢复与交接/当前工作没有 Feature，准备换一个对话继续.md>) | 任务交接准备；[task-handoff-godot](<../../../project-source/skills/task-handoff-godot/SKILL.md>) | 保留 | 研究/讨论/审核的交接使用原任务及权限，现有入口完整。 |
| 119 | [外部调研还没结束，继续查清原来的问题](<../../docs/quick-reference/Godot 项目开发/项目恢复与交接/外部调研还没结束，继续查清原来的问题.md>) | 外部研究续接；现有规范／命令（无专门 Skill） | 保留 | 现有 researcher 是角色而非项目 Skill；按真实查询/委派方式继续，不补不存在的研究入口。 |
| 120 | [项目问题还没讨论清楚，继续原来的讨论](<../../docs/quick-reference/Godot 项目开发/项目恢复与交接/项目问题还没讨论清楚，继续原来的讨论.md>) | 讨论续接；[project-clarifier](<../../../project-source/skills/project-clarifier/SKILL.md>) | 保留 | 只继续未决取舍、不写文件，现有澄清入口准确。 |
| 121 | [独立审核中断了，需要继续完成原范围的报告](<../../docs/quick-reference/Godot 项目开发/项目恢复与交接/独立审核中断了，需要继续完成原范围的报告.md>) | 独立审核续接；[review-code](<../../../project-source/skills/review-code/SKILL.md>)（代码范围）、原选定专业review方法 | 补引用 | 场景已明确代码用 review-code；提示词可补同样条件引用，避免把所有审核固定为代码。 |

### Godot 项目开发 / 经验沉淀

| 编号 | 同名场景 | 能力与已有 Skill | 决定 | 具体理由 |
| --- | --- | --- | --- | --- |
| 122 | [一个阶段已经结束，先总结值得保留的经验](<../../docs/quick-reference/Godot 项目开发/经验沉淀/一个阶段已经结束，先总结值得保留的经验.md>) | 开发经验复盘；[development-retro-godot](<../../../project-source/skills/development-retro-godot/SKILL.md>) | 保留 | 只读建议与是否固化分开，已点名复盘 Skill，不自动写知识或规则。 |
| 123 | [经验已经确认，需要整理进项目知识](<../../docs/quick-reference/Godot 项目开发/经验沉淀/经验已经确认，需要整理进项目知识.md>) | 确认知识写入；[technical-documentation-writing-godot](<../../../project-source/skills/technical-documentation-writing-godot/SKILL.md>) | 补引用 | 已有写作 Skill 覆盖知识条目，按知识README维护归属和证据，不再调用只读retro或新增同类入口。 |
| 124 | [重复操作已确认值得固化，需要做成项目脚本](<../../docs/quick-reference/Godot 项目开发/经验沉淀/重复操作已确认值得固化，需要做成项目脚本.md>) | 项目工具固化；[engineering-change-plan](<../../../project-source/skills/engineering-change-plan/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>) | 补引用 | 现有工程规划和执行已覆盖；仅在未规划时进入maintenance准备，保留实际工具验证和既有授权。 |

## 5. 依据、覆盖限制与验证含义

### 实际读取的公共规范和专项正文

逐条表的124个场景链接加上提示词库本身，构成全部被审入口。以下列出承担判断的规范和专项来源；对按需读取的规范只声称所列范围，不把整套工程规则、工具源码或第三方实现计入全量审核。

| 来源 | 实际用于判断的范围 |
| --- | --- |
| [职责设计准则](../baselines/skill-script-prompt-design.md) | Skill、提示词与场景职责，按需引用，授权、副作用和完整覆盖要求 |
| [根 AGENTS.md](../../../AGENTS.md)、[项目入口](../../../project-source/Project_AGENTS.md) | 框架与项目范围、写作、工作流、分发源边界和适用 Git 入口 |
| [00-overview](../../../project-source/methodology/00-overview.md) | Skill 分组、任务路由、按需研究和环境流程 |
| [01-product-doc-structure](../../../project-source/methodology/01-product-doc-structure.md) | 视觉原型与 scoped logic prototypes 小节 |
| [04-coding-rules-4-layers](../../../project-source/methodology/04-coding-rules-4-layers.md) | 增量规则维护 |
| [05-document-language](../../../project-source/methodology/05-document-language.md) | 验证配置、环境和首次扫描相关约定 |
| [07-engineering-change](../../../project-source/methodology/07-engineering-change.md) | 反馈分类、Bug 路由和因果诊断 |
| [08-testing-strategy](../../../project-source/methodology/08-testing-strategy.md) | 按影响选择运行测试、原件支撑和证据时效 |
| [09-artifact-lifecycle](../../../project-source/methodology/09-artifact-lifecycle.md) | 产物、进度和历史的归属与生命周期 |
| [10-architecture-overview](../../../project-source/methodology/10-architecture-overview.md) | 模块边界、调用者义务、重构判断和架构决定 |
| [11-specialist-workflows](../../../project-source/methodology/11-specialist-workflows.md) | 专业设计、内容接入、诊断与审核的分工 |
| [12-independent-review](../../../project-source/methodology/12-independent-review.md) | 独立审核上下文、执行者、证据与返回边界 |
| [人工验收文件契约](../../../project-source/methodology/manual-acceptance-files.md) | 待验收材料、真实用户结果、导入与记录 |
| [项目知识 README](../../../project-source/defaults/docs/knowledge/README.md) | 知识写入的事实、证据和唯一正文归属 |
| [复制清单](../../project-files.json)、[researcher 角色](../../../project-source/agents/researcher.toml) | 分发与角色事实；研究 Agent 不等于同名 Skill |

已读 Skill 正文按以下能力分组列出；同一个 Skill 被多个场景使用时只列一次。具体入口适用性仍见逐条理由。

- **框架指令与专项入口**：[writing-for-agents-yaya](<../../../.agents/skills/writing-for-agents-yaya/SKILL.md>)、[bug-diagnosis-yaya](<../../../.agents/skills/bug-diagnosis-yaya/SKILL.md>)、[feedback-triage-yaya](<../../../.agents/skills/feedback-triage-yaya/SKILL.md>)、[development-retro-yaya](<../../../.agents/skills/development-retro-yaya/SKILL.md>)、[task-handoff-yaya](<../../../.agents/skills/task-handoff-yaya/SKILL.md>)、[plan-review-yaya](<../../../.agents/skills/plan-review-yaya/SKILL.md>)。
- **来源、规划、执行与建议**：[project-clarifier](<../../../project-source/skills/project-clarifier/SKILL.md>)、[project-terminology](<../../../project-source/skills/project-terminology/SKILL.md>)、[product-author](<../../../project-source/skills/product-author/SKILL.md>)、[product-spec-elicitor](<../../../project-source/skills/product-spec-elicitor/SKILL.md>)、[feature-plan](<../../../project-source/skills/feature-plan/SKILL.md>)、[feature-execute](<../../../project-source/skills/feature-execute/SKILL.md>)、[feature-sync](<../../../project-source/skills/feature-sync/SKILL.md>)、[project-next-step-advisor](<../../../project-source/skills/project-next-step-advisor/SKILL.md>)、[engineering-change-plan](<../../../project-source/skills/engineering-change-plan/SKILL.md>)、[engineering-refactor-select](<../../../project-source/skills/engineering-refactor-select/SKILL.md>)、[plan-review-godot](<../../../project-source/skills/plan-review-godot/SKILL.md>)。
- **专业设计与内容接入**：[prototype-godot](<../../../project-source/skills/prototype-godot/SKILL.md>)、[design-art-direction](<../../../project-source/skills/design-art-direction/SKILL.md>)、[design-audio-direction](<../../../project-source/skills/design-audio-direction/SKILL.md>)、[design-ui-spec](<../../../project-source/skills/design-ui-spec/SKILL.md>)、[design-audio-asset-spec](<../../../project-source/skills/design-audio-asset-spec/SKILL.md>)、[design-visual-asset-spec](<../../../project-source/skills/design-visual-asset-spec/SKILL.md>)、[design-localization-spec](<../../../project-source/skills/design-localization-spec/SKILL.md>)、[content-asset-integration](<../../../project-source/skills/content-asset-integration/SKILL.md>)、[content-localization](<../../../project-source/skills/content-localization/SKILL.md>)。
- **项目诊断与反馈**：[feedback-triage-godot](<../../../project-source/skills/feedback-triage-godot/SKILL.md>)、[bug-diagnosis-godot](<../../../project-source/skills/bug-diagnosis-godot/SKILL.md>)、[diagnostics-instrumentation](<../../../project-source/skills/diagnostics-instrumentation/SKILL.md>)、[diagnostics-performance](<../../../project-source/skills/diagnostics-performance/SKILL.md>)、[diagnostics-soak-test](<../../../project-source/skills/diagnostics-soak-test/SKILL.md>)。
- **专业审核**：[review-code](<../../../project-source/skills/review-code/SKILL.md>)、[review-ux](<../../../project-source/skills/review-ux/SKILL.md>)、[review-art](<../../../project-source/skills/review-art/SKILL.md>)、[review-audio](<../../../project-source/skills/review-audio/SKILL.md>)、[review-assets](<../../../project-source/skills/review-assets/SKILL.md>)、[review-localization](<../../../project-source/skills/review-localization/SKILL.md>)、[review-balance](<../../../project-source/skills/review-balance/SKILL.md>)。
- **交接、复盘与写作**：[task-handoff-godot](<../../../project-source/skills/task-handoff-godot/SKILL.md>)、[development-retro-godot](<../../../project-source/skills/development-retro-godot/SKILL.md>)、[technical-documentation-writing-godot](<../../../project-source/skills/technical-documentation-writing-godot/SKILL.md>)、[technical-documentation-writing-yaya](<../../../.agents/skills/technical-documentation-writing-yaya/SKILL.md>)。

写作参考还包括 [Godot 写作指南](../../../project-source/skills/technical-documentation-writing-godot/references/writing-guide.md)，报告归档使用 [框架写作指南](../../../.agents/skills/technical-documentation-writing-yaya/references/writing-guide.md)。这些写作方法只改善组织和表达，不替代权威规则或审核判断。

### 本次结论能证明什么

- **文本与入口**：已逐条比较完整提示词、同名场景页及必要正文，指出14条可以安全补名的入口；没有把框架与生成项目的职责混用。
- **Skill 职责**：核对本次场景实际需要的触发、执行者、输出、权限和完成边界；不据此宣称所有 Skill 的全部路径或整仓规则已经全面正确。
- **脚本职责**：本次引用既有工具契约来判断是否需要 Skill 包装，没有执行工具源码全量审核，也没有新增脚本或状态机制。
- **运行与触发**：两位分区审核均为静态审核，未通过本次审核证明工具回归、项目创建、真实 Godot 运行、用户人工验收或客户端 Skill 发现与隐式触发已通过。名称可达和职责适用不等于客户端实际触发成功。

本报告不以“保留”担保尚未执行的运行结果，也不将14处入口补充视作修复所有语义问题。新增入口、改变执行者或扩展流程的建议仍须按明确讨论结果另行处理。
