# 项目对象与目录

[Godot 项目手册](../README.md)

本页说明生成项目中每类文档和代码放在哪里、谁来写、谁来读。路径都相对项目根目录。目录或模板存在，只表示位置已经准备好，不表示对应的工作已经完成。

想知道一个功能涉及哪些职责，先读[游戏逻辑、表现与协作](game-logic-and-presentation.md)，再回到本页找具体位置。目录按资料用途和业务模块组织，不按“逻辑 / 表现”两层拆分：GDD 同时描述规则与体验，测试和工具也同时服务两者。

## 主要对象及读写关系

### 规则、方法与配置

| 位置 | 保存什么 | 谁维护 / 谁读取 |
| --- | --- | --- |
| `README.md` | 项目导航 | 项目维护者 / 用户与 Agent |
| `AGENTS.md` | Agent 的约束与任务路由 | 项目维护者 / 所有执行 Agent |
| `yaya/agent-rules/` | 按领域划分的工程规则 | 所属规则 / 执行与审核时按任务读取 |
| `yaya/methodology/` | 开发与验证流程契约、模板 | 所属规范 / 执行与审核时按任务读取 |
| `.agents/skills/`、`.claude/skills/` | 各项专门方法（Skill），两个目录内容相同 | 所属 Skill / 主 Agent 按任务选用：Codex 读前者，Claude Code 读后者 |
| `.codex/agents/`、`.claude/agents/` | researcher、independent-reviewer 等角色配置，同一角色的两种格式说明正文相同 | 所属配置 / 宿主加载：Codex 读前者，Claude Code 读后者；文件存在不代表宿主已加载 |
| `docs/methodology-config.json` | 文档语言与工具路径 | 环境准备 / 项目命令 |
| `docs/project-rules.md` | 项目的开发约束与工程原则；条目默认必须遵守，写“建议：”的可有理由地偏离 | 获准的规则修改 / 受影响的工作 |
| `docs/game-organization.md` | 逻辑与表现的职责、文档关系、模块组织与命名判断，源文件见[游戏职责与项目组织指南](../../../project-source/defaults/docs/game-organization.md) | 随项目复制 / 设计与结构工作 |

### 设计与专业规格

| 位置 | 保存什么 | 谁维护 / 谁读取 |
| --- | --- | --- |
| `docs/gdd/` | 游戏定位、体验与反馈目标、核心循环、系统规则、数值、内容与版本范围 | `design-gdd` 维护整体设计，`design-balance` 维护获准的数值主题 / 所有依赖设计的工作 |
| `docs/gdd/design-scope-and-boundaries.md` | 《设计范围与边界》：整体范围、排除项和版本边界 | `design-gdd` 在第一次保存设计时建立 / 讨论、规划、实现与审核 |
| `docs/gdd/open-questions.md` | 《开放问题》：尚未决定的设计选择、影响和解决方式（等用户选择，还是等计算、调查或试玩证据）；初始只有用途说明 | GDD 作者 / 讨论、规划、审核、实验与续接 |
| `docs/terminology.md` | 已确认的项目术语定义（唯一正文） | `project-terminology` / 所有文档；详细玩法规则仍在 GDD |
| `docs/unadopted-ideas.md` | 暂不采纳的设想及原因；不是开发承诺 | 需求讨论 / 采纳时迁移到正式位置并留链接 |
| `docs/art/`、`docs/audio/`、`docs/ui/`、`docs/localization/` | 从 GDD 细化出的共享方向与专业规格 | 对应的 design Skill / GDD 保存整体目标并引用这些正文 |
| `docs/presentation/` | 一次游戏表现的过程、组件、备选方案、采用组合、实现与验收入口；方案专用的资源规格写在对应章节 | `design-game-presentation` 与实现任务 / UI 文档和 GDD 引用；README 只做导航 |

### 交付规划与 Feature 记录

