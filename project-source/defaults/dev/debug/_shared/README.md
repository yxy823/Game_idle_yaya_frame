# 调试台共享代码

调试台从调试入口启动真实游戏，在独立窗口中修改游戏正在使用的调参资源、切换候选、比较、播放固定局面、查看 analyzer 分析，并把满意的设定采纳到游戏。本目录是各项目共用的代码、主题、图标与测试；本项目有哪些调试对象、怎样启动，见[本项目的调试台](../README.md)。按“你想做的事”列出的 13 个界面任务见[调试台使用场景](usage-scenarios.md)。

## 入口与项目挂钩

调试入口是 `dev/debug/debug_main.tscn`。它延迟到根节点就绪后依次执行：

1. 按 `game/` 下 `.import`、`.uid` 和资源文件头里的 UID 修正内存中的 UID 表（见[采纳到游戏与收尾](#采纳到游戏与收尾)）。
2. 执行 `dev/debug/adoption-queue/` 中排队的采纳。
3. 调用项目挂钩 `dev/debug/debug_project.gd` 的 `use_debug_save(tree: SceneTree) -> String`。
4. 打开调试窗口，切到项目设置 `application/run/main_scene` 指定的主场景。

`debug_project.gd` 属于项目自己：按本项目的存档系统改写 `use_debug_save`，把游戏存档指到只供调试的 `user://` 文件，并返回这个路径；固定局面播放时把起始状态写到这里。框架分发的默认版本返回空字符串，不改任何存档，这时调试窗口的状态栏提示“调试会话可能写入真实存档：在 dev/debug/debug_project.gd 设置调试存档位置”。没有任何调试对象时，入口照常打开游戏，状态栏提示“还没有调试对象：在 dev/debug/<对象>/ 下添加”。

依赖只能从 `dev/` 指向游戏：`game/`、`main/`、`components/` 和 `project.godot` 不得引用 `dev/` 下的路径、UID 或类名，游戏和 `tests/` 也不读取预设与组合。[依赖方向测试](../../../tests/invariants/debug_dependency_test.gd)只读文本与 UID 表检查这几条。

## 窗口与操作

调试窗口顶部是“调参 / 分析”两个标签页，底部是状态栏。“调参”页自上而下是组合与对比条、播放条、插槽列表与检查器；“分析”页放截图分析等画面分析。切换标签页只换显示内容，游戏和固定局面播放照常进行。窗口默认 1000 × 760 逻辑像素乘以屏幕缩放，限制在屏幕可用区内；启动时游戏窗口和调试窗口左右并排，放不下时调试窗口先变窄到最小宽度，再按比例缩小游戏窗口。只有调试主窗口设置 `force_native=true`，弹窗沿用内嵌窗口；窗口换到另一块屏幕时按新屏幕的 DPI 重设缩放。

| 操作 | 行为 |
| --- | --- |
| F1 | 在游戏窗口、调试窗口或调试弹窗中显示或隐藏调试窗口；按住不重复触发。 |
| 反引号 ` 或点对比开关的另一侧 | 在“当前改动”和对比对象之间切换。显示对比对象时参数只读、不能采纳，再按一次回到当前改动。固定局面播放中在下一遍开头切换。没有任何不同时只提示“还没有改动可对比”。 |
| 对比开关右侧的下拉箭头 | 选择对比对象：默认“游戏原值”，也可以选一个已保存的组合。 |
| 组合下拉 | 载入一个组合的整套预设，或选“游戏原值”回到游戏文件的值。 |
| 关闭游戏窗口 | 有未保存改动时先问：“保存”把每个有改动的插槽存进它当前的预设（没有预设的存成“关闭前-日期时间”）再关闭、“不保存直接关闭”或“取消”。 |
| 调试窗口关闭按钮 | 隐藏窗口；F1 可以再次打开。 |
| 播放条的调试对象 | 浏览该对象和 global 的插槽；下拉显示对象的中文名。启动时选第一个不是 global 的对象；当前场景识别到已登记对象时自动跟随。 |
| 搜索与筛选 | 搜索插槽编号、中文名或参数名；“全部 / 已修改 / 钉选”三选一并显示数量，类别可折叠。没有符合条件的插槽时，列表写出当前筛选和搜索词，以及怎样看到所有插槽。钉选记在本机 `user://debug/pinned-slots.json`，不进项目文件。 |
| 载入预设或组合 | 有未保存改动时先问：“保存”（没有预设的存成“载入前-日期时间”）、“不保存载入”或“取消”。 |
| 确认框 | 按钮顺序固定为［推荐操作］［其他操作］…［取消］；会丢改动或改游戏文件的按钮用危险样式。预设、组合和插槽的名字写在“…”里，换行时整个名字移到下一行。 |
| 不能点的按钮 | 悬停时说明原因，包括播放或对比时锁定的参数行按钮、下拉框、勾选框、滑条和数值框；解锁后恢复原来的提示。 |

“N 处不同”是当前改动与对比对象逐字段比较的不同数。参数行左侧的琥珀色竖条表示与已载入的预设（或游戏原值）不同，行尾按钮只还原这一项。状态栏只用日常用语说明结果；引擎错误名、文件路径和字段名放在“详情”里。结果在 10 秒后（按真实时间，不随游戏倍速）或改参数时清除，展开“详情”时保留；启动时关于调试存档和没有调试对象的提示不按时清除，直到有新的结果替换它。颜色、字号和控件样式在 [debug_theme.tres](debug_theme.tres)，图标及其许可见 [icons/](icons/README.md)。

## 调试对象、插槽与候选

每份 `game/<对象>/tuning/**/*.tres` 是一个插槽，编号是 `<对象>/<相对路径去掉 .tres>`，目录层级形成类别。目录发现先登记路径，只激活当前对象与 global 的资源，参数控件只为选中的插槽创建。`global` 是特殊对象：它的插槽出现在每个对象的列表里。

```text
game/shop/tuning/feedback/sound.tres
dev/debug/shop/
├── debug_target.gd                  可选：对象与类别中文名、主场景、固定局面、一遍结束的判断
├── slots/feedback/sound/
│   ├── slot.gd                      可选：插槽与字段中文名、游戏中的实现、试播与分析动作
│   ├── <候选>/
│   │   ├── candidate.tres           候选描述文件
│   │   └── ...                      候选自己的场景、脚本、素材和许可说明
│   └── presets/<名称>.tres          插槽预设
├── combos/<名称>.tres               对象组合，包含 global 插槽
└── tests/                           本对象专有的测试
```

候选是插槽目录的直接子目录中名为 `candidate.tres` 的描述文件，`presets/` 不算。描述资源用 [candidate_definition.gd](candidate_definition.gd)：`display_name`、`candidate_uid`（候选场景、脚本或音频的 UID 字符串）、`default_params`（`{"script_uid": "uid://…", "fields": {"字段名": 值}}`，无参数时为空 Dictionary）、`license_note`、`source_url`。

有候选的调参资源同时声明 `candidate` 与 `candidate_params`：选择候选时两者一起替换，通用参数保持原值。没有参数的规则或素材也要声明 `candidate_params`（值留空）：调试台切换候选、选回游戏原值时总是成对写入这两个字段，缺少 `candidate_params` 时切换会报“它的文件或参数和这个插槽对不上”。候选与游戏当前的实现必须同类：游戏没有设置实现时才允许“未设置”；脚本或场景的根脚本要和游戏的实现继承同一个最上层 `class_name`；没有 `class_name` 时比较引擎基类。“实现”区第一项是游戏当前采纳的实现，标“游戏在用”；其后是游戏目录中其他已采纳过的实现（`CANDIDATES` 与刚采纳的 `adopted.tres`），仍可选回；最后是 `dev/` 下的候选。

插槽的 `slot.gd` 可以声明：

| 常量或方法 | 作用 |
| --- | --- |
| `TITLE` | 列表和检查器标题；没有时显示资源名或文件名。 |
| `FIELDS` | `{"字段名": "中文名"}`，也覆盖该插槽各候选的参数字段。共享测试要求每个插槽和参数都有中文名。 |
| `VALUES` | `{"字段名": {存储值: "中文名"}}`，给枚举选项和数值框的特殊值命名。 |
| `value_text(field_name, value)` | 数值框和“还原这一项”提示显示值的方式，例如把 MIDI 音高 72 写成“C5”；先查 `VALUES`，返回空字符串时按默认格式（数字加单位）显示。两处用同一套写法。输入时仍是数字。 |
| `CANDIDATES` | `{"uid://…": {"name": "中文名", "params": "uid://参数脚本"}}`，登记游戏目录中的实现，用于命名和选回；没有参数的实现只写 `name`。 |
| `ADOPT_DIRECTORY` | 采纳的候选移到 `game/<对象>/<ADOPT_DIRECTORY>/<候选名>/`；默认是插槽路径改成下划线。 |
| `LOGIC` | 设为 `true` 表示本插槽是规则插槽（逻辑候选）：采纳确认框在这个插槽下加一行“这是规则变化：采纳前先让 Agent 把规则写进 GDD”。 |
| `action_names()`、`run(action, live, scene)` | 试播按钮，显示在“实现”区标题右侧；`run` 返回带 `error` 的结果。 |
| `analysis_extras(live, metrics)` | 分析区的动作：返回 `action`、`icon`、`tooltip`、`reason`（非空时按钮禁用并显示原因）、`apply`（Callable，返回状态栏文字）和 `notes`。 |

参数单位来自调参脚本 `@export_range` 的 `suffix:`。曲线与渐变编辑器通过 `SlotPanel.register_editor(resource_type, factory)` 注册；未注册的资源类型只读。

## 固定局面与播放

对象的 `debug_target.gd` 登记播放所需的一切，共享代码不认识游戏的脚本和信号：

| 常量或方法 | 作用 |
| --- | --- |
| `TITLE` | 播放条“调试对象”下拉中的中文名；没有时显示对象编号。 |
| `MAIN_SCENE`、`FIXTURES` | 播放时重载的场景；`{"中文名": "res://…固定局面文件"}`。 |
| `CATEGORIES` | `{"<对象>/<类别>": "中文名"}`，列表分组标题；没有时显示类别路径。 |
| `matches(scene)`、`accepts(node)` | 当前场景是否属于本对象；新加入的节点是否是要绑定的游戏节点。 |
| `prepare_fixture(path, save_path, still)` | 把固定局面写进 `save_path`（`debug_project.gd` 返回的调试存档），返回 `{"error", "seed"}`；`still` 为 true 时局面停在开头不开始。 |
| `bind(node, seed)`、`connect_finished(callback)` | 给游戏节点设随机种子；把“这一遍结束”接到无参数回调。 |
| `advance_feedback(delta)`、`feedback_pending()` | 结束后等特效、音频等尾部反馈播完再循环。 |

点播放时调试台写入固定局面、重载场景；每遍从同一局面与随机种子开始。播放及暂停时参数、候选、预设和采纳按钮锁定，调试窗口按 `PROCESS_MODE_ALWAYS` 继续响应，游戏按 SceneTree 暂停。支持暂停或继续、回到开头（结束播放、解除锁定、局面停在开头）、0.1 到 2 倍速（同时改 `Engine.time_scale` 与 `AudioServer.playback_speed_scale`，音高也随之变化）和 1/3/5/无限遍。没有固定局面的对象仍能浏览和调整全部插槽。

## 插槽预设与组合

插槽预设用 [slot_preset.gd](slot_preset.gd)，字段为 `slot_id` 与 `fields`，保存全部可持久化脚本字段（包括 `@export_storage`）。Curve 和 Gradient 内嵌复制，外部资源存 UID 字符串，调参资源之间的引用存 `{"slot_id": "<对象>/…"}`，`candidate_params` 按脚本 UID 与字段字典内嵌。

组合用 [target_combo.gd](target_combo.gd)，字段为 `target_id` 与 `entries`：

```text
target_id = "shop"
entries = {
    "shop/feedback/sound": "shop/feedback/sound#明亮",
    "shop/feedback/effect": "",
    "global/ui-volume": ""
}
```

空字符串表示游戏原值，其余用 `<插槽编号>#<预设名>` 引用插槽预设。

- **保存**：组合只保存引用。有未保存插槽时，起好组合名后先确认“一并保存”，确认框逐个列出插槽的改动存进哪个预设。覆盖被组合引用的预设前先提示；另存预设或组合时，命名框预填不重名的新名字（“<当前名>-2”），输入已存在的名字先确认覆盖，预设还列出用到它的组合；一次保存多个插槽时不覆盖其他组合正在用的预设，改存为“<预设>-<组合名或载入前/关闭前>”。
- **载入**：逐项核对插槽、字段名、类型、候选及参数脚本，对不上的项改用游戏原值，插槽仍记着这个预设并标“（已修改）”；候选缺失时候选和参数一起回退。字段改名会作为旧字段与缺失字段报告，不按位置错配。
- **删除**：删除预设先列出引用它的组合，确认后这些条目改为空字符串；删除组合也需确认。

预设和组合由调试台在运行中保存，文件头和外部引用没有 UID；它们不是游戏资源，不需要补 UID，资源格式检查跳过它们，修改它们也不改变内容指纹。

## 分析

调试台按资源 Analyzer 的[运行一次分析](../../../yaya/tools/analyzer/README.md#运行一次分析)在后台调用 worker：读取 `docs/methodology-config.json` 的 `analyzer_python_executable`，在 `reports/asset-analyzer/jobs/debug/` 写请求文件，每帧检查进程是否结束，结束后读取结果并删除请求与结果文件；游戏不等待 worker。没有配置时分析区只显示“未配置 analyzer”，其他功能不受影响。

- **音效候选**：插槽的当前候选是 AudioStream 时，“实现”与“参数”之间显示基础音高、时长、峰值、真峰值、RMS、20 ms 最大 RMS、起音、衰减和频谱重心；每个文件在一次会话中只分析一次。插槽的 `analysis_extras` 可以在这里加动作和说明。
- **截图分析**：位于“分析”页，截取游戏窗口的根视口，存为 `reports/asset-analyzer/jobs/debug/game-*.png`，显示正常、灰度、红色盲、绿色盲四格。

## 采纳到游戏与收尾

检查器底部的“采纳到游戏”写当前插槽，箭头菜单中的“采纳全部插槽（当前组合）到游戏”写当前组合的所有插槽。用户只确认一次：确认框写出每个插槽会怎样和将修改的游戏文件。写入前检查整个资源图：引用 `dev/` 下文件或缺 UID 的设定不能采纳。

插槽选中的候选还在 `dev/` 里时，调试台先把候选移进游戏再写参数（[candidate_adoption.gd](candidate_adoption.gd)）：

- **移动什么**：候选目录中除 `candidate.tres` 外的全部文件一起移到 `game/<对象>/<ADOPT_DIRECTORY>/<候选名>/`，不复制，UID 不变。描述文件改名为 `adopted.tres` 留在原处，用来显示中文名和参数类型；落选的候选和被替换的实现都不动，后者之后仍可在“实现”里选回。
- **素材当场生效**：只有素材和说明的候选（音效、图片）当场移动，调试台把 UID 指到新路径，游戏下一次使用就是新文件。
- **脚本、场景和文本资源排到下次启动**：这类文件写着旧的 `res://` 路径，运行中的游戏还按旧路径缓存着它们，所以先写入其他参数，把移动排进 `dev/debug/adoption-queue/`，状态栏写“（游戏将在下次启动时使用）”。下次启动调试入口时，入口在加载调参资源之前移动文件、改写其中指向旧目录的路径并写入游戏文件。
- **重启不依赖收尾**：游戏启动时读的 UID 表是编辑器缓存，移动后仍指向 `dev/`。所以每次有文件移动后，调试台在后台运行一次 `--headless --import` 让编辑器重扫；入口每次启动也先修正内存中的 UID 表。
- **待收尾记录**：每次采纳都在 `dev/debug/adoption-log.md` 追加一行：时间、插槽、移动的候选与文件、写入的游戏文件。文件只列还没收尾的采纳。

### 编辑器开着时

本项目的 Godot 编辑器开着时（按进程命令行判断：`--editor`、`-e` 或打开 `project.godot`，无头进程不算），调试台不启动后台导入，因为编辑器窗口重新获得焦点时会自己扫描，两个编辑器进程不能同时写 `.godot` 缓存。状态栏提示“Godot 编辑器正开着本项目：切回编辑器窗口，它会自动更新文件登记；更新前请从调试台启动游戏”。编辑器重新扫描前，不经调试入口直接启动主场景时，已移动的脚本类候选会按旧路径报错。

### 收尾步骤

用户在调试台采纳后，Agent 按以下步骤让文件成为正式资源。命令在项目根目录的 PowerShell 中运行，Godot 路径取自 `docs/methodology-config.json` 的 `engine_executable`，写法与[首次 Godot 扫描](../../../yaya/tools/README.md#首次-godot-扫描)相同：

```powershell
$projectConfig = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
$projectGodot = (Resolve-Path -LiteralPath $projectConfig.engine_executable -ErrorAction Stop).Path
```

1. 读 `dev/debug/adoption-log.md` 的每一行，记下移动的目录与写入的 `.tres`。
2. 如果 `dev/debug/adoption-queue/` 还有文件，关闭调试会话后运行排队的移动：

   ```powershell
   & $projectGodot --headless --path . --script res://dev/debug/_shared/run_adoption_queue.gd | Out-Host
   $LASTEXITCODE
   ```

3. 让编辑器扫描并按新路径重新导入移动的素材。如果本项目的编辑器开着，先请用户保存并关闭编辑器（关闭时它会自己扫描），第 4 步也等编辑器关闭后再运行：

   ```powershell
   & $projectGodot --headless --path . --import | Out-Host
   $LASTEXITCODE
   ```

4. 用编辑器序列化器重存写入的 `.tres` 和移动的 `.tscn`、`.tres`，补回外部资源的 UID（[resave_godot_files.gd](../../../yaya/tools/README.md#resave_godot_filesgd)）：

   ```powershell
   & $projectGodot --headless --editor --path . --script res://yaya/tools/godot/resave_godot_files.gd -- res://game/<对象>/tuning/<插槽>.tres | Out-Host
   $LASTEXITCODE
   ```

5. 把 `adopted.tres` 的 `display_name` 和 `default_params.script_uid` 写进该插槽 `slot.gd` 的 `CANDIDATES`（没有参数的候选只写 `name`，不写参数脚本），删除 `adopted.tres` 和已空的候选目录（删除前确认候选的许可说明已随素材移进 `game/`，`adopted.tres` 里的来源与许可摘要已写进设计文档的资源条目）；被替换的实现是否从游戏目录删除，由用户决定。更新[本项目的调试台](../README.md)中的候选登记。
6. 检查 UID 未变化、字段与依赖仍正确，运行 `check-godot-resource-format.py`，再按[测试影响评估](../../../yaya/methodology/08-test-traceability-and-evidence.md#测试影响评估)选择要跑的测试，至少包括写入资源所属组件的测试、依赖方向测试和 `dev/debug/<对象>/tests/` 下的对象测试（对象测试按 UID 定位候选，采纳移动后应照常通过）。
7. 删除 `adoption-log.md` 中已处理的行，全部处理完时删除该文件。

第 5、7 步的删除被权限拦截时，不要换别的方式绕过：把完整的删除命令交给用户执行，其余步骤照常继续。

`adoption-log.md` 不进版本库，只是 Agent 收尾的待办信号。收尾改动的提交范围见 `AGENTS.md` 的[开始修改前](../../../AGENTS.md#开始修改前)。`dev/debug/` 下新增或改动的插槽预设与组合属于用户的调试草稿，收尾时随采纳一并提交；没有采纳时，用户要求或下次收尾时提交。

## 从编辑器启动

主要方式是项目说明里的命令行启动。需要脚本热重载、远程场景树或性能分析器时，也可以在编辑器中打开 `debug_main.tscn` 按 F6 运行，但有这些限制：

- **窗口**：游戏嵌进编辑器的“游戏”面板，调试窗口不能和它并排；初始位置可能部分越出屏幕，按两次 F1 回到屏内。
- **按键**：真实键盘的 F1 和反引号经过编辑器嵌入层时可能被编辑器拿走。
- **热重载**：只有在 Godot 脚本编辑器里保存才生效，Agent 或外部编辑器写的文件不会更新运行中的游戏，也不重新执行 `_ready`。
- **调参只在调试台里改**：编辑器检查器显示的是编辑器自己的资源副本，不是游戏当前值；内嵌的候选参数切换过对比后不再同步，也没有提示。
- **停止前先保存**：从编辑器停止（F8）直接结束游戏进程，不出现“关闭前保存”的提问，未保存的改动丢失。

## 测试

- **共享测试**：`_shared/tests/` 用 [fixtures/sample/](tests/fixtures/sample/) 下的样例游戏与样例调试对象（`game/` 与 `debug/` 两棵目录分别代替项目的 `game/` 与 `dev/debug/`）。唯一读本项目文件的是 [catalog_test.gd](tests/catalog_test.gd) 的中文名检查：它同时检查本项目每个插槽、参数和已采纳的实现都有中文名，所以新建调参资源或新增字段后要补 `slot.gd`。采纳测试与[界面任务测试](tests/usage_scenario_test.gd)把样例复制到 `user://` 下再移动，不改 `dev/` 与 `game/` 的真实文件；界面任务测试把每一步看到的文字写进引擎日志。
- **对象专有测试**：放在 `dev/debug/<对象>/tests/`，测试本项目的 `debug_target.gd`、`slot.gd` 与 `debug_project.gd`。
- **调试入口启动检查**：[fresh_load.gd](tests/fixtures/fresh_load.gd) 在新进程中启动真实的调试入口，检查全部调试资源能载入、窗口常驻、主场景打开、调试对象跟随。游戏会读写自己的 `user://` 数据，所以在项目副本里运行：`& $projectGodot --headless --path <项目副本> --script res://dev/debug/_shared/tests/fixtures/fresh_load.gd`。
