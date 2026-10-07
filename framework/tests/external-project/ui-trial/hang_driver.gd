# 驱动在等待中卡住：看门狗应以退出码 2 结束进程。
extends "res://yaya/tools/ui-trial/ui_trial_driver.gd"


func _run() -> void:
	step("waiting for a signal that never comes")
	await wait_seconds(3600.0)
