extends RefCounted
## Chinese names of the UI token steps, shared by the slots whose fields pick a primitive.

const SWATCHES := {
	0: "灰 50", 1: "灰 100", 2: "灰 200", 3: "灰 300", 4: "灰 400", 5: "灰 500", 6: "灰 600",
	7: "灰 700", 8: "灰 800", 9: "灰 900", 10: "强调 400", 11: "强调 500", 12: "强调 600",
	13: "阴影色",
}
const FONT_SIZES := {0: "特小", 1: "小", 2: "中", 3: "大", 4: "特大", 5: "超大"}
const SPACING := {0: "无", 1: "特小", 2: "小", 3: "中", 4: "大", 5: "特大"}
const RADII := {0: "无", 1: "小", 2: "中", 3: "大"}
const BORDER_WIDTHS := {0: "无", 1: "细", 2: "粗"}
const SHADOWS := {0: "无", 1: "小", 2: "中", 3: "大"}

## The three button slots share one resource script.
const BUTTON_FIELDS := {
	"background": "背景", "background_hover": "悬停背景", "background_pressed": "按下背景",
	"background_disabled": "禁用背景", "font_color": "文字颜色", "font_disabled_color": "禁用文字颜色",
	"border_color": "边框颜色", "border_width": "边框宽度", "focus_color": "焦点框颜色",
	"focus_border_width": "焦点框宽度", "radius": "圆角", "padding_horizontal": "左右内边距",
	"padding_vertical": "上下内边距", "font_size": "字号",
}
const BUTTON_VALUES := {
	"background": SWATCHES, "background_hover": SWATCHES, "background_pressed": SWATCHES,
	"background_disabled": SWATCHES, "font_color": SWATCHES, "font_disabled_color": SWATCHES,
	"border_color": SWATCHES, "border_width": BORDER_WIDTHS, "focus_color": SWATCHES,
	"focus_border_width": BORDER_WIDTHS, "radius": RADII, "padding_horizontal": SPACING,
	"padding_vertical": SPACING, "font_size": FONT_SIZES,
}
