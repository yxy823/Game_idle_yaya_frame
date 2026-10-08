# 资源 Analyzer

Analyzer 在开发期离线分析图像与音频的源文件，用命令行运行，输出 JSON 和按模块生成的结果图。游戏内调试台可在后台调用它；它不播放音频、不模拟资源导入，正式导出排除整个 `yaya/tools/`。

## 准备与使用

Analyzer 使用独立的 Python 3.13.16 环境 `yaya-analyzer-2`，项目 `docs/methodology-config.json` 的 `analyzer_python_executable` 指向其解释器。同一台电脑上使用这套锁定依赖的项目可以共用环境；它与普通工具的 `python_executable` 分开。创建项目时不会自动配置。

第一次在这台电脑上使用时：

1. 用户在终端建环境（需要联网）：`conda create --name yaya-analyzer-2 python=3.13.16 pip --yes`。
2. 用户运行 `conda env list`，找到 `yaya-analyzer-2` 的目录；解释器是其中的 `python.exe`，例如 `C:/Users/<用户名>/anaconda3/envs/yaya-analyzer-2/python.exe`。
3. 用户把锁定依赖装进这个环境（需要联网）。依赖装在环境里，不在项目中；在项目根目录执行只是为了用相对路径找到锁定文件，在别处执行时把它换成锁定文件的绝对路径：

   ```powershell
   & '<解释器路径>' -m pip install --only-binary=:all: -r 'yaya/tools/analyzer/requirements.txt'
   & '<解释器路径>' -m pip check
   $LASTEXITCODE
   ```

4. Agent 或用户在每个要用 Analyzer 的项目的配置中写入 `"analyzer_python_executable": "<解释器路径>"`。之后的项目只做这一步。

- 只安装 Windows wheel，不需要 WSL、FFmpeg CLI 或本地编译；分析运行时不联网。
- 运行依赖和传递依赖都在锁定文件中；维护回归另装 `jsonschema`，不作为运行依赖。各项目自带的 Analyzer 副本可能锁定不同版本，按依赖代次分别建环境，不覆盖旧项目仍使用的环境。`yaya-analyzer-2` 是环境代次，算法修订号另见结果中的 `analyzer.version`。
- 没有配置、依赖缺失或版本与锁定文件不一致时，调用方无法启动解释器，或分析结果为 `dependency_missing`。

## 运行一次分析

1. 在 `reports/asset-analyzer/jobs/` 下写一个请求文件，例如 `jobs/click.json`：

   ```json
   {"path": "D:/Games/MyGame/dev/debug/board/slots/audio/click/click-a/click_a.wav", "asset_type": "audio", "parameters": {}, "force": false}
   ```

   - `path`：源文件的绝对路径。
   - `asset_type`：`audio` 或 `image`。
   - `modules`：可省略，默认运行全部适用模块；`[]` 只运行基础分析；显式列表只加指定模块，例如 `["audio_max_rms", "audio_pitch"]`。基础分析始终运行，未知或类型不符的模块返回 `invalid_modules`。
   - `parameters`：可省略或为空；公共默认值和上限见 `capabilities.json`，选中模块的默认值和上限见对应模块声明。不接受未选模块的参数。
   - `force`：`true` 时绕过缓存重新计算。
2. 在项目根目录运行：

   ```powershell
   & '<analyzer_python_executable>' -B yaya/tools/analyzer/worker.py --request reports/asset-analyzer/jobs/click.json --output reports/asset-analyzer/jobs/click.result.json
   ```

3. 读取输出文件中的 UTF-8 JSON，检查 `status` 和 `errors`；可捕获的分析失败也写结构化结果，不能只看退出码。使用 `--output` 时 stdout 为空，文件在完整写入后原子发布。不传 `--output` 时保持单份 JSON stdout。
4. 用完删除请求文件。结果文件按需要保留在 `reports/` 下，例如供调试台读取并显示。

Godot 用 `OS.create_process` 传入 `--request`、`--output` 和自己的 `--parent-pid`，轮询进程结束后读取结果文件。每次请求使用唯一输出路径，避免把旧结果当成本次完成。文件模式不把 JSON 写入无人读取的 stdout 管道。

worker 一次只分析一个文件，不做排队、超时和批量比较；需要比较多个文件时，逐个运行后对比结果中的数值。`--parent-pid` 只供启动它的父进程使用：父进程退出时 worker 随之退出并清理请求文件。

## 测量口径与限制

