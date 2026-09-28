# Agent 指令写作定向审核

当前框架存在局部重复正文、少量引用不明和条件性参考常驻的问题；调研续接的完成条件也有一处可收紧的表述。未发现足以支持整体重写或全面拆分 Skill 的证据，也没有运行证据证明这些文字已经造成漏读、误触发或提前结束。

## 1. 依据与范围

- 检查日期：2026-09-28。
- 检查版本：`60fe2eda1778391b514f01625de83be9837c67c5`；开始审核时工作区干净。
- 外部参考：[writing-for-agents](D:/A_Games/Game_Ai_Agent/general-development-agents/mattpocock--skills/skills/productivity/writing-for-agents/SKILL.md) 及同目录 [SKILL-MECHANICS.md](D:/A_Games/Game_Ai_Agent/general-development-agents/mattpocock--skills/skills/productivity/writing-for-agents/SKILL-MECHANICS.md)。按本轮实际读取的本地内容评价，没有核实上游版本。
- 本仓库依据：[职责设计准则](../baselines/skill-script-prompt-design.md)；外部参考提供检查角度，不替代已确认的框架边界。
- 执行者：主 Agent 统筹与复核；`audit_rules`、`audit_skills`、`audit_prompts` 分别检查规则、Skill 与提示词。主 Agent 对报告采用的关键片段再次核对，提示词与 Skill 分支对主要发现进行了追加复核。
- 变更范围：仅归档本报告，不实施建议、不修改规则或提示词，不将建议自动加入待办。

| 对象 | 实际覆盖与限制 |
| --- | --- |
| 文本与规则 | 根规则、Project_AGENTS、核心路由，以及知识、验证、完成和产物归属的相关规范；未逐条审核全部工程领域规则 |
| Skill | 阅读 28 个分发 Skill 的入口正文，按问题追查相关 schema、测试策略、专业工作和审核规范；不是全部 references、脚本与行为的全量审核 |
| 提示词与场景 | 枚举 124 条提示词，定向精读 15 条和 4 篇对应场景；未逐条审核其余提示词语义 |
| 脚本 | 未审核实现职责或执行行为，仅核对与文字判断有关的复制范围及命令契约引用 |

本报告采用源码行号帮助定位；行号对应上述版本。下面的建议均属低优先级文字维护，排序表示本轮建议先关注的位置，不表示已发生功能故障。

## 2. 具体发现与最小建议

### 2.1 调研续接的替代完成条件偏宽

**证据：** [prompts.json](../../prompts.json) 第 147 行的“外部调研还没结束，继续查清原来的问题”将完成条件写成“原问题在授权范围得到有依据的结论或具体证据缺口”。[同名场景](<../../docs/quick-reference/Godot 项目开发/项目恢复与交接/外部调研还没结束，继续查清原来的问题.md>) 第 51 行保持一致。

“证据缺口”既可能是已经查证但当前无法取得的材料，也可能只是尚未开始补查的问题。该措辞没有在替代出口处明确区分两者，对应 writing-for-agents 所说的完成界限不够清楚。

**反证与限制：** [researcher.toml](../../../project-source/agents/researcher.toml) 第 9–10 行已经要求问题充分回答，或继续推进需要不可获得的证据，才停止。委派该角色时，主要歧义得到消解。提示词自身也要求继续查证，因此不能断言 Agent 会仅列缺口就结束。不过，[00-overview.md](../../../project-source/methodology/00-overview.md) 第 118 行对直接查询明确引用的是角色的来源与版本指导，没有同样明确地引用停止条件。

**最小建议：** 仅将提示词及同名场景的替代出口限定为“已完成必要查证；剩余问题因当前不可获得的证据无法继续，具体缺口与恢复条件已说明”。不增加调研阶段、固定查询次数或报告门槛。

### 2.2 项目脚本入口中的“职责准则”来源不明

**证据：** [prompts.json](../../prompts.json) 第 154 行要求“按职责准则比较复用、合并和最小新增”；[同名场景](<../../docs/quick-reference/Godot 项目开发/经验沉淀/重复操作已确认值得固化，需要做成项目脚本.md>) 第 24 行要求“对照脚本职责准则”，均未给出该名称的来源。维护侧的职责设计准则不在[项目复制清单](../../project-files.json)中。

这是引用不够明确：生成项目中的读者无法确定它是专有文件名，还是后文一般要求的概称。

**反证与限制：** 提示词紧接着已经列出输入输出、副作用、成功条件、重试与清理要求。[变更范围规则](../../../project-source/agent-rules/00-core/change-scope-and-ownership.md) 和 [maintenance 规范](../../../project-source/methodology/07-engineering-change.md) 也提供可用依据，因此不存在必须找到维护仓库才能工作的证据。

**最小建议：** 去掉“按职责准则／对照脚本职责准则”，保留后面的具体要求；如果确实要引用文件，应指向生成项目已有的准确来源。无需新建准则或分发维护侧整份文档。

### 2.3 Registry 字段契约在多个入口重复展开

**证据：** 以下三处都展开了 `unit_test_paths` 的路径存在性、空数组、登记时机等语义，而不只是一句操作提醒：

- [feature-plan/SKILL.md](../../../project-source/skills/feature-plan/SKILL.md) 第 48 行。
- [02-feature-list-schema.md](../../../project-source/methodology/02-feature-list-schema.md) 第 295 行。
- [08-testing-strategy.md](../../../project-source/methodology/08-testing-strategy.md) 第 111–112 行。

