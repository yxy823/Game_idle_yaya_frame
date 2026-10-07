# 主线程死循环：看门狗无法触发，只能由外层超时结束进程树。
extends "res://yaya/tools/ui-trial/ui_trial_driver.gd"


func _run() -> void:
	step("blocking the main thread")
	var spins := 0
	while spins >= 0:
		spins = (spins + 1) % 1000
