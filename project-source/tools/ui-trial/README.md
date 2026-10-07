# 按界面任务试用

在项目副本里用程序驱动界面：点按钮、选下拉项、注入按键、读界面文字和截图，按界面任务逐个走一遍；另带一个界面静态扫描，找出可能的可用性问题。`review-ux` 审核界面时，可以用这些工具产生实际交互证据，何时使用、怎样判断结果由 `review-ux` 说明。

下文的 `python` 和 Godot 一律换成 `docs/methodology-config.json` 中配置的路径；命令在项目根目录执行。

## 为什么只在副本里运行

试用会执行游戏和调试台的真实代码，可能写入 `user://`（存档、预设、日志）。Godot 按 `project.godot` 的 `config/name` 选择 `user://` 所在目录，所以副本必须改名，才不会写进用户真实的存档。工具设了三道检查：

1. `prepare-trial-copy.py` 先写入改名后的 `project.godot` 并读回确认，确认后才同步其余文件；没改成就以非零退出码中止。
2. `run-ui-trial.py` 只在 `config/name` 以 ` trial` 结尾的副本中启动 Godot。
3. 驱动基类启动时再核对一次项目名，不符合就以退出码 3 退出，不执行任何步骤。

## 准备副本

```powershell
python -B yaya/tools/ui-trial/prepare-trial-copy.py --copy D:\Games\MyGame_trial
```

| 参数 | 作用 | 默认值 |
| --- | --- | --- |
| `--copy <目录>` | 必填。副本目录，不存在时创建；已存在的必须是项目副本（有 `project.godot`）或空目录 | 无 |
| `--project <目录>` | 要复制的项目 | 脚本所在项目 |

- **同步范围**：复制项目的全部文件，包括 `.godot/`（省去重新导入），不复制 `.git/` 和 `reports/`；项目里已删除的文件也从副本删除。
- **保留**：副本自己的 `reports/` 不覆盖、不删除，驱动脚本和试用输出放在那里；副本目录本身不删除，再次运行只同步变化。`reports/.gdignore` 不存在时创建，Godot 不会把试用输出当成项目资源。
- **改名**：副本的 `config/name` 为 `<原名> trial`，例如 `Match Three v2 trial`，存档目录随之变成 `%APPDATA%/Godot/app_userdata/Match Three v2 trial/`。项目启用了 `application/config/use_custom_user_dir` 时，改名不能分开存档，工具直接拒绝。

退出码：`0` 已改名并同步；`1` 改名或读回失败、项目没有 `config/name`、启用了自定义存档目录，或同步中途出错；`2` 参数或路径不可用（副本在项目内、目录非空且不是项目副本、源项目本身已是副本）。

## 编写驱动脚本

驱动脚本放在副本的 `reports/ui-trial/drivers/` 下，继承驱动基类的路径，只在 `_run()` 里写步骤：

```gdscript
extends "res://yaya/tools/ui-trial/ui_trial_driver.gd"


func _run() -> void:
	if open_scene("res://main/main.tscn") == null:
		return
	if not await wait_until(func() -> bool: return find("StartButton") != null, 5.0, "start button shown"):
		return
	click("StartButton")
	await press_key(KEY_ESCAPE)
	expect(text_of("StatusLabel").contains("已暂停"), "status says paused")
	await save_screenshot("paused.png")
```

| 方法 | 作用 |
| --- | --- |
| `step(文字)` | 记录一个步骤 |
| `expect(条件, 文字)` | 条件成立记 `ok:`，不成立让试用失败；返回条件本身，失败后用 `return` 结束 `_run()` |
| `fail(文字)` | 让试用失败并退出 |
| `await wait_frames(n)`、`await wait_seconds(s)` | 等待帧或秒 |
| `await wait_until(条件函数, 秒, 文字)` | 每帧检查，成立返回 `true`，超时让试用失败 |
| `open_scene(路径)` | 实例化场景并设为当前场景 |
| `find(名称或路径, 起点)`、`require(...)` | 名称在起点之下递归查找，包括代码创建的节点和子窗口；带 `/` 的按节点路径查找。`require` 找不到时让试用失败 |
| `click(按钮)` | 像用户点击一样发出 `pressed`；按钮隐藏或禁用时让试用失败；切换按钮先改按下状态 |
| `select_option(下拉框, 序号或文字)` | 选中 `OptionButton` 的一项并发出 `item_selected` |
| `await press_key(键, 窗口)` | 向窗口注入一次按下与松开（`push_input`），默认根窗口 |
| `text_of(控件)` | 读 Label、Button、RichTextLabel、LineEdit、TextEdit 显示的文字 |
| `visible_texts(起点)` | 列出起点之下全部可见文字，用于查找状态栏、提示 |
| `await save_screenshot(文件名, 窗口)` | 把窗口画面存成 PNG；无头模式不渲染，记录跳过 |

