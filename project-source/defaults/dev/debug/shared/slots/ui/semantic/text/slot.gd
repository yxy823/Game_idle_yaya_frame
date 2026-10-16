extends RefCounted
## Names shown by the debug window.

const Names := preload("res://dev/debug/shared/slots/ui/token_names.gd")
const TITLE := "正文文字"
const FIELDS := {"font_color": "文字颜色", "font_size": "字号"}
const VALUES := {"font_color": Names.SWATCHES, "font_size": Names.FONT_SIZES}
