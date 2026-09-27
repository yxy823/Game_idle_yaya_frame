# Skill、Agent 与提示词

[操作手册](../README.md)

Skill 保存可复用方法，Agent 是执行方法的实例，提示词表达本次具体任务。三者不具有相同粒度：每条正式提示词只对应一个具体场景，通用 Skill 与脚本则按职责和独立变化原因划界，不能为了每篇场景复制一套实现。

## Skill 职责速查

以下名称对应生成项目 `.agents/skills/<名称>/SKILL.md`。当前源文件是 [skills 目录](../../../../project-source/skills)，具体触发和排除项以各自 description 与正文为准。

| Skill | 唯一主要职责 |
| --- | --- |
| `project-next-step-advisor` | 根据当前事实给状态、下一步或回复建议；不执行建议 |
| `project-clarifier` | 澄清会实质影响范围或验收的未决问题 |
| `project-terminology` | 保存已确认且含义不变的局部/共享定义与术语引用 |
| `product-author` | 协调 Product 行为要求的创建和变化，交给正确来源维护 |
| `product-init-elicitor` | 梳理游戏总体范围与模块结构 |
| `product-spec-elicitor` | 澄清模块行为；明确契约的实现缺陷交工程流程，不重写需求 |
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
| `review-code` | 独立判断需求符合性、代码质量和实际覆盖 |
| `review-ux` | 操作理解、可操作性及相关无障碍要求 |
| `review-art` | 实际视觉表现与美术/界面规格 |
| `review-audio` | 实际音频和场景播放的听觉与规格符合性 |
| `review-assets` | 资源技术规格、引用、导入及可核实来源 |
| `review-localization` | 语言覆盖、含义、术语与实际显示 |
| `review-balance` | 数值组合与已确认策略、成长及节奏目标 |

前缀帮助识别职责，不代表必须按 design → content → diagnostics → review 全部执行。只读调查、规格编写与实现有不同授权；纯术语已经明确时直接交 `project-terminology`，不重复开启需求访谈。本地化规格也不再由运行接入 Skill 兼管。

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

advisor 起草的提示词同样明确标识各固定字段，不按任务长短省略。状态查询仍直接回答，不为套字段额外生成提示词；等待人工验收、缺少决定或验证受阻应与完成条件分开表达。

职责设计的长期评价规则在 [设计准则](../../../review/baselines/skill-script-prompt-design.md)，项目实际路由在 [方法总览](../../../../project-source/methodology/00-overview.md)。
