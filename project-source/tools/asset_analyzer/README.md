# 资源 Analyzer

这是开发期、离线、源文件分析能力。Godot 的导入尺寸/时长仍在浏览器显示；本工具不参与音频播放、事件绑定或 Cue 保存。

## 准备与使用

使用已初始化项目 `docs/methodology-config.json` 中的 `python_executable`。支持 Windows 11 x64、Python 3.12 与 Godot 4.7.1；其他 Python/Godot 版本需另行验证。依赖只在需要分析的项目中安装，创建器不自动安装。

在实际项目根目录执行：

```powershell
$config = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
& $config.python_executable -B -m pip install --only-binary=:all: --target 'reports/asset-analyzer/runtime' -r 'tools/asset_analyzer/requirements.txt'
$LASTEXITCODE
```

新目录安装使用锁定的 Windows wheel，不需要 WSL、FFmpeg CLI 或本地编译。不要在已有依赖目录混装版本；升级时关闭工作台，移走旧 `runtime`，按新锁定文件安装并回归。现有 Python 环境不会被此命令升级。运行不联网。

1. 在现有工作台浏览器选中资源，点击 `Analyze selected source`。
2. 非模态分析窗口中点 `Analyze selection as A`。返回同一个浏览器选另一个资源，再打开分析窗口并点 B。
3. 表格并排显示同类型测量与不可用原因；下拉选择数据序列。图中蓝色 A、橙色 B，共用坐标及单位；滚轮缩放 X、右键复位，悬停显示 X 坐标。长值有完整 tooltip，整个窗口和指标表可滚动。
4. 换成不同类型资源会清除另一类型的比较位。分析 A/B 与事件试调 A/B 分开，不会误改游戏配置。
5. `Reanalyze A/B` 以当前静音阈值绕过缓存。`Cancel tasks` 或关闭分析窗口会取消其任务；返回主工作台仍可预览、试听、保存。

分析结果中的 `cache.hit` 和界面 HIT/MISS 表示是否复用。缓存仍需要后台进程启动、版本检查和文件哈希，不等于零耗时。

## 结构与协议

| 位置 | 责任 |
| --- | --- |
| `../asset_workbench/analysis_service.gd`、`analysis_job.gd` | 队列，默认同时 2 个进程（可设 1–4）、30 秒超时、取消、非阻塞管道、退出码/输出上限、进程与临时文件清理 |
| `worker.py` | 一次请求一个独立进程，分派适配器、版本核对、SHA-256 缓存；只读等待 Windows 父进程句柄，父进程退出时终止，不创建子进程 |
| `audio_adapter.py`、`image_adapter.py` | 唯一依赖具体分析库的算法适配器 |
| `protocol.py`、`result.schema.json` | Schema v1、测量状态、公共数据契约；Python 与 Godot 两端进行边界检查 |
| `../asset_workbench/analysis_result.gd` | 结果验证、并排比较格式、独立的项目规则检查 |
| `../asset_workbench/analysis_panel.gd`、`analysis_chart.gd` | 共用浏览器选择的分析窗口与通用数字序列图；不识别第三方输出 |

输入为 JSON 文件，含 `path`、`asset_type` (`audio` / `image`)、`parameters` 与 `force`。内部 worker 通过参数数组启动，不经过 shell；stdout 为一份 UTF-8 JSON，stderr 只用于诊断。输出上限 2 MiB。

结果包含 `schema_version`、`status`、`asset`、`analyzer`、`metrics`、`series`、`warnings`、`errors`、`cache`。`analyzer.backend` 是后端名称到具体版本的映射（含 FFmpeg 库版本），承担 backend_version 语义，便于组合多个库。协议不会直接暴露其私有输出。

单值条目：`{"status":"available","value":-6.02,"unit":"dBFS","reason":""}`。
不可用条目：`{"status":"not_applicable","value":null,"unit":"LUFS","reason":"Requires at least 0.4 seconds"}`。
序列条目：`{"status":"available","kind":"line","x":[0.0,0.1],"y":[0.0,0.5],"x_unit":"s","y_unit":"linear full scale"}`。`histogram` 同样使用数值 x/y，当前图表绘制分布折线。

