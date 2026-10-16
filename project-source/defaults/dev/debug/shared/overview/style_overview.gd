extends Control
## Main scene of the shared debug target: every shared UI style, read from the files each time it
## opens. Token cards redraw after a token changes; control samples follow the project theme. The
## usage lists which interfaces use each style, and "打开" picks an interface like the playback
## bar's target dropdown does.

const Session := preload("res://dev/debug/_shared/debug_session.gd")
const Target := preload("res://dev/debug/_shared/debug_target.gd")
const SharedTarget := preload("res://dev/debug/shared/debug_target.gd")
const Cards := preload("res://dev/debug/shared/overview/token_cards.gd")
const Samples := preload("res://dev/debug/shared/overview/control_samples.gd")
const Usage := preload("res://dev/debug/shared/overview/style_usage.gd")
const WINDOW_NAME := "DebugWindow"
const CATEGORY_PREFIX := "shared/ui"
const MARGIN := 24
const GAP := 16
const PAGE_TITLE_SIZE := 34
const SECTION_SIZE := 28
const NAME_WIDTH := 300.0
const USERS_WIDTH := 420.0
const HINT_COLOR := Color("c27c0e")

## Where the tokens and their slot names are read; tests point them at fixtures.
var tokens_root := "res://game/shared/tuning/ui"
var names_root := "res://dev/debug/shared/slots/ui"
var cards := Cards.new()
var usage := Usage.new()
## The debug targets other than shared, found where the debug window looks.
var interfaces: Array = []
var _tokens_box: VBoxContainer
var _refresh_queued := false


func _ready() -> void:
	for target: RefCounted in Target.discover(Session.game_root, Session.debug_root):
		if target.id != "shared":
			interfaces.append(target)
	cards.tokens_root = tokens_root
	cards.names_root = names_root
	cards.category_prefix = CATEGORY_PREFIX
	cards.categories = SharedTarget.CATEGORIES
	cards.load_tokens()
	var ids: PackedStringArray = []
	for target: RefCounted in interfaces:
		ids.append(target.id)
	usage.scan(Session.game_root, ids, Usage.variations(ThemeDB.get_project_theme()))
	_build()
	for token: Resource in cards.tokens.values():
		token.changed.connect(_queue_refresh)


func _build() -> void:
	# The project theme's panel behind the page, so the page follows the panel tokens too.
	var background := Panel.new()
	add_child(background)
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = SIZE_EXPAND_FILL
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, MARGIN)
	scroll.add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", GAP)
	margin.add_child(page)
	page.add_child(Cards.heading("样式总览", PAGE_TITLE_SIZE))
	page.add_child(Cards.label("每次打开时读取 game/shared/tuning/ui/ 和各界面的场景；"
		+ "在调试窗口改 token 后，这一页立即更新。"))
	_add_interfaces(page)
	_tokens_box = VBoxContainer.new()
	_tokens_box.add_child(cards.build())
	page.add_child(_tokens_box)
	page.add_child(Cards.heading("控件示例", SECTION_SIZE))
	page.add_child(Samples.build(ThemeDB.get_project_theme()))
	_add_usage(page)


func _add_interfaces(page: VBoxContainer) -> void:
	page.add_child(Cards.heading("界面", SECTION_SIZE))
	if interfaces.is_empty():
		page.add_child(Cards.label("还没有其他调试对象：在 game/<对象>/tuning/ 下添加调参资源后出现在这里"))
	for target: RefCounted in interfaces:
		page.add_child(_interface_row(target))


func _add_usage(page: VBoxContainer) -> void:
	page.add_child(Cards.heading("共享样式的使用范围", SECTION_SIZE))
	for entry in usage.shared:
		page.add_child(_usage_row(entry.name, entry))
	page.add_child(Cards.heading("界面自己的样式", SECTION_SIZE))
	if usage.own.is_empty():
		page.add_child(Cards.label("各界面还没有自己的 Theme 或主题类型变体"))
	for entry in usage.own:
		var shown := entry.name.trim_prefix(Session.game_root + "/")
		page.add_child(_usage_row("%s（定义在%s）" % [shown, _title(entry.owner)], entry))


func _usage_row(shown: String, entry: Usage.Entry) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = entry.name.validate_node_name()
	row.add_theme_constant_override("separation", GAP)
	var name_label := Cards.label(shown)
	name_label.custom_minimum_size.x = NAME_WIDTH
	row.add_child(name_label)
	var titles: PackedStringArray = []
	for id in entry.users:
		titles.append(_title(id))
	var users := Cards.label("没有界面在用" if titles.is_empty() else "在用：" + "、".join(titles))
	users.custom_minimum_size.x = USERS_WIDTH
	row.add_child(users)
	var hint := Cards.label(entry.hint())
	hint.name = "Hint"
	hint.add_theme_color_override("font_color", HINT_COLOR)
	row.add_child(hint)
	return row


func _interface_row(target: RefCounted) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = target.id
	row.add_theme_constant_override("separation", GAP)
	var title := Cards.label(target.title())
	title.custom_minimum_size.x = NAME_WIDTH
	row.add_child(title)
	var open := Button.new()
	open.name = "Open"
	open.text = "打开"
	var window := get_tree().root.get_node_or_null(WINDOW_NAME)
	if window == null:
		open.disabled = true
		open.tooltip_text = "从调试入口启动后才能打开"
	elif target.main_scene().is_empty():
		open.disabled = true
		open.tooltip_text = "这个调试对象没有登记主场景：在它的 debug_target.gd 写 MAIN_SCENE"
	open.pressed.connect(func() -> void: window.open_target(target.id))
	row.add_child(open)
	return row


func _title(id: String) -> String:
	for target: RefCounted in interfaces:
		if target.id == id:
			return target.title()
	return id


## A preset sets many fields at once; redraw once after all of them.
func _queue_refresh() -> void:
	if not _refresh_queued:
		_refresh_queued = true
		_refresh_tokens.call_deferred()


func _refresh_tokens() -> void:
	_refresh_queued = false
	for child in _tokens_box.get_children():
		child.queue_free()
	_tokens_box.add_child(cards.build())
