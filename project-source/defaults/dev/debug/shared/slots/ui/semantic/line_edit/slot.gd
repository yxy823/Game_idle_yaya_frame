extends RefCounted
## Names shown by the debug window.

const Names := preload("res://dev/debug/shared/slots/ui/token_names.gd")
const TITLE := "输入框"
const FIELDS := {
	"background": "背景", "font_color": "文字颜色", "placeholder_color": "占位文字颜色",
	"border_color": "边框颜色", "focus_border_color": "焦点边框颜色", "border_width": "边框宽度",
	"radius": "圆角", "padding": "内边距", "font_size": "字号",
}
const VALUES := {
	"background": Names.SWATCHES, "font_color": Names.SWATCHES,
	"placeholder_color": Names.SWATCHES, "border_color": Names.SWATCHES,
	"focus_border_color": Names.SWATCHES, "border_width": Names.BORDER_WIDTHS,
	"radius": Names.RADII, "padding": Names.SPACING, "font_size": Names.FONT_SIZES,
}
