# 修改空白项目与同步使用说明

[维护文档入口](README.md) · [框架规则](../../../AGENTS.md) · [维护工具](../../README.md)

本页保存框架维护的材料归属、说明同步和验证约定。具体任务入口由文档总入口统一导航，不在这里复写场景流程或正式提示词。

## 先判断修改属于哪里

| 内容 | 维护位置 |
| --- | --- |
| 项目分发材料 | project-source/；路径变化同时核对复制清单 |
| 创建器与复制规则 | framework/commands/create_project.py 与 framework/project-files.json |
| 概念、配置与工具说明 | framework/docs/operation-manual/ |
| 具体项目或维护场景 | framework/docs/quick-reference/ 的对应 Project |
| 项目内简短导航 | project-source/Project_README.md |
| 框架维护、供用户自行复用的 Skill | 仓库根目录的 .agents/skills/；所需参考、配套脚本及私有依赖随各 Skill 保存，不整包分发给项目 |
| Codex 指令编写与审核方法 | .agents/skills/writing-for-agents-yaya/，框架自用，不分发 |
| 框架文档写作 | .agents/skills/technical-documentation-writing-yaya/，框架自用，不分发 |
| Godot 项目文档写作 | project-source/skills/technical-documentation-writing-godot/，独立维护，随 Skill 目录整包分发 |
| Skill、规则和流程正文 | 所属源规范；只有任务涉及行为时调整，整理目录不隐含行为修改 |
| 职责设计和审核事实 | 长期准则在 framework/review/baselines/，当次报告在 framework/review/reports/ |
| 框架共用术语 | framework/docs/terminology.md；项目自己的业务词汇不回灌此处 |
| 正式操作提示词 | framework/prompts.json，唯一手写正文 |
| 维护约束与未完成工作 | 根 AGENTS.md / framework/progress.md |
| 已有游戏的独有修改 | 明确指定的外部项目，不自动回灌或同步 |

编写或审核框架指令时使用 [Codex 指令编写与审核 Skill](../../../.agents/skills/writing-for-agents-yaya/SKILL.md)；整理已确认说明的表达与组织时使用[框架文档编写 Skill](../../../.agents/skills/technical-documentation-writing-yaya/SKILL.md)。职责评价、提示词字段与审核覆盖仍由[职责设计准则](../../review/baselines/skill-script-prompt-design.md)定义，按任务需要查阅，不因使用其中一个 Skill 而固定加载另一个。

Project_AGENTS.md 是待复制源规则。根规则明确引用的沟通、可读性与共用工程约定适用于维护；项目开发 Stage 不在维护仓库启用。查看 Skill 源材料不等于当前任务进入该 Skill 流程。

维护分发的 Godot 文件按领域读取 project-source/agent-rules/，授权、Git、验证地点和交付仍以本维护仓库规则为准。框架面向单人项目，同目录暂停/切换/续接和独立审核支持，不扩展多人改动归属或 worktree 流程。

## 找到受影响的说明

只核对实际变化相关专题及直接调用者，不每次全仓通读。

