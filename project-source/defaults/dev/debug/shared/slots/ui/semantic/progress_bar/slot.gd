extends RefCounted
## Names shown by the debug window.

const Names := preload("res://dev/debug/shared/slots/ui/token_names.gd")
const TITLE := "进度条"
const FIELDS := {
	"track": "底槽颜色", "fill": "填充颜色", "font_color": "文字颜色", "radius": "圆角",
	"font_size": "字号",
}
const VALUES := {
	"track": Names.SWATCHES, "fill": Names.SWATCHES, "font_color": Names.SWATCHES,
	"radius": Names.RADII, "font_size": Names.FONT_SIZES,
}
