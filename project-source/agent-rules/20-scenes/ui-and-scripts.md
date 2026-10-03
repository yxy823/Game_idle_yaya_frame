# 场景 UI 与脚本绑定

尊重 Control 和 Container 的所有权，以及脚本与资源的兼容性。

## UI

- **[必须]** 使用 Control 和 Container 的布局语义，不手工去对抗 Container 所管理的矩形。
- **[必须]** 以 `Control` 为根、铺满视口的 UI 场景，必须建立明确的 Full Rect 或等价的根节点尺寸契约。不假设新建的 `Control` 根节点会自动铺满视口；它默认的锚点和偏移不构成这个契约。
- **[优先]** 非全屏的控件、弹窗、提示框或嵌入面板，可以使用有意设计的固有尺寸或最小尺寸契约，而不用 Full Rect；把尺寸由谁决定写明确。
- **[复核]** 每个节点反复设置主题覆盖，可能说明应由共享的 Theme 或 ThemeVariation 负责样式。没有理由时不重复设置覆盖。
- **[必须]** 更换 UI 的父节点时，考虑锚点、偏移、尺寸标志、鼠标与焦点行为、主题传播和容器所有权。

### 焦点与模态对话框

这些规则适用于键盘或手柄焦点导航属于已批准 UI 的情况。

- **[必须]** 屏幕或对话框变为可交互时，给一个可见、可获得焦点的 Control 设置初始焦点。自动导航有歧义时，定义焦点邻居；指针悬停不会产生键盘焦点。隐藏的 Control 会失去焦点。参见 Godot 4.7 的[焦点导航指南](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_navigation.html)和 [Control 参考](https://docs.godotengine.org/en/4.7/classes/class_control.html)。
- **[必须]** 活动的模态对话框中，UI 导航保持在对话框之内。关闭或取消时，只有之前的焦点所有者仍然有效、在树中、可见、且在当前屏幕上可获得焦点时，才把焦点还给它；否则使用该屏幕设计的备用焦点（如果有）。已有的对话框焦点行为已满足这个契约时，直接使用它。
- **[复核]** 修改焦点流程时，检查打开、关闭或取消、再次打开，以及原焦点目标被隐藏或移除后的恢复。按项目支持的输入方式测试；这条规则不增加对平台或设备支持的要求。

## 脚本

- **[必须]** 挂载的脚本在 Godot 4.7 下能编译，且其基类型与 Node 类型兼容。
- **[优先]** 大段业务逻辑放在外部 `.gd` 脚本中，不嵌入场景序列化。
- **[必须]** 测试和调试用的插桩不能保留在正式场景中。

## 信号连接方式

| 连接方式 | 适用于 |
| --- | --- |
| 编辑器连接 | 已经存在于同一个编辑好的场景中的 Node |
| 代码中用信号 `Callable` 调用 `connect()` | 运行时实例化的 Node，或有意跨场景的连线 |

- **[优先]** 项目内保持一种约定。编辑器连接在 `.tscn` 及其差异中可见；代码连接把运行时连线集中在 `_ready()` 中，但查看场景文件时看不到。

```gdscript
signal start_requested

# 场景中编辑好的静态节点，可以用编辑器连接到这个方法。
func _on_start_button_pressed() -> void:
	start_requested.emit()

func _ready() -> void:
	# 运行时创建的控件必须在代码中连接。
	var button: Button = _create_dynamic_button()
	button.pressed.connect(_on_dynamic_button_pressed)

func _on_dynamic_button_pressed() -> void:
	queue_redraw()
```
