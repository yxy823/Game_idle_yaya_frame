# 问答渲染脚本的来源与本地改动

[框架维护](../README.md)

本页记录随项目分发的问答渲染脚本 [am.mjs](../../../project-source/skills/qa-explainer-godot/scripts/am.mjs) 的上游来源和本地改动，只在框架维护时使用，不进入生成项目。

来源：<https://github.com/QingYunA/answer-me-with-html> 的 `skills/answer-me-with-html/`，提交 `533c39fd47d814a6bee3d9c1df388345f4e4c858`（2026-10-10），MIT 许可证见 Skill 目录下的 [LICENSE](../../../project-source/skills/qa-explainer-godot/LICENSE)。

之后从上游挑选并入的提交：b0ebc16（正文公式，Temml 渲染）、43d5314（标注和回复引用公式时用 TeX 原文）、4392f11（窄窗口横向时间线的标注键不随宽度变化）。并入时删掉了只供措辞检查用的 `opensDisplay`、`isDisplayLine`；`RUNTIME_JS` 开头加入公式文本函数后，外层多了一层包裹函数。没有并入的上游改动：新版本按钮和更新提示（#188、#190、#198）、页脚移到页头（#186）、DeepSeek Harness 插件（#199、#200）。下次同步上游时，从 `4da5ae8` 之后开始核对。

