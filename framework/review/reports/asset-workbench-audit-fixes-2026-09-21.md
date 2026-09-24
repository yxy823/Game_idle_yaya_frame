# 工作台审核修复、入口拆分与默认尺寸验证

日期：2026-09-21。用户报告审核的是 `22517e17ecf9cadafca2d5466d1a986a8244b116`； 本轮修改前核对的实际代码为 `f7f598e`，第三阶段基础能力已存在。报告的四个主要问题在当前实现仍成立。 本轮修复这些问题并保留已有第三阶段，未重做资源浏览、Cue 保存、FeedbackPresenter 或 SoundManager。

## 已实施的用户要求

- `project-source/defaults/project.godot` 明确默认视口 1600×900；创建器原样复制。单对象/组合主窗口继承它，分析与批量窗口默认同为 1600×900。删除按屏幕 90% 缩小和 Fit 按钮；显式命令行覆盖、窗口缩放与编辑器宿主约束仍属 Godot 行为。
- `examples/asset_workbench/single/` 保存单对象工作台、消费场景、脚本和 Cue；`composition/` 保存组合工作台、真实组合场景和三个 Cue。两个目录各有 `example-workbench.tscn`，按 F6 独立运行，不互相打开/返回。
- 组合工作台在自身中央选择真实对象，右侧直接编辑选中对象，复用候选、参数、A/B、分析、保存与播放；素材继续共享原文件且不染色。
- UI 布局讨论复用现有“Godot 项目开发 → 需求设计 → 设计界面与交互”及 `design-ui-spec`。现有规范已包含线框、信息层级、交互状态、显示条件和 Godot 原型问题，无需新建 Prompt/Skill。操作衔接见 [工作台说明](../../docs/blank-project/guides/asset-workbench.md#先讨论按钮与布局)。

## 审核问题与实际修复

| 问题 | 当前实现与边界 |
| --- | --- |
| P1 峰值内存 | 图像改为 256×256 分块统计，浮点中间值按块分配；最多 262,144 源像素参与调色板，较大图的精确色数为 unsupported。音频电平/静音流式累计，包络第二遍解码，响度单独限 2,000,000 声道样本。输入上限均降为 8,000,000（图像像素/音频声道样本）。 |
| P1 并发预算 | 数量上限之外按任务类型预留内存：图像 256 MiB、音频 384 MiB、队列默认总预算 512 MiB。两个图像可并行；两个音频或音频加图像串行。worker 自身加入 Windows Job，限制提交内存，失败时返回结构化错误；不限制 Godot 主进程。 |
| P1 A/B 条件 | 比较 Schema、资源类型、Analyzer id/version、完整后端版本映射和参数。参数相对当前设置改变时标记 STALE；不兼容原因显示在表格/图表上方，停止 B 叠加。提供当前设置重算两侧；版本不一致明确报告，不能凭不同版本猜测哪份结果更新。 |
| P2 协议/缓存 | JSON Schema 是字段契约的唯一正文，Python/Godot 都读取它；两个小型解释器只实现本 Schema 使用的词汇。共享 32 项变异夹具与非有限数检查；标准 JSON Schema 测试另扩展 x/y 等长约束。缓存再核对 asset、analyzer、parameters 与完整身份；语义损坏/超限缓存忽略并重算，成功后原子替换。 |
| P2 源能力 | 两端读取 capabilities.json 预检普通文件、类型和声明扩展名；Godot 额外拒绝内嵌/AtlasTexture 间接资源。区分 source_not_file、unsupported_format、corrupt_file、decode_failed；合法 SVG 为明确不支持，损坏 PNG/音频为解码相关错误。不会临时导出伪装源资源。 |
| P3 图表 | 单位/种类不兼容时明确说明 B 为何隐藏；histogram 按柱形绘制，line 保持折线；缩放保持鼠标下的数据位置，边界仍限制可视范围。 |

内存限制依据 [Windows Job Objects](https://learn.microsoft.com/en-us/windows/win32/procthread/job-objects) 和 [扩展限制结构](https://learn.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-jobobject_extended_limit_information)。 提交内存限额不等于包含共享映射的总工作集；实测分别报告二者，不能据此保证任意素材、机器的工作集完全相同。 大资源超出响度预算时只降级相关指标，基础电平/静音/包络继续返回；不把近似色数或近似响度冒充精确测量。

## 实现位置

以下相对 `project-source/`，通过既有递归复制映射分发：

| 文件 | 责任 |
| --- | --- |
| `tools/asset_analyzer/capabilities.json` | 支持源格式、参数与硬上限、单任务和总内存预算 |
| `source_probe.py`、`memory_budget.py`（同目录） | 外部源预检/解码错误分类、Windows 限制和内存高水位 |
| `audio_statistics.py`、`audio_adapter.py`、`image_adapter.py`（同目录） | 流式累计、音频/图像后端适配及有界统计 |
| `result.schema.json`、`schema_validation.py`、`protocol.py`、`worker.py`（同目录） | Schema v1、Analyzer v2、共享契约检查、语义缓存恢复 |
| `tools/asset_workbench/analysis_schema.gd`、`analysis_source.gd` | Godot 协议解释和源文件能力预检 |
| `analysis_service.gd`、`analysis_result.gd`、`analysis_panel.gd`、`analysis_chart.gd`（同目录） | 预算调度、比较条件、过期提示/重算、图表 |
| `workbench.gd`、`composition_workbench.gd`、`composition_panel.gd`（同目录） | 共用单对象交互与独立组合入口；组合直接控制被选对象的真实 Presenter |

Godot 本地进程失败沿用已有错误结果；它不伪称已经得到外部后端版本。 缓存新增算法版本 2，Schema 仍为 1，底层依赖没有升级或新增： PyAV 18.1.0、Pillow 12.3.0、NumPy 2.5.3、pyloudnorm 0.2.0、SciPy 1.18.1。 许可证与 Windows wheel 边界继续见 [依赖记录](../../../project-source/tools/asset_analyzer/DEPENDENCIES.md)。 Windows Job 使用 Python 标准库 ctypes；JSON Schema 库只用于测试，不成为 Godot 项目的运行依赖。

## 本轮实际验证

测试载体仍为用户指定的 `D:/A_Games/Game_idle_yaya_frame_workbench_test`， Godot 4.7.1.stable.official.a13da4feb、Windows 11、CPython 3.12.13。 同步了本轮代码、测试及已移动的场景引用；测试项目 Cue 原值随文件移动保留，未覆盖其试调结果或机器配置。 测试项目仅增加 display 尺寸并修正已移动的 main_scene 路径；框架默认环境仍为 incomplete、无主场景。

| 检查 | 本轮结果；证据路径相对测试项目 |
| --- | --- |
| Python 后端 | 22/22 unittest；含原 17 项及语义缓存变异、合法不支持源、响度预算、大图采样、共同 Schema 变异 |
| Godot Analyzer | 18/18；`reports/gdunit-wrapper/run-p80ra4k3/result.json`；含进程故障、缓存、Schema 共同夹具、参数/版本/后端差异、STALE/重算、源预检、预算并发和鼠标缩放 |
| 单对象首期回归 | 12/12；`run-glnmkowk/result.json`（同上级）；试听、预览、试调、停止、主题及保存/真实消费 |
| 组合入口 | 7/7；`run-zg0skux1/result.json`；独立入口、对象选择/各自 A/B、批量音量、共享分析、保存冲突、真实播放、切换后连续触发 |
| 第三阶段分组 | 12/12；`run-kla5g9je/result.json`；新源路径/协议下真实分组、缓存、比较、规则、历史及失败隔离 |
| 内存边界 | 下表；`reports/asset-analyzer/memory-check.json`；另验证 64 MiB 子进程限额拒绝 128 MiB 分配 |
| lint | 37 文件，0 Critical / 0 Warning；`reports/asset-analyzer/audit-lint.json` |
| 维护/复制 | 38/38 unittest；实际复制到临时目录，验证 1600×900、两目录入口、无旧混合入口，以及 incomplete/无主场景边界 |
| 真实渲染 | 两入口、分析/批量浅深色、STALE、柱形图、小窗滚动；两个 capture 退出 0，Agent 已看图。主窗口/项目设置都为 1600×900，见 `reports/asset-analysis-group/window-state.json` |
| 离线手册 | 现有生成器构建通过，22 篇文档、33 张 Mermaid、476 个源链接；未使用 Playwright，未将构建写为人工排版验收 |

最初回归发现测试局部变量遮蔽、组合入口未挂接播放器节点、Schema/UI 函数复杂度，以及压力夹具并发清理同一缓存的问题；均修正并重跑受影响检查。失败记录不作为通过证据。

内存压力素材由测试程序生成，不引入未知许可媒体。单次实测值如下（MiB，四舍五入）：

| 资源 | 峰值工作集 | 峰值提交内存 | 时间 |
| --- | --- | --- | --- |
| 4000×2000 RGBA，800 万像素 | 75.8 | 97.1 | 1.09 s |
| 双声道 WAV，800 万声道样本 | 121.7 | 101.4 | 0.92 s |
| 响度预算边界，200 万声道样本 | 170.2 | 148.7 | 1.03 s |
| 两个大图同时运行，各进程峰值相加 | 150.6 | 193.3 | 各约 1.10 s |

并发一行是两个进程各自高水位之和，不是假装同步采样的整机峰值。音频大任务串行由 Godot 集成测试验证。 低采样率极长时间信号、高压缩比/特殊编码和所有第三方原生异常没有穷尽测试；它们仍受输入上限、进程内存限额、超时及错误隔离约束。

## 复跑命令

框架根目录：

```powershell
$python = 'C:/Users/89523/anaconda3/envs/codex-python/python.exe'
$env:YAYA_TEST_PROJECT = 'D:/A_Games/Game_idle_yaya_frame_workbench_test'
& $python -B -m unittest discover -s framework/tests/project -p asset_analyzer_backend_test.py -v
& $python -B framework/tests/project/asset_analyzer_memory_check.py
& $python -B -m unittest discover -s framework/tests -p test_*.py
```

引擎夹具来自 `framework/tests/project/`，suite 放入测试项目对应 `tests/features/<suite>/`； 协议 corpus 与进程 fixture 放入 `tests/features/asset_analyzer/`，capture 放入 `tests/`。 先按本次范围同步源代码、保留机器配置和 Cue，再在测试项目根运行：

```powershell
$godot = 'E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe'
$python = 'C:/Users/89523/anaconda3/envs/codex-python/python.exe'
foreach ($suite in @('asset_analyzer','asset_workbench','asset_composition','asset_analysis_group')) {
  & $python -B tools/testing/run-gdunit-tests.py --godot-binary $godot --target ('tests/features/'+$suite+'/'+$suite+'_test.gd') --continue
}
& $godot --path . --script res://tests/asset_analysis_group_capture.gd | Out-Host
& $godot --path . --script res://tests/asset_analyzer_capture.gd | Out-Host
& $godot --headless --path . --script res://addons/gdscript-linter/analyzer/analyze-cli.gd -- --json --output reports/asset-analyzer/audit-lint.json res:// | Out-Host
```

GUI 引擎使用管道等待退出，核对日志与实际退出状态；不能只启动进程就写成检查通过。

## 仍需人工体验的内容

用户尚未验收第二/第三阶段的按钮分组、组合交互与实际听感。本轮自动/渲染检查不替代人工接受。 可按 UI 设计入口继续讨论布局，不把示例布局或本报告当成正式游戏规范。 高级音乐/视觉分析、运行时自然语言场景生成、任意节点属性编辑仍未实现。 原图、声音、SoundManager 插件、首期表现与保存组件均未改变；没有新增生产 Autoload 或外部服务。 本轮未重跑完整需求到 Feature 收尾流程，也未重做第二路径完整引擎初始化；其验证缺口继续保留在框架进度。
