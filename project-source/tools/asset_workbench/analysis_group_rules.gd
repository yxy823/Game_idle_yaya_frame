extends VBoxContainer

## Edits explicit project thresholds without changing Analyzer algorithms or media.

signal edited

const Group = preload("res://tools/asset_workbench/analysis_group.gd")

var rules: Array = []
var _metrics: OptionButton = OptionButton.new()
var _operator: OptionButton = OptionButton.new()
var _value: SpinBox = SpinBox.new()
var _rules: ItemList = ItemList.new()


func _ready() -> void:
	var label := Label.new()
	label.text = "Group rules (source measurements; no automatic asset edits)"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	_metrics.fit_to_longest_item = false
	add_child(_metrics)
	var row := HFlowContainer.new()
	add_child(row)
	for text: String in ["Minimum", "Maximum", "Max distance from median (3+ samples)"]:
		_operator.add_item(text)
	row.add_child(_operator)
	_value.min_value = -1000000
	_value.max_value = 1000000
	_value.step = 0.01
	row.add_child(_value)
	var add := Button.new()
	add.text = "Add rule"
	add.pressed.connect(_add)
	row.add_child(add)
	var remove := Button.new()
	remove.text = "Remove selected rule"
	remove.pressed.connect(_remove)
	row.add_child(remove)
	_rules.custom_minimum_size.y = 80
	add_child(_rules)


func display(current: Array, stats: Dictionary) -> void:
	rules = current
	var previous: String = _metrics.get_item_text(_metrics.selected) if _metrics.selected >= 0 else ""
	_metrics.clear()
	var labels: Array[String] = []
	for column: Dictionary in stats.values():
		var label := "%s / %s (%s)" % [column.type, column.metric, column.unit]
		if label in labels:
			continue
		labels.append(label)
		_metrics.add_item(label)
		_metrics.set_item_metadata(labels.size() - 1, {"type": column.type,
			"metric": column.metric, "unit": column.unit})
		if label == previous:
			_metrics.select(labels.size() - 1)
	_rules.clear()
	for rule: Dictionary in rules:
		_rules.add_item("%s / %s: %s %.5f %s" % [
			rule.type, rule.metric, rule.operator, rule.value, rule.unit])


func _add() -> void:
	if _metrics.selected < 0 or rules.size() >= Group.MAX_RULES:
		return
	if _operator.selected == 2 and _value.value < 0:
		return
	var rule: Dictionary = _metrics.get_selected_metadata().duplicate()
	rule.operator = ["min", "max", "delta"][_operator.selected]
	rule.value = _value.value
	if rule not in rules:
		rules.append(rule)
	edited.emit()


func _remove() -> void:
	var selected := _rules.get_selected_items()
	if not selected.is_empty():
		rules.remove_at(selected[0])
		edited.emit()
