# 第二阶段：外部 Analyzer 实施与验证

日期：2026-09-21。维护仓库：`D:/A_Games/Game_idle_yaya_frame`；基线提交 `49bf0ba`。
用户在本轮明确确认第一阶段已通过验收，并授权第二阶段代码、测试、文档和验收记录。
实际验证项目沿用 `D:/A_Games/Game_idle_yaya_frame_workbench_test`，不是未初始化的分发源目录。

## 实施结论与范围

已建立源资源选择 → Godot 后台进程 → 外部音频/图像分析 → Schema v1 → 指标/图表 → 同类 A/B → 内容缓存闭环。
分析是原浏览器上的新入口，使用非模态窗口；没有第二套资源浏览器，没有重做预览或修改 SoundManager。
第一阶段事件 A/B 和分析资源 A/B 各有明确用途，后者不写入 Cue。当前交付的自动化与渲染证据不替代用户对第二阶段界面的人工验收。

## 开始前审查与复用

已阅读实际根 `AGENTS.md`、维护手册/同步约定、源 `Project_AGENTS.md`、Feature 执行/资源规格 Skill、相关开发流程与 GDScript/测试规则，并核对维护提示词。源项目流程只作为被维护材料，没有在框架仓库创建虚假 Feature 或 Stage 5 接受记录。

| 现有能力 | 实际位置与本轮处理 |
| --- | --- |
| 资源浏览、独立试听 | `project-source/tools/asset_workbench/asset_browser.gd`；新增明确分析按钮，原试听和绑定行为保留 |
| 事件预览、试调、A/B | `workbench.gd`、`cue_controls.gd`、`components/feedback/feedback_presenter.gd`；未重写表现模型 |
| 保存及游戏消费 | `preview_session.gd`、示例 `FeedbackCue .tres` 与 `example_reward_game.gd`；保持磁盘冲突检查、保存/重载和真实消费链 |
| 原生属性 | 浏览器原有 Texture2D 尺寸、AudioStream 时长保留；外部分析单独标记源文件口径 |
| 音频适配器 | `components/feedback/audio_playback.gd` 复用 SoundManager 局部播放器池；仅该适配器依赖插件 API，Analyzer 不依赖它 |
| 第三方版本 | `addons/sound_manager/UPSTREAM.md` 固定提交 `1c041582db806a0d0edad77111d1fb7a009346ef`，plugin.cfg 2.6.2；全局插件/Autoload 未启用，本轮未修改其文件 |
| 后台执行 | 已有 `tools/lib/gdunit_process.py` 面向测试进程树与证据，不是运行时分析服务；没有现成 Godot 分析队列，因此新增小型单进程任务封装 |
| 数据、缓存、图表 | 原有 Cue 是表现配置，不能用作测量结果；此前没有 Analyzer 协议/内容缓存/通用数据图表，本轮补充 |
| 环境与测试 | Windows 11；Godot `4.7.1.stable.official.a13da4feb`；指定 conda Python 3.12.13；既有 unittest、真实 gdUnit 包装器、Godot lint 与渲染夹具 |

## 技术选择与文件位置

采用 PyAV **18.1.0**、Pillow **12.3.0**、NumPy **2.5.3**、pyloudnorm **0.2.0**、SciPy **1.18.1**。
2026-09-21 核对官方发布、维护状态、Windows wheel 与许可后实际安装；没有沿用旧调研中的模糊版本。
PyAV wheel 实际链接 FFmpeg **8.1.2 / LGPL-3.0-or-later**，不是当日独立 CLI 最新的 9.0.2。
主包许可及 wheel 附带组件边界、来源链接、未选 FFmpeg CLI/librosa/OpenCV 的原因见
[依赖记录](../../../project-source/tools/asset_analyzer/DEPENDENCIES.md)。

选择可安装的 Windows wheel，避免额外 CLI 路径、日志解析和编译链；SciPy 是成熟响度实现的依赖。
所有包安装在测试项目的 `reports/asset-analyzer/runtime`，没有升级原 Python 环境、修改框架默认 ready 状态或写入机器绝对路径。

