# 资源 Analyzer

Analyzer 在开发期离线分析图像与音频的源文件。Godot 导入后的尺寸和时长仍显示在工作台的资源候选列表中；Analyzer 不参与音频播放、事件绑定或 Cue 保存。

## 准备与使用

使用项目 `docs/methodology-config.json` 中的 `python_executable`。已在 Windows 11 x64、Python 3.12 与 Godot 4.7.1 上验证；项目环境检查接受 Godot 4.7.x，其他 Python 或 Godot 版本需另行验证。依赖只在需要分析的项目中安装，创建项目时不会自动安装。

在项目根目录执行：

```powershell
$config = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
& $config.python_executable -B -m pip install --only-binary=:all: --target 'reports/asset-analyzer/runtime' -r 'asset_workbench/analyzer/requirements.txt'
$LASTEXITCODE
```

- 安装到新目录时使用锁定的 Windows wheel，不需要 WSL、FFmpeg CLI 或本地编译。
- 这条命令不会升级已有的 Python 环境；分析运行时不联网。
- 不要在已有依赖目录中混装版本。升级时关闭工作台，移走旧的 `runtime`，按新的锁定文件安装并回归。

单项分析的操作：

1. 在工作台的资源候选列表中选中资源，点击“分析候选源文件”。不必等分析完成就可以预览。
2. 在非模态的“源资源分析”窗口中点“候选 → 分析 A”。回到资源候选列表选择另一资源，再打开分析窗口并点 B。候选和两侧的分析来源分别显示，换候选不会重命名旧结果。
3. 窗口先显示核心测量与问题摘要，再显示完整指标、图表及折叠详情。图中分析 A 为蓝色，B 为橙色。音频包络的横轴为秒，纵轴为线性满幅幅度，不是 dB 或播放后音量。滚轮缩放图表并保持鼠标下的数据点，右键复位；接近数据边界时限制可视区。详细路径与结果可打开复制。
4. 换成另一类型的资源时，会清除另一类型的比较位。分析 A/B 与事件试调的 A/B 相互独立，不会误改游戏配置。
5. 在“分析条件与判定规则”中修改静音阈值后，旧结果标记为 STALE。Schema、资源类型、Analyzer 或后端版本、参数不一致时，停止叠加 B 并说明原因；单位或图表种类不同也会提示。“按当前条件重分析 A/B”用当前参数重算两侧，旧值保留供检查。
6. “重分析 A/B”以当前静音阈值绕过缓存。“取消分析”或关闭窗口会取消其任务，预览、试听和保存仍可使用。失败、部分结果、取消、不支持、缺失字段和依赖缺失都按实际结果状态显示，不补 0。

分析结果中的 `cache.hit` 和界面上的 HIT/MISS 表示是否复用了缓存。复用缓存仍需要启动后台进程、核对版本和计算文件哈希，不等于零耗时。

## 分组批量分析与一致性检查

1. 使用“候选更多 → 将筛选结果加入批量分析”，或“分析当前对象源资源 / 分析场景源资源”。后两者只收集当前方案中的图像和音频，跳过空项，不分析 Shader。集合保留原有成员，重复路径只加入一次，不会隐式修改事件。
2. “集合与结果更多 → 添加源文件夹”选择项目内的目录，分帧扫描其中的 PNG、JPEG、WebP、BMP、TGA、TIFF、WAV、OGG、MP3 和 FLAC 文件。扫描跳过隐藏项、链接以及 `addons`、`reports` 子目录，最多扫描 50,000 条目录项、512 个资源；达到上限时保留已发现的内容并提示缩小范围。
3. “分析集合源文件”与单项分析共用队列、超时及缓存；菜单中的“强制重分析集合”绕过缓存。关闭或取消只取消本窗口的任务，已完成的结果保留，单项分析及预览继续工作。
4. 成员表显示源文件、类型、状态、缓存及问题摘要。选中成员后先看警告和依据，再按需展开统计或规则；完整路径可从集合菜单查看复制。按住 Ctrl 选中两项同类结果，点“分析对比 A/B（选中两项）”，会复用原窗口和图表，不重复分析。
5. 同类统计显示有效样本数、最小值、中位数和最大值。类型、单位、Schema、Analyzer 或后端版本、分析参数不同的结果分开统计，表格第一列的 tooltip 保留版本与参数。不可用、缺失和失败的值不进入统计，也不当作零或规则通过。
6. 分析后，从指标下拉框添加 `Minimum`、`Maximum` 或 `Max distance from median` 规则，阈值使用该指标的原单位。中位数偏差需要至少 3 个可比测量，否则显示 unmeasured。规则直接用现有数据检查，不改变底层算法或素材；最多 64 条。
7. 集合菜单的“保存集合与规则”把分组保存为项目内的 `.json`；“加载集合（替换当前集合）”读取并验证后替换当前分组及结果。示例见 `asset_workbench/examples/example_analysis_group.json`。`parameters` 沿用后端的参数协议，可设置静音阈值等，重分析后生效。
8. “保存分析结果快照”写入 `reports/asset-analyzer/history/batch-*.json`；“打开历史快照”标记 HISTORICAL 与原保存时间，不代表当前文件。重分析会检查内容哈希；导出的资源身份使用项目相对路径。分组与快照共用 32 MiB 上限（含 UTF-8 编码及格式化开销）；超限时保留已有文件和当前结果，可缩小分组后重试。

