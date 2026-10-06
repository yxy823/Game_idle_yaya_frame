# 输入与 Command 测试

区分轮询得到的 Action 状态、事件路由、UI 适配层和业务 Command，按被测契约选择路径。Command 与 Query 的生产设计见 [structure-and-dependencies.md](../10-gdscript/structure-and-dependencies.md)。

## 输入路径

- `Input.action_press()` 和 `Input.action_release()` 只改变轮询得到的 Action 状态，例如 `Input.is_action_pressed()`。它们不产生事件，不经过 `_input()`、`_unhandled_input()` 或 GUI。注意：Action 不在 InputMap 中时，这两个方法报 ERROR，会让测试运行失败。
- 事件路由、GUI 消费、焦点、`mouse_filter` 或 Viewport 路由是契约时，用 `Input.parse_input_event()` 或 gdUnit SceneRunner 的输入模拟，不直接调用处理函数。
- `InputEventAction` 证明的是 Action 语义，不是物理按键或鼠标的绑定：

```gdscript
func _send_action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
```

- 物理绑定、修饰键、`exact_match`、鼠标按键与滚轮等设备特有的行为，用真实的物理 InputEvent 测试，例如 `InputEventKey`、`InputEventMouseButton`。
- 玩法测试使用语义 Action 或生产 Command，不绑定当前的默认按键。
- 测试注入的按下状态在 teardown 中释放，见[清理](fixtures-and-isolation.md#清理)。

## UI 与业务行为

- UI 连接、UI 状态和下游的业务行为，是不同的测试目标。
- 契约是“用户能点击这个控件”时，直接发出控件信号或调用处理函数不算证据。
- 业务规则通过 Command 或领域 API 测试，不强制经过鼠标或 UI。
- 业务断言读取权威的领域状态或查询，不从深层的 UI Node 推断状态。

## Command 测试

- 夹具可以快速建立合法的初始状态，但准备过程与被测的 Command 是两回事。
- 被拒绝的 Command，既断言失败结果，也断言权威状态没有任何部分修改。
- 文本或控制台命令的解析器测试，与 Command 行为测试分开。
- 建议：复杂 Bug 从合法的初始场景、确定的种子与时间输入，加一串生产 Command 复现。
