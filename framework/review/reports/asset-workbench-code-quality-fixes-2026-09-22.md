# 工作台编码规范问题修复与实际验证

## 范围与版本

用户在静态审核后明确授权修复四项问题并实际验证；Shader 接入仅讨论，本轮没有实现。
修改基于 `2d00f251c6d5d7ce7f4569232086bbd2e0bf97d5`，开始时维护仓库工作区干净。
本报告的通过结果来自本轮最终代码，不沿用 2026-09-21 的通过记录。

源代码在 `project-source/`，回归夹具在 `framework/tests/project/`。
实际执行使用既有外部项目 `D:/A_Games/Game_idle_yaya_frame_workbench_test`：
Windows、Godot `4.7.1.stable.official.a13da4feb`、Vulkan Forward+ / RTX 4060 Laptop GPU，
Python 使用 `C:/Users/89523/anaconda3/envs/codex-python/python.exe` 和项目已安装的 Analyzer 依赖。
只同步本轮具体源文件、相关说明与三份回归夹具，未覆盖机器配置、主场景设置和 Cue。
执行后核对源代码、四套测试及 Cue 与对应源材料一致；故障注入的两份契约 JSON 已恢复原字节。

## 四项修复

| 审核问题 | 最终行为与取舍 | 对应源材料 |
| --- | --- | --- |
| 组合区 `Stop all` 只停止舞台，连续触发和浏览器试听仍继续 | 面板发出 `stop_requested`，由既有工作台 `stop_all()` 统一停止。复用现有协调职责，不增加新状态机 | `composition_panel.gd`、`composition_workbench.gd` |
| 快照写入没有上限，读取却拒绝超过 32 MiB 的 JSON | 读写共用 `MAX_JSON_BYTES`；写入前计算格式化 JSON 加换行的 UTF-8 字节数，超限时返回错误，不创建或截断目标文件。上限未提高，也不引入压缩/分片格式 | `analysis_group.gd` |
| 两份分析契约在 GDScript 静态变量初始化时读取文件 | 按需显式加载，只有结构可用时才缓存；服务在启动任务前初始化默认预算和契约。缺失、解析失败及当前解释器不支持的结构返回含文件路径的 `analyzer_config`，失败不缓存，恢复文件后可重试 | `analysis_source.gd`、`analysis_schema.gd`、`analysis_service.gd` |
| 七处代码超过 100 字符限制 | 折行及提取局部判定，保持原表达式语义。未调宽规则 | `analysis_source.gd`、`analysis_result.gd`、`analysis_chart.gd`、`single/example_reward_game.gd` |

工作台脚本位于 [tools/asset_workbench](../../../project-source/tools/asset_workbench/)，
示例脚本位于 [examples/asset_workbench/single](../../../project-source/examples/asset_workbench/single/)。
配置校验只检查当前消费者需要的类型、预算和解释器输入结构；结果字段仍由原来的共同 JSON Schema 定义。
不新增配置服务、依赖、结果协议版本、流程 Gate 或自动同步。

## 本轮实际验证

以下原始证据路径均相对外部验证项目。四套 Godot 测试共 51 项，均通过测试包装器的最终判定，
不是仅看引擎退出码或测试界面的绿色文字。

| 检查 | 结果与覆盖 | 原始证据 |
| --- | --- | --- |
| Godot Analyzer | 18/18；真实音频/图像进程、缓存、协议、STALE、取消/超时、预算；扩展失败隔离用例，逐一模拟两份契约缺失、坏 JSON、数组及空对象，检查预览播放与恢复后同一窗口继续分析 | `reports/gdunit-wrapper/run-821_g245/result.json` |
| Godot 组合工作台 | 8/8；点击实际 `Stop all` 按钮信号后，连续触发、试听循环、活动声音和效果停止，延迟声音不再启动；原对象切换、批量保存冲突与实际消费回归 | `reports/gdunit-wrapper/run-adbo4zwi/result.json` |
| Godot 分组/历史 | 13/13；中文 UTF-8 内容恰好 32 MiB 可保存、读取并装入批量模型；再增加 1 字节后，已有目标保持原内容，新目标不创建；原批量、规则、历史、重算与失败隔离回归 | `reports/gdunit-wrapper/run-si74ld_x/result.json` |
| Godot 单对象工作台 | 12/12；浏览、试听、A/B、触发/停止、主题、保存/重载和示例消费 | `reports/gdunit-wrapper/run-e1v3k7t5/result.json` |
| Python 后端 | 22/22 unittest；使用项目锁定依赖的真实音频/图像分析与共同契约回归 | `reports/asset-analyzer/review-fixes-20260922-backend.log` |
| 最终 Lint | 37 文件，0 Critical、0 Warning，203 Info；Info 仍包含既有数值提示和引擎方法签名提示，不冒充零诊断 | `reports/asset-analyzer/review-fixes-20260922-lint-final.json` |
| 框架维护回归 | 38/38 unittest，包含复制与契约边界；运行输出保留在本次会话 | 框架根目录 `unittest discover -s framework/tests -p test_*.py` |
| 真实渲染 | 两份现有 capture 均退出 0；单对象/组合入口、音频/图像 A/B、批量、浅深色、小窗滚动实际渲染。Agent 查看了两个入口、音频结果、批量结果、深色及小窗滚动后的截图 | `reports/asset-analyzer/review-fixes-20260922-rendering/` |