分组是轻量 JSON，不另建数据库或业务资产关系：

- 分组使用 `group_version: 1`，包含 `name`、`assets`（path 与 type）、`parameters` 和 `rules`。
- 规则包含 `type`、`metric`、`unit`、`operator`（min、max 或 delta）和 `value`。
- 快照使用 `snapshot_version: 1`，保存 group、results 与 created_at；单项结果仍使用 Analyzer Schema v1。

例如，“UI 音效 RMS 不高于 -12 dBFS”可写成：

```json
{"type":"audio","metric":"rms","unit":"dBFS","operator":"max","value":-12}
```

这是项目自己选择的阈值，不是通用的推荐响度。图像可比较饱和度、透明比例、luma 等；这类数值偏差不等于审美错误或风格不一致。没有聚类、语义风格推断、跨历史趋势图或综合评分。

## 测量口径与限制

| 类别 | 实现与适用范围 |
| --- | --- |
| 音频基础 | 第一个音频流的格式、codec、解码时长、采样率、声道和布局；只有已识别的 PCM codec 报告源位深，压缩或精度未知的格式不以解码浮点位深冒充 |
| 电平 | 原始解码样本的 sample peak、RMS、crest factor（peak/RMS，dB）；包络每段取绝对峰值或 RMS，默认 256 点，所有声道参与 |
| 响度 | pyloudnorm BS.1770-4 集成响度：1 或 2 声道，至少 0.4 秒；LRA 至少 3 秒，采用后端的 TECH 3342 实现及其 1.5 秒尾部补零；更多声道暂不支持权重映射 |
| 静音 | 所有声道的样本幅度都低于阈值、连续不少于最短时长的区间，返回起止、持续时长及首尾静音；不是语音活动检测 |
| 图像 | 第一帧的源像素尺寸、模式与 Alpha，透明、不透明、半透明比例，Alpha 摘要与分布 |
| 颜色 | 排除 alpha=0 的像素，其余等权；RGB 均值与直方图、HSV 饱和度及分布按全图分块累计。不超过 262,144 像素的图像提供精确色数和频率；更大的图按固定步长采样代表色与调色板，并报告样本数、单位与警告，精确色数为 unsupported |
| 亮度与对比 | 编码 sRGB 通道加权的 luma 及其标准差与直方图，明确标为 proxy；不做 ICC、EXIF 旋转、线性光校准，也不模拟 Godot 导入、Shader 或显示变换 |

- 零样本的电平是负无穷，在有限 JSON 中以 not_applicable 加原因表示；被响度门限排除的信号同样不伪造 LUFS 或 LRA。
- 真峰值、pitch、tempo 明确为 unsupported；节拍、基频、调性、音阶、音色、轮廓、光照与审美分析均未实现。
- `Allowed edge silence` 是 Godot 侧独立的项目规则，初始 0.05 秒。它不改变测量，也不改写源文件。修改静音阈值后需要重新分析；修改规则阈值则直接用现有结果检查。没有无解释的综合分数。