注意：

- **出错即退出**：引擎报出的任何错误，包括脚本运行错误和 `push_error`，都让试用以退出码 1 结束；警告只记录。被试的代码本身报错时，试用同样停下，这正是要找的问题。
- **看门狗**：驱动在等待中卡住时，看门狗到时以退出码 2 结束。主线程死循环时看门狗无法触发，由运行脚本的外层超时结束整个进程树。
- **无头模式的尺寸**：无头模式的根窗口只有 64×64 且改不了尺寸，基类把画布缩放到项目设置的视口尺寸，控件按真实尺寸布局；游戏代码读到的 `root.size` 仍是 64×64。
- **独占对话框会挡按键**：场景里打开着的 `AcceptDialog` 等独占窗口会挡住发给根窗口的按键，和玩家实际遇到的一样。
- **点击不经过鼠标**：`click` 直接发出信号，不检查按钮是否被别的控件盖住；需要确认能否点到时看截图。

## 运行

```powershell
python -B yaya/tools/ui-trial/run-ui-trial.py --copy D:\Games\MyGame_trial --script reports/ui-trial/drivers/open_menu.gd
```

| 参数 | 作用 | 默认值 |
| --- | --- | --- |
| `--copy <目录>` | 必填。已准备好的副本 | 无 |
| `--script <路径>` | 必填。驱动脚本：`res://` 路径，或副本内的文件路径（相对副本或绝对路径） | 无 |
| `--window` | 打开真实窗口运行，`save_screenshot` 才会保存 PNG。窗口出现在用户桌面上，先用无头模式调通，最后只开一次 | 无头 |
| `--timeout-seconds <秒>` | 外层墙钟超时，到时结束本次创建的整个进程树 | `180` |
| `--watchdog-seconds <秒>` | 驱动看门狗，必须小于外层超时 | 外层超时减 15 秒 |
| `-- <参数…>` | `--` 之后的参数原样传给驱动脚本（`OS.get_cmdline_user_args()`） | 无 |

Godot 路径读取副本的 `docs/methodology-config.json` 中的 `engine_executable`。

**输出**：每次运行在副本的 `reports/ui-trial/<脚本名>-<日期-时间>/` 下保存 `steps.log`（步骤与结论）、`engine.log`（Godot 完整输出）和驱动保存的截图、扫描结果。控制台打印输出目录、进程是否全部结束、Godot 退出码及其含义。

退出码：`0` 驱动完成且输出中没有 `SCRIPT ERROR`；`1` 驱动失败（Godot 退出码 1 为步骤失败或引擎报错，2 为看门狗到时，3 为项目名检查拒绝），或输出中有 `SCRIPT ERROR`；`2` 参数错误、副本未改名或找不到 Godot，未启动 Godot；`3` 外层超时，进程树已结束；`4` 本次创建的 Godot 进程没能全部结束。

## 静态扫描

```powershell
python -B yaya/tools/ui-trial/run-ui-trial.py --copy D:\Games\MyGame_trial --script res://yaya/tools/ui-trial/ui_scan.gd -- --scenes=res://ui/shop.tscn,res://ui/settings.tscn
```

逐个实例化 `--scenes` 中的场景，等两帧后检查，结果写入输出目录的 `scan.json`。场景的 `_ready` 会执行，所以同样只在副本中运行。驱动脚本也可以在操作到某个状态后扫描运行中的界面：

```gdscript
const Scan := preload("res://yaya/tools/ui-trial/ui_scan.gd")
var findings := Scan.scan_node(find("ShopPanel"))
```

只检查可见的按钮、输入框、滑条和数值框；隐藏的页面打开后再扫描。按钮文字取按钮自身的文字，没有时取按钮内可见的 Label。

| 规则 | 线索 |
| --- | --- |
| S01 | 按钮没有文字，也没有悬停提示 |
| S02 | 按钮文字含糊（OK、确定、是、否、X 等）；对话框内的按钮除外 |
| S03 | 同一窗口内多个按钮文字相同 |
| S04 | 点击区域宽或高小于 24 像素（参照 WCAG 2.2 SC 2.5.8）；按项目视口尺寸计算，窗口缩放后的实际像素更大 |
| S05 | 危险按钮与同一窗口内最近的交互控件间距小于 8 像素。名称、文字或提示含“删除”“重置”“退出”“覆盖”等词即视为危险；控件可设元数据 `ui_trial_role = "danger"` 明确标出 |
| S10 | 禁用的按钮没有悬停提示说明原因 |

每条结果只是线索：要对照界面任务和截图确认，误报不写进审核结论。扫描不检查键盘焦点链、全屏界面有无返回控件和危险操作有无确认步骤，这些靠按界面任务试用判断。扫描以退出码 `0` 结束时只说明扫描完成，结果数量不影响退出码；场景加载失败时退出码为 `1`。
