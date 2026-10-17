extends RefCounted
## One row of samples per control type the project theme styles, in the states a still control
## can show. They use the project theme, so a token edit restyles them when the theme rebuilds.
## Buttons are GameButton, so hovering and pressing the "正常" sample plays the button motion.

const Cards := preload("res://dev/debug/shared/overview/token_cards.gd")
const GAP := 12
const NAME_WIDTH := 220.0
const PANEL_SIZE := Vector2(160, 64)
const PROGRESS := 60.0
const PROGRESS_WIDTH := 200.0
const LINE_EDIT_WIDTH := 200.0
## Row titles of the theme types the project theme styles. A variation added to the theme builder
## gets its name here; until then its row shows the type name and the base type's name.
const TYPE_NAMES := {
	"Button": "按钮（未选变体）", "ButtonPrimary": "主要按钮", "ButtonSecondary": "次要按钮",
	"ButtonDanger": "危险按钮", "Label": "正文文字", "LineEdit": "输入框", "Panel": "面板",
	"PanelContainer": "面板容器", "ProgressBar": "进度条",
}


static func build(theme: Theme) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", GAP)
	var types := theme.get_type_list()
	types.sort()
	for type in types:
		var base := theme.get_type_variation_base(type)
		if base == &"":
			base = StringName(type)
		if not ClassDB.can_instantiate(base) or not ClassDB.is_parent_class(base, &"Control"):
			continue
		var row := HBoxContainer.new()
		row.name = type
		row.add_theme_constant_override("separation", GAP * 2)
		var fallback := "%s（基于%s）" % [type, TYPE_NAMES.get(String(base), base)]
		var caption := Cards.label(String(TYPE_NAMES.get(type, fallback)))
		caption.custom_minimum_size.x = NAME_WIDTH
		row.add_child(caption)
		var states := _states(base)
		for state: String in states:
			var item := VBoxContainer.new()
			var control: Control = states[state]
			if base != type:
				control.theme_type_variation = type
			item.add_child(control)
			item.add_child(Cards.label(state))
			row.add_child(item)
		column.add_child(row)
	return column


## The states worth showing for a control class, each as a new control.
static func _states(base: StringName) -> Dictionary[String, Control]:
	if ClassDB.is_parent_class(base, &"Button"):
		var pressed := _button(base, "按下")
		pressed.toggle_mode = true
		pressed.button_pressed = true
		var disabled := _button(base, "禁用")
		disabled.disabled = true
		return {"正常（可悬停、按下）": _button(base, "按钮"), "按下": pressed, "禁用": disabled}
	if ClassDB.is_parent_class(base, &"LineEdit"):
		var typed := _control(base) as LineEdit
		typed.text = "输入的文字"
		var empty := _control(base) as LineEdit
		empty.placeholder_text = "占位文字"
		var read_only := _control(base) as LineEdit
		read_only.text = "只读"
		read_only.editable = false
		return {"正常": typed, "占位文字": empty, "只读": read_only}
	var control := _control(base)
	if control is Range:
		control.value = PROGRESS
		control.custom_minimum_size.x = PROGRESS_WIDTH
	elif control is Label:
		control.text = "正文文字"
	elif control is Container:
		control.add_child(Cards.label("面板内容"))
	else:
		control.custom_minimum_size = PANEL_SIZE
	return {"正常": control}


static func _button(base: StringName, text: String) -> Button:
	var button: Button = GameButton.new() if base == &"Button" else _control(base) as Button
	button.text = text
	return button


static func _control(base: StringName) -> Control:
	var control := ClassDB.instantiate(base) as Control
	if control is LineEdit:
		control.custom_minimum_size.x = LINE_EDIT_WIDTH
	return control
