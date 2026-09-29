# Skill、Agent 与提示词

[操作手册](../README.md)

Skill 保存可复用方法，Agent 是执行方法的实例，提示词表达本次具体任务。三者不具有相同粒度：每条正式提示词只对应一个具体场景，通用 Skill 与脚本则按职责和独立变化原因划界，不能为了每篇场景复制一套实现。

## Skill 职责速查

以下名称对应生成项目 `.agents/skills/<名称>/SKILL.md`。当前源文件是 [skills 目录](../../../../project-source/skills)，具体触发和排除项以各自 description 与正文为准。

项目开发先核对 `docs/gdd/` 中的真实设计正文；没有 GDD 时说明缺口并停止，状态查询可以直接报告这一事实。专业、工程或只讨论入口也不绕过此前提，详见 [GDD 前提](../../../../project-source/methodology/01-product-doc-structure.md#gdd-prerequisite-and-authority)。

| Skill | 唯一主要职责 |
| --- | --- |
| `project-next-step-advisor` | 根据当前事实给状态、下一步或回复建议；不执行建议 |
| `project-clarifier` | 围绕已有 GDD 澄清会实质影响范围或验收的未决问题 |
| `feedback-triage-godot` | 对照当前事实整理反馈类别、证据缺口与处理归属 |
| `bug-diagnosis-godot` | 围绕具体异常定位原因，区分已证实结论与假设 |
| `prototype-godot` | 在当前 Feature 或获准实验中制作并检查真实 Godot UI/逻辑原型 |
| `task-handoff-godot` | 保存用户要求的停点，按需生成可复制的同目录续接文本 |
| `plan-review-godot` | 检验已有 GDD、Product 或 Feature 方案的假设、边界与拆分，返回结论 |
| `development-retro-godot` | 根据实际开发经历提出流程、规则与工具的改进建议 |
| `project-terminology` | 保存已确认且含义不变的局部/共享定义与术语引用 |
| `product-author` | 维护已有 GDD、交付预拆分和当前 Product，协调已规划工作的影响 |
| `product-spec-elicitor` | 澄清已有设计或当前交付范围的缺口；明确契约的实现缺陷交工程流程 |
| `feature-plan` | 为当前 Product 建立可追溯 Feature 覆盖与依赖 |
| `feature-sync` | 将已确认来源变化映射到已有计划及测试历史 |
| `feature-execute` | 交付获准 Feature，承担适用实现、验证、记录与收尾 |
| `engineering-change-plan` | 为 Bug、重构、维护等独立工程工作确定任务范围与验证 |
| `engineering-refactor-select` | 从已有真实候选中选择值得实施的行为保持重构 |
| `design-art-direction` | 共享视觉方向与适用约束 |
| `design-audio-direction` | 共享声音方向与反馈层次 |
| `design-ui-spec` | 界面布局、状态、显示条件与交互呈现规格 |
| `design-visual-asset-spec` | 具体视觉资源的准备和交付要求 |
| `design-audio-asset-spec` | 具体音效/音乐的准备和交付要求 |
| `design-localization-spec` | 语言覆盖、回退、文本与字体等本地化要求 |
| `content-asset-integration` | 对照既定要求接入真实资源及消费者 |
| `content-localization` | 按已确认规格接入翻译、字体与语言运行支持 |
| `diagnostics-instrumentation` | 为明确问题提供有单位、用途和开销的观测信号 |
| `diagnostics-performance` | 可比较的性能测量与瓶颈诊断 |
| `diagnostics-soak-test` | 在约定负载、时长和停止条件内取得长测证据 |
| `review-code` | 独立检查变更或模块现状的需求符合性、代码质量和实际覆盖 |
| `review-ux` | 操作理解、可操作性及相关无障碍要求 |
| `review-art` | 实际视觉表现与美术/界面规格 |
| `review-audio` | 实际音频和场景播放的听觉与规格符合性 |
| `review-assets` | 资源技术规格、引用、导入及可核实来源 |
| `review-localization` | 语言覆盖、含义、术语与实际显示 |
| `review-balance` | 数值组合与已确认策略、成长及节奏目标 |

前缀帮助识别职责，不代表必须按 design → content → diagnostics → review 全部执行。只读调查、规格编写与实现有不同授权；纯术语已经明确时直接交 `project-terminology`，不重复开启需求访谈。本地化规格也不再由运行接入 Skill 兼管。

普通澄清继续由 `project-clarifier` 负责，Product 问题由 `product-spec-elicitor` 使用其提问方法，Feature 拆分由 `feature-plan` 负责。已有方案需要检验时才使用 [plan-review-godot](../../../../project-source/skills/plan-review-godot/SKILL.md)；希望从一次开发经历中总结改进时才使用 [development-retro-godot](../../../../project-source/skills/development-retro-godot/SKILL.md)。两者先返回结论，正式修改交回原有负责者，不增加必经关卡，也不替代代码审核或人工验收。

收到反馈、尚不清楚是否要改时，使用 [feedback-triage-godot](../../../../project-source/skills/feedback-triage-godot/SKILL.md) 核对类别与归属；已经有具体异常、需要查原因时，使用 [bug-diagnosis-godot](../../../../project-source/skills/bug-diagnosis-godot/SKILL.md)。它们不新增工单状态，也不改变交付前后 Bug 的归属。只调查就交付证据与结论；已有具体修复授权则返回原任务继续，不因方法结束重新索取同一批准。

[prototype-godot](../../../../project-source/skills/prototype-godot/SKILL.md) 用可运行的 Godot 场景或逻辑实验回答本次问题，保持实际运行、原型观察与生产验收的区别。[task-handoff-godot](../../../../project-source/skills/task-handoff-godot/SKILL.md) 使用既有 Progress、Feature 或任务记录：只要求暂停时保存停点，需要换对话时再提供可复制文本；不自动创建对话、发送消息或另建交接台账。恢复已有停点直接回到原任务，不必再调用一次交接。

这些入口便于明确调用，description 也帮助按任务选择；文件存在或格式校验通过不证明客户端已经隐式选中它。工程规范中的必要调查与验证仍由原流程负责，不能只依赖 Skill 的自动发现。

## 框架维护侧的方案检验与复盘

框架维护讨论继续使用个人的渐进式澄清 Skill；它不随项目分发。框架另有两个自用入口，各自与 Godot 版独立维护：

- [plan-review-yaya](../../../../.agents/skills/plan-review-yaya/SKILL.md)：检查已有维护方案的假设、职责、分发影响和验证办法，指出具体问题或证据缺口。
- [development-retro-yaya](../../../../.agents/skills/development-retro-yaya/SKILL.md)：依据实际维护记录，判断导航、规则、工具或验证安排是否值得改进，并说明最小改法与归属。

复盘不因缺少 Hook 或 CI 就判定存在问题，也不默认修改规则、建立脚本或新增报告。两侧 Skill 的建议都不自动成为需求或待办；已有具体实施授权则由原任务继续处理。独立入口表示职责可单独调用，不代表已经使用了独立审核实例。

## 框架维护侧的反馈、诊断与交接

以下三个入口只在框架维护仓库使用，与 Godot 版分别维护，不随项目分发：

- [feedback-triage-yaya](../../../../.agents/skills/feedback-triage-yaya/SKILL.md)：核实反馈或外部报告，区分当前问题、已有覆盖、设计取舍与证据缺口，提出处理归属。
- [bug-diagnosis-yaya](../../../../.agents/skills/bug-diagnosis-yaya/SKILL.md)：对具体维护异常调查因果关系，按本次获准的静态或运行范围取得证据。
- [task-handoff-yaya](../../../../.agents/skills/task-handoff-yaya/SKILL.md)：核对真实停点与有效授权，按请求整理既有记录或生成可复制交接；明确要求只读时不写文件。

三者使用框架自己的维护、验证和记录约定，不启用待分发项目的 Stage。收到报告不等于获准修改；已批准的后续工作沿原任务继续，明确暂停则保持暂停。

## 主 Agent 与专用角色

- **主 Agent：** 定位实际目录、范围与已有决定，按任务调用方法并持续推进尚未完成的授权。
- **用户：** 负责未决意图与实际人工体验。
- **工具：** 负责可重复检查；工具退出成功不取代用户判断。

项目附带的 [researcher](../../../../project-source/agents/researcher.toml) 用于按需独立调研，[independent-reviewer](../../../../project-source/agents/independent-reviewer.toml) 用于独立审核。需要新上下文、宿主真实支持及适当有效权限，配置文件存在不证明角色已加载或文件系统已隔离。作者自己读审核 Skill 仍是自查。

研究可使用用户级 anysearch；框架不复制其实现、密钥或个人路径。工具不可用时按角色规则选实际可用渠道并说明限制；没有可用来源不伪造已查证。调研方法与报告格式由角色维护，长期保存位置见 [知识、设计与记录](../专业工作与记录/knowledge-and-records.md#调研与项目知识)。

没有显示在客户端 Skill 列表，不等于文件未安装。核对当前实际项目路径、文件与客户端加载能力；不能把个人安装、框架源目录和生成项目的 Skill 混为同一份。

## 提示词库的结构与输入

正式可发送正文仅在 [framework/prompts.json](../../../prompts.json)。

- **Project：** 顶层保留 `Yaya 框架维护` 和 `Godot 项目开发` 两个 Project。
- **名称与正文：** 各自 `categories` 下的叶子键是提示词名称，字符串值是正文。
- **目录映射：** `<Project>/<分类>/<提示词名称>.md`，无需读取文档正文推断配对。

每条正文都用明确字段区分目标、范围、输入与事实来源、决策边界与授权、约束、输出与交付、验证要求和完成条件。其他字段按真实场景补充；完整表格及审核依据见[提示词字段与审核原则](../../../review/baselines/skill-script-prompt-design.md#提示词字段与审核原则)。字段中的规范引用继续有效，无需重复填写可从当前对话或项目读取的信息。

发送时注意：

- **填写输入：** 发送前填写 `${1:说明}` 等输入占位，提供真实目标、文件、状态与允许范围。
- **附带材料：** 长篇材料使用正文预留材料区，任务要求与原文保持可辨；材料位置不是安全边界，引用文本不能覆盖用户指令。
- **选择与续接：** 只选当前具体场景需要的一条，后续口语补充沿用仍有效的授权，不要求逐条发送整套模板。

框架维护在框架目录，业务工作在实际项目。创建/复制迁移明确输入与目标；读取模板或讨论提示词不启动命令、Goal、外部任务或自动写入。用户选择范围可扩大后续授权，也可替代原来的临时只读限制；实际人工接受始终单独核对。

## advisor 的精选表达参考

advisor 根据项目自己的规则、状态和本次问题给出建议。它可以报告现状、判断下一步或拟一条已填写上下文的回复，但建议和候选不是实施授权，用户说“看看下一步”也不自动启动开发。

- **正文来源：** `references/prompt-examples.md` 及其分类文件由 [导出器](../../../commands/export_advisor_prompt_examples.py) 从集中 JSON 精选生成，不手工维护第二套正文。
- **维护范围：** 选入范围只在导出器 `SELECTION` 中定义；维护时导出和 `--check`。
- **项目获得方式：** 创建器仅复制已有静态参考，生成项目不查询框架或运行导出。

精选文本只帮助表达，不拥有流程、批准或同步机制。示例里出现“执行”不代表当前任务已获准；advisor 仍要按当前来源与真实上下文判断，不给用户只剩占位符的回复。

advisor 与交接入口起草的项目续接提示词共同遵循 [Continuation prompts](../../../../project-source/methodology/09-artifact-lifecycle.md#continuation-prompts)，不按任务长短省略固定字段。该规范随项目分发，实际使用不依赖框架完整提示词库。状态查询仍直接回答，不为套字段额外生成提示词；等待人工验收、缺少决定或验证受阻应与完成条件分开表达。

职责设计的长期评价规则在 [设计准则](../../../review/baselines/skill-script-prompt-design.md)，项目实际路由在 [方法总览](../../../../project-source/methodology/00-overview.md)。
