# 框架 Skill 全量职责审核（2026-09-25）

本轮完整读取并评价 `project-source/skills/` 下全部 **27 个 Skill**。建议优先拆出 `product-author` 的纯术语维护职责，以及 `content-localization` 的规格编写职责；收窄澄清入口和 Product 缺陷澄清的触发边界。其余能力不能因为包含多个阶段、检查项、资产类型或调用工具就机械拆开。

另有一项跨文件问题：已确认的单人项目范围尚未贯彻到生成项目的 Skill、方法论和 Git 规则。它需要统一修改职责与入口约定，不能仅删除一个 `worktree` 词或复制更多 Skill。

## 审核范围与证据边界

- 执行者：独立子智能体 `/root/audit_all_skills`。未编写被审核 Skill；按实际源码形成结论，既有讨论中的判断只作为待核实线索。本次未声称客户端加载了 `independent-reviewer.toml` 命名角色，也未把角色文件存在视为权限隔离证明。
- 检查基准：`8fe14d6e4f63fe824eef485d34ea6313f31ac65f`。开始时工作区只有本轮新增的[职责设计准则](../baselines/skill-script-prompt-design.md)未跟踪；被审核 Skill 与相关 `project-source/` 规范无工作区差异。协调者同时维护准则和入口文档，这些变更不属于被审核实现。
- 范围：全部 27 个完整 `SKILL.md`，以及影响职责判断的实际调用关系、advisor 场景参考、方法论权威条款和复制映射。第三方实现、个人安装 Skill、脚本内部实现及提示词全量内容不计入本报告覆盖；脚本和提示词由各自专项报告评价。
- 方法：按八个维度逐项判断，横向比较权威正文与产物归属。不打分、不按命中数判定拆分，不把文件长度当作缺陷。下表将八维合并为三个阅读栏，分别覆盖“意图／触发／输出”“变化原因／依赖／生命周期”“授权／拆分成本”。
- “变化原因”来自当前契约的差异分析，不代表已经统计历史修改频率；本次未开展 Git 历史热点统计。未观察到实际运行的问题，明确写为职责风险或改进建议。
- 这是静态职责审核。未运行测试、项目生成、Godot、HTML，也未修改任何被审核对象或原始证据；仅创建本报告。