| 位置 | 保存什么 | 谁维护 / 谁读取 |
| --- | --- | --- |
| `docs/product.md` | 交付预拆分：各交付单元的粗略边界、来源、依赖和建议顺序 | `product-author` / 规划 |
| `docs/product/NN-<delivery>.md` | 当前交付单元的范围与衔接，轮到时才编写 | `product-author` / 规划与实现 |
| `docs/feature-list.json` | Feature 的 ID、标题、依赖、状态与详情入口 | 规划与执行 / 可开始任务判断、Feature 记录检查 |
| `docs/features/F0XX.json` | 单个 Feature 的范围、AC、来源、验证义务与 notes | 规划与执行 / 测试选择、完成检查 |
| `docs/features/F0XX-design.md` | 该 Feature 的实施设计与局部决定；简短理由也写在这里 | 原任务 / 不另设 AC 或测试映射 |
| `docs/test-registry.json` | 组件与测试 ID、套件与用例、planned / active / retired 状态 | 规划与实现 / 测试运行器 |
| `docs/feature-list-revisions.json` | 规划实际覆盖的来源基线与修订记录 | 规划与同步 / 不是“最新 Git 提交”的别名 |
| `docs/features/F0XX-evidence.json` | 一个 Feature 的完成证据：验证原件的引用与内容绑定 | 完成记录工具 / 该 Feature 第一次记录真实结果时创建 |

### 架构、知识与过程记录

| 位置 | 保存什么 | 谁维护 / 谁读取 |
| --- | --- | --- |
| `docs/architecture.md` | 当前模块、状态所有者、协作关系与实现导航 | 结构或重要决定改变时更新 |
| `docs/architecture/` | 子系统说明与 ADR | 同上 |
| `docs/knowledge/` | 项目自己的实践经验 | 获准的经验整理 / 规划、调试、实现时查阅 |
| `docs/qa/` | 用户问过、以后还会用到的问题，按主题分文件；可以和其他正文重复 | `qa-explainer-godot` / 用户阅读生成的 HTML 页面；不作为需求或设计依据 |
| `docs/research/` | 外部资料调研 | 获准的调研 / 需要时查阅；不能代替需求正文 |
| `docs/progress.md` | 当前停点与下一步 | 原任务 / 新对话恢复工作 |
| `docs/progress/` | 已归档的执行历史，每项一份 | 原任务 |
| `reports/` | 运行原件、人工验收与任务报告 | 对应工具或用户；默认不纳入 Git |

`source` 字段和链接能帮助找到材料，但不说明材料已获准、仍然有效或已被完整覆盖。测试已登记、测试已执行、验收已决定和 Feature 已 `done` 是四个不同的状态。

## 代码与开发工具

```text
项目根/
├── main/                     最小启动和装配入口
├── game/                     游戏独有模块、场景、状态与资源
│   └── <对象>/tuning/        调参资源：调试台可以修改的参数与实现（按需建立）
├── components/               实际可复用能力
├── assets/                   共享资产（按真实需要组织）
├── .githooks/                提交钩子：提交时检查文档的术语、措辞、链接和链接文字、Godot 资源格式，以及两份 Skill 目录是否一致；另检查提交说明的术语
├── .claude/                 Claude Code 配置：用户消息中有不用的说法时提示 Agent；skills/ 是供 Claude Code 读取的 Skill 副本
├── addons/                   第三方插件及已记录补丁
├── dev/                      只用于开发的内容，导出时排除
│   ├── debug/                调试台：调试入口、共享代码、项目挂钩与各调试对象的候选
│   └── tools/                项目自己的常用命令脚本，README 是脚本列表
├── yaya/                     框架随项目提供的流程、规则与工具
│   ├── methodology/          开发与验证流程契约、模板
│   ├── agent-rules/          按领域划分的工程规则
│   └── tools/
│       ├── checks/           环境、Feature 记录、文件格式、链接、术语与措辞检查
│       ├── features/         组件合并与完成记录命令
│       ├── godot/            由 Godot 执行的项目文件维护脚本
│       ├── lib/              验证快照、解析及共享实现
│       ├── testing/          gdUnit 运行、报告与验证支持
│       └── ui-trial/         在项目副本中按界面任务试用界面
└── tests/
    ├── unit/                 组件级自动测试
    ├── features/             Feature 验收与回归
    └── invariants/           跨任务不变量
```