组件 `line`、`bar`、`sankey`、`loop`、`quadrant`，以及 `venn`、`matrix`、`pyramid`、`layers`、`nested`、`fishbone`、`process`、`journey`、`kanban`、`story-map`、`gantt`、`wardley`，`scatter`、`waterfall`、`treemap`、`heatmap`、`radar`、`polar`，`swimlane`、`state`，以及 `bar`、`line` 的变体的排版代码一次性移植自 [SeeCode](https://github.com/Aryanutkarsh/seecode)（提交 `82c33b6`，MIT 许可证全文在 `am.mjs` 末尾），集中在 `am.mjs` 的 `var seecode` 和 `SEECODE_CSS`。只取每种图的排版，写法改成与现有组件一致的文本语法，颜色改用主题变量，文字不小于 12px；不带 SeeCode 的查看器、动画、导出和水印，保留 `data-sc-step` 属性供以后加动画。以后不与 SeeCode 同步。

移植后按我们的页面重做了细节：图里文字分 14px（名称、图例）、13px（刻度、数值、说明）、18px（循环中心）三档；四象限的点标签按右、左、上、下依次避让，仍冲突时上下错开并画引线；多字符单位只在轴上写一次；竖向柱的长类别名拆成两行；重点象限底色改为强调色 8% 透明度。共用的参数解析 `checkParamNames` 对非英文参数名（如 `单位=金币`）报错并给出英文写法；`callout`、`loop`、`fishbone` 组件名后面是标题文字，定义里用 `textArgs: true` 跳过这项检查。英文参数名后的全角等号（`unit＝金币`）按 `=` 处理，因为中文输入法容易打出，意图没有歧义。长文字用均衡换行，行首不放标点（含 `·`），不截断。行尾的开括号移到下一行开头。`state` 复用 `flow` 已打包的 dagre 排版，只补状态形状、起止点和自环；`swimlane` 由脚本按拓扑顺序推算列号，连线用改过的 SeeCode 直角绕障路由，Agent 不写坐标。色阶不用 SeeCode 的调色板，由 `--accent`、`--err`、`--ink-3`、`--paper` 经 `color-mix()` 派生，深色模式随变量自动翻转。

问答 Skill `qa-explainer-godot` 的 `SKILL.md` 按 Yaya 框架的 Q&A 重写，只保留上游的渲染脚本。内部命令 `am`、设置目录 `~/.answer-me-with-html/` 和页面里的 `am-` 类名沿用上游名字，没有改。

`am.mjs` 是上游从 `src/` 构建出的单文件，这里直接修改它，没有改上游源码。改动依据是 `skills/ui-visual-review` 和 `skills/ui-interaction-review` 对示例页「TCP 的三次握手」的审查。

| 问题 | 改动 | 对应规则 |
|---|---|---|
| V1–V8：图表结构线、浅色状态文字、树链接和图标对比不足；窄屏树分支断开；中文表头字体、辅助文字和标题字距不合适 | shadcn 局部加深结构线、状态色和辅助文字，保留高亮 accent；树链接沿用主题 accent 并加下划线；窄屏树按已有 `--n` 保留每列至少 200px，共同根节点与分支共用宽度并在树内滚动；表头改为 sans、12px/1.5、400；中日韩标题字距归零；不改卡片边框和深色状态 token | R04、R07、R11、R12、R14、R18、R20、R23、R24、R29、R31 |
| 图表被缩小，图里文字只有 7.5–9.7px | 布局脚本 `MIN_SCALE` 0.75 → 1，`BAND_LOS` 只保留 1；`.am-diagram svg` 不再 `max-width: 100%`，放不下时横向滚动，打印时仍按纸宽缩放；连线标签、分组标签、ER 键标记、步骤编号改为 12px（`EDGE_FS`、`CLUSTER_FS`、`KEY_FS`、`EDGE_FS2` 同步改为 12） | R31 |
| 横向滚动没有提示 | `.am-diagram` 加左右边缘阴影，阴影只出现在还有内容的一侧 | R31 |
| 宽表格横向滚动没有提示（隔行底色会盖住背景阴影） | 页面脚本按滚动位置给 `.am-table-wrap` 加 `am-more-start` / `am-more-end`，CSS 用 `mask-image` 淡出还有内容的一侧 40px；右到左页面方向相反；打印时去掉。树（`.am-tree`）在窄屏横向滚动时用同一套淡出。 | R31 |
| 手机上工具栏标签一字一行 | 标签放进 `.am-pick-label`，760px 以下隐藏，`select` 加 `aria-label`；按钮和选择框 `white-space: nowrap` | R12 |
| 面板正文铺满宽面板（最宽 91em） | 面板内 `p`、`li`、`blockquote` 的 `max-width`：中文、日文、韩文 40em，其他 70ch | R15 |
| 中文软换行渲染成空格（「建立连接。 双方」） | `md()` 输出后删掉中文字符之间、全角标点之后的换行，`<pre>` 内不动 | 排版 |
| 表格和下方段落间距为 0 | `.am-table-wrap` 下边距 12px | R09、R10 |
| 页面高度接近一屏时纵向滚动条反复出现，布局脚本宽度不稳定退回等宽网格，宽表格面板被分到 1/3 宽、短中文列被挤成竖排，两列时留空；长标题末行孤字 | `html` 加 `scrollbar-gutter: stable`，始终保留滚动条位置，稳定布局脚本测量的容器宽度；电脑端（`@media screen and (min-width: 761px)`）的 `.am-md th, .am-md td` 加 `min-width: 5em`，窄面板中保留列宽并横向滚动；仅 `.am-head h1` 加 `text-wrap: balance`，平衡页面标题换行 | 测试发现 |
| 字号有 11 种（含 10、11、11.5、12.5、15、15.5、17px） | 收敛到 12 / 13 / 14 / 16 / 18 / 24px；`font-weight: 600` 统一改为 700 | R03、R14 |
| 浅色页脚对比度 2.89:1；部分 11px 弱化文字用 `--ink-3` | 页脚、步骤编号、树标签、刻度改用 `--ink-2`，字号 12px | R23 |
| blueprint 主题三层框线加刻度 | 只保留一层外框，删除内框和刻度 | R28、R38 |
| 右上角浮动工具栏没有底色，页面滚动后盖住面板内容（例如表头） | 工具栏改为横贯顶部的工具条：`--bg` 底色加 `--line` 下边框，按钮靠右；`.am-sheet` 上边距 80px、`.am-doc` 88px、760px 以下 64px；去掉 `.am-head` 为让位工具栏留的 300px 右边距；文档目录吸顶位置 24px → 64px；锚点跳转加 `scroll-padding-top: 56px`；标注提示条下移到 56px | 测试发现 |
| 图标按钮只有 `title`，键盘聚焦时不显示提示 | 评论和展开按钮改用 `data-tip`，悬停和 `:focus-visible` 时在按钮左侧显示 tooltip | R39 |
| 复制失败仍显示「已复制」 | `copyText` 返回是否成功；回复面板复制失败时提示「复制失败：文字已选中，请按 Ctrl+C」并选中全文；复制源稿、复制代码失败时在回复面板里显示原文供手动复制 | I16、I27 |
| 标注只能用鼠标点段落 | 标注模式下段落加 `tabindex=0`，Tab 聚焦后按 Enter 或空格打开标注框；Esc 先关标注框，再按一次退出标注模式并把焦点还给「标注」按钮；聚焦段落有 outline | I12 |
| 进入标注模式后没有说明 | 显示 `role=status` 提示条「点击段落，或用 Tab 选中后按 Enter……」；桌面在工具栏下方右侧，760px 以下在屏幕底部，不挡标题 | I09 |
| 「标注」开启状态和普通按钮差别小 | `.am-btn--remark.is-on` 改用 `--accent-bg` 底色和 `--accent` 边框、文字 | R35 |
| 回复面板没有意见时只显示空白，也不说明用法 | 空状态写明「点评论图标写评论，或用『标注』标出某一段」；面板下方提示「复制后粘贴到对话里。页面更新后，已复制的意见会清空」 | I09 |
| 所有项目的页面都存到 `~/.answer-me-with-html/pages/`，分不清来源 | 页面存到当前目录的 `.explain/`，视频存到 `.explain/videos/`；首次写入时在 `.explain/` 放一个内容为 `*` 的 `.gitignore`；`--replace` 只认当前目录的 `.explain/`；`am clean` 和清理提示只统计当前目录的页面；设置、主题、配音缓存仍在 `~/.answer-me-with-html/`；`am serve` 只服务旧目录，新页面改用 `file://` 链接 | 用户要求 |
| 文档模板的目录在 Claude 桌面 App 预览中点击不跳转（页面以 data: 快照打开，`#锚点` 链接失效） | `doc` 模板目录链接加 `onclick`，用 `scrollIntoView()` 滚动到对应面板，保留 `href` | 测试发现 |
| `doc` 模板中正文限宽 40em、字号 14px，宽屏上文字只占面板一半，在句中提前换行，读起来像源稿有硬换行 | 只对 `doc` 模板：`.am-doc` 最大宽度 1120px → 1280px、字号 16px；面板内 `p`、`li`、`blockquote` 不再限宽，铺满面板。`sheet` 模板不变 | 用户反馈 |
| 问答分主题成页，页面之间不能互相跳转 | frontmatter 新增 `home`、`home_label`（不显示在页头信息行）：`doc` 模板在左侧目录顶部显示「← 首页」链接，有 `home` 时不足 3 个面板也显示目录。新增 `scripts/qa-build.mjs`：渲染目录下全部主题文件时自动写入这两项，并按各文件 `title` 和 `##` 标题生成首页 `index.html` | 用户要求 |
| 页脚「Generated by Answer me with HTML … ★ Star on GitHub」 | `colophon()` 返回空字符串，不再输出页脚 | 用户要求 |
| 渲染时自带的 STE 措辞检查，词表与框架的措辞检查重复且细节不一致 | 删除 `src/lint/` 全部模块、`am lint` 命令、`style` 设置项与 frontmatter 字段、`--style` 参数、页面根标签的 `data-style` 和 `ask` 组件的检查钩子；措辞改由项目的 `check-wording.py` 检查 | 用户要求 |
| `am patch` 更新页面后，旧评论和标注仍留在 localStorage，再次复制会重复发送 | 页面按源稿算版本号；复制回复成功时记下版本号，之后改动评论或标注会清掉该记录；打开页面时若已复制且版本不同，清空评论和标注 | I24 |

网页默认主题改为「卡片」（`shadcn`）：`pickTheme` 对网页始终返回 `shadcn`，视频仍用 `blueprint`；主题列表 `ALL` 把卡片排在图纸前面，工具栏的主题选择框第一项是卡片；`SKILL.md` 第 3 节同步。用户要求。

不运行上游更新命令；`am.mjs` 的 `update_check` 默认改为关闭，因为上游更新会覆盖本地改动。

工具栏的「回复 / 标注 / 复制源稿」保留文字按钮，没有按 R39 改成图标。

新增界面文字只补了 zh、zh-Hant、en、ja；he 回退到英文。

R 编号指 `skills/ui-visual-review`，I 编号指 `skills/ui-interaction-review`。
