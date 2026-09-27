# 游戏代码组织与命名指南

新建模块、场景、脚本、Resource 或素材，以及调整已有文件归属时，使用本指南判断放置位置和名称。具体约束以[项目规则](project-rules.md)及下文链接的工程规则为准；本页提供判断方法与示例。

## 先确定内容属于谁

项目使用以下共同骨架：

```text
res://
├── main/                  应用入口与顶层组装
│   └── main.tscn          最小启动场景
├── game/                  当前游戏的功能模块
├── components/            输入与职责明确的可复用能力
├── assets/                跨模块共享的素材
├── addons/                插件及其所属文件
└── tests/                 按实际需要添加的项目测试
```

文档、工具和明确标记的示例保留各自位置。`main/main.tscn` 已配置为启动场景；入口存在不代表环境就绪、已有玩法或已经运行成功。GDD 与 Product 初始只有用途与待定说明，尚无 GDD 设计正文或交付预拆分；任务和测试记录为空，环境尚未验证。

| 判断问题 | 建议归属 |
| --- | --- |
| 负责启动应用或连接顶层模块吗？ | 放在 `main/`，具体行为仍由所属模块实现。 |
| 实现当前游戏特有的概念或策略吗？ | 放在 `game/` 中有明确名称的模块；设置、存档、全局 UI 也属于当前游戏的功能。 |
| 消费者能否在不引入当前游戏规则、不查找其全局对象的情况下使用它？ | 确实需要独立复用时放在 `components/`，否则先留在当前模块。 |
| 只供一个模块或场景使用吗？ | 场景、专属脚本、美术、声音与配置尽量放在所属模块附近。 |
| 素材确实跨模块共享吗？ | 放在 `assets/`，或选择更明确的共同归属，例如仅用于 UI 的字体和主题可放在 `game/ui/`。 |
| 来自插件或外部包吗？ | 保留包的边界和命名契约。 |

可复用组件也可以拥有自己的专属素材。只在同一个模块内部共享的 Resource 可以留在该模块；“有多个使用者”不等于必须移入根 `assets/`。

## 有实际内容再展开模块

从当前需要的场景、专属脚本和资源开始。例如，拥有采矿功能的项目可能逐渐形成：

```text
game/mining/
├── mining_panel.tscn
├── mining_panel.gd
├── mining_rules.gd
├── ore_definition.gd
└── ores/
    ├── copper_ore.tres
    └── copper_ore.png
```

这些文件只用于说明，不是初始项目内容。示例假定矿石只属于采矿；若同一物品定义同时服务背包、商店等功能，可由 `game/items/` 统一拥有并供各模块引用。只有内容增长后更方便查找时，才增加 `art/`、`audio/`、`data/` 或更细的功能目录。

模块名称来自当前游戏：探索游戏可能需要 `world/` 与 `actors/`，放置游戏可能需要 `production/` 与 `upgrades/`。有需求再建立相应目录和实现。功能专属面板跟随功能，菜单等全局 UI 可归入 `game/ui/`。

逻辑分层与目录分层分别判断：优先在所属游戏模块内部明确输入、规则与表现的职责。例如，`mining_rules.gd` 与 `mining_panel.gd` 可以同属 `game/mining/`，规则代码不依赖面板实现。再按内容规模与查找、维护需要细分目录；逻辑分层本身不要求新建根级 `core/`、`presentation/` 等目录。依赖方向沿用[项目架构原则](project-rules.md#22-core-architecture-principles)。

## 用领域与职责命名

先表达领域概念，需要区分时再补充职责。项目自有 Godot 文件与目录使用英文 `snake_case`，类名与场景节点名使用 `PascalCase`；场景与专属脚本尽量同名，例如 `mining_panel.tscn` 与 `mining_panel.gd`。第三方原名和工具要求的约定名称按其契约保留。具体要求见[资源命名](../agent-rules/60-assets/naming-and-organization.md)、[GDScript 命名](../agent-rules/10-gdscript/typing-and-api.md#style-and-naming)与[场景结构](../agent-rules/20-scenes/structure-and-ownership.md)。

以下是可选的职责词，按真实需要采用：

| 职责词 | 适用含义 | 示例 |
| --- | --- | --- |
| `Definition` | 在制作阶段定义的内容身份与属性 | `OreDefinition`、`ore_definition.gd` |
| `Config` | 配置特定功能或服务的参数 | `MiningConfig`、`mining_config.gd` |
| `State` | 有明确所有者与生命周期的可变状态 | `MiningState`、`mining_state.gd` |
| `Rules` | 值得与表现分开的领域判断和约束 | `MiningRules`、`mining_rules.gd` |
| `Panel` | 职责有边界的界面面板 | `MiningPanel`、`mining_panel.tscn` |
| `Calculator` | 输入与结果明确的特定计算 | `ProductionCalculator`、`production_calculator.gd` |
| `Store` | 明确的存储、持久化或数据访问边界 | `SaveStore`、`save_store.gd` |
| `Manager` | 对多个所属对象或共同生命周期的真实协调 | `FeedbackManager`、`feedback_manager.gd` |

小模块可能只需要一个场景和脚本。使用职责词不要求同时增加 `class_name`、继承层、Resource 类型或 Autoload；职责能说清时，用具体名称代替笼统的 `utils.gd`。Resource 的角色与可变性见[资源职责、共享与局部性](../agent-rules/21-resources/roles-sharing-and-locality.md)。

## 生命周期与文件位置分别判断

Autoload 按真实生命周期选择，文件仍按职责归属。例如，需要跨场景存续的存档服务可以留在 `game/saving/`；场景局部协调者则跟随其所属场景。`Manager` 后缀不表示全局生命周期，放进 `components/` 也不自动证明它已经独立。

需要跨模块协作时，先指出状态归谁、调用哪个 API、由谁连接双方。组装放在相关父级或协调者，不为接线方便把游戏规则引入通用组件。实现细节沿用[依赖规则](../agent-rules/10-gdscript/structure-and-dependencies.md)与[Autoload 规则](../agent-rules/40-project-config/autoloads.md)。

当实际边界需要说明时，按[架构约定](../methodology/10-architecture-overview.md)维护项目的可选架构文档。新增目录本身不要求创建架构地图、ADR 或额外验证阶段。
