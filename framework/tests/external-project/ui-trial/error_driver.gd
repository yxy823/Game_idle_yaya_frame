# 驱动步骤中出现脚本运行错误：应立即以退出码 1 结束，不把后续步骤当成完成。
extends "res://yaya/tools/ui-trial/ui_trial_driver.gd"


func _run() -> void:
	step("before the error")
	var empty: Array = []
	step("never logged %s" % empty[3])
	await wait_seconds(3600.0)
