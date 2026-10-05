extends RefCounted

## Shared presentation helpers. These controls own no cue or analysis state.


static func label(parent: Node, text: String, wrap_text: bool = true) -> Label:
	var control := Label.new()
	control.text = text
	if wrap_text:
		control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(control)
	return control


static func button(parent: Node, text: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = text
	control.pressed.connect(action)
	parent.add_child(control)
	return control


static func section(parent: Node, title: String, folded: bool = false) -> VBoxContainer:
	var section_control := FoldableContainer.new()
	section_control.title = title
	section_control.folded = folded
	parent.add_child(section_control)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	section_control.add_child(content)
	return content


static func grid(parent: Node) -> GridContainer:
	var control := GridContainer.new()
	control.columns = 2
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(control)
	return control


static func field(parent: GridContainer, title: String, control: Control) -> void:
	var caption := label(parent, title)
	caption.custom_minimum_size.x = 86
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.custom_minimum_size.x = 120
	if control is OptionButton:
		control.fit_to_longest_item = false
		control.clip_text = true
	parent.add_child(control)


static func show_text(parent: Node, title: String, text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = title
	var body := RichTextLabel.new()
	body.text = text
	body.selection_enabled = true
	body.custom_minimum_size = Vector2(460, 180)
	dialog.add_child(body)
	parent.add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()


# SpinBox 会按 step 取整显示的值。只有用户改过的数值才写回 Cue，
# 否则编辑别的字段时，手写在 .tres 里、不在步长上的合法值会被悄悄改掉。
static func show_number(spin: SpinBox, value: float) -> void:
	spin.set_value_no_signal(value)
	spin.set_meta("edited", false)


static func mark_edited(spin: SpinBox) -> void:
	spin.set_meta("edited", true)


static func edited_number(spin: SpinBox, current: float) -> float:
	return spin.value if spin.get_meta("edited", false) else current
