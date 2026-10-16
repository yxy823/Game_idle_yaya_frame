extends RefCounted
## Names shown by the debug window.

const TITLE := "按钮动效"
const FIELDS := {
	"hover_scale": "悬停缩放", "press_scale": "按下缩放", "duration": "过渡时长",
	"transition": "过渡曲线", "easing": "缓动方式",
}
const VALUES := {
	"transition": {
		0: "线性", 1: "正弦", 2: "五次方", 3: "四次方", 4: "二次方", 5: "指数", 6: "弹性",
		7: "三次方", 8: "圆弧", 9: "弹跳", 10: "回拉", 11: "弹簧",
	},
	"easing": {0: "渐入", 1: "渐出", 2: "先入后出", 3: "先出后入"},
}