参数与上限：

- 算法参数集中在 `capabilities.json`：`silence_dbfs=-50`、`silence_min_seconds=0.05`、`series_points=256`、`palette_size=8`。
- 音频上限 8,000,000 个声道样本，图像上限 8,000,000 像素；任务可以调低，但不能超过硬上限。
- 音频电平和静音流式累计，再解码一遍生成定长包络。最多保留 4,096 段静音区间，超出后区间指标为 unsupported，首尾静音仍保留。响度单独限 2,000,000 个声道样本，超出时响度为 unsupported，其余基础指标照常返回。
- 图像按 256×256 分块处理，调色板最多采样 262,144 个源像素，不保留全图浮点 RGB 副本。

内存预算：

- 每个图像进程预留并硬限 256 MiB，每个音频进程 384 MiB，队列默认总预留 512 MiB。因此可以同时运行两个图像任务，音频任务串行；数量设置不会绕过预算。
- Windows Job 限制的是进程提交内存，不是所有共享页的工作集总和。`execution` 记录实测的 `peak_commit_bytes` 与 `peak_working_set_bytes`。
- 分配超限或原生后端异常退出时返回结构化失败；预算设置失败则不执行分析。临时目录和解释器都使用 Windows 原生路径。

支持的源格式：

- 支持的扩展名在同一能力文件中声明：PNG、JPEG、WebP、BMP、TGA、TIFF、WAV、OGG、MP3、FLAC。不能仅凭扩展名保证具体编码可以解码。
- 内嵌资源、AtlasTexture、`.tres` 与 `.res` 只显示“仅支持源文件分析”，不会偷偷导出替代素材。
- 错误分为 `source_not_file`、`unsupported_format`（含后端缺少解码能力）、`corrupt_file`（后端识别出损坏输入）和 `decode_failed`（其他解码异常）。

## 缓存与运行目录

`reports/asset-analyzer/` 已被项目忽略，Godot 不导入其中的 wheel 和缓存：

- `runtime/`：可重新安装的本项目依赖，不随项目复制，也不进入正式游戏导出。
- `cache/<key>.json`：可检查、可删除。键包含规范路径、源内容 SHA-256、参数、Analyzer 类型与版本、全部后端版本和 Schema 版本。读取时先按共同 Schema 校验，再比对 asset、analyzer、parameters 与本次完整身份。缺字段、类型错误、语义不一致或超过 2 MiB 的缓存会被忽略并重算，成功后原子替换；失败或部分失败的结果不缓存。
- `jobs/`：请求与写缓存的短期文件。完成、取消、超时和工作台退出时都清理自己的文件；worker 检测父进程退出，避免引擎异常退出后留下计算进程。
- `history/`：用户显式保存的批量分析快照。不会自动淘汰，也不代表资源当前仍是相同内容；需要长期版本管理时由项目选择归档位置。

强制重分析会覆盖当前缓存；关闭工作台后可以删除整个 `cache` 目录，让其重新生成。旧内容的缓存键不会自动淘汰，按项目需要定期清理；不建立数据库。

## 故障处理

- 缺少解释器或依赖、无法解码、超限、超时、异常退出、空输出和协议损坏，都显示为结构化错误，不关闭工作台。
- 文件在分析过程中改变时，拒绝写缓存并要求重试。
- Godot 侧的能力配置与结果 Schema 在首次需要时加载，成功后在进程内复用。文件缺失、JSON 损坏或必需结构无效时返回 `analyzer_config` 并指出文件，预览与播放仍可继续。加载失败不缓存，恢复正确文件后可以重试；加载成功后再修改契约，需要重启工作台进程，不提供自动热重载。
- Analyzer 只在开发环境运行，正式导出排除 `asset_workbench/analyzer/` 与工作台；音频播放与正式组件没有 Python 依赖。

## 结构与协议