| 变化 | 操作专题 | 真实依据 |
| --- | --- | --- |
| 复制、目录、重命名、初始化边界 | [框架与项目](../operation-manual/框架基础/framework-and-project.md)、[项目目录](../operation-manual/框架基础/project-layout.md) | 创建器、清单、默认文件 |
| 环境字段、插件或 lint 默认值 | [配置](../operation-manual/框架基础/configuration.md)、[错误含义](../operation-manual/方法与工具/errors-and-results.md) | 配置源、检查器、插件及补丁 |
| Product、AC、依赖、规划与历史 | [需求与规划](../operation-manual/需求与任务/requirements-and-planning.md) | methodology、模板、规划/同步 Skill、检查器 |
| Stage、验收、任务类型、完成或持续授权 | [阶段语义](../operation-manual/需求与任务/feature-lifecycle.md) | 执行规范、Feature Skill、工程规范 |
| 专业所有者、资源、语言或独立审核 | [专业来源](../operation-manual/专业工作与记录/specialist-work.md)、[Skill 与角色](../operation-manual/方法与工具/skills-and-agents.md) | 专业/审核规范、相应 Skill、角色及复制映射 |
| 参数、测试选择、结果、指纹或错误 | [命令与证据](../operation-manual/方法与工具/commands-and-evidence.md)、[错误含义](../operation-manual/方法与工具/errors-and-results.md) | 实际 CLI、tools/lib/verification_snapshot.py、完成校验与测试策略 |
| 工作台、Analyzer、表现组件 | [资源工作台](../operation-manual/专业工作与记录/asset-workbench.md) | 对应工具、示例 README、消费接口及夹具 |
| 术语、设计、架构、规则、研究、知识或 Progress | [知识与记录](../operation-manual/专业工作与记录/knowledge-and-records.md) | 来源规范、生命周期、角色与领域规则 |
| 场景输入、步骤、提示词或出口 | 对应 Project/分类/同名场景 | prompts.json、所属 Skill/methodology/CLI、场景职责清单 |

框架路由、职责、产物、授权或完成机制改变时，同步核对 project-next-step-advisor 的 SKILL.md 及 references/scenarios.md；只更新失效内容，不复制另一套流程。术语唯一入口为 project-terminology，本地化规格为 design-localization-spec，content-localization 负责按已定要求实现。

路径或字段变化追到全部读写方、调用链、模板、复制映射和回归夹具。说明与源码冲突时分别判断实际行为及待修问题，不能只改一段文字掩盖未解决契约。

## 文档同步应包含什么

按变化类型选择需要同步的内容：

- **用户可见行为或默认值变化**：同步对应参数、路径、初始状态、输出、副作用与必要错误解释。
- **结构变化**：更新入口、链接、锚点和相关图。
- **仅内部实现变化**：使用契约不变时，核对后不必制造无意义修改。

文档面向最终行为，不保留两套旧/新教程或空重定向页。历史原因由 Git 与当次报告保存，不建立说明版本状态、同步收据、来源哈希清单或发布资格。

### 说明的组织与措辞