| 类别 | 实现与适用范围 |
| --- | --- |
| 音频基础 | 第一个音频流的格式、codec、解码时长、采样率、声道和布局；只有已识别的 PCM codec 报告源位深，压缩或精度未知的格式不以解码浮点位深冒充 |
| 电平 | 原始解码样本的 sample peak、RMS、crest factor（peak/RMS，dB）；包络每段取绝对峰值或 RMS，默认 256 点，所有声道参与 |
| 响度 | pyloudnorm BS.1770-4 集成响度：1 或 2 声道，至少 0.4 秒；LRA 至少 3 秒，采用后端的 TECH 3342 实现及其 1.5 秒尾部补零；更多声道暂不支持权重映射 |
| 静音 | 所有声道的样本幅度都低于阈值、连续不少于最短时长的区间，返回起止、持续时长及首尾静音；不是语音活动检测 |
| 短窗 RMS | `max_rms_10ms/20ms/50ms`（dBFS）：全文件完整窗口，1 ms 步长；各声道分别算 RMS，再取所有窗口、声道的最大值。不足窗口不补零，返回 not_applicable；不是 LUFS |
| 起音与衰减 | `attack_10_90`、`decay_to_10`（s）：所有声道平均功率的 1 ms RMS 包络；峰值前首次 10%→90%，峰值后首次降至 10%。未降至阈值返回 not_applicable；多事件音效可能误导，不是 ADSR 拟合 |
| 能量持续 | `energy_duration_95`（s）：原始声道平均样本功率累计至 2.5% 和 97.5% 的包含端点区间；静音返回 not_applicable |
| 频谱 | `spectral_centroid`、`spectral_bandwidth`、`spectral_rolloff_85`（Hz）：频谱分支移除各声道 DC，声道功率平均，Hann 窗幅度加权，再按帧能量汇总；二阶带宽，85% 累计幅度滚降。最终不足一帧补零，不保留全图 STFT |
| 频段 | `band_energy_ratios`：Welch 功率谱的 20–120/120–500/500–2000/2000–8000/8000–20000 Hz 占比，分母为全部可观测 AC 功率。每段给出实际覆盖上界；未覆盖时 ratio 为 null，五段不必合计为 1 |
| 真峰值 | 原有 `true_peak`（dBTP）由 4 倍 SciPy polyphase FIR 过采样计算；Kaiser beta=5、128 样本重叠、文件边界零延拓，全声道取最大。这是重建峰值估计，不是认证 BS.1770 仪表 |
| 基础音高 | 原有 `pitch`（Hz）为接受帧中位数；另有 `pitch_note`、`pitch_voiced_fraction` 和 `pitch_confidence`。最高 AC 能量声道重采样到 16 kHz，pYIN 65.406–min(4000,源 Nyquist) Hz、1024 帧长、256 步长，最低频率在帧内超过两个周期 |
| 图像 | 第一帧的源像素尺寸、模式与 Alpha，透明、不透明、半透明比例，Alpha 摘要与分布 |
| 颜色 | 排除 alpha=0 的像素，其余等权；RGB 均值与直方图、HSV 饱和度及分布按全图分块累计。不超过 262,144 像素的图像提供精确色数和频率；更大的图按固定步长采样代表色与调色板，并报告样本数、单位与警告，精确色数为 unsupported |
| 亮度与对比 | 编码 sRGB 通道加权的 luma 及其标准差与直方图，明确标为 proxy；不做 ICC、EXIF 旋转、线性光校准，也不模拟 Godot 导入、Shader 或显示变换 |
| 色觉四宫格 | `cvd_grid.value.path` 为 PNG 绝对路径；左上正常、右上灰度、左下 protan、右下 deutan。Machado 2009 severity=1 在线性 sRGB 中计算，灰度采用标准 XYZ Y，再编码回 sRGB；结果裁剪到 sRGB，Alpha 保留，不改变旧 luma 指标 |

- 零样本的电平是负无穷，在有限 JSON 中以 not_applicable 加原因表示；被响度门限排除的信号同样不伪造 LUFS 或 LRA。
- 音高使用有效能量帧：RMS 高于静音阈值且不低于最大帧 RMS 的 1%；补零产生的文件外帧不算观测。有声比例和平均有声概率以这些帧为分母；中位频率只取有声且概率≥0.5 的帧。至少 3 个接受帧、有声比例≥0.6、平均概率≥0.5 才给频率与音名，否则为 not_applicable，并保留可计算的证据值。概率不是音高正确率，不适合据此断言和弦或调性。
- `tempo` 仍为 unsupported；节拍、调性、音阶、音色、轮廓、光照与审美分析未实现。未选中的 true peak 和 pitch 模块保留 unsupported 条目及原因。
- 修改静音阈值后需要重新分析。没有无解释的综合分数。

