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

1. 在工作台“资源候选”选中资源，点击“分析候选源文件”。无需完成分析就可预览。
2. 非模态“源资源分析”窗口中点“候选 → 分析 A”。返回同一浏览器选择另一资源，再打开分析窗口并点 B。候选和两侧分析来源分别显示，换候选不会重命名旧结果。
3. 核心测量与问题摘要在前，完整指标、图表及折叠详情在后。图中分析 A 为蓝色、B 为橙色；音频包络的横轴为秒，纵轴为线性满幅幅度，不是 dB 或播放后音量。滚轮缩放、右键复位；详细路径与结果可打开复制。
4. 换成不同类型资源会清除另一类型的比较位。分析 A/B 与事件试调 A/B 分开，不会误改游戏配置。
5. 在“分析条件与判定规则”改静音阈值后，旧结果标记 STALE；Schema、资源类型、Analyzer/后端版本或参数不一致时停止 B 叠加并说明原因。“按当前条件重分析 A/B”用当前参数重算两侧；单位或图表种类不同也会提示。旧值保留供检查。
6. “重分析 A/B”以当前静音阈值绕过缓存。“取消分析”或关闭窗口取消其任务；预览、试听、保存仍可使用。失败、部分结果、取消、不支持、缺失字段和依赖缺失沿用实际结果状态，不补 0。

分析结果中的 `cache.hit` 和界面 HIT/MISS 表示是否复用。缓存仍需要后台进程启动、版本检查和文件哈希，不等于零耗时。

## 分组批量分析与一致性检查

1. 使用“候选更多 → 将筛选结果加入批量分析”，或使用“分析当前对象源资源 / 分析场景源资源”。后两者只收集当前方案中的图像/音频并跳过空项，不分析 Shader。集合保留此前成员，重复路径只加入一次，不隐式修改事件。
2. “集合与结果更多 → 添加源文件夹”选择项目内目录，逐帧发现 PNG/JPEG/WebP/BMP/TGA/TIFF、WAV/OGG/MP3/FLAC。跳过隐藏项、链接及 addons/reports 子目录。最多扫描 50,000 条目录项、512 个资源；达到限制保留已有内容并提示缩小范围。
3. “分析集合源文件”共用单项分析的队列、超时及缓存；菜单中的“强制重分析集合”绕过缓存。关闭或取消只取消本窗口任务，已完成结果保留，单项分析及预览继续工作。
4. 成员表显示源文件、类型、状态、缓存及问题摘要；选中后先查看警告和依据，再按需展开统计或规则。完整路径可从集合菜单查看复制。Ctrl 选中两项同类结果，点“分析对比 A/B（选中两项）”复用原窗口和图表，不启动重复分析。
5. 同类统计显示有效样本数、最小值、中位数和最大值。类型、单位、Schema、Analyzer/后端版本或分析参数不同时分开统计；表格第一列 tooltip 保留版本与参数。不可用、缺失和失败值不进入统计，也不作为零或规则通过。
6. 分析后，从指标下拉框添加 `Minimum`、`Maximum` 或 `Max distance from median` 规则，阈值使用该指标原单位。中位数偏差需要至少 3 个可比测量，否则显示 unmeasured。规则立即复用现有数据检查，不改底层算法或素材；上限 64 条。
7. 集合菜单的“保存集合与规则”保存项目内 `.json`；“加载集合（替换当前集合）”读取并验证后替换分组及结果。示例见 `examples/asset_workbench/example-analysis-group.json`。`parameters` 沿用后端参数协议，可设置静音阈值等，重分析后生效。
8. “保存分析结果快照”写入 `reports/asset-analyzer/history/batch-*.json`；“打开历史快照”标记 HISTORICAL 与原时间，不代表当前文件。重分析检查内容哈希；导出身份用项目相对路径。分组与快照共用 32 MiB 上限，包含 UTF-8 编码及格式化开销；超限保留已有文件和当前结果，可缩小分组重试。

分组是轻量 JSON，不另建数据库或业务资产关系。`group_version: 1` 下包含 `name`、`assets`（path/type）、`parameters`、`rules`；规则包含 `type`、`metric`、`unit`、`operator`（min/max/delta）、`value`。快照另用 `snapshot_version: 1`，保留 group、results、created_at；单项结果继续使用 Analyzer Schema v1。

例如“UI 音效 RMS 不高于 -12 dBFS”可写成：

```json
{"type":"audio","metric":"rms","unit":"dBFS","operator":"max","value":-12}
```

这是项目选择的阈值，不是通用推荐响度。图像可比较饱和度、透明比例、luma 等；这类数值偏差不等于审美错误或风格不一致。当前没有聚类、语义风格推断、跨历史趋势图或综合评分。

## 结构与协议