任务终态为 success / partial / failed / cancelled；queued / running 由 Godot 信号提供。每个指标区分 available、not_applicable、unsupported、failed，未返回的字段显示 missing。unsupported 不等于任务执行失败；个别本应可算的指标失败使整体 partial，其余结果保留。错误是 code/message，不使用终端文本作为 UI 数据接口。

## 测量口径与限制

| 类别 | 实现与适用范围 |
| --- | --- |
| 音频基础 | 第一个音频流，格式、codec、解码时长、采样率、声道和布局；仅已识别 PCM codec 报源位深，压缩/未知精度不冒充解码浮点位深 |
| 电平 | 原始解码样本的 sample peak、RMS、crest factor（peak/RMS dB）；包络每段取绝对峰值/RMS，默认 256 点，所有声道参与 |
| 响度 | pyloudnorm BS.1770-4 集成响度：1/2 声道、至少 0.4 秒；LRA 至少 3 秒，采用后端 TECH 3342 实现及其 1.5 秒尾部补零；更多声道暂不支持权重映射 |
| 静音 | 所有声道的样本幅度均低于阈值，连续不少于最短时长，返回起止/持续/首尾静音；不是语音活动检测 |
| 图像 | 第一帧、源像素尺寸/模式/Alpha，透明/不透明/半透明比例、Alpha 摘要与分布 |
| 颜色 | 排除 alpha=0，其余像素等权，精确可见 RGB 色数、最高频代表色、RGB 均值/直方图、HSV 饱和度及分布；不是感知聚类 |
| 亮度与对比 | 编码 sRGB 通道加权 luma 与标准差/直方图，明确为 proxy；不进行 ICC、EXIF 旋转、线性光校准、Godot 导入/Shader/显示变换 |

零样本电平是负无穷，有限 JSON 中以 not_applicable + 原因表示；被响度门限排除的信号同样不伪造 LUFS/LRA。真峰值、pitch、tempo 明确 unsupported；节拍、基频、调性、音阶、音色、轮廓/光照/审美分析均未实现。

算法参数在 `worker.DEFAULTS` / `LIMITS` 定义：silence_dbfs=-50、silence_min_seconds=0.05、series_points=256、palette_size=8；解码上限 30,000,000 个声道样本，图像上限 16,000,000 像素。大资源会明确失败；这不是全量长音乐离线分析器。超时可由 `AnalysisService.timeout_seconds` 调整，不能以阻塞主线程替代。

`Allowed edge silence` 是 Godot 侧独立项目规则，初始 0.05 秒；不改变测量、不参与源文件改写。静音阈值改变后需重新提交/重分析，规则阈值改变则直接用现有结果检查。没有无解释综合分数。

## 缓存、故障与迁移

`reports/asset-analyzer/` 已被项目忽略，Godot 不导入其中 wheel 和缓存：

- `runtime/`：可重新安装的本项目依赖，不随框架复制或正式游戏导出。
- `cache/<key>.json`：可检查、可删除；键包含规范路径、源内容 SHA-256、参数、Analyzer 类型/版本、全部后端版本、Schema 版本。成功结果原子写入；失败/部分失败不缓存，损坏缓存重新分析。
- `jobs/`：请求与写缓存的短期文件。完成、取消、超时、工作台退出都清理自有文件；worker 检测父进程退出，避免引擎异常退出后遗留计算进程。

强制重分析可覆盖当前缓存；关闭工作台后可删除 `cache` 目录全部重新生成。旧内容键不会自动淘汰，定期按项目需要清理；不建立数据库。

缺少解释器、依赖、无法解码、超限、超时、异常退出、空输出、损坏协议均显示结构化错误，不关闭工作台。文件在分析过程中改变时拒绝缓存并要求重试。仅开发环境运行，正式导出排除 `tools/asset_analyzer/` 与工作台；音频播放与正式组件没有 Python 依赖。

增加指标优先在对应 Adapter 返回新的 metrics/series，现有表和图自动消费；新增后端从 worker 分派，保持 v1 字段/单位，改变算法时升级 ANALYZER_VERSION。协议不兼容变更需同步 Schema、两端验证和测试。高级指标必须先定义适用类别、有效性与实际筛选用途。

依赖版本与许可证见 [DEPENDENCIES.md](DEPENDENCIES.md)。