渲染产物中 `group/window-state.json` 记录主窗口与项目设置均为 1600×900。
捕获脚本只将原夹具的输出目录机械替换到本次独立产物目录，保留旧证据；两份运行副本及 `engine.log` 一并保留。
未修改手册 Markdown/HTML：现有工作台指南继续链接本轮更新的示例与 Analyzer README，具体操作说明在对应 README 同步。

### 调试过程中的失败

- 初次 Lint 的新增函数复杂度/测试类方法数告警，经职责拆分和复用原失败隔离用例后消除；`lint-01`、`lint-02` 结果保留。
- `run-bh3os6ix` 的 18 项断言通过，但新增测试变量遮蔽产生引擎警告，包装器正确判为失败；改名后 `run-821_g245` 最终通过。
- `run-ajh3a281` 的快照测试错误地比较 Godot 整数与 JSON 解析后的浮点存储类型。小型真实引擎探针确认 `1` 往返成为 `1.0`，这不影响现有快照校验和加载。
- `run-60h4kjqb` 继续用字符串断言比较上述不同表示，导致断言库对巨大差异生成诊断时占用过高；核对进程归属后终止，未记为通过。最终夹具先规范化 JSON 数字表示，再将布尔比较结果交给断言库，保持完整内容、边界与实际加载检查；`run-si74ld_x` 通过。检查未发现该次测试遗留的 `snapshot-size-*` 文件。

失败记录保留，不修改第三方断言库、不调大测试超时、不降低产品大小边界或断言范围来获得通过。

## 复跑入口

使用已同步本轮文件的指定外部项目，在其根目录执行：

```powershell
$python = 'C:/Users/89523/anaconda3/envs/codex-python/python.exe'
$godot = 'E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe'
foreach ($suite in @('asset_analyzer', 'asset_composition', 'asset_analysis_group', 'asset_workbench')) {
    & $python -B tools/testing/run-gdunit-tests.py --godot-binary $godot --target "tests/features/$suite/${suite}_test.gd" --continue
    if ($LASTEXITCODE -ne 0) { break }
}
```

契约故障注入测试仅适用于该独立验证项目，必须串行执行；期间不要另外启动分析任务或修改契约文件。
后端与维护回归在框架根目录执行：

```powershell
$env:YAYA_TEST_PROJECT = 'D:/A_Games/Game_idle_yaya_frame_workbench_test'
& 'C:/Users/89523/anaconda3/envs/codex-python/python.exe' -B -m unittest discover -s framework/tests/project -p asset_analyzer_backend_test.py -v
& 'C:/Users/89523/anaconda3/envs/codex-python/python.exe' -B -m unittest discover -s framework/tests -p test_*.py
```

## Shader 接入讨论与验证边界

当前 `FeedbackPresenter` 继承 `Control`，图标和放射线在同一个 CanvasItem 的 `_draw()` 绘制，
可以接入 `canvas_item` Shader；只作用图标时应分离其绘制节点。已有组合场景也可承载原生材质节点。
但 `FeedbackCue`、试调控件、值比较和保存目前没有 Shader 参数契约，不能称为现成 Shader 编辑器。

用户进一步说明目标是“组合场景：多个对象的材质和特效联动”。较小的后续范围是选一个真实的多对象联动效果，
复用现有对象选择、各自 A/B、同时触发和统一停止，补必要参数控件、对象间参数隔离、显式保存/重载，
并让独立组合场景消费同一配置。需要错峰、统一进度或重复触发时，先明确该效果的时序要求，再补对应表现数据；
现有音频延迟字段不应隐式改成所有视觉效果的时钟，也不预先扩建通用时间轴。
Shader 代码与只读纹理可共享，可变 uniform 值按适用契约使用实例参数或独立材质；
现有 `trial_copy()` 浅复制不能直接承担新增可变材质的隔离。
需要停止/重播一致时使用表现组件管理的时间或进度 uniform，不能把全局 `TIME` 当作单个试调的时钟。
参见 Godot 4.7 的 [CanvasItem Shader](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/canvas_item_shader.html)
和 [ShaderMaterial 参数共享说明](https://docs.godotengine.org/en/4.7/classes/class_shadermaterial.html)。

全屏后处理、3D 材质和通用任意 Shader 参数编辑需要不同的预览上下文，尚未实施或验证。
现有 Analyzer 测量源图片/音频，不测 Shader 后的最终画面。
本轮自动断言和渲染不替代用户对听感、布局与交互的接受，也未覆盖所有设备、全部编码和完整项目开发流程。
