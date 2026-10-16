extends RefCounted
## Names shown by the debug window.

const Names := preload("res://dev/debug/shared/slots/ui/token_names.gd")
const TITLE := "面板"
const FIELDS := {
	"background": "背景", "border_color": "边框颜色", "border_width": "边框宽度", "radius": "圆角",
	"padding": "内边距", "shadow": "阴影", "shadow_color": "阴影颜色",
}
const VALUES := {
	"background": Names.SWATCHES, "border_color": Names.SWATCHES,
	"border_width": Names.BORDER_WIDTHS, "radius": Names.RADII, "padding": Names.SPACING,
	"shadow": Names.SHADOWS, "shadow_color": Names.SWATCHES,
}