框架说明的详细写法维护在 [Yaya 框架文档编写 Skill](../../../.agents/skills/technical-documentation-writing-yaya/SKILL.md) 中，本节保存框架的页面分工与检查约定。生成项目通过[本地写作入口](../../../project-source/Project_AGENTS.md#使用说明的可读性)使用创建时复制的 Godot 版 Skill；该包独立维护，使用时无需访问框架或框架版写作资料。

| 位置 | 职责 |
| --- | --- |
| docs/README.md | 两册与维护说明的统一导航 |
| operation-manual/ | 框架、概念、对象、配置与工具用法 |
| quick-reference/ | 每篇一个具体场景、一个同名专用提示词；11 类规则只显示有内容的栏目 |
| framework-maintenance/ | 维护规范与验证工具说明，不保留另一套具体场景正文 |

场景按 JSON 的 Project、分类、提示词名称直接对应目录/文件名，对应关系、栏目使用和编号要求维护在速查手册 README；11 类信息的定义与写法引用框架版 Skill 的流程参考，不作为 Godot 项目文档的默认结构。

- **路径核对**：使用 [路径检查器](../../commands/check_scenario_prompt_paths.py) 核对路径集合。
- **内容审核**：正文实质变化时由独立审核者确认标题、输入、单一目标、步骤与出口；调整列表时保留原有条件和先后依赖。只重新生成 HTML 不触发正文复审。

路径匹配不证明内容或实际执行通过。

两本手册之间不互相引用，必要解释就地提供，权威规范、工具和公共术语仍可共同引用。构建脚本自动核对所收录 Markdown 的链接、锚点、收录范围和 HTML 产物结构，不递归审核被引用文件的全部内容与链接。

### 可复用写作 Skill 的维护

[technical-documentation-writing-yaya](../../../.agents/skills/technical-documentation-writing-yaya/SKILL.md) 位于根目录的 `.agents/skills/`，服务整个框架的手册、场景、工具说明、维护设计和审核记录。[technical-documentation-writing-godot](../../../project-source/skills/technical-documentation-writing-godot/SKILL.md) 位于项目 Skill 分发源中，服务实际游戏项目的 README、GDD、Product、Feature、架构、知识和操作说明。框架手册里介绍游戏开发的页面仍由框架版处理；项目中的实际文档由 Godot 版处理。

- **独立正文**：两份 Skill 各自保存 `SKILL.md`、`agents/openai.yaml` 和完整参考。可以独立调整例子、默认组织和写作方法，不跨包引用或自动同步正文；相似原则可分别维护。各自产物的实际契约仍由所属规范拥有，不在写作包中另造流程。
- **发现与调用**：两份元数据均设置 `allow_implicit_invocation: true`，职责由各自 `description` 限定，`short_description` 用于界面展示。框架只启用根目录的框架版；Godot 版源文件在维护仓库只作为分发材料，复制后成为项目本地 Skill。
- **项目分发**：现有 `project-source/skills/` 目录映射整包复制 Godot 版到生成项目的 `.agents/skills/technical-documentation-writing-godot/`，保留内部相对引用。不复制框架版，也不另外生成普通写作指南副本。
- **内容与语言**：框架版保留框架文档的说明语言；Godot 版入口与参考使用项目流程源规范的英文版本，编写产物时读取项目 `document_language`。GDD、Product、Feature 及其验收场景沿用自己的结构，不能套用框架的 11 类栏目或 S1 编号。
- **更新边界**：修改框架版不改变 Godot 版；修改 Godot 版源材料只影响以后创建的项目。已创建项目拥有独立副本，后续更新由用户决定，不回查框架或自动同步。
- **包内资源与外部依据**：每包的写作方法通过内部相对路径读取。框架版查当前框架规范，Godot 版查当前游戏项目的规则、模板、词表和工具，不跨项目读取。当前两包均不需要执行脚本、私有运行时或同步工具。
- **修改验证**：根据真实误用、表达问题或维护成本调整相应条款与示例；分发变化核对复制后的文件、入口和相对引用。首次创建或明显改变适用范围时，用独立试写检查实际结果与可携带性；格式校验不替代内容判断，不要求每次局部改字都重新跑完整试写。

## 保持初始化边界

手册、维护说明、完整提示词、框架自用 Skill 包和框架审核材料不加入项目复制清单，也不移动到 project-source/。Godot 版写作 Skill 是项目自身的分发材料，按普通项目 Skill 整包复制。项目 README 保持自身短导航；生成项目不查询框架、不接受自动同步。

advisor 的精选表达参考由集中 JSON 派生。修改入选正文、选择范围或所引用 Skill 名称后，按 [导出说明](../../README.md#导出-advisor-精选表达参考) 生成并检查；创建器只复制静态材料，项目不承担转换或回查职责。

## 按修改选择验证范围

分发源、外部项目和维护夹具的具体边界见 [复制与运行验证](validating-framework.md)，命令见 [按需检查](../../README.md#按需检查)。

| 修改 | 相称检查 |
| --- | --- |
| Markdown、目录与导航 | 对照源材料核对修改涉及的事实与示例；构建脚本检查所收录手册的链接、锚点、两册隔离与产物；构建范围外的改动文件另做静态链接检查；检查 Git 差异 |
| 只重新生成 HTML | 执行构建脚本并确认退出码与诊断输出；不手动重复链接检查或复审未改正文 |
| HTML 构建器、模板或交互 | 针对改变运行现有构建回归并重新生成；构建成功不等于排版与交互体验已验收 |
| 提示词或场景 | JSON/名称/路径检查与对应正文独立审核；不将其写成已逐条执行 |
| 创建器或清单 | 映射、边界及按需创建器回归 |
| Python 项目工具 | 相关实现与调用静态核对，指定外部项目中的工具回归 |
| Godot 代码、插件、场景或资源 | 按实际影响在指定外部项目运行真实引擎验证 |
| 仅静态或只读请求 | 不生成项目、不启动 Godot、不运行测试 |

文档指纹与人工验收回归可用中立临时 Git 夹具；不创建业务项目或替代真实人工体验。项目工具回归入口不替用户创建/更新项目，不启动引擎。已有结果只在对应最终内容与覆盖仍有效时复用，未执行部分明确保留。

检查手册未被复制无需创建真实游戏，可静态展开清单核对。静态图源核对不是渲染或视觉验收。外部测试项目的机器路径、主场景、台账与历史不回灌默认值。

## 提交与交付

提交与未完成事项遵循[根维护约定](../../../AGENTS.md#本地提交)，不在本页维护第二套规则。交付提供受影响文档入口与真实验证结果；文档任务不宣称游戏运行通过，框架提交不更新已有游戏。

## HTML 阅读版构建

两本阅读版由同一[生成器](../../commands/build_blank_project_handbook.py)使用共享[页面模板](../../commands/blank-project-handbook-page.html)和[交互源码](../../commands/blank-project-handbook-interactions.js)分别生成；命令、参数、环境与输出见[构建用法](../../README.md#构建-html-阅读版)。Markdown 是唯一手写正文，不直接编辑生成的 HTML。

- **自动完成**：解析现有目录与分类，改写本册内部链接，渲染或复用 Mermaid SVG，检查本地链接、锚点、章节覆盖、两册隔离及离线资源，再写入 HTML。
- **失败处理**：检查失败返回非零并保留既有阅读版，按脚本指出的源文件或链接修复后重跑。所选手册全部检查通过后才开始写入。
- **日常重建**：Agent 执行脚本并读取退出码和诊断即可，不手动重复自动检查，不因重新生成而复审已确认正文。
- **体验反馈**：浏览器排版与交互由用户在外部检查，禁止使用 Playwright Skill 做手册可视化检查；人工试读不是生成前置，构建与体验结论分开报告。

## 整体重检与详细报告

按目标选择已有场景，不在维护规范中复写执行步骤：

- **检查当前工作区**：[本地静态审核](<../quick-reference/Yaya 框架维护/维护与复盘/想检查本地框架是否自洽，先做静态审核.md>)。
- **请外部 Agent 审核**：[GitHub 快照审核](<../quick-reference/Yaya 框架维护/维护与复盘/想请独立 Agent 审核 GitHub 上的框架快照.md>)，以固定完整提交 SHA 区分远端快照与本地改动。
- **核实收到的意见**：[外部意见复核](<../quick-reference/Yaya 框架维护/维护与复盘/收到外部审核意见，先核实哪些值得修改.md>)。
- **验证真实流程**：[小任务验证](<../quick-reference/Yaya 框架维护/维护与复盘/想用一个小任务实际验证框架流程.md>)，实际运行范围与静态结论分别记录。

总体判断依据为[设计复盘](../../review/baselines/design-quality.md)，文本与职责评价依据为[职责设计准则](../../review/baselines/skill-script-prompt-design.md)。报告只记录已核实的版本、范围和证据，不授予实施权限。

## 后续用口语继续

同一会话的具体授权、职责、说明同步和如实验证要求继续有效。最新明确要求调整相应目标与范围，已被替代的临时只读、输出或停止条件不永久约束后续工作。

例如先只读分析，再明确说“按该方案修改这两处”，即可在所选范围实施；“这样改合适吗”仍是讨论。已批准且未变的决定不重复确认，新决定和实际人工验收分别处理。交接区分有效原则、当前限制与已替代要求，接收方依自己的实际文件与授权继续。