| 位置 | 责任 |
| --- | --- |
| `../asset_workbench/analysis_service.gd`、`analysis_job.gd` | 队列受数量和 512 MiB 预留预算共同约束，默认最多 2 个进程（数量可设 1–4）；30 秒超时、取消、非阻塞管道、退出码/输出上限、进程与临时文件清理 |
| `worker.py` | 一次请求一个独立进程，分派适配器、版本核对、SHA-256 缓存；只读等待 Windows 父进程句柄，父进程退出时终止，不创建子进程 |
| `audio_adapter.py`、`image_adapter.py` | 唯一依赖具体分析库的算法适配器 |
| `result.schema.json`、`schema_validation.py`、`../asset_workbench/analysis_schema.gd` | Schema v1 为唯一字段契约，两端读取同一文件；共同变异夹具检验必需字段、类型、状态、单位、诊断与序列长度 |
| `capabilities.json`、`source_probe.py`、`../asset_workbench/analysis_source.gd` | 源格式、参数/上限和预算共用配置；两端预检普通源文件 |
| `memory_budget.py`、`audio_statistics.py` | Windows worker 提交内存硬限制/实测高水位、流式电平与静音累计；不限制 Godot 进程 |
| `../asset_workbench/analysis_result.gd` | 结果验证、并排比较格式、独立的项目规则检查 |
| `../asset_workbench/analysis_panel.gd`、`analysis_chart.gd` | 共用浏览器选择的分析窗口与通用数字序列图；不识别第三方输出 |
| `../asset_workbench/analysis_batch.gd`、`analysis_group_scan.gd` | 共用队列的批量任务与有界目录发现；只管理自己的任务 |
| `../asset_workbench/analysis_group.gd`、`analysis_group_statistics.gd` | 分组/历史结构校验、读写、可比样本统计与有解释的规则检查 |
| `../asset_workbench/analysis_batch_panel.gd`、`analysis_group_rules.gd` | 分组结果、批量入口与独立规则编辑；将两项结果交回现有 A/B 窗口 |

输入为 JSON 文件，含 `path`、`asset_type` (`audio` / `image`)、`parameters` 与 `force`。内部 worker 通过参数数组启动，不经过 shell；stdout 为一份 UTF-8 JSON，stderr 只用于诊断。输出上限 2 MiB。

结果包含 `schema_version`、`status`、`asset`、`analyzer`、`metrics`、`series`、`warnings`、`errors`、`cache`。`analyzer.backend` 是后端名称到具体版本的映射（含 FFmpeg 库版本），承担 backend_version 语义，便于组合多个库。协议不会直接暴露其私有输出。

单值条目：`{"status":"available","value":-6.02,"unit":"dBFS","reason":""}`。
不可用条目：`{"status":"not_applicable","value":null,"unit":"LUFS","reason":"Requires at least 0.4 seconds"}`。
序列条目：`{"status":"available","kind":"line","x":[0.0,0.1],"y":[0.0,0.5],"x_unit":"s","y_unit":"linear full scale"}`。`histogram` 使用数值 x/y 绘制柱形分布，x 为分箱中心；line 绘制折线。图表轮缩放保持鼠标下的数据点，接近数据边界时限制可视区。

运行时校验器仅解释当前 Schema 使用的词汇，并非通用 JSON Schema 引擎；新增校验词汇必须补充两端支持和共同夹具。`x-equal-lengths` 约束 x/y 等长，递归拒绝 NaN/Infinity；标准 JSON 本身不允许非有限数。分析器版本为 2；旧缓存因算法版本变化自然失效。

任务终态为 success / partial / failed / cancelled；queued / running 由 Godot 信号提供。每个指标区分 available、not_applicable、unsupported、failed，未返回的字段显示 missing。unsupported 不等于任务执行失败；个别本应可算的指标失败使整体 partial，其余结果保留。错误是 code/message，不使用终端文本作为 UI 数据接口。

## 测量口径与限制

| 类别 | 实现与适用范围 |
| --- | --- |
| 音频基础 | 第一个音频流，格式、codec、解码时长、采样率、声道和布局；仅已识别 PCM codec 报源位深，压缩/未知精度不冒充解码浮点位深 |
| 电平 | 原始解码样本的 sample peak、RMS、crest factor（peak/RMS dB）；包络每段取绝对峰值/RMS，默认 256 点，所有声道参与 |
| 响度 | pyloudnorm BS.1770-4 集成响度：1/2 声道、至少 0.4 秒；LRA 至少 3 秒，采用后端 TECH 3342 实现及其 1.5 秒尾部补零；更多声道暂不支持权重映射 |
| 静音 | 所有声道的样本幅度均低于阈值，连续不少于最短时长，返回起止/持续/首尾静音；不是语音活动检测 |
| 图像 | 第一帧、源像素尺寸/模式/Alpha，透明/不透明/半透明比例、Alpha 摘要与分布 |
| 颜色 | 排除 alpha=0，其余像素等权；RGB 均值/直方图、HSV 饱和度及分布按全图分块累计。最多 262,144 像素的图像提供精确色数和频率；更大图的代表色/调色板按固定步长采样，并报告样本数、单位与警告，精确色数为 unsupported |
| 亮度与对比 | 编码 sRGB 通道加权 luma 与标准差/直方图，明确为 proxy；不进行 ICC、EXIF 旋转、线性光校准、Godot 导入/Shader/显示变换 |

