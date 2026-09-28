# 两份技术文档 Skill 独立静态审核

审核日期：2026-09-29。执行者：独立审核子智能体 `audit_prompts`。审核依据：[职责设计准则](../baselines/skill-script-prompt-design.md)、当前仓库维护规则及用户已确认的两包独立维护方案。

## 结论与基线

在本次完整读取的两套 Skill 和必要集成改动中，未发现需要修复的实质问题，建议保留当前实现。框架版覆盖框架文档，Godot 版服务实际游戏项目；两者各自拥有完整入口、元数据和参考，允许独立修改。相似写作原则分别维护是本次已确认设计，不作为重复缺陷。

审核对象是当前工作区，不是只有 HEAD 的旧文件。开始与结束核对到的 HEAD 均为 `3fb7cec3ee0c3b9ca4af38d63394a179c0cbc01a`；本次变更尚未提交。最终静态核对时：旧 Skill 的 5 个文件删除，11 个既有源文件修改，两个新目录包含 10 个未跟踪文件，另有两册 HTML 重建差异和一份旧报告的 3 条链接更新。本报告是独立新增产物，不把未提交内容描述为该 HEAD 已包含的内容。

被审实现保持只读；审核者只新增本报告，没有修改 Skill、规则、说明、复制清单或测试。协调者另按旧报告原有的“链接随后续目录迁移更新”声明调整链接；历史结论与审核基线保持原样，没有改写为对本次新包的审核。

## 内容覆盖

以下两个包均枚举并完整阅读，每个包恰有 5 个文件；不是仅检查文件名或 description。

| 文件 | 实际职责与审核结论 |
| --- | --- |
| [框架版 SKILL.md](../../../.agents/skills/technical-documentation-writing-yaya/SKILL.md) | 保留。覆盖框架 README、两册手册、维护说明、设计依据、审核报告和源材料说明；明确框架中介绍 Godot 的手册仍归框架版，实际项目写作归 Godot 版。只处理已确认内容的表达，不接管指令触发、职责或完成机制设计。 |
| [框架版 agents/openai.yaml](../../../.agents/skills/technical-documentation-writing-yaya/agents/openai.yaml) | 保留。展示信息与框架写作职责相符；允许隐式选用的配置存在，但配置本身不证明客户端实际触发稳定。 |
| [框架版 writing-guide.md](../../../.agents/skills/technical-documentation-writing-yaya/references/writing-guide.md) | 保留。普通单页使用本页，结构整理与流程写作按条件读取其他参考；保留既有字段、路径、语言、授权和证据契约，没有把全部参考设为每次必读。 |
| [框架版 document-structure.md](../../../.agents/skills/technical-documentation-writing-yaya/references/document-structure.md) | 保留。目录、标题、正文归属、术语和去重共同服务查找与维护；目录图和参数表明确是示意，不能从例子推导搬迁授权或真实参数。 |
| [框架版 procedure-writing.md](../../../.agents/skills/technical-documentation-writing-yaya/references/procedure-writing.md) | 保留。11 类信息的定义留在框架侧，适用栏目与编号由场景规范决定；概念、设计、报告不强套结构，步骤出口不替代整体完成。 |
| [Godot 版 SKILL.md](../../../project-source/skills/technical-documentation-writing-godot/SKILL.md) | 保留。覆盖实际项目 README、已有 GDD/Product、Feature、架构、知识、研究和验证说明；排除 GDD 初始化、游戏设计决定和代码或 Skill 职责审核，返回后继续原授权任务。 |
| [Godot 版 agents/openai.yaml](../../../project-source/skills/technical-documentation-writing-godot/agents/openai.yaml) | 保留。名称、简短说明和隐式选用配置与项目写作入口一致，没有框架工具或安装依赖。 |
| [Godot 版 writing-guide.md](../../../project-source/skills/technical-documentation-writing-godot/references/writing-guide.md) | 保留。按文档类型指向项目本地契约；明确必需 Product 栏目不能因“不适用”省略，语言由项目配置决定；观察到的代码行为不自动改写批准的游戏规则。 |
| [Godot 版 document-structure.md](../../../project-source/skills/technical-documentation-writing-godot/references/document-structure.md) | 保留。区分设计、交付、架构和知识的说明职责，服从所属规范；示例是可能的组织方式，没有要求为小改动创建全套文档、迁移台账或重写历史。 |
| [Godot 版 procedure-writing.md](../../../project-source/skills/technical-documentation-writing-godot/references/procedure-writing.md) | 保留。只处理实际工具操作、复现和检查说明；明确游戏场景、玩法序列和验收场景不自动变成操作手册，没有引入框架 11 栏、S1 编号、构建命令或新增 Stage。 |

