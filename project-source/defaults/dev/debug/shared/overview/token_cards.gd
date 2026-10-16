extends RefCounted
## Token cards built by reflection over the UI tuning resources: every exported field, named by
## the shared slots' slot.gd. Primitive values are drawn (swatch, text size, spacing bar, corner,
## border, shadow); a semantic field shows the primitive step it picks and that step's value.

const SWATCH := Vector2(28, 28)
const BOX := Vector2(56, 36)
const BAR_HEIGHT := 12.0
const CARD_WIDTH := 380.0
const TITLE_SIZE := 22
const CATEGORY_SIZE := 26
const GAP := 12
## Field name, drawn value, value text.
const COLUMNS := 3
const SAMPLE_TEXT := "示例 Aa"
const MOTION_SAMPLE := "移上鼠标、按下试动效"
## Colors of the drawn spacing bars, corners and borders; they are not tokens.
const DRAW_FILL := Color("5b8def")
const DRAW_LINE := Color("43434c")
const DRAW_BACK := Color("ffffff")
const SHADOW_COLOR_FIELD := &"shadow"

var tokens_root: String
var names_root: String
## Slot id prefix of tokens_root, for the category titles: "shared/ui".
var category_prefix: String
## The shared target's CATEGORIES.
var categories: Dictionary = {}
## Every token resource, by path relative to tokens_root without ".tres".
var tokens: Dictionary[String, Resource] = {}
## Primitive resources by global class name, to resolve the steps semantic fields pick.
var _primitives: Dictionary[String, Resource] = {}
## Chinese step names by enum class ("UiPalette.Swatch"), from the slots' VALUES.
var _step_names: Dictionary[String, Dictionary] = {}


func load_tokens() -> void:
	tokens.clear()
	_collect(tokens_root, "")
	for relative in tokens:
		var resource := tokens[relative]
		var script := resource.get_script() as Script
		while script != null:
			if not script.get_global_name().is_empty():
				_primitives[script.get_global_name()] = resource
			script = script.get_base_script()
		var values: Dictionary = _slot(relative).get("VALUES", {})
		for property in fields(resource):
			if property.usage & PROPERTY_USAGE_CLASS_IS_ENUM and values.has(property.name):
				_step_names[property.class_name] = values[property.name]


## The exported fields of a token resource, in declaration order.
static func fields(resource: Resource) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for property in resource.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_STORAGE:
			result.append(property)
	return result


## One heading and a row of cards per token directory, in the order of the shared CATEGORIES.
func build() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", GAP)
	var groups: Dictionary[String, Array] = {}
	for relative in tokens:
		var directory := relative.get_base_dir()
		if not groups.has(directory):
			groups[directory] = []
		groups[directory].append(relative)
	var order := groups.keys()
	var keys := categories.keys()
	order.sort_custom(func(a: String, b: String) -> bool:
		var rank_a := _rank(keys, _category(a))
		var rank_b := _rank(keys, _category(b))
		return rank_a < rank_b if rank_a != rank_b else a < b)
	for directory: String in order:
		column.add_child(heading(String(categories.get(_category(directory), directory)),
			CATEGORY_SIZE))
		var cards := HFlowContainer.new()
		cards.add_theme_constant_override("h_separation", GAP)
		cards.add_theme_constant_override("v_separation", GAP)
		for relative: String in groups[directory]:
			cards.add_child(_card(relative))
		column.add_child(cards)
	return column


static func label(text: String) -> Label:
	var item := Label.new()
	item.text = text
	return item


static func heading(text: String, font_size: int) -> Label:
	var item := label(text)
	item.add_theme_font_size_override("font_size", font_size)
	return item


func _category(directory: String) -> String:
	return category_prefix.path_join(directory)


## Directories without a category title come last.
static func _rank(keys: Array, key: String) -> int:
	var rank := keys.find(key)
	return rank if rank >= 0 else keys.size()


func _collect(directory: String, prefix: String) -> void:
	for file in DirAccess.get_files_at(directory):
		if file.get_extension() == "tres":
			tokens[prefix + file.get_basename()] = ResourceLoader.load(directory.path_join(file))
	for child in DirAccess.get_directories_at(directory):
		_collect(directory.path_join(child), prefix + child + "/")


## Constants of the token's slot.gd: TITLE, FIELDS and VALUES; {} when it has none.
func _slot(relative: String) -> Dictionary:
	var path := names_root.path_join(relative).path_join("slot.gd")
	if not ResourceLoader.exists(path):
		return {}
	return (ResourceLoader.load(path) as Script).get_script_constant_map()