最小入口只是起点，不是预先搭好的完整架构。代码、场景和资源可以按业务模块放在一起；存档、设置和全局 UI 按实际所有者组织。工程规则目录的编号层级不要求游戏照搬，也不要求预先建立 Bootstrap、Autoload、事件总线或“每类脚本一个目录”。

例如商店模块可以把购买规则和商店面板放在同一目录：前者负责得出有效的购买结果，后者负责显示和交互。职责清楚不等于要建根级的 `logic/`、`presentation/` 目录，怎样拆分按已有结构和维护需要决定。

其他说明：

- `yaya/` 集中存放框架随项目复制的流程、规则和工具。复制后它们属于项目，可以按需修改；游戏的代码、场景、文档和测试不放进 `yaya/`。`reports/` 保存本项目的运行原件和验收记录，留在根目录。
- `dev/debug/` 随项目复制：调试入口、`_shared/` 下的共享代码与测试、项目挂钩 `debug_project.gd`，以及项目自己的调试台说明 `dev/debug/README.md`（唯一的启动命令写在那里）。依赖只能从 `dev/` 指向游戏：`game/`、`main/`、`components/` 和 `project.godot` 不引用 `dev/`，`tests/invariants/` 中的依赖方向测试检查这一点。调试台的测试留在 `dev/debug/` 下，全量测试也运行它们。概念见[调试台与实际接入](../specialist-work-and-records/specialist-work.md#调试台与实际接入)。
- `.git/` 由创建器建立，并把 `core.hooksPath` 设为 `.githooks`；`.godot/`、运行报告、业务测试套件和设计正文在实际工作中产生。
- 初始 GDD 页面含用途说明和默认要求，尚不构成游戏设计。项目预置调试台测试和依赖方向测试；这些文件及占位 Product 不代表验证结果。

## 复制与重命名

完整映射只维护在 [project-files.json](../../project-creation/project-files.json)，主要关系如下：

- **项目入口**：`Project_AGENTS.md → AGENTS.md`、`Project_README.md → README.md`。
- **方法与角色**：`skills/ → .agents/skills/` 和 `.claude/skills/`、`agents/*.toml → .codex/agents/`、`agents/*.md → .claude/agents/`。新增的 Skill 只要放在 skills 目录内，就会随整个目录复制，不需要单独加映射。
- **Skill 的两份副本**：Codex 只从 `.agents/skills/` 发现 Skill，Claude Code 只从 `.claude/skills/` 发现，所以项目里保存两份相同的内容，这是唯一正文原则的例外。不用目录链接代替副本：Windows 的 junction 会被 Git 顺着链接重复提交，忽略它又不会随 Git 进入新建的 worktree。修改 Skill 时两个目录一起改；只改了一份就提交时，[提交钩子](../../../project-source/tools/README.md#提交钩子)拒绝提交。
- **角色的两种格式**：Codex 读 `.codex/agents/` 下的 TOML，Claude Code 读 `.claude/agents/` 下带 YAML 头的 Markdown，格式不同，不能共用一个文件。两份的名称、描述和说明正文相同；文件头按各自宿主填写模型、推理强度和宿主特有的设置，例如 Claude Code 版 implementation-advisor 用 `disallowedTools: Agent` 禁止再委派，并用 `skills` 预加载 implementation-guidance-godot。Codex 只在项目被标为受信任时加载 `.codex/agents/`，文件中的模型与推理强度优先于主 Agent 的启动参数；框架仓库的复制器回归测试检查分发源的两份一致，新增角色时两种格式都要加文件和复制映射。
- **其他材料**：默认文档、工程规则、方法、代码、工具和插件按清单复制。

`framework/`、框架根目录的维护规则和完整提示词库不进入项目。创建器不替换模板变量，也不安装分析器依赖；某个组件被复制进来，不代表项目已经开始使用它。

## 模板与按需记录

`yaya/methodology/templates/` 提供之后按需创建的文件格式：Product、Feature 详情（含工程变更）、Feature 设计、完成证据、人工验收清单、架构和 ADR，另有 Stage 8 学习反馈的回复格式。模板不需要一次填满；正式 JSON 保留所属契约要求的字段，Feature 设计稿按实际内容省略不适用的章节。

Feature 索引、修订记录、测试登记、Progress 和项目规则不是模板：创建项目时直接复制为 `docs/` 下的初始文件，之后由项目自己维护。

GDD 的固定入口、标准主题名称和导入非标准 GDD 的处理，见[GDD 是项目开发的前提](../requirements-and-tasks/requirements-and-planning.md#gdd-是项目开发的前提)。Product 模板用来组织交付，不能代替 GDD。

各类产物的存放位置：

| 产物 | 位置 | 注意 |
| --- | --- | --- |
| 初始化结果 | `reports/initialization.md` | 之后只追加新结果 |
| gdUnit 运行原件 | `reports/gdunit-wrapper/<Feature-ID 或 focused>/run-<id>/` | 保留真实结果，包括失败 |
| 人工验收清单 | `reports/manual-acceptance/` | 用户结论写回同一份清单的 `status` 和 `comment`，不另建结果文件，见[人工验收文件](../../../project-source/methodology/contracts/manual-acceptance-files.md) |
| Feature 自定义结果 | `reports/features/<Feature-ID>/` | — |
| 本地导出包 | `reports/exports/<日期>/` | 不进 Git，见[本地导出检查](../../../project-source/tools/README.md#本地导出检查) |
| 其他维护报告 | `reports/maintenance/<任务>/` | — |
| 临时文档 | 项目根目录 `tmp/<任务>/` | 草稿、当次方案、交接副本与资料摘录，可按主题分层；不放进正式目录 |
| 临时探针、命令辅助文件与验证副本 | `reports/scratch/<任务>/` | 目录名带 scratch 不代表可以随意删除；以后还会用到的命令脚本按[保存常用脚本](../../../project-source/methodology/09-records-reports-and-handoff.md#保存常用脚本)提出保存，用户同意后移到 `dev/tools/` |

临时目录里不能存放重要代码或决定的唯一副本；等待用户决定是否保存的脚本可以暂留在 scratch。当前验收、失败调查或知识条目还在引用的报告要保留；需要重新归组时，同时修改读写这些报告的工具和引用。工具原件的固定路径不要随意搬动。

## Git 与 Godot 扫描的区别

Git 的默认范围如下，具体规则以[默认 .gitignore](../../../project-source/defaults/.gitignore) 为准：

- **默认忽略**：Godot 缓存、派生的翻译缓存、`reports/`、`tmp/` 和本机秘密；`.env.example`、`.env.template` 可以保留。
- **按项目规则跟踪**：源素材、必要的 `.import`、`.gd.uid`、导出预设、插件、Skill 和正式文档。

几个容易混淆的概念：

- `.gdignore` 只控制 Godot 是否扫描某个目录，与 Git 是否跟踪、文件能否删除无关。
- `.import` 是导入配置，`.godot/` 是缓存，不能一起当作垃圾清空。
- `reports/` 默认不进 Git，所以提交代码不会把验证原件带到其他目录或机器。

相关专题：[知识、设计与记录](../specialist-work-and-records/knowledge-and-records.md)、[专业来源与资源](../specialist-work-and-records/specialist-work.md)。
