extends PanelContainer
## The playback bar: debug target, fixture, restart, play or pause, speed, loops and state.

signal requested(action: String)
signal target_selected(identity: String)
signal speed_selected(value: float)
signal loops_selected(value: int)

const Session := preload("res://dev/debug/_shared/debug_session.gd")
const Playback := preload("res://dev/debug/_shared/playback_controller.gd")
const Kit := preload("res://dev/debug/_shared/ui_kit.gd")
const Messages := preload("res://dev/debug/_shared/debug_messages.gd")
const Select := preload("res://dev/debug/_shared/debug_select.gd")
const BAR_HEIGHT := 44.0
const PRIMARY_WIDTH := 48.0
const FIXTURE_WIDTH := 148.0
const SPEED_WIDTH := 72.0
const LOOPS_WIDTH := 68.0
const STATUS_WIDTH := 84.0
const STATUS_DOT := 8.0

var target: Select
var fixture: Select
var speed: Select
var loops: Select
var play: Button
var restart: Button
var lock_chip: PanelContainer
var playback_status: Label
var _status_dot: Panel
var _session: Session


func _init() -> void:
	name = "PlaybackBar"
	theme_type_variation = &"PlaybackBar"
	custom_minimum_size.y = BAR_HEIGHT
	var line := Kit.row(8)
	add_child(line)
	target = Select.new("target", "")
	target.chosen.connect(func(index: int) -> void:
		target_selected.emit(_session.targets[index].id))
	line.add_child(target)
	fixture = Select.new("layout-grid", "")
	fixture.min_width = FIXTURE_WIDTH
	fixture.tooltip_text = "固定局面：每次播放都从同一个局面开始"
	line.add_child(fixture)
	line.add_child(_divider())
	restart = Kit.icon_button("player-skip-back", "回到开头：结束播放、解除参数锁定，局面停在开头")
	restart.pressed.connect(func() -> void: requested.emit("开头"))
	line.add_child(restart)
	play = Kit.icon_button("player-play", "播放：载入固定局面并开始", &"PrimaryButton")
	play.custom_minimum_size = Vector2(PRIMARY_WIDTH, Kit.CONTROL)
	play.pressed.connect(_play_pressed)
	line.add_child(play)
	line.add_child(_divider())
	_build_rates(line)
	line.add_child(Kit.spacer())
	lock_chip = Kit.chip("已锁定参数", "lock")
	lock_chip.tooltip_text = "播放或暂停时参数已锁定，回到待播放后可改"
	lock_chip.visible = false
	line.add_child(lock_chip)
	_build_status(line)


func _build_rates(line: HBoxContainer) -> void:
	speed = Select.new("gauge", "")
	speed.min_width = SPEED_WIDTH
	speed.tooltip_text = "倍速：0.1 到 2 倍，同时改变音频速度与音高"
	var speeds: PackedStringArray = []
	for value in Playback.SPEEDS:
		speeds.append(String.num(value).trim_suffix(".0") + "×")
	speed.set_items(speeds, Playback.SPEEDS.find(1.0))
	speed.chosen.connect(func(index: int) -> void: speed_selected.emit(Playback.SPEEDS[index]))
	line.add_child(speed)
	loops = Select.new("repeat", "")
	loops.min_width = LOOPS_WIDTH
	loops.tooltip_text = "循环次数：1 / 3 / 5 / 无限"
	var counts: PackedStringArray = []
	for value in Playback.LOOPS:
		counts.append("∞" if value < 0 else str(value))
	loops.set_items(counts, 0)
	loops.chosen.connect(func(index: int) -> void: loops_selected.emit(Playback.LOOPS[index]))
	line.add_child(loops)


func _build_status(line: HBoxContainer) -> void:
	var status := Kit.row(6)
	status.custom_minimum_size.x = STATUS_WIDTH
	_status_dot = Panel.new()
	_status_dot.custom_minimum_size = Vector2(STATUS_DOT, STATUS_DOT)
	_status_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status.add_child(_status_dot)
	playback_status = Kit.label("待播放", &"StatusText")
	status.add_child(playback_status)
	line.add_child(status)


static func _divider() -> VSeparator:
	var line := VSeparator.new()
	line.custom_minimum_size.y = 20.0
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return line


func configure(session: Session) -> void:
	_session = session
	var names: PackedStringArray = []
	var shared := "shared"
	for item: RefCounted in session.targets:
		names.append(item.title())
		if item.id == "shared":
			shared = item.title()
	target.set_items(names, 0)
	Messages.usable_tooltip(target, "调试对象：列表显示它和“%s”的插槽；切换场景时自动跟随" % shared)


func target_changed() -> void:
	var names: PackedStringArray = []
	var current := 0
	for index in range(_session.targets.size()):
		names.append(_session.targets[index].title())
		if _session.targets[index] == _session.active:
			current = index
	target.set_items(names, current)
	var fixtures: PackedStringArray = []
	if _session.active.adapter != null:
		fixtures.append_array(_session.active.adapter.FIXTURES.keys())
	fixture.set_items(fixtures, 0 if not fixtures.is_empty() else -1)
	if fixtures.is_empty():
		fixture.set_value("无固定局面")


func refresh(playback: Playback) -> void:
	var locked := playback.locked()
	var no_fixture := fixture.get_popup().item_count == 0
	Messages.explain(target, locked, "播放中不能切换调试对象：先点“回到开头”结束播放")
	Messages.explain(fixture, locked or no_fixture, "播放中不能换局面：先点“回到开头”结束播放"
		if locked else "这个调试对象没有登记固定局面")
	var paused := playback.state == Playback.State.PAUSED
	play.icon = Kit.icon("player-pause" if locked and not paused else "player-play")
	Messages.usable_tooltip(play, "继续" if paused else ("暂停：游戏与音频同时停止" if locked
		else "播放：载入固定局面并开始"))
	Messages.explain(play, not locked and no_fixture, "这个调试对象没有登记固定局面，不能播放")
	Messages.explain(restart, playback.fixture.is_empty(), "还没有播放过固定局面")
	lock_chip.visible = locked
	_paint_status(playback, locked, paused)


## Gray while idle, accent while playing, amber while paused.
func _paint_status(playback: Playback, locked: bool, paused: bool) -> void:
	playback_status.text = _status_text(playback)
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(int(STATUS_DOT / 2.0))
	box.bg_color = Kit.color(&"warn") if paused \
		else (Kit.color(&"accent") if locked else Kit.color(&"tx3"))
	_status_dot.add_theme_stylebox_override("panel", box)
	playback_status.theme_type_variation = &"StatusText"
	if locked and not paused:
		playback_status.add_theme_color_override("font_color", Kit.color(&"tx1"))
	else:
		playback_status.remove_theme_color_override("font_color")


static func _status_text(playback: Playback) -> String:
	match playback.state:
		Playback.State.IDLE:
			return "待播放"
		Playback.State.STARTING:
			return "载入中"
		Playback.State.PAUSED:
			return "已暂停"
	var total := "∞" if playback.loop_count < 0 else str(playback.loop_count)
	return "第 %d/%s 遍" % [playback.completed + 1, total]


## While playback runs or is paused the primary button pauses or resumes it.
func _play_pressed() -> void:
	requested.emit("暂停" if lock_chip.visible else "播放")


func chosen_fixture() -> String:
	var caption := fixture.selected_text()
	if caption.is_empty() or _session.active.adapter == null:
		return ""
	return _session.active.adapter.FIXTURES[caption]