func _card(relative: String) -> PanelContainer:
	var resource := tokens[relative]
	var names := _slot(relative)
	var card := PanelContainer.new()
	card.name = relative.replace("/", "_")
	card.custom_minimum_size.x = CARD_WIDTH
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", GAP)
	card.add_child(column)
	column.add_child(heading(String(names.get("TITLE", relative.get_file())), TITLE_SIZE))
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", GAP)
	column.add_child(grid)
	var titles: Dictionary = names.get("FIELDS", {})
	var values: Dictionary = names.get("VALUES", {})
	for property in fields(resource):
		var field: String = property.name
		grid.add_child(label(String(titles.get(field, field))))
		grid.add_child(_visual(resource, property))
		grid.add_child(label(_text(resource, property, values.get(field, {}))))
	if resource is UiShadows:
		column.add_child(_shadow_levels(resource))
	if resource is UiButtonMotion:
		var button := GameButton.new()
		button.text = MOTION_SAMPLE
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		column.add_child(button)
	return card


func _visual(resource: Resource, property: Dictionary) -> Control:
	var value: Variant = resource.get(property.name)
	if property.usage & PROPERTY_USAGE_CLASS_IS_ENUM:
		var source: Resource = _primitives.get(String(property.class_name).get_slice(".", 0))
		return _draw(source, _step_value(source, value), true)
	return _draw(resource, value, false)


## The primitive value of a step; a source without FIELDS (shadow levels) keeps the step.
static func _step_value(source: Resource, step: int) -> Variant:
	if source == null:
		return null
	var steps: Variant = source.get_script().get_script_constant_map().get("FIELDS")
	return source.get(steps[step]) if steps is Array else step


func _draw(source: Resource, value: Variant, step: bool) -> Control:
	if value is Color:
		var swatch := ColorRect.new()
		swatch.color = value
		swatch.custom_minimum_size = SWATCH
		return swatch
	if source is UiShadows and step:
		return _shadow_box(source, value)
	if value is int and not source is UiShadows:
		return _size_sample(source, value)
	return Control.new()


## A primitive size drawn as what it sizes: text, a spacing bar, a corner or a border.
func _size_sample(source: Resource, value: int) -> Control:
	if source is UiFontSizes:
		return heading(SAMPLE_TEXT, value)
	if source is UiSpacing:
		var bar := ColorRect.new()
		bar.color = DRAW_FILL
		bar.custom_minimum_size = Vector2(value, BAR_HEIGHT)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return bar
	if source is UiRadii or source is UiBorderWidths:
		var box := StyleBoxFlat.new()
		box.bg_color = DRAW_FILL if source is UiRadii else DRAW_BACK
		box.border_color = DRAW_LINE
		box.set_corner_radius_all(value if source is UiRadii else 0)
		box.set_border_width_all(value if source is UiBorderWidths else 0)
		return _box(box)
	return Control.new()


func _shadow_levels(shadows: UiShadows) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", GAP * 2)
	var names: Dictionary = _step_names.get("UiShadows.Level", {})
	for level in UiShadows.Level.values():
		var item := VBoxContainer.new()
		item.add_child(_shadow_box(shadows, level))
		item.add_child(label(String(names.get(level, UiShadows.Level.keys()[level]))))
		row.add_child(item)
	return row


func _shadow_box(shadows: UiShadows, level: int) -> Control:
	var box := StyleBoxFlat.new()
	box.bg_color = DRAW_BACK
	var palette: Resource = _primitives.get("UiPalette")
	shadows.apply(level, palette.get(SHADOW_COLOR_FIELD), box)
	return _box(box)


static func _box(style: StyleBox) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = BOX
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.add_theme_stylebox_override("panel", style)
	return panel


## "强调 500 · #3a6fd8" for a semantic step, "16 px" for a primitive size.
func _text(resource: Resource, property: Dictionary, names: Dictionary) -> String:
	var value: Variant = resource.get(property.name)
	if not property.usage & PROPERTY_USAGE_CLASS_IS_ENUM:
		return _value_text(resource, property.name, value)
	var shown := String(names.get(value, _enum_key(property.hint_string, value)))
	var source: Resource = _primitives.get(String(property.class_name).get_slice(".", 0))
	var steps: Variant = source.get_script().get_script_constant_map().get("FIELDS") \
		if source != null else null
	if steps is Array:
		shown += " · " + _value_text(source, steps[value], source.get(steps[value]))
	return shown


static func _value_text(resource: Resource, field: String, value: Variant) -> String:
	if value is Color:
		return "#" + value.to_html(value.a < 1.0)
	for property in fields(resource):
		if property.name == field and String(property.hint_string).contains("suffix:"):
			return "%s %s" % [value, String(property.hint_string).get_slice("suffix:", 1)]
	return str(value)


## "TRANS_QUAD" for 4 from a hint "TRANS_LINEAR:0,...,TRANS_QUAD:4".
static func _enum_key(hint: String, value: int) -> String:
	for item in hint.split(","):
		if item.get_slice(":", 1) == str(value):
			return item.get_slice(":", 0)
	return str(value)
