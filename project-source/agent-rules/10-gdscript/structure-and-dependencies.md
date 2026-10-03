# GDScript 结构与依赖

明确状态归谁、依赖朝哪个方向，不通过 SceneTree 搜索去发现协作对象。职责模型与示例见 [docs/game-organization.md](../../docs/game-organization.md)。

## 职责

- 每个脚本有一个主要职责。按真实的职责和依赖边界拆分文件，不按行数、节点数、复杂度等度量拆分。lint 的度量只是审核信号，见 [指标只是信号](../../methodology/contracts/gdscript-lint.md#指标只是信号)。
- 可变的业务状态只有一个权威所属方。其他系统通过所属方提供的 API 修改它。悬停、显示插值这类表现状态属于表现所属方，不是玩法数值的第二份权威。
- 建议：相互独立的能力用组合；只有稳定的 `is-a` 关系才用继承。不为假想的复用搭建抽象基类。

## 依赖方向

- 父节点或协调者向下调用子模块的 API；子模块向上发出信号，不用 `get_parent()` 查找或修改父节点。同级模块经由所属方或协调者通信，不直接访问彼此。
- 场景内部的引用用 `$Child` 或 `%UniqueName`。跨模块依赖用导出引用、注入或协调者，不用深层父路径、`/root/...` 路径或递归的 `find_child()`。
- 分组用于分类和广播，不用作隐藏的服务定位器。
- 只按 [Autoload 适用范围](../40-project-config/autoloads-and-plugins.md#autoload) 使用 Autoload。信号需要穿过多层场景转发时，按其中的事件总线做法处理。

下面的父节点负责接线：收到拾取事件后先更新背包，再通知 HUD。示例假设拾取一定成功；加入可能失败时，先处理失败结果，再决定是否显示成功反馈。

```gdscript
extends Node

@onready var _player: Player = $Player
@onready var _inventory: Inventory = $Inventory
@onready var _hud: Hud = $Hud


func _ready() -> void:
	_player.item_collected.connect(_on_player_item_collected)


func _on_player_item_collected(item_id: StringName) -> void:
	_inventory.add_item(item_id)
	_hud.show_item_pickup(item_id)
```

`Player`、`Inventory`、`Hud` 是项目中带 `class_name` 的脚本；`Player` 声明 `signal item_collected(item_id: StringName)`。

## Command 与 Query

这里的 Command 指会修改状态的业务操作入口，可以是所属方的普通方法，也可以是 Command 对象。何时需要 Command 对象见 [docs/project-rules.md](../../docs/project-rules.md)。

- Command 表达稳定的业务意图，例如 `buy_upgrade(upgrade_id)`。不提供 `set_property`、`call_method` 这类任意修改或反射式入口。
- 修改状态的 Command 与只读的 Query 分开。Query 不顺带修复、创建或推进状态。
- Command 中的实体引用用稳定的业务 ID 或槽位 ID，不用 NodePath 或 UI 节点名。
- 被拒绝的 Command 不留下部分修改：先完成全部校验，再修改权威状态。
- 建议：可能失败的 Command 返回或发出结构化的结果，例如结果枚举加原因；日志文本不是唯一的成功或失败接口。
- Input Action 与 Command 是两个命名空间。输入适配层把带上下文的输入意图映射到 Command，Command 不读取 Input。

## 调试控制台与测试入口

- 调试控制台或文本命令只负责解析参数、解析引用，然后调用带类型的生产 Command；不重新实现业务逻辑，也不跳过校验、成本、阶段检查或事件发出。
- 测试与调试代码不在生产代码中开后门，要求见[测试与调试后门](../70-tests/production-isolation.md#测试与调试后门)。
- 建议：能独立测试的规则计算，与 SceneTree、I/O、特效和外部服务分开。依赖物理或场景生命周期的玩法，仍由它自己的 Node 负责规则判断。