两包的输入均是当前任务、已有文档和相关事实；输出是获准的文档修改或只读建议。结构调整、命令执行、业务决定和验收仍由原任务及所属规范控制。参考中的“例如”“可能”“按需要”等表达与硬性契约区分明确，没有把例子固化成每份文档的必填内容。

## 必要集成核对

完整阅读本次 11 个既有源文件的差异，并追读影响判断的上下文；另核对一份历史报告的链接迁移差异。

| 集成位置 | 核对结果 |
| --- | --- |
| [根 AGENTS.md](../../../AGENTS.md)、[framework/README.md](../../README.md) | 框架写作入口改为 Yaya 版，Godot 版以项目分发源身份介绍；两包可独立维护，不承诺跨包引用或同步。 |
| [维护说明](../../docs/framework-maintenance/updating-the-blank-project.md) | 维护位置、正文归属、发现与调用、分发、语言和验证说明已对应两包。框架版不复制，Godot 版整包复制；保留按需独立试写要求，没有新增同步机制。 |
| [框架与项目说明](../../docs/operation-manual/框架基础/framework-and-project.md)、[场景编写入口](../../docs/quick-reference/README.md) | 旧“三份普通规则”介绍已替换；框架场景仍引用框架版 11 类信息，没有把该结构设为项目文档默认。 |
| [职责设计准则](../baselines/skill-script-prompt-design.md) | 写作参考分别指向两包；审核职责和长期设计准则仍由原文件持有，未交给写作 Skill 自行判定业务行为。 |
| [复制清单](../../project-files.json) | 删除旧三份指南的单独映射；现有 `project-source/skills` → `.agents/skills` 映射包含 Godot 整包。没有框架版的新映射，也没有旧 `agent-rules/00-core/documentation/` 副本。 |
| [项目 AGENTS 源](../../../project-source/Project_AGENTS.md)、[Core 路由源](../../../project-source/agent-rules/00-core/README.md) | 分别从生成项目根目录和 `agent-rules/00-core/` 指向同一个 `.agents/skills/technical-documentation-writing-godot/SKILL.md`。这两个链接按生成后的布局解释，不能因源模板目录没有 `.agents/` 就判为失效。 |
| [文档语言规范](../../../project-source/methodology/05-document-language.md) | 只删除旧中文普通指南的语言例外；新的 Godot 入口与参考为英文规范源，产物仍采用项目 `document_language`，标识与机器结构保持原契约。 |
| [复制回归源码](../../tests/test_project_copy.py) 第 166–194 行 | 真实分发用例调用当前仓库复制入口；新增断言核对必需 5 文件、源与目标完整文件集合、逐文件字节一致，并排除旧包、框架包和旧普通指南目录。断言针对分发契约，没有用内容数量代替行为或写作质量判断。 |
| [2026-09-26 旧审核报告](technical-documentation-skill-review-2026-09-26.md) | 只核对既有迁移声明和本次 3 条链接差异。链接转向框架版继承位置，历史结论、日期与基线未改；没有重新审查或认可旧报告对当前实现的适用性。 |

另定向阅读了[创建器](../../commands/create_project.py)第 24–75 行。其现有目录展开与复制逻辑能够承接新增 Godot 子包，本次没有修改创建器或引入专门安装逻辑。复制回归的源码审查只证明所设计的检查内容；运行结果另列。

## 引用和旧入口