| 新增/修改文件 | 实际责任 |
| --- | --- |
| `project-source/tools/asset_analyzer/protocol.py`、`result.schema.json` | v1 结构和四种指标状态；声明支持类型/指标、Analyzer 版本及后端版本映射 |
| 同目录 `worker.py` | 请求分派、明确版本检查、内容哈希/参数/版本缓存、原子写入、Windows 父进程退出保护 |
| 同目录 `audio_adapter.py`、`image_adapter.py` | 实际调用第三方解码、响度和图像库；原始后端细节停在这里 |
| 同目录 `requirements.txt`、`README.md`、`DEPENDENCIES.md` | 固定依赖、操作、协议、算法口径、缓存和扩展说明 |
| `project-source/tools/asset_workbench/analysis_service.gd`、`analysis_job.gd` | 排队、并发上限、超时/取消、非阻塞管道、退出码、2 MiB 输出限制、结构与资源身份核对、清理 |
| 同目录 `analysis_result.gd` | 两端契约的 Godot 边界、指标文本、同类比较、独立静音规则检查 |
| 同目录 `analysis_panel.gd`、`analysis_chart.gd` | 指标表、A/B 数据、可缩放数据序列图、状态/警告/参数/后端版本显示 |
| 同目录 `asset_browser.gd`、`workbench.gd`、`workbench_theme.gd` | 增加分析入口与生命周期挂载、Tree 样式和沿用浅/深色主题；原素材无染色 |
| `framework/tests/project/asset_analyzer_backend_test.py` | 有真实依赖的 opt-in unittest，不使默认项目工具测试强依赖媒体包 |
| 同目录 `asset_analyzer_test.gd`、`analyzer_process_fixture.py`、`asset_analyzer_capture.gd` | 实际引擎进程/异常/UI 集成及渲染证据；不随框架复制 |
| 示例 README、tools README、维护手册工作台专题与阅读版、framework README/progress | 同步现状、使用与验证边界 |

`framework/project-files.json` 已递归复制整个 tools，无需重复加映射。新增源码、Schema、依赖声明随项目复制；Python wheel、分析缓存、测试脚本和运行证据不会进入空白分发源。

概念接口的等效实现：`AnalysisService.submit(path, kind, parameters, force)` 分派 audio/image；`analysis_result.compare_rows` 和通用 Chart 执行比较；`rule_messages` 在 Godot 侧检查规则。没有为四个概念方法再造抽象类层。
`analyzer.backend` 的版本映射承担 backend/backend_version 语义，能表达多个实际后端及 FFmpeg 库版本。

## 结果与指标

实际音频 JSON 保留在测试项目 `reports/asset-analyzer/audio-results.json`，图像为 `image-results.json`。
下面是实际 A 结果的选定字段（为便于阅读缩减了指标/序列/缓存详情，并缩短路径；不是完整 Schema 验证夹具）：

```json
{
  "schema_version": 1,
  "status": "success",
  "asset": {"path": ".../example-confirmation-a.ogg", "type": "audio"},
  "analyzer": {
    "id": "audio_basic", "version": 1,
    "backend": {"av": "18.1.0", "numpy": "2.5.3", "pyloudnorm": "0.2.0", "scipy": "1.18.1"}
  },
  "metrics": {
    "duration": {"status": "available", "value": 0.28984126984127, "unit": "s", "reason": ""},
    "sample_peak": {"status": "available", "value": -0.929786788710431, "unit": "dBFS", "reason": ""},
    "rms": {"status": "available", "value": -11.3127595279947, "unit": "dBFS", "reason": ""},
    "integrated_loudness": {"status": "not_applicable", "value": null, "unit": "LUFS", "reason": "Requires at least 0.4 seconds"}
  }
}
```

实际 B 时长 0.539002 秒、sample peak -0.955889 dBFS、RMS -14.883515 dBFS、集成响度 -13.300539 LUFS。
两者源音频不同，A 的短时长没有被伪造为有效 LUFS。包络输出为有限 x/y 数组，图表直接绘制；图像的透明比例、主色与各类分布同样来自真实像素。

