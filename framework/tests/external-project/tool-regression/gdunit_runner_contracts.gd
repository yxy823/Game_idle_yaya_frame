# 仅供维护者在外部项目检查真实运行器；不复制为新项目的业务测试。
extends GdUnitTestSuite

const FAILURE_ENV := "YAYA_RUNNER_REGRESSION_FAILURE"
const EXPECTED_ERROR := "intentional scoped runner regression"
const ErrorAssertImpl := preload("res://addons/gdUnit4/src/asserts/GdUnitGodotErrorAssertImpl.gd")


func before() -> void:
	# 故意制造 suite 启动错误，用于确认绿断言不能掩盖生命周期错误。
	if OS.get_environment(FAILURE_ENV) == "native":
		push_error("intentional unhandled runner regression")


func test_normal_assertion() -> void:
	assert_bool(true).is_true()


func test_parameterized(value: int, _test_parameters: Array = [[1], [2]]) -> void:
	assert_bool(value > 0).is_true()


func test_scoped_expected_error() -> void:
	var error_assert := assert_error(func() -> void: push_error(EXPECTED_ERROR)) as ErrorAssertImpl
	await error_assert.is_push_error(EXPECTED_ERROR)
