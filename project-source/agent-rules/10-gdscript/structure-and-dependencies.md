# GDScript 结构与依赖

明确所有权和依赖方向，不通过 SceneTree 去发现协作对象。

## 职责

- **[必须]** 每个脚本只有一个主要职责。不为了满足度量阈值而机械地拆分文件；按真实的职责和依赖边界拆分。
- **[必须]** 可变的业务状态只有一个权威所属方。其他系统通过所属方定义的 API 或命令路径修改它。悬停、显示插值等表现层的局部状态属于其表现所属方，不是玩法数值的第二个权威来源。
- **[优先]** 相互独立的能力优先用组合。只有稳定的 `is-a` 关系和受支持的共享契约才使用继承。
- **[复核]** 只在目标 Godot 版本和架构确实需要抽象契约时使用抽象类；不为假想的复用搭建继承脚手架。

## 依赖方向

- **[优先]** 场景内部的引用使用 `$` 或 `%`。不通过很深的父节点路径、根路径或递归的 `find_child()` 搜索来发现跨模块依赖。
- **[必须]** 跨模块依赖使用明确的 API、依赖注入、协调者或其他有意设计的边界。
- **[必须]** 默认的依赖方向是：向下用命令（Command）或 API 调用，向上用事件或信号。同级模块通过所属方或协调者通信，不直接访问彼此。
- **[必须]** 按[导出、属性与信号](typing-and-api.md#导出属性与信号)选择信号 API，包括动态边界的例外情况。
- **[必须]** 分组用于给行为分类并向成员广播，不是隐藏的全局服务定位器。

### 通信示例

父节点负责协调，可以调用子节点的 API。子节点向上报告事件，不通过 `get_parent()` 查找或修改父节点。

区分“请求一个动作”“动作被接受后的结果”和“读取当前状态”，说明见 `docs/game-organization.md`。下面的示例假设拾取已被接受、且物品一定能加入；如果加入可能失败，先处理这个结果，再显示成功反馈。打开 HUD 时显示当前背包内容，本身不应重放拾取事件。

```gdscript
# parent.gd
extends Node

@onready var inventory: Node = $Inventory
@onready var hud: Control = $HUD

func _ready() -> void:
	$Player.item_collected.connect(_on_player_item_collected)

func _on_player_item_collected(item_id: String) -> void:
	inventory.add_item(item_id)
	hud.show_item_pickup(item_id)
```

```gdscript
# player.gd
extends Node

signal item_collected(item_id: String)

func collect_item(item_id: String) -> void:
	item_collected.emit(item_id)
```

不要把它改成 `get_parent().get_node("HUD")` 或查找同级节点。如果要让信号穿过多层场景转发、会形成信号迷宫，使用 `40-project-config/autoloads.md` 中描述的专用 Autoload 事件总线模式。

## 全局服务与可测试性

- **[必须]** 只按 [Autoload 适用范围](../40-project-config/autoloads.md#适用范围) 使用 Autoload；它不是图方便的服务定位器。
- **[必须]** 测试和调试适配器调用与正式代码相同的 API 和命令边界。不创建任意的反射 setter 或通用的 `set_property` 后门。
- **[优先]** 在符合真实架构、且能提高可测试性时，把可以独立测试的规则计算与 SceneTree、I/O、特效和外部服务分开。依赖物理或场景生命周期的玩法，仍然负责它自己的游戏规则判断；Node 不会因为是 Node 就自动成为表现对象。