参数与上限：

- 公共参数在 `capabilities.json`：`silence_dbfs=-50`、`silence_min_seconds=0.05`、`series_points=256`、`palette_size=8`。模块参数同样直接写在 `parameters` 中：audio_pitch 的 `max_pitch_seconds=10`（可调低至 0.064）；image_cvd_grid 的 `cvd_max_panel_pixels=2073600`（可调低至 1），不能超过硬上限。
- 音频上限 8,000,000 个声道样本，图像上限 8,000,000 像素；任务可以调低，但不能超过硬上限。
- 音频电平和静音流式累计，再解码一遍生成定长包络。最多保留 4,096 段静音区间，超出后区间指标为 unsupported，首尾静音仍保留。响度单独限 2,000,000 个声道样本，超出时响度为 unsupported，其余基础指标照常返回。
- 图像按 256×256 分块处理，调色板最多采样 262,144 个源像素，不保留全图浮点 RGB 副本。
- 音频模块顺序运行，流式模块只保留分块数据；pYIN 最多保留 10 秒的一个原始声道和重采样信号。超出时 pitch 返回 unsupported，不暗中截取。四宫格每格最多 2,073,600 像素，等比缩小并记录 source_size、panel_size、image_size；基础统计仍针对原图。

内存预算：

- 每个图像进程硬限 256 MiB，每个音频进程 384 MiB。
- Windows Job 限制的是进程提交内存，不是所有共享页的工作集总和。`execution` 记录实测的 `peak_commit_bytes` 与 `peak_working_set_bytes`。
- 可捕获的分配超限返回结构化失败；预算设置失败则不执行分析。原生崩溃、强制终止或无法继续执行 Python 时不能保证产生结果文件；调用方检查进程结束后文件是否存在，不把缺失当成功。不增加监督子进程。
- worker 在计算库导入前设置 `OPENBLAS_NUM_THREADS=1`、`OMP_NUM_THREADS=1`、`NUMBA_NUM_THREADS=1`。不复用游戏进程的内存预算。

支持的源格式：

- 支持的扩展名在同一能力文件中声明：PNG、JPEG、WebP、BMP、TGA、TIFF、WAV、OGG、MP3、FLAC。不能仅凭扩展名保证具体编码可以解码。
- 内嵌资源、AtlasTexture、`.tres` 与 `.res` 不是源文件，不能分析，也不会导出替代素材。
- 错误分为 `source_not_file`、`unsupported_format`（含后端缺少解码能力）、`corrupt_file`（后端识别出损坏输入）和 `decode_failed`（其他解码异常）。

## 缓存与运行目录

`reports/asset-analyzer/` 已被项目忽略，Godot 不导入其中的缓存：

- `cache/<key>.json`：键包含规范路径、源内容 SHA-256、参数、Analyzer 类型与版本、全部锁定后端版本、Schema 版本，以及排序去重的模块列表与模块版本。模块顺序、输出路径和 force 不改变键。读取时先按共同 Schema 校验，再核对完整身份；无效或超过 2 MiB 的缓存重算，失败或部分失败不缓存。
- `cache/<key>/cvd-grid.png`：先原子发布结果图，再发布缓存 JSON；缓存命中时检查预期路径、PNG 可读性和尺寸，图被删除或损坏后重算。
- `jobs/`：调用方创建和清理的请求与结果文件。原子写入临时文件放在各自目标目录，成功或可捕获失败后清理，不在请求旁创建缓存临时文件。
- `numba-cache/py313-librosa1.0.0-numba0.68.0-llvmlite0.50.0/`：项目内的 Numba 编译缓存，由 worker 设置 `NUMBA_CACHE_DIR`；不写 site-packages，`-B` 不禁止这类缓存。可以删除，下次 pYIN 重新编译。

同一文件可以由两个 worker 同时分析，临时文件各自独立。Windows 读者短暂占用目标时，PNG、缓存 JSON 和输出 JSON 的原子替换每隔 50 ms 重试，最多等待 1 秒；持续失败仍返回错误。删除缓存前先等正在分析的 worker 退出。

强制重分析会覆盖当前缓存；可以随时删除整个 `cache` 目录，让其重新生成。旧内容的缓存键不会自动淘汰，按项目需要定期清理；不建立数据库。

## 故障处理

