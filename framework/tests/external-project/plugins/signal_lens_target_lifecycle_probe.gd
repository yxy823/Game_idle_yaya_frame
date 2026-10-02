extends SceneTree
## Run with --headless --debug --script in a dedicated external verification project.
## Exercises real Signal Lens target/signal logic; local debugger output is not remote UI evidence.

const REPORT := "res://reports/signal-lens-target-lifecycle.json"
var checks: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_record("Debugger active", EngineDebugger.is_active())
	_record("No existing Signal Lens capture", not EngineDebugger.has_capture("signal_lens"))
	if not EngineDebugger.is_active() or EngineDebugger.has_capture("signal_lens"):
		_finish()
		return
	var lens := ObservedLens.new()
	lens.name = "LensProbe"
	root.add_child(lens)
	var target_b: ProbeTarget = await _check_destroyed_target(lens)
	await _check_live_target_switch(lens, target_b)
	EngineDebugger.unregister_message_capture("signal_lens")
	lens.queue_free()
	await process_frame
	_record("Probe lens released", not is_instance_valid(lens))
	_finish()


func _check_destroyed_target(lens: ObservedLens) -> ProbeTarget:
	var target_a := ProbeTarget.new()
	target_a.name = "TargetA"
	root.add_child(target_a)
	_record("Target A selected", lens._on_node_signal_data_requested("", [target_a.get_path()]))
	if OS.get_cmdline_user_args().has("--free-immediately"):
		target_a.free()
	else:
		target_a.queue_free()
	await process_frame
	_record("Target A destroyed", not is_instance_valid(target_a))
	_record("Freed target compares equal to null", lens.target_node == null)

	var target_b := ProbeTarget.new()
	target_b.name = "TargetB"
	root.add_child(target_b)
	_record("Target B selected after A destruction",
		lens._on_node_signal_data_requested("", [target_b.get_path()]))
	_record("Target B retained", is_instance_valid(lens.target_node) and lens.target_node == target_b)
	_record("Target B capture connected",
		target_b.pulse.is_connected(lens._on_target_node_signal_emitted))
	lens.emissions.clear()
	target_b.pulse.emit(7)
	_record("Target B signal reaches capture once", lens.emissions == [["TargetB", "pulse"]])
	return target_b


func _check_live_target_switch(lens: ObservedLens, target_b: ProbeTarget) -> void:

	# Switching away from a still-live target must keep the existing disconnect behavior.
	var target_c := ProbeTarget.new()
	target_c.name = "TargetC"
	root.add_child(target_c)
	_record("Live target C selected", lens._on_node_signal_data_requested("", [target_c.get_path()]))
	_record("Previous live target B disconnected",
		not target_b.pulse.is_connected(lens._on_target_node_signal_emitted))
	lens.emissions.clear()
	target_b.pulse.emit(8)
	target_c.pulse.emit(9)
	_record("Only target C signal reaches capture", lens.emissions == [["TargetC", "pulse"]])
	target_b.queue_free()
	target_c.queue_free()
	await process_frame
	_record("Probe targets released",
		not is_instance_valid(target_b) and not is_instance_valid(target_c))


func _finish() -> void:
	var passed := true
	for check in checks:
		passed = passed and check.passed
	DirAccess.make_dir_recursive_absolute(REPORT.get_base_dir())
	var file := FileAccess.open(REPORT, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write Signal Lens lifecycle report")
		quit(1)
		return
	file.store_string(JSON.stringify({"godot": Engine.get_version_info().string,
		"immediate_free": OS.get_cmdline_user_args().has("--free-immediately"),
		"checks": checks}, "\t") + "\n")
	file.close()
	print("SIGNAL_LENS_PROBE ", "PASS" if passed else "FAIL", ": ", checks.size(), " checks")
	quit(0 if passed else 1)


func _record(label: String, passed: bool) -> void:
	checks.append({"check": label, "passed": passed})
	print("SIGNAL_LENS_CHECK ", label, ": ", passed)


class ProbeTarget extends Node:
	signal pulse(value: int)


class ObservedLens extends "res://addons/signal_lens/autoload/signal_lens_autoload.gd":
	var emissions: Array[Array] = []

	func _on_target_node_signal_emitted(node_name: String, signal_name: String) -> void:
		emissions.append([node_name, signal_name])
		super._on_target_node_signal_emitted(node_name, signal_name)