审核者以只读路径检查核对两包 Markdown 中的 9 个内部文件链接，未发现缺失；Godot 结构参考的 `establish-the-document-contract` 锚点与目标标题一致。Godot 写作指南列出的 7 处项目契约或目录均在分发源中存在，其中项目 `docs/knowledge/README.md` 由 `project-source/defaults/docs/` 提供。以上是静态解析和来源核对，没有现场生成项目。

对非历史报告、非 HTML 的当前源材料检索旧 Skill 名称和旧普通指南路径，剩余命中仅为复制回归中要求它们不存在的断言，未发现有效入口仍依赖旧目录。检索服务于本次路径迁移，不代表对全仓其他内容做了语义审核。

初次核对时，两册 HTML 尚保留旧入口。协调者完成重建后，审核者再次检索两册 HTML，旧 Skill 路径及旧普通指南目录均未命中，因此不把这一已消除的中间状态保留为待办。本次没有检查浏览器排版和交互。

## 检查结果的来源与限制

### 审核者亲自完成

- 枚举并完整阅读两个新包的 10 个文件，独立判断职责、读取条件、规则与例子强度、完整性及任务续接边界。
- 阅读 11 个既有源文件的本次差异及上述必要上下文，核对复制目的路径、语言契约、回归断言和正文归属；另核对旧报告 3 条链接迁移。
- 读取 Git HEAD 与未提交状态，进行包内文件链接、项目契约路径及旧入口检索。报告写入前确认目标文件尚不存在。
- 未修改被审实现，没有亲自运行复制回归、Skill 校验器、手册构建、Godot、客户端自动触发试验或两次试写。

### 协调者提供的本轮结果

以下为协调者转交的执行和独立试写结果；审核者没有读取其完整原始日志或试写全文，也没有独立复跑，故不把它们混写为本审核者亲验结果。

| 项目 | 转交结果与实际证明范围 |
| --- | --- |
| 复制回归 | 指定 Python 解释器在沙箱外运行创建器 unittest 文件，10 项通过；未启动 Godot。 |
| 包格式检查 | 两包的 `quick_validate` 均通过；格式结果不替代本报告的内容判断。 |
| 扩展静态链接检查 | 14 份 Skill 或非手册 Markdown 的 112 条链接检查退出码 0，包含生成后路径映射；这是协调者提供的额外结果，不与本审核者的 9 条包内检查混计。 |
| 手册重建 | 退出码 0；操作手册 13 篇、148 个来源链接、2 个图表缓存复用，场景手册 127 篇、999 个来源链接。只支持构建器覆盖的检查，不证明浏览器阅读体验。 |
| Yaya 独立试写 | `audit_skills` 读取入口与 writing-guide，将给定错误报告改为如实区分构建、未运行 Godot、未用户体验和未更新已有项目；只产出对话草稿。 |
| Godot 独立试写 | `audit_rules` 按 `zh-CN` 改写 Product 总览，保留 5 个必需章节、当前手动采集与后续自动范围；没有生成详细 Product/Feature 或套入 11 栏/S1。相对 GDD 链接按目标位置转换，但模拟目标存在性未验证；缺失项目名与历史保留为未知。 |

两次试写是有限情境的输出证据，不能证明所有文档类型或客户端自动触发稳定性。实际引擎运行、用户体验与已有项目更新不属于本次静态审核的完成条件，也没有被报告为通过。

## 分类结论与交付边界

| 类别 | 结论 |
| --- | --- |
| 文本编写 | 已覆盖两包全部正文及本次集成说明，未发现需要修复的问题。阅读入口、示例限定和契约保护清楚。 |
| Skill 职责 | 已覆盖两个完整包，建议保留当前独立维护方案。没有发现越权设计、重复审批或局部返回结束原任务的问题。 |
| 脚本职责 | 没有新增 Skill 脚本或修改生产复制逻辑；只审查复制承接方式和新增回归断言，不作全量脚本审核结论。 |
| 提示词与场景 | 本次未修改任务提示词或具体场景正文；只核对场景编写入口对框架版参考的引用，没有重新审核全部场景。 |

本报告完成的是限定范围独立静态审核，不授予额外修改权限，不代表已正式提交或已更新任何外部游戏项目。尚未亲验的内容已按证据来源注明，不另建审核状态或同步台账。