零样本电平是负无穷，有限 JSON 中以 not_applicable + 原因表示；被响度门限排除的信号同样不伪造 LUFS/LRA。真峰值、pitch、tempo 明确 unsupported；节拍、基频、调性、音阶、音色、轮廓/光照/审美分析均未实现。

算法参数集中在 `capabilities.json`：silence_dbfs=-50、silence_min_seconds=0.05、series_points=256、palette_size=8。音频上限 8,000,000 个声道样本，图像上限 8,000,000 像素；可按任务调低，不能超过硬上限。

音频电平/静音流式累计，再解码一遍生成定长包络；最多保留 4,096 段静音区间，超出后区间指标为 unsupported，首尾静音仍保留。响度单独限 2,000,000 个声道样本，超出时响度为 unsupported，其余基础指标继续返回。图像每块 256×256，调色板最多采样 262,144 个源像素，不保留全图浮点 RGB 副本。

每个图像进程预留/硬限 256 MiB，每个音频进程 384 MiB，默认队列总预留 512 MiB。因此可以同时运行两个图像任务，音频任务串行；数量设置不会绕过预算。Windows Job 限制的是进程提交内存，不是所有共享页的工作集总和。`execution` 记录实测 peak_commit_bytes/peak_working_set_bytes；分配超限或原生后端异常退出走结构化失败。预算设置失败则不执行分析。开发期临时目录/解释器均使用 Windows 原生路径。

支持的源扩展名由同一能力文件声明：PNG/JPEG/WebP/BMP/TGA/TIFF、WAV/OGG/MP3/FLAC。内嵌资源、AtlasTexture、.tres/.res 只显示“仅支持源文件分析”，不偷偷导出替代素材。错误分别为 source_not_file、unsupported_format（含后端缺少解码能力）、corrupt_file（后端识别出损坏输入）、decode_failed（其他解码异常）；不能仅凭扩展名保证具体编码可解码。

`Allowed edge silence` 是 Godot 侧独立项目规则，初始 0.05 秒；不改变测量、不参与源文件改写。静音阈值改变后需重新提交/重分析，规则阈值改变则直接用现有结果检查。没有无解释综合分数。

## 缓存、故障与迁移

`reports/asset-analyzer/` 已被项目忽略，Godot 不导入其中 wheel 和缓存：

- `runtime/`：可重新安装的本项目依赖，不随框架复制或正式游戏导出。
- `cache/<key>.json`：可检查、可删除；键包含规范路径、源内容 SHA-256、参数、Analyzer 类型/版本、全部后端版本、Schema 版本。读取先按共同 Schema 校验，再比对 asset/analyzer/parameters 与本次完整 identity。缺字段、错类型、语义不一致或超过 2 MiB 的缓存忽略并重算，成功后原子替换；失败/部分失败不缓存。
- `jobs/`：请求与写缓存的短期文件。完成、取消、超时、工作台退出都清理自有文件；worker 检测父进程退出，避免引擎异常退出后遗留计算进程。
- `history/`：用户显式保存的批量分析快照；不自动淘汰，不代表当前资源仍保持相同内容。需要长期版本管理时由项目选择归档位置。

强制重分析可覆盖当前缓存；关闭工作台后可删除 `cache` 目录全部重新生成。旧内容键不会自动淘汰，定期按项目需要清理；不建立数据库。

缺少解释器、依赖、无法解码、超限、超时、异常退出、空输出、损坏协议均显示结构化错误，不关闭工作台。文件在分析过程中改变时拒绝缓存并要求重试。仅开发环境运行，正式导出排除 `tools/asset_analyzer/` 与工作台；音频播放与正式组件没有 Python 依赖。

Godot 侧的能力配置与结果 Schema 在首次需要时加载，成功后在进程内复用；缺失、JSON 损坏或必需结构无效时返回 `analyzer_config` 并指出文件，预览与播放仍可继续。加载失败不缓存，恢复正确文件后可以重试；已成功加载后再修改契约，需要重启工作台进程，不提供自动热重载。

增加指标优先在对应 Adapter 返回新的 metrics/series，现有表和图自动消费；新增后端从 worker 分派，保持 v1 字段/单位，改变算法时升级 ANALYZER_VERSION。协议不兼容变更需同步 Schema、两端验证和测试。高级指标必须先定义适用类别、有效性与实际筛选用途。

依赖版本与许可证见 [DEPENDENCIES.md](DEPENDENCIES.md)。