| 位置 | 职责 |
| --- | --- |
| `../ui/analysis_service.gd`、`analysis_job.gd` | 队列同时受数量和 512 MiB 预留预算约束，默认最多 2 个进程（数量可设 1–4）；30 秒超时、取消、非阻塞管道、退出码与输出上限，以及进程和临时文件清理 |
| `worker.py` | 每次请求一个独立进程，分派适配器、核对版本、SHA-256 缓存；只读等待 Windows 父进程句柄，父进程退出时终止，不创建子进程 |
| `audio_adapter.py`、`image_adapter.py` | 唯一依赖具体分析库的算法适配器 |
| `result.schema.json`、`schema_validation.py`、`../ui/analysis_schema.gd` | Schema v1 是唯一的字段契约，两端读取同一文件；共同的变异夹具检验必需字段、类型、状态、单位、诊断与序列长度 |
| `capabilities.json`、`source_probe.py`、`../ui/analysis_source.gd` | 源格式、参数、上限和预算共用这份配置；两端都预检普通源文件 |
| `memory_budget.py`、`audio_statistics.py` | Windows worker 的提交内存硬限制与实测高水位，流式电平与静音累计；不限制 Godot 进程 |
| `../ui/analysis_result.gd` | 结果验证、并排比较格式、独立的项目规则检查 |
| `../ui/analysis_panel.gd`、`analysis_chart.gd` | 由资源候选列表打开的分析窗口，以及通用数字序列图；不识别第三方输出 |
| `../ui/analysis_batch.gd`、`analysis_group_scan.gd` | 共用队列的批量任务与有界目录扫描；只管理自己的任务 |
| `../ui/analysis_group.gd`、`analysis_group_statistics.gd` | 分组与历史结构的校验和读写、可比样本统计、带解释的规则检查 |
| `../ui/analysis_batch_panel.gd`、`analysis_group_rules.gd` | 分组结果、批量入口与独立的规则编辑；把两项结果交回已有的 A/B 窗口 |

请求与输出：

- 输入为 JSON 文件，包含 `path`、`asset_type`（`audio` 或 `image`）、`parameters` 与 `force`。
- 内部 worker 通过参数数组启动，不经过 shell。stdout 输出一份 UTF-8 JSON，上限 2 MiB；stderr 只用于诊断。
- 结果包含 `schema_version`、`status`、`asset`、`analyzer`、`metrics`、`series`、`warnings`、`errors` 和 `cache`。`analyzer.backend` 是后端名称到具体版本的映射（含 FFmpeg 库版本），承担 backend_version 的含义，便于组合多个库。协议不直接暴露后端的私有输出。

指标与序列条目示例：

```json
{"status":"available","value":-6.02,"unit":"dBFS","reason":""}
{"status":"not_applicable","value":null,"unit":"LUFS","reason":"Requires at least 0.4 seconds"}
{"status":"available","kind":"line","x":[0.0,0.1],"y":[0.0,0.5],"x_unit":"s","y_unit":"linear full scale"}
```

依次为单值条目、不可用条目和序列条目。序列 `kind` 为 `line` 时绘制折线；为 `histogram` 时用数值 x/y 绘制柱形分布，x 为分箱中心。

状态：

- 任务终态为 success、partial、failed 或 cancelled；queued 与 running 由 Godot 信号提供。
- 每个指标区分 available、not_applicable、unsupported 和 failed，未返回的字段显示为 missing。unsupported 不等于任务失败；个别本应可算的指标失败时，整体为 partial，其余结果保留。
- 错误以 code 与 message 表示，不把终端文本当作界面数据接口。

运行时校验器只解释当前 Schema 用到的词汇，不是通用的 JSON Schema 引擎。`x-equal-lengths` 约束 x 与 y 等长，并递归拒绝 NaN 与 Infinity；标准 JSON 本身不允许非有限数。Analyzer 版本为 2；算法版本变化后，旧缓存自然失效。

## 扩展

- **新增指标**：优先在对应 Adapter 返回新的 metrics 或 series，现有的表和图会自动显示。高级指标必须先定义适用类别、有效性与实际筛选用途。
- **新增后端**：从 worker 分派，保持 v1 的字段与单位；改变算法时升级 `ANALYZER_VERSION`。
- **新增校验词汇**：同时补充两端的支持和共同夹具。
- **协议不兼容的变更**：同步修改 Schema、两端验证和测试。

依赖版本与许可证见 [DEPENDENCIES.md](DEPENDENCIES.md)。
