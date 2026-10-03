# Godot 游戏项目

使用 Windows 11、PowerShell 7、Godot 4.7、GDScript 和 gdUnit4，由一位项目使用者与 Agent 配合开发。项目名称、工具路径和具体玩法由当前项目决定。

可以从游戏想法开始讨论和建立 GDD，也可以维护已有设计。交付规划与实现需要当前范围足够明确的真实设计；空模板不能代替 GDD。具体要求见 [GDD 前提与职责](methodology/01-product-doc-structure.md#gdd-prerequisite-and-authority)。

## 从游戏功能开始阅读

游戏逻辑负责规则、业务状态和有效结果，游戏表现负责玩家如何感知和操作。两者可在同一个业务模块内协作；开发环境、测试和工具共同支持它们。职责边界、商店购买示例与代码组织见[游戏职责与项目组织指南](docs/game-organization.md)。

围绕一个功能，可以按以下关系定位资料；这不是每次工作必须通读的顺序：

1. 从 [GDD](docs/gdd/README.md) 找到游戏目标、规则与体验要求。
2. 从 [UI 设计](docs/ui/README.md)找到界面，从[游戏表现](docs/presentation/README.md)找到具体反馈的过程与方案；非 UI 表现直接由 GDD 引用。
3. 从[项目架构](docs/architecture.md)找到实际状态所有者、实现与协作。
4. 从 [Product](docs/product.md) 和 [Feature](docs/features/README.md) 找到本次交付、局部设计、验证和验收记录。

## 常用入口

| 要做什么 | 从哪里开始 |
| --- | --- |
| 查找文档、台账或当前进度 | [项目文档目录](docs/README.md)，逐项说明用途与初始状态 |
| 选择讨论、设计、规划、开发或审核入口 | [任务路由](methodology/00-overview.md#canonical-task-routing)；项目约束见 [AGENTS.md](AGENTS.md) |
| 执行已批准的 Feature | [执行流程](methodology/03-execute-loop.md) |
| 配置 Python、Godot 和文档语言 | [环境与语言约定](methodology/05-document-language.md)；配置在 `docs/methodology-config.json`，文档默认中文 |
| 运行环境检查、测试或静态检查 | [工具说明](tools/README.md)；GDScript 解析与 lint 见[直接检查说明](methodology/contracts/gdscript-lint.md) |
| 预览与接入图像、音频、Shader、粒子或动画 | [资源工作台示例](asset_workbench/examples/README.md)，可按 F6 运行；示例素材不代表正式游戏素材 |

`main/main.tscn` 是最小启动入口；游戏功能放在 `game/`，复用能力与共享素材分别放在 `components/`、`assets/`，测试放在 `tests/`。具体归属见[组织指南](docs/game-organization.md)。

新项目只有文档用途说明、空台账和最小入口，尚无正式玩法、业务测试或已完成任务。环境就绪、测试通过和人工验收各自需要实际证据。

## 编辑器效率插件

在 Godot 的“项目 → 项目设置 → 插件”中启用或停用。新项目默认启用 Script-IDE、Inspector Tabs 和 Kanban Tasks；Edit Resources as Table 与 Signal Lens 已安装，按需启用。gdUnit4 保持启用，GDScript linter 面板和 SoundManager 全局插件保持停用。

| 插件 | 使用入口与用途 |
| --- | --- |
| Script-IDE | Script 编辑区的标签页、成员大纲和快速搜索；偏好在编辑器设置的 `Plugin / Script Ide` 中调整 |
| Inspector Tabs | 检查器属性分类标签；在高级编辑器设置的 `Inspector Tabs` 中调整布局或切换滚动定位模式 |
| Kanban Tasks | 顶部 `Tasks` 工作区；个人灵感看板默认保存到项目根的 `kanban_tasks_data.kanban`，与开发任务记录各自独立，无同步关系 |
| Edit Resources as Table | 启用后进入顶部 `ResourceTables` 工作区，以表格浏览和编辑 Resource；当前组合在退出编辑器时有资源泄漏诊断，因此默认停用 |
| Signal Lens | 启用后在调试器中查看运行中节点的信号连接与触发；插件会注册 `SignalLens` Autoload，停用时移除，发行导出前先停用 |