已实现的全部指标、适用条件、参数和限制集中在 [Analyzer 使用与协议说明](../../../project-source/tools/asset_analyzer/README.md#测量口径与限制)。
关键边界：sample peak 不是真峰值；crest factor 不是 LRA；集成响度至少 0.4 秒，LRA 至少 3 秒且仅验证 1/2 声道；零电平与响度门限使用明确状态；可见颜色排除 alpha=0；亮度采用明确标记的编码 sRGB luma proxy。
未实现 pitch/BPM/beat/onset/key/scale/timbre、高级视觉或审美分析，没有引入大型模型。后续只需按实际用途扩展 Adapter/metric/series；不因存在扩展点提前安装高级依赖。

## 可重复命令与验证

以下命令均使用实际测试项目。外部写入与真实引擎执行已走本机权限审批；未运行 pytest。

后端回归在维护仓库根执行，使用已存在的测试依赖 jsonschema 4.26.0 校验实际输出，生产 Analyzer 不依赖 jsonschema：

```powershell
$env:YAYA_TEST_PROJECT='D:/A_Games/Game_idle_yaya_frame_workbench_test'
& 'C:/Users/89523/anaconda3/envs/codex-python/python.exe' -B -m unittest discover -s framework/tests/project -p asset_analyzer_backend_test.py -v
```

按范围复制 `asset_analyzer_test.gd` / `analyzer_process_fixture.py` 到指定项目 `tests/features/asset_analyzer/`，capture 到 `tests/asset_analyzer_capture.gd`。
下列引擎命令在该项目根执行，Godot Windows GUI 二进制通过管道等待结束：

```powershell
$python='C:/Users/89523/anaconda3/envs/codex-python/python.exe'
$godot='E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe'
& $python -B tools/testing/run-gdunit-tests.py --godot-binary $godot --target tests/features/asset_analyzer/asset_analyzer_test.gd --continue
& $python -B tools/testing/run-gdunit-tests.py --godot-binary $godot --target tests/features/asset_workbench/asset_workbench_test.gd --continue
& $godot --path . --script res://tests/asset_analyzer_capture.gd | Out-Host
& $godot --headless --path . --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- --json --output reports/asset-analyzer/lint.json res:// | Out-Host
```

| 检查 | 实际结果/证据 |
| --- | --- |
| Python 后端 | **17/17 通过**；正常音频/图像、RGB/RGBA/全透明、静音/近静音/短音频、损坏/不支持、中文空格路径、真实缺依赖、缓存命中/强制重算/同 mtime 内容变化/参数与 Analyzer/后端/Schema 版本变化、坏缓存、partial、父进程退出清理与正常退出；`reports/asset-analyzer/backend-tests.log` |
| Godot 分析集成 | **12/12 通过**；两种真实外部调用/图表数据、缓存、Unicode 路径与文件变化、进程不存在、超时、无效/空 JSON、非零退出、输出上限、队列并发/排队和运行取消、完成回调取消另一任务、场景退出清理、缺失指标显示、规则与测量分离、分析失败后实际声音仍播放、图表单位/滚轮缩放/右键复位检查；`reports/gdunit-wrapper/run-paub453m/result.json` |
| 第一阶段行为 | **12/12 通过**；试听、明确绑定、事件 A/B、参数/主题隔离、延迟取消、实际保存与游戏消费；`reports/gdunit-wrapper/run-uwesvxds/result.json` |
| GDScript lint | **22 文件，0 Critical / 0 Warning**；`reports/asset-analyzer/lint.json`；信息级风格建议不等于行为错误 |
| 实际渲染 | 非 headless / NVIDIA RTX 4060 Vulkan，音频/图像 A/B、浅/深色、600×450 小窗及滚动到详情；`reports/asset-analyzer/capture.log`、`audio-analysis.png`、`image-analysis.png`、`analysis-dark.png`、`analysis-compact*.png`；Agent 查看截图，不代替人工接受 |
| 维护层 | `python -B -m unittest discover -s framework/tests -p test_*.py`：**38/38 通过**；实际 tools 复制映射静态核对为递归复制，源 Analyzer 目录只有 8 个源/声明/说明文件，无 runtime/cache/jobs |
| 使用手册 | 现有构建器重建通过：22 篇、33 Mermaid、474 个源链接；命令 `python -B framework/commands/build_blank_project_handbook.py --browser 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'`，使用本机已缓存 Mermaid CLI；未使用 Playwright 或把 HTML 构建当成排版人工验收 |

本轮发现并修复了 PCM 单声道布局命名、Godot JSON 错误日志、数字格式与图表主题，以及最初 stdin 监视方式的 Python 退出锁问题；最终改为 Windows 父进程句柄等待并验证清理竞态。上表只列最终通过结果，旧失败日志不作为通过依据。

## 验收闭环与未覆盖范围

用户要求的 12 项自动验收闭环由上述真实资源、后台进程、结构化结果、指标/图表、同类 A/B、缓存失效、故障隔离与第一阶段回归覆盖。
Analyzer 细节留在 Python Adapter；Godot 图表消费统一数值序列。关闭/取消只终止自己拥有的 Python 进程，没有终止系统其他 Python 或 Godot 实例。

保留的限制：这是源文件、第一流/第一帧分析；不模拟最终混音/导入/Shader/显示效果，不支持所有声道布局。分析有解码像素/样本、进程时间和输出上限；当前内存解码适合资源检查，不是任意长音乐批处理。缓存无自动淘汰，旧键可按项目需要删除。父进程退出保护明确面向 Windows；其他 OS、其他 Godot/Python 版本以及生产导出不在本轮验证范围。

第二阶段界面的人工作业体验仍待用户接受；第一阶段已有接受不自动延伸到新窗口。
本轮没有重做初始化到完整 Feature 的全流程抽样，也不以媒体分析测试宣称全部框架流程再次验证。框架默认配置仍保持未初始化；测试项目的机器配置与安装目录没有回写源材料。