schema 第 274 行已经声明 Registry 语义以测试策略为权威，因此这些展开正文增加了同一规则的维护落点。当前核对的语义一致；没有发现实际漂移。

**最小建议：** 字段语义归测试策略，schema 保留结构并准确引用；feature-plan 保留建立候选、复用现有记录、处理冲突和该步骤需要的提示。涉及更新既有 Registry 的保护要求不应随去重删除。

相近但较弱的例子是 [feature-sync/SKILL.md](../../../project-source/skills/feature-sync/SKILL.md) 第 227 行重复枚举退休字段及历史保留要求，对应 schema 第 278–287 行。这里只适合精简字段正文；Stage 2 展示关系、Stage 3 确认后修改，以及 replacement ID 的规划时机，是同步流程自己的职责，必须保留。

### 2.4 知识使用和维护规则有多份展开正文

**证据：** [Project_AGENTS.md](../../../project-source/Project_AGENTS.md) 第 61、63 行与 [00-overview.md](../../../project-source/methodology/00-overview.md) 第 110、112 行，重复说明查询时机、复用已读材料、核对适用条件、保留经验和提交时机。[09-artifact-lifecycle.md](../../../project-source/methodology/09-artifact-lifecycle.md) 第 40、42 行及[知识 README](../../../project-source/defaults/docs/knowledge/README.md) 第 43–45 行又展开已有条目优先、原始证据、只读边界和不强造记录等要求。

这些不全是无效重复：根入口需要提醒查知识，生命周期文档需要说明产物归属。问题在于多处各自带有一套维护细则，调整某个条件时需要同步追查多个正文。目前未发现冲突。

**最小建议：** 根入口保留触发条件和关键边界；知识组织与维护方法留在知识 README；生命周期文档保留产物归属和证据关系；Stage 保留提交前完成的时序要求。其他位置准确链接，保留帮助恢复上下文的短提醒。

### 2.5 条件性编辑器排障细节仍占据常驻上下文

**证据：** [Project_AGENTS.md](../../../project-source/Project_AGENTS.md) 第 92–100 行限定了本机编辑器检查分支，但根文件仍携带具体错误字符串、四种异常目录名及清理判断。这些诊断资料在状态查询、普通文档维护等任务中不需要。

这符合参考 Skill 的“仅部分分支需要的参考未充分下沉”。它是小范围的上下文组织问题，不能仅凭篇幅认定已经稀释注意力或造成遗漏。

**最小建议：** 根入口保留启动编辑器必须走沙箱外审批的关键护栏，并明确启动前应读的条件指针；具体诊断和目录核对合入已有验证说明的专节。已有的权限、保留旧目录与真实结果约束保持完整，不新增脚本或独立流程。

## 3. 已有设计与不应推导的结论

| 检查角度 | 当前判断 |
| --- | --- |
| 按条件读取 | [Core 路由](../../../project-source/agent-rules/00-core/README.md)按变更、冲突、验证等情境提供入口；Project_AGENTS 第 45 行明确不是全量阅读序列。这部分已经符合参考建议 |
| 阶段正文唯一 | [feature-execute](../../../project-source/skills/feature-execute/SKILL.md) 第 11 行把执行顺序交给唯一 Stage 规范，只要求读取共享约定与当前阶段。不能因阶段多就主张拆成多个 Skill |
| 示例按需加载 | [project-next-step-advisor](../../../project-source/skills/project-next-step-advisor/SKILL.md) 第 37 行只在需要措辞示例时读索引及相关条目，状态查询不读示例 |
| 可判断的完成条件 | [执行规范](../../../project-source/methodology/03-execute-loop.md)要求按 criterion ID 映射证据，并区分环境失败、当前验证和人工验收；不能从一处调研措辞推广为整体完成机制模糊 |
| 固定字段与有用提醒 | 8 个提示词字段属于已确认的组织要求；必要的恢复提示、保护要求和结果概括不因重复出现就应删除 |
| 否定措辞 | “禁止”和“不得”的数量不能证明它们导致误执行；权限、数据保护和验收边界仍需要明确护栏。普通表达可改为目标动作，但本次没有对照运行支持一律删除禁令 |
| 默认行为和无效指令 | 某句话是否无效取决于模型、上下文与实测。不能仅以“Agent 应该懂”认定 no-op，也不建议为压缩文字大量引入需要重新解释的术语 |

本次没有发现必须拆分 Skill 职责的证据。脚本职责未纳入实现审核；提示词与场景仅做定向抽样，未报告的问题不等于全库已经通过。没有进行模型触发率、漏读率或提前结束率实验，也不将外部 Skill 对这些现象的解释当作本项目已验证的因果关系。

## 4. 验证与交付边界

完成了当前文件的静态阅读、关键来源交叉核对和报告本地链接检查。报告归档前检查 Git 差异；未运行 pytest、Godot、项目生成或模型行为测试。未修改手册正文，因此不构建 HTML 阅读版。

建议优先澄清第 2.1、2.2 项，再在维护对应文件时处理第 2.3–2.5 项。以上建议不授予实施权限，不要求本轮补做行为实验，也不新增规则或监督机制。`framework/progress.md` 原有待办状态未变化，本次没有新增已授权实施事项。
