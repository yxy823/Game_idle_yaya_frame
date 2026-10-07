# require() 收到 null（上一步 find 没找到）：以“找不到节点”的说明失败，不变成引擎错误。
extends "res://yaya/tools/ui-trial/ui_trial_driver.gd"


func _run() -> void:
	var scene := open_scene("res://scan_cases.tscn")
	if scene == null:
		return
	require(find("NoSuchNode"))