核心依据包括[任务路由](../../../project-source/methodology/00-overview.md)、[Product 与术语契约](../../../project-source/methodology/01-product-doc-structure.md)、[Feature 产物归属](../../../project-source/methodology/02-feature-list-schema.md#ownership)、[执行循环](../../../project-source/methodology/03-execute-loop.md)、[工程变更](../../../project-source/methodology/07-engineering-change.md)、[专业工作](../../../project-source/methodology/11-specialist-workflows.md)、[独立审核](../../../project-source/methodology/12-independent-review.md)和[Git 规则](../../../project-source/agent-rules/00-core/git-worktree-and-commits.md)。这些生成项目材料在本次维护仓库中作为审核对象阅读，不用于启动项目开发流程。

## 全部 27 个 Skill 的覆盖与结论

“保留”表示当前职责划分有依据，不表示其实际执行、所有措辞或下游工具均已验证通过。共享的单人范围问题见 S5，不在每一行重复。

### 澄清与 Product：4 个

| Skill 与源码 | 意图、触发与实际输出 | 变化原因、依赖与生命周期 | 授权、拆分成本与结论 |
| --- | --- | --- | --- |
| [project-clarifier](../../../project-source/skills/project-clarifier/SKILL.md) | 回答设计／概念疑问；另提供“保存已确认术语”入口。前者交付会话结论，后者交给写入者。 | 提问方法服务多个调用方；持久术语的更新规则可以独立变化。讨论不需完整 Product 或引擎，术语写入需文档语言及来源契约。 | 自身不写，但 description 同时承诺讨论和授权文档结果。**收窄入口**：保留澄清方法，已明确的术语维护直接进入专用写入者；见 S3。无需为每种讨论主题复制 Skill。 |
| [product-init-elicitor](../../../project-source/skills/product-init-elicitor/SKILL.md) | 在缺少实际 Product 意图时形成一个结构化初始草案；整体定位、模块、依赖共同解释一个产品范围。 | 初始化输入和完整草案契约不同于局部修改；其视觉／音频信息只作为专业规格输入。全部阶段属于草案形成过程，没有独立写入或交付状态。 | 明确只返回草案，写入归 author。**保留**；不能按问题主题或模块数拆成多个必经 Skill。与增量 elicitor 的区分合理。 |
| [product-spec-elicitor](../../../project-source/skills/product-spec-elicitor/SKILL.md) | 新模块、修改、Product 缺陷、跨模块都返回同一种局部需求补丁；不会修代码。 | 四种模式主要调整补丁覆盖范围；复用同一提问方法、来源与语言协议，跨模块只是同一补丁的扩展。 | 写入边界清楚，但“Bug 修复”触发及 bug_fix 模式未就地限定为意图缺失／矛盾／变化。**收窄触发，保留共同补丁方法**；见 S4。 |
| [product-author](../../../project-source/skills/product-author/SKILL.md) | 编写／变更／补录 Product 并衔接计划；另可独立维护不改变含义的术语。术语路径显式跳过正常 Steps 1–7。 | Product 行为变化影响专业来源、计划与同步；纯术语改名／定义整理有独立原因、来源与结束点，可在 Stage 3 嵌套返回。 | 两条路径都写文档，但可写产物和后续义务不同。**拆分纯术语职责**；Product 内的必要规划编排仍保留调用关系，见 S1。 |

### 规划、执行与工程：5 个

| Skill 与源码 | 意图、触发与实际输出 | 变化原因、依赖与生命周期 | 授权、拆分成本与结论 |
| --- | --- | --- | --- |
| [feature-plan](../../../project-source/skills/feature-plan/SKILL.md) | 将当前尚未规划的 Product 转为可验证 Feature，追加索引、明细、必要组件和适用的首个基线。 | 新增当前 Product 与后续 Product 使用同一计划契约；Registry、明细、索引必须一起一致，初次基线是有条件的关联产物。 | 预览审批、计划写入、验证和提交属于同一成果；不执行 Feature。**保留**。共享 Registry 方法已有单一入口，不为调用方复制整套规划。 |
| [feature-sync](../../../project-source/skills/feature-sync/SKILL.md) | 对已提交来源变化与旧计划做影响分析，应用已批准的计划、依赖和测试追踪调整。 | Git 差异与无法恢复历史时的当前文档对齐是同一“恢复有效对应关系”的不同证据来源；增加／删除／拆并属于同一计划演化契约。 | 分析、确认、写入、记录锚点有依赖，分析阶段无写入；实现修复回到 execute。**保留**，不按七阶段拆 Skill；单人范围调整时同步审视旧 Git 前置。 |
| [feature-execute](../../../project-source/skills/feature-execute/SKILL.md) | 完成一项已批准 Feature，或从实际阶段继续；交付经过适用验证和验收的实现。 | Skill 将 Stage 0–8 唯一正文交给方法论；新执行、恢复和接纳既有实现共用任务状态。测试、人工验收及收尾服务同一交付。 | 不建立另一套完成规则；中断后复用授权。**保留编排职责**，不能把每个 Stage 变成一项独立用户任务。核心 Git 范围迁移会影响其引用。 |
| [engineering-change-plan](../../../project-source/skills/engineering-change-plan/SKILL.md) | 收集 bug／refactor／maintenance 特有证据，形成同类工程 Feature；当前 Feature 自身缺陷退回原任务。 | 三模式约束不同，但都结束于批准且有效的工程计划；共用索引、明细、组件和验证写入，不执行修复。 | **保留共用计划方法，收窄范围**。专用场景提示词应预先确定模式；不能让已确定场景再选择三种任务。第 26 行隔离 worktree 路线需按 S5 移除。 |
| [engineering-refactor-select](../../../project-source/skills/engineering-refactor-select/SKILL.md) | 从尚未解决的记录中比较值得处理的重构候选，也允许明确建议暂缓。 | 扫描、证实当前问题、比较成本共同产生一个候选选择结果；无变更状态、无引擎依赖。缺陷发现仅转交分类。 | 严格只读，不实施、不提交，选择不替代计划授权。**保留**；与 plan 的“已选目标形成计划”不重复，用户指定目标时跳过选择。 |

### 专业设计：5 个

| Skill 与源码 | 意图、触发与实际输出 | 变化原因、依赖与生命周期 | 授权、拆分成本与结论 |
| --- | --- | --- | --- |
| [design-art-direction](../../../project-source/skills/design-art-direction/SKILL.md) | 选择／维护共享视觉方向，产出适用范围明确的 Art Bible。 | 风格、调色和视觉优先级共同构成共享视觉契约；局部资源规格另有 owner。读取参考不等于制作资产。 | 写入已授权的专业来源，独立评价归 review-art。**保留**；不按配色、造型等同一设计维度拆 Skill。 |
| [design-audio-direction](../../../project-source/skills/design-audio-direction/SKILL.md) | 维护共享声音方向与反馈层级，产出 Sound Bible。 | 音乐、环境声和效果音共同受声场及优先级约束；具体资源、混音实现和实际听感审核分别交接。 | 不制作声音或更改玩法，新增意图返回 Product。**保留**；与单项声音规格有明确抽象层级。 |
| [design-ui-spec](../../../project-source/skills/design-ui-spec/SKILL.md) | 形成布局、状态和交互呈现规格，给 Godot 原型提供输入。 | 多个屏幕状态属于一个界面目标；原型观察可能回流规格，但运行原型是独立授权任务。依赖 Product、视觉约束和代表资源。 | 可以写自己的 UI 文档，不能实现原型或代作 UX／人工验收。**保留**；discussion-only 是同一设计成果的未落盘状态，不另造 Skill。 |
| [design-visual-asset-spec](../../../project-source/skills/design-visual-asset-spec/SKILL.md) | 将视觉／UI 要求转为可交付的具体资源清单与规格。 | 图片、动画、字体、模型的字段不同，统一目标是可交付规格；来源大小和可见尺寸区分已明确。 | 只维护范围内规格，不制作、导入或审核。**保留**；按资源类型拆会复制同一清单与交接规则。 |
| [design-audio-asset-spec](../../../project-source/skills/design-audio-asset-spec/SKILL.md) | 形成 SFX、音乐／环境声的具体规格、真实样本引用和听感缺口。 | 不同声音类型的字段都服务交付说明；共享方向由 Sound Bible 提供，制作尚未实现。 | 直接写自己的清单条目，不合成、录音、接入或验收。**保留**；与视觉规格共享清单协议，不共管同一条目的专业决定。 |

### 接入与诊断：5 个

| Skill 与源码 | 意图、触发与实际输出 | 变化原因、依赖与生命周期 | 授权、拆分成本与结论 |
| --- | --- | --- | --- |
| [content-asset-integration](../../../project-source/skills/content-asset-integration/SKILL.md) | 将已供应资源导入、替换或连接到已批准的消费位置，更新实际位置与状态。 | 新资源与替换有不同检查重点，但都完成“资源被正确消费”；路径／UID／导入与消费者验证强关联。依赖具体资源类型而非全部处理工具。 | 在 Feature／实验内修改，外部原件保留；不生产或独立审核。**保留共享方法**；专用提示词明确是哪一种接入场景，无需为图片／音效复制整套方法。 |
| [content-localization](../../../project-source/skills/content-localization/SKILL.md) | 一路编写本地化规格；另一路实现翻译资源、提取键、字体和 locale 切换。 | 规格可独立完成，运行支持需 Godot API 和显示验证；前者因语言决策变化，后者因实现或资源变化。持久产物与退出条件不同。 | 规格可独立写，运行实现必须属于已授权 Feature／实验。**拆分规格与实现职责**；见 S2。 |
| [diagnostics-instrumentation](../../../project-source/skills/diagnostics-instrumentation/SKILL.md) | 为具体未知事实设计／增加最小可解释信号，返回位置、观察版本与局限。 | 日志、计数、计时和显示属于信号手段；定义单位、开关、成本与清理服务同一探针生命周期。 | 持久修改需任务授权；不负责性能结论或修复。**保留**；探针设计是实施的必要部分，纯建议可停在获准范围，不必另建普遍平台或 Skill。 |
| [diagnostics-performance](../../../project-source/skills/diagnostics-performance/SKILL.md) | 用可比 workload 和原始证据测量、判断瓶颈，返回修复建议与结论限制。 | 帧时间、加载和内存是指标差异；同一测量契约要求版本、环境、预热和工作负载。探针与修复各归原授权任务。 | 不把性能诉求转换成修复授权，不自证优化成功。**保留**；测量与因果分析共同支撑诊断结果，不能按指标复制 Skill。 |
| [diagnostics-soak-test](../../../project-source/skills/diagnostics-soak-test/SKILL.md) | 执行有预算、时间与停止条件的持续场景，产出实际时长和积累趋势证据。 | 与性能瞬时／可比负载测量有不同资源生命周期；必须管理长跑停止、采样中断和隔离数据。 | 运行需授权，失败只转交修复；不虚构完整时长或 gdUnit 通过。**保留独立**；可共享信号方法，不能并入“性能测试”掩盖时长与资源义务。 |

### 独立审核：7 个

| Skill 与源码 | 意图、触发与实际输出 | 变化原因、依赖与生命周期 | 授权、拆分成本与结论 |
| --- | --- | --- | --- |
| [review-code](../../../project-source/skills/review-code/SKILL.md) | 对变更或现状给出需求符合性与代码质量两方面结论。 | diff 和当前快照是取证方式差异；两方面都针对同一被审对象。依赖实际调用边界和适用来源，没有独立写入生命周期。 | 原始对象只读；缺少需求证据仍可给有依据的质量发现。**保留**；不按两个结论或 diff／无 diff 拆 Skill，避免重复审同一代码。 |
| [review-ux](../../../project-source/skills/review-ux/SKILL.md) | 评价指定流程的可用性、交互和适用无障碍要求，输出行为障碍与证据。 | 各界面状态服务同一用户目标；交互证据与截图能力不同，明确限制结论。 | 不重画界面、不改规格、不替代人工体验。**保留**；与 design-ui-spec 的生成／评价分离合理。 |
| [review-art](../../../project-source/skills/review-art/SKILL.md) | 在实际显示上下文中评价视觉结果是否符合已批准方向。 | 造型、色彩、缩放和动画服务视觉符合性；技术导入问题可调用 review-assets。 | 不选择新风格或修改作品；审美建议与违约分开。**保留**，与 UX 有重叠观察项但结论对象不同。 |
| [review-audio](../../../project-source/skills/review-audio/SKILL.md) | 评价可实际听到的声音及触发、循环、遮蔽和混音行为。 | 源文件与运行声音是同一听感问题的取证层；要求实际聆听，文字不能替代。 | 不制作／接入，也不代替用户验收。**保留**；技术资源检查共享 review-assets，不复制其职责。 |
| [review-assets](../../../project-source/skills/review-assets/SKILL.md) | 评价资源技术适配、引用、导入和来源记录，输出受影响消费者与缺口。 | 多种格式共同服从“实际资源能否正确被消费”的技术检查；主观视觉／听觉评价有独立方法。 | 明确禁止重导入、删除、改来源或修引用，执行验证必须隔离。**保留**；和接入步骤有相同检查项，但作者验证与独立审核不是重复写入者。 |
| [review-localization](../../../project-source/skills/review-localization/SKILL.md) | 评价语言覆盖、语义忠实和 locale 呈现，输出语言／流程覆盖与问题位置。 | 键、占位符、排版和用语共同影响一次本地化审核；语言能力限制与机械检查已区分。 | 只读、不替用户确认语言体验。**保留**；S2 拆分后更新入口引用，无需把每种语言或机械／语言判断拆为必经 Skill。 |
| [review-balance](../../../project-source/skills/review-balance/SKILL.md) | 依据已批准目标分析公式、策略和数值失衡，输出有假设边界的计算／模拟发现。 | 依赖模型和参数，研究生命周期与实际玩家体验不同；清楚排除泛化试玩分析。 | 不调值、不改目标、不把预测当体验结论。**保留独立**；可用授权模拟辅助，不因此混入实现职责。 |

### 建议入口：1 个

| Skill 与源码 | 意图、触发与实际输出 | 变化原因、依赖与生命周期 | 授权、拆分成本与结论 |
| --- | --- | --- | --- |
| [project-next-step-advisor](../../../project-source/skills/project-next-step-advisor/SKILL.md) | 解释状态，必要时给实际下一步及续接表达；不执行建议。 | 状态解释与下一步推荐使用相同事实和权威路由，提示词是可选表达产物；不建立自己的生命周期。 | 严格禁止写入、测试、Godot 和调用写入标准器。**保留**；随 S1–S5 更新目的入口与场景参考，不能保留旧职责别名作为第二套路由。 |

## 需要调整的职责

### S1：将纯术语维护从 Product 编写中拆出

**结论：建议拆分 Skill；Product 写入及其必要下游编排保留。** 这是职责优化，不是声称现有分支完全没有边界。

证据：[product-author](../../../project-source/skills/product-author/SKILL.md)第 18 行声明自己是 Product 与术语的唯一写入者；第 33–46 行给出可独立调用的纯术语路径，明确不运行 UI／音频澄清、不规划／同步 Feature、执行自己的提交并返回；第 156–176 行则承担 Product 修改后的计划衔接。两条路线已有不同入口、输出和完成点，具备拆分基础。[术语规范](../../../project-source/methodology/01-product-doc-structure.md#project-terminology-optional)与[Stage 3 文档检查点](../../../project-source/methodology/03-execute-loop.md#3d-documentation-checkpoint-before-final-verification)都直接依赖这个双重 owner。

八维判断：用户可以单独要求“记录一个已确定概念”，不需要需求定义；触发不要求完整 Product；输出是定义及引用；变化原因是命名和含义说明；只依赖相关来源与文档语言；可单独完成或嵌入 Feature 后返回；授权仅限意义保持的文档写入；拆分能减少误入规划链，成本是更新唯一写入权与调用方，而非复制全部 Product 工作流。

| 拟保留／拆出的职责 | 输入 | 输出与可写范围 | 结束位置 |
| --- | --- | --- | --- |
| Product 编写与变更 | 已确认的行为、相关现有来源、授权范围 | Product 正文与历史、必要关联链接；委托专业 owner 和规划方法 | 获准 Product 范围和实际计划影响已处理；实现由既有调用方继续 |
| 纯术语维护，名称可用 `project-terminology` | 已确认含义、来源、要调整的定义／别名／链接及写入范围 | 局部定义或 `docs/terminology.md`，一份拥有正文，引用保持有效 | 定义已写入并核对；独立请求收尾，Feature 内返回原 Stage；不创建计划或改代码 |

最小调整：迁移现有术语分支而非重新设计一套术语系统。Product 行为变更仍由 Product owner 决定；如果术语变化实际改变行为，先返回该 owner。一个 Product 变更同时需要术语调整时，由原任务协调同一逻辑修改，不制造两套审批或冲突提交。

受影响方：[project-clarifier](../../../project-source/skills/project-clarifier/SKILL.md)、两个 elicitor 的术语建议返回契约、[advisor](../../../project-source/skills/project-next-step-advisor/SKILL.md)与其[场景参考](../../../project-source/skills/project-next-step-advisor/references/scenarios.md)、方法论 00／01／03、[项目规则入口](../../../project-source/Project_AGENTS.md)、[集中提示词](../../prompts.json)及其生成参考和场景文档。Product 内的局部定义写入权必须明示：行为正文仍由 Product owner 拥有，意义保持的定义整理由术语方法在同一任务授权下处理，不能产生两个相互竞争的定义源。

### S2：将本地化规格与运行接入分为两项职责

**结论：建议拆分 Skill，独立审核继续保留。** 当前正文已经区分授权，但两个可独立交付的入口仍合并在一个 Skill 中。

证据：[content-localization](../../../project-source/skills/content-localization/SKILL.md)第 10 行写 `docs/localization/localization-spec.md`，第 12–16 行修改运行翻译／Godot 机制并验证真实显示；[专业工作 owner 表](../../../project-source/methodology/11-specialist-workflows.md#ownership-and-decisions)把规格所有权也交给同一个 integration Skill。前者能够在没有运行实现的情况下完成，后者通常消费已确定规格。

八维判断：选择语言约定和交付语言支持是不同结果；规格不足和实现缺失是不同入口；持久规格与运行资源分别可验收；前者随术语／语言决策变化，后者随引擎机制／界面变化；只有后者依赖运行工具；规格生命周期与实现／验收周期独立；允许写入范围不同；拆开能使入口明确，与现有 design／content／review 分工一致，代价只需清楚传递来源。

| 拟拆职责 | 输入 | 输出与可写范围 | 结束位置 |
| --- | --- | --- | --- |
| 本地化规格，名称可用 `design-localization-spec` | 源语言、目标 locale、Product 语义、术语与已确认体验要求 | 本地化规格及必要链接；明确覆盖、回退、变量／复数和呈现约束 | 获准规格可供实现、未决项明确，实际来源影响已交回原任务 |
| 本地化运行接入，保留 `content-localization` | 已确定规格、待接入翻译／文本、现有机制和实现授权 | 翻译资源、键／占位符消费、locale 切换、实际适用的字体与显示修正 | 相关运行检查完成，回原 Feature／实验完成适用验收与交付 |

不需要在没有证据时进一步拆“翻译”“键提取”“字体”三个必经 Skill；它们能否独立成为长期能力，应依未来实际调用与产物边界评价。译文未确定时仍保持草案，不以接入授权替代语义决定。

受影响方：方法论 00／11、[review-localization](../../../project-source/skills/review-localization/SKILL.md)的入口描述、advisor 的专业工作路由、集中提示词中的本地化入口、场景覆盖与专业说明。共享领域术语继续引用其原始定义，本地化规格只拥有 locale 表达，不再复制第二套业务概念。

### S3：澄清入口应聚焦未决问题，已确定术语直接调用写入职责

**结论：收窄范围，不再新增另一层澄清 Skill。**

证据：[project-clarifier](../../../project-source/skills/project-clarifier/SKILL.md)第 3 行同时包含讨论与已确定术语文档请求，第 8–14 行先选择两种 outcome，第 30–34 行重新安排术语位置与写入者；这些写入归属规则还在 author 和术语规范出现。现有正文明确不重复询问，不能据此声称每次都会强制访谈，但直接写入请求仍经过不必要的澄清路由。

最小调整：澄清 Skill 保留事实核对、重要问题和可审阅提案，只有真实歧义才调用；明确“已定定义落盘”的专用场景调用 S1 的术语 writer。讨论中用户授权保存时，返回已确定内容与授权给原协调流程继续即可。`product-init-elicitor`、`product-spec-elicitor` 仍复用同一 [Shared questioning method](../../../project-source/skills/project-clarifier/SKILL.md#shared-questioning-method)，无需复制到每个 Skill 或添加强制问答阶段。

调整后输入是未决问题与相关事实；输出是已解答结论或具体待定选择；完成点是当前问题已足够支持下一步，而非必须产生文档。相关写入依赖、提交与文档生命周期归其实际 owner。这样保留提问方法的共享收益，同时缩小澄清入口的副作用承诺。

### S4：Product 补丁 elicitor 的 Bug 触发过宽

**结论：收窄触发及模式前提，不因四个模式拆四个 Skill。**

证据：[product-spec-elicitor](../../../project-source/skills/product-spec-elicitor/SKILL.md)第 8 行把一般“Bug 修复”列为触发，第 90–99 行收集实际／预期差异后建议写入 Product 的边界或纠正要求；这段没有重述“已有确认意图被实现违反则退出”。相对地，[product-author](../../../project-source/skills/product-author/SKILL.md)第 94–105 行和[工程分类](../../../project-source/methodology/07-engineering-change.md#classification-boundary)已经限定该路线仅处理缺失、矛盾或确实改变的意图。

具体风险：当用户直接触发 elicitor，或自动选择仅依据宽泛 description／triggers 时，一个纯实现缺陷可能得到 Product 补丁，而不是回到原 Feature 修复。通过 author 的正常调用已有上游防护，因此这里是入口契约不一致的静态风险，未声称已观察到实际误写。

最小调整：把触发明确为“澄清缺失／矛盾／变化的 Product 意图”；mode C 首先核对预期来源，对已有明确要求的实现缺陷返回工程／原 Feature 路线且不产出需求改写。现有模式值是否改名由协议调用检查决定；不只改名称而保留宽泛行为，也不凭“Bug”单词直接改玩家需求。

输入与退出仍是“具体意图缺口 → 结构化 Product 补丁 → 返回 Product writer”，其余模式共享问法和补丁协议，没有独立持久生命周期。受影响方主要是 author 的模式分派、需求澄清提示词和直接触发说明。

### S5：单人范围需要贯穿可复制规则和建议入口

**结论：收窄范围与修订共用规范，不以拆 Skill 处理。**

证据：根维护约定已排除多人协作、改动归属处理与 worktree 隔离／续接，但 [engineering-change-plan](../../../project-source/skills/engineering-change-plan/SKILL.md)第 26 行仍主动提供“明确批准的隔离 worktree”；[advisor 场景参考](../../../project-source/skills/project-next-step-advisor/references/scenarios.md)第 37 行仍把另一个任务的 dirty tree 作为改动归属冲突；[生成项目 Git 规则](../../../project-source/agent-rules/00-core/git-worktree-and-commits.md#clean-worktree-and-task-ownership)和[生成项目 AGENTS](../../../project-source/Project_AGENTS.md#environment-and-git)仍要求跨会话逐文件匹配 ownership。

这证明范围变更尚未落到被分发材料，不能把根文档一句限制当作生成项目已生效。与此同时，“clean worktree”也可以只是“干净 Git 工作目录”的术语，不能简单全文删除每处 worktree，更不能删掉 Git 状态检查、未提交工作保留或明确路径暂存。

最小调整：在单一项目目录内处理暂停／切换／恢复，保留真实差异、当前任务停点和证据；去掉独立 worktree 路线与跨任务归属证明流程。统一修改共用 Git 规则后，再调整 author／plan／sync／execute／engineering 和 advisor 的适用引用，保留已授权续接和人工验收边界。[独立审核规范](../../../project-source/methodology/12-independent-review.md#read-only-outcomes-and-isolated-validation)仍需保护原始证据；可通过安全副本或已授权验证环境实现隔离，不要求项目 workflow 支持 worktree。不得为消除一个词而让审阅者在原始被审项目产生缓存或修改。

本问题不证明上述所有 Skill 都职责混杂；它是同一范围决定的调用链尚未同步。修改时以“何种结果需要保护”检查替代方案，避免制造新的归属登记表。

## 横向职责比较与保留依据

| 比较对象 | 观察与取舍 |
| --- | --- |
| Product author、两个 elicitor、clarifier | elicitor 返回草案／补丁，author 落盘；clarifier 提供共享问法。生成建议和写入已确认要求不是两份权威正文。保留共同问法；按 S1／S3 去掉术语路径的过度绕行。 |
| 初始规划、来源同步、工程计划 | 都写 Feature／Registry，但分别处理首次分解、旧来源变化和不改变意图的技术计划；历史与锚点义务不同，不能合成一个宽泛“生成任务”入口。Registry 合并已经共用 `feature-plan` 的方法契约与现有工具，不应复制脚本或再建组件登记表。 |
| Product 与专业 owner | Product 拥有玩家行为，视觉／音频／UI owner 拥有专业来源，已有明确链接及 source discovery。不要为了场景一对一把同一 Art Bible 内容复制到 Product。S2 使本地化符合这一分工。 |
| 视觉／音频规格 | 两者维护同一资源清单的不同专业条目，格式由方法论统一；共用文件不表示抢占同一职责。保留稳定资源 ID、单份清单与实际交接。 |
| 资源接入与资源审核 | 读取文件、UID 和消费者的检查对象重合，但一个实施接入，一个独立评价；写入权限和证据角色不同。不能为“去重”合并作者和审核者。 |
| UX、art、assets | 对比度、裁剪和尺寸可能同时被观察，但分别回答操作可用性、视觉契约与技术适配。共同事实应引用同一证据；一个独立实例可组合方法，不要求三次重复审核。 |
| audio、assets | 资源格式／导入由技术方法覆盖，实际反馈听感由 audio 覆盖。可组合方法，不把波形统计当作已聆听。 |
| instrumentation、performance、soak | 探针负责可解释信号与清理；性能负责可比测量；长跑负责实际时长、资源预算与停止。共享信号有益，合并生命周期会隐去不同完成条件。 |
| 七个 review Skill | 统一权限、证据与报告契约已经在方法论 12；各 Skill 保留领域判断。没有发现需要为每个场景另复制审核 Skill 的依据，也不应将七项变成固定流水线。 |
| review-code 的符合性／质量判断 | 两个视角都针对同一个快照并共享调用分析；拆开会重复阅读且丢失“符合要求但实现有缺陷”的联系。允许分别报告两项结论，保留一项审核方法。 |
| advisor 与任务路由 | advisor 明确读取方法论 00，生成措辞不授予执行权；状态解释与可选下一步属于同一只读指导结果。保留 Skill，更新它引用的目的地与回归情境。 |

## 后续改动影响与验证缺口

1. 本报告给出职责调整建议，尚未拆分、改名或重写 Skill。报告不授予被审核实现的自动修改权限；按用户最终选择实施，并保留原有具体授权、有效历史和必要验证。
2. S1／S2 涉及唯一 owner 变更，应先更新权威来源，再改直接调用者、advisor、提示词和场景。只改 description、另添新 Skill 但保留旧入口原样，会形成两套可用正文。
3. [复制清单](../../project-files.json)整目录复制 `project-source/skills` 到 `.agents/skills`，当前无逐 Skill 白名单；新增／删除目录会直接改变新项目内容。仍应检查生成后的路由和引用。已有生成项目独立拥有文件，本次没有同步外部项目。
4. 已定位的说明消费者还包括[旧 Skill 参考材料](../../docs/framework-maintenance/migration-source/reference/skills.md)、[专业工作材料](../../docs/framework-maintenance/migration-source/guides/specialist-workflows.md)、[场景覆盖基线](../baselines/scenario-coverage.md)和 advisor 生成表达参考。后续变更必须从 [prompts.json](../../prompts.json)和其导出器更新生成正文，不能手改生成参考。这里只核对引用影响，不宣称已逐段审核全部旧说明或全部提示词。
5. 27 个 Skill 的正文全量覆盖不等于所有工程规则、模板、工具和真实客户交互全量验证。核心结论依赖的引用已读取；领域工程规则具体 Godot API 正确性、工具运行结果、语言模型触发效果、角色客户端加载、视觉与聆听能力没有在本轮验证。
6. 后续有针对性的场景验证应覆盖：已确认术语直接维护；术语实际改变玩法时退回 Product；只写本地化规格；仅按既定规格接入语言；直接请求明确已有要求的 Bug；当前 Feature 内调用支持 Skill 后继续；单目录暂停／新对话恢复；审核过程保持原始证据只读。它们是待执行验证建议，不是本轮通过结果。

本轮保留的是完整静态职责结论及明确边界；不存在“27 个 Skill 已运行通过”或“框架全部问题已修复”的结论。
