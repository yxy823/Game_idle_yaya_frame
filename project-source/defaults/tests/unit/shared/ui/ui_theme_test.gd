extends GdUnitTestSuite
## The UiTheme autoload rebuilds the project theme from the cached tuning resources that the
## debug console edits. Each test restores the token values it changes.

const SignalAssertImpl := preload("res://addons/gdUnit4/src/asserts/GdUnitSignalAssertImpl.gd")
const PALETTE := preload("res://game/shared/tuning/ui/primitives/palette.tres")
const PRIMARY := preload("res://game/shared/tuning/ui/semantic/buttons/primary.tres")

var palette: UiPalette = PALETTE
var primary: UiButtonStyle = PRIMARY
var _accent: Color
var _background: UiPalette.Swatch


func before_test() -> void:
	_accent = palette.accent_500
	_background = primary.background


func after_test() -> void:
	palette.accent_500 = _accent
	primary.background = _background
	await _theme_rebuilt()


func test_primitive_change_reaches_semantic_use_under_canvas_layer() -> void:
	assert_int(primary.background).is_equal(UiPalette.Swatch.ACCENT_500)
	var button := _primary_button()
	palette.accent_500 = Color("ff00ff")
	await _theme_rebuilt()
	assert_that(_normal_color(button)).is_equal(Color("ff00ff"))


func test_semantic_choice_change_reaches_theme() -> void:
	var button := _primary_button()
	primary.background = UiPalette.Swatch.GRAY_700
	await _theme_rebuilt()
	assert_that(_normal_color(button)).is_equal(palette.gray_700)


func test_each_button_style_is_a_button_type_variation() -> void:
	var theme := ThemeDB.get_project_theme()
	for variation: StringName in [&"ButtonPrimary", &"ButtonSecondary", &"ButtonDanger"]:
		assert_str(theme.get_type_variation_base(variation)).is_equal("Button")
		assert_bool(theme.has_stylebox(&"normal", variation)).is_true()
		assert_bool(theme.has_color(&"font_color", variation)).is_true()
	var danger := theme.get_stylebox(&"normal", &"ButtonDanger") as StyleBoxFlat
	assert_that(danger.bg_color).is_equal(palette.danger_500)


## Game UI usually sits under a CanvasLayer, which a theme set on the root window never reaches.
func _primary_button() -> Button:
	var layer := auto_free(CanvasLayer.new()) as CanvasLayer
	var button := Button.new()
	button.theme_type_variation = &"ButtonPrimary"
	layer.add_child(button)
	add_child(layer)
	return button


func _normal_color(button: Button) -> Color:
	return (button.get_theme_stylebox(&"normal") as StyleBoxFlat).bg_color


## The UiTheme autoload rebuilds one frame after a token changes; assert_signal waits 2000 ms.
func _theme_rebuilt() -> void:
	var signal_assert := assert_signal(ThemeDB.get_project_theme()) as SignalAssertImpl
	await signal_assert.is_emitted("changed")