- 无法解码、超限、异常和依赖缺失都以结构化结果返回，`status` 为 `failed` 或 `partial`。
- 文件在分析过程中改变时，拒绝写缓存，需要重试。
- 能力配置的参数数值与范围由 worker 校验，不合法时返回结构化错误。
- `--output` 目标无法写入时退出码为 1，stderr 给出 `output_write_failed` 结构化诊断，stdout 仍为空；该目标无法写入意味着不能保证结果文件存在。正常分析结果（含 failed/partial）仍以 JSON status 判断。

## 结构与协议

| 位置 | 职责 |
| --- | --- |
| `worker.py` | 每次请求一个独立进程，分派适配器、核对版本、SHA-256 缓存；只读等待 Windows 父进程句柄，父进程退出时终止，不创建子进程 |
| `audio_adapter.py`、`image_adapter.py` | 保留基础指标及原有测量口径 |
| `feature_runner.py`、`features/*.py` | 自动发现和选择模块；各模块独立声明指标、版本、参数及产物，运行时才导入计算库 |
| `atomic_output.py` | 同盘临时文件、原子发布与本 worker 临时文件所有权 |
| `memory_budget.py`、`audio_statistics.py` | Windows worker 的提交内存硬限制与实测高水位，流式电平与静音累计；不限制 Godot 进程 |

请求与输出：

- 输入为 JSON 文件，包含 `path`、`asset_type`（`audio` 或 `image`）、可选 `modules`、`parameters` 与 `force`。
- 请求文件和结果的单份 UTF-8 JSON 都以 2 MiB 为上限；请求超限、不是 JSON 对象，或 `path`、`asset_type` 不是字符串时，返回错误码为 `invalid_request` 的 failed 结果；`--output` 时原子写文件且 stdout 为空，省略时写 stdout；stderr 只用于诊断。
- 结果包含 `schema_version`、`status`、`asset`、`analyzer`、`metrics`、`series`、`warnings`、`errors` 和 `cache`。`analyzer.backend` 是后端名称到具体版本的映射（含 FFmpeg 库版本），承担 backend_version 的含义，便于组合多个库。协议不直接暴露后端的私有输出。

指标与序列条目示例：

```json
{"status":"available","value":-6.02,"unit":"dBFS","reason":""}
{"status":"not_applicable","value":null,"unit":"LUFS","reason":"Requires at least 0.4 seconds"}
{"status":"available","kind":"line","x":[0.0,0.1],"y":[0.0,0.5],"x_unit":"s","y_unit":"linear full scale"}
```

依次为单值条目、不可用条目和序列条目。序列 `kind` 为 `line` 时绘制折线；为 `histogram` 时用数值 x/y 绘制柱形分布，x 为分箱中心。

状态：

- 结果状态为 success、partial 或 failed。
- 每个指标区分 available、not_applicable、unsupported 和 failed，未返回的字段显示为 missing。unsupported 不等于任务失败；个别本应可算的指标失败时，整体为 partial，其余结果保留。
- 错误以 code 与 message 表示，不把 stderr 文本当作数据接口。

结果 Schema 保持 v1，新增可选 `analyzer.modules` 和指标；现有字段与单位不变。运行时校验器只解释当前 Schema 词汇，`x-equal-lengths` 约束 x 与 y 等长，并递归拒绝 NaN 与 Infinity。算法版本为 3；模块版本和算法版本变化后旧缓存自然失效。

## 扩展

- **新增功能**：添加 `features/<功能名>.py`，声明 `ASSET_TYPE`、`VERSION`、`METRICS`（指标到单位的映射），按需声明 `DEFAULTS`、`LIMITS`、`ARTIFACTS`（指标到产物文件名的映射），提供 `run(path, params, context)`，返回 metrics、series、warnings 三项。顶层不导入计算库；不修改 worker 或另建模块登记表。`context` 提供基础 metrics 和该键的 artifact_dir；产物用 atomic_target 发布。
- **功能入口**：音频为 `audio_max_rms`、`audio_attack_decay`、`audio_energy_duration`、`audio_spectrum`、`audio_true_peak`、`audio_pitch`，图像为 `image_cvd_grid`。基础 Adapter 始终运行。新增计算库时同步唯一依赖锁定文件及许可；功能算法变更升级模块 VERSION，基础算法变更升级 ANALYZER_VERSION。
- **新增校验词汇**：同时补充 `schema_validation.py` 和后端测试。
- **协议不兼容的变更**：同步修改 Schema、验证和测试，以及读取结果的调用方。

依赖版本与许可证见 [DEPENDENCIES.md](DEPENDENCIES.md)。
