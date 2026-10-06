# 资源 Analyzer

Analyzer 在开发期离线分析图像与音频的源文件，用命令行运行，结果是一份 JSON。它不参与游戏运行、音频播放或资源导入；正式导出排除整个 `yaya/tools/`。

## 准备与使用

Analyzer 运行在一个只装它锁定依赖的独立 Python 3.12 环境中，项目 `docs/methodology-config.json` 的 `analyzer_python_executable` 指向这个环境的解释器。同一台电脑上的项目共用这个环境，只需安装一次；它与 `python_executable` 分开，锁定的版本不会影响项目其他工具。已在 Windows 11 x64、Python 3.12 与 Godot 4.7.1 上验证。创建项目时不会自动配置。

第一次在这台电脑上使用时：

1. 用户在终端建环境（需要联网）：`conda create --name yaya-analyzer python=3.12 --yes`。
2. 用户运行 `conda env list`，找到 `yaya-analyzer` 的目录；解释器是其中的 `python.exe`，例如 `C:/Users/<用户名>/anaconda3/envs/yaya-analyzer/python.exe`。
3. 用户把锁定依赖装进这个环境（需要联网）。依赖装在环境里，不在项目中；在项目根目录执行只是为了用相对路径找到锁定文件，在别处执行时把它换成锁定文件的绝对路径：

   ```powershell
   & '<解释器路径>' -m pip install --only-binary=:all: -r 'yaya/tools/analyzer/requirements.txt'
   $LASTEXITCODE
   ```

4. Agent 或用户在每个要用 Analyzer 的项目的配置中写入 `"analyzer_python_executable": "<解释器路径>"`。之后的项目只做这一步。

- 只安装 Windows wheel，不需要 WSL、FFmpeg CLI 或本地编译；分析运行时不联网。
- 这个环境里只装锁定文件中的包。锁定文件变了（例如框架更新了版本），在同一环境中按新文件重新执行第 3 步，再回归使用它的项目；各项目锁定的版本不同时，为它们分别建环境。
- 没有配置、依赖缺失或版本与锁定文件不一致时，调用方无法启动解释器，或分析结果为 `dependency_missing`。

## 运行一次分析

1. 在 `reports/asset-analyzer/jobs/` 下写一个请求文件，例如 `jobs/click.json`：

   ```json
   {"path": "D:/Games/MyGame/dev/showcase/visual/board/sounds/click_a.wav", "asset_type": "audio", "parameters": {}, "force": false}
   ```

   - `path`：源文件的绝对路径。
   - `asset_type`：`audio` 或 `image`。
   - `parameters`：可省略或为空，空时使用 `capabilities.json` 的默认值；可覆盖的键和上限见同一文件。
   - `force`：`true` 时绕过缓存重新计算。
2. 在项目根目录运行：

   ```powershell
   & '<analyzer_python_executable>' -B yaya/tools/analyzer/worker.py --request reports/asset-analyzer/jobs/click.json > reports/asset-analyzer/jobs/click.result.json
   ```

3. stdout 是一份 UTF-8 JSON 结果，格式见下文“请求与输出”。分析失败也输出结构化结果，`status` 为 `failed`，`errors` 写明原因；不要只看进程退出码。
4. 用完删除请求文件。结果文件按需要保留在 `reports/` 下，例如供画面演示台读取并显示。

worker 一次只分析一个文件，不做排队、超时和批量比较；需要比较多个文件时，逐个运行后对比结果中的数值。`--parent-pid` 只供启动它的父进程使用：父进程退出时 worker 随之退出并清理请求文件。

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
- 修改静音阈值后需要重新分析。没有无解释的综合分数。

参数与上限：

- 算法参数集中在 `capabilities.json`：`silence_dbfs=-50`、`silence_min_seconds=0.05`、`series_points=256`、`palette_size=8`。
- 音频上限 8,000,000 个声道样本，图像上限 8,000,000 像素；任务可以调低，但不能超过硬上限。
- 音频电平和静音流式累计，再解码一遍生成定长包络。最多保留 4,096 段静音区间，超出后区间指标为 unsupported，首尾静音仍保留。响度单独限 2,000,000 个声道样本，超出时响度为 unsupported，其余基础指标照常返回。
- 图像按 256×256 分块处理，调色板最多采样 262,144 个源像素，不保留全图浮点 RGB 副本。

内存预算：

- 每个图像进程硬限 256 MiB，每个音频进程 384 MiB。
- Windows Job 限制的是进程提交内存，不是所有共享页的工作集总和。`execution` 记录实测的 `peak_commit_bytes` 与 `peak_working_set_bytes`。
- 分配超限或原生后端异常退出时返回结构化失败；预算设置失败则不执行分析。临时目录和解释器都使用 Windows 原生路径。

支持的源格式：

- 支持的扩展名在同一能力文件中声明：PNG、JPEG、WebP、BMP、TGA、TIFF、WAV、OGG、MP3、FLAC。不能仅凭扩展名保证具体编码可以解码。
- 内嵌资源、AtlasTexture、`.tres` 与 `.res` 不是源文件，不能分析，也不会导出替代素材。
- 错误分为 `source_not_file`、`unsupported_format`（含后端缺少解码能力）、`corrupt_file`（后端识别出损坏输入）和 `decode_failed`（其他解码异常）。

## 缓存与运行目录

`reports/asset-analyzer/` 已被项目忽略，Godot 不导入其中的缓存：

- `cache/<key>.json`：可检查、可删除。键包含规范路径、源内容 SHA-256、参数、Analyzer 类型与版本、全部后端版本和 Schema 版本。读取时先按共同 Schema 校验，再比对 asset、analyzer、parameters 与本次完整身份。缺字段、类型错误、语义不一致或超过 2 MiB 的缓存会被忽略并重算，成功后原子替换；失败或部分失败的结果不缓存。
- `jobs/`：请求文件与写缓存的短期文件，由调用方在用完后删除。

强制重分析会覆盖当前缓存；可以随时删除整个 `cache` 目录，让其重新生成。旧内容的缓存键不会自动淘汰，按项目需要定期清理；不建立数据库。

## 故障处理

- 无法解码、超限、异常和依赖缺失都以结构化结果返回，`status` 为 `failed` 或 `partial`。
- 文件在分析过程中改变时，拒绝写缓存，需要重试。
- 能力配置的参数数值与范围由 worker 校验，不合法时返回结构化错误。

## 结构与协议

| 位置 | 职责 |
| --- | --- |
| `worker.py` | 每次请求一个独立进程，分派适配器、核对版本、SHA-256 缓存；只读等待 Windows 父进程句柄，父进程退出时终止，不创建子进程 |
| `audio_adapter.py`、`image_adapter.py` | 唯一依赖具体分析库的算法适配器 |
| `memory_budget.py`、`audio_statistics.py` | Windows worker 的提交内存硬限制与实测高水位，流式电平与静音累计；不限制 Godot 进程 |

请求与输出：

- 输入为 JSON 文件，包含 `path`、`asset_type`（`audio` 或 `image`）、`parameters` 与 `force`。
- stdout 输出一份 UTF-8 JSON，上限 2 MiB；stderr 只用于诊断。
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

运行时校验器只解释当前 Schema 用到的词汇，不是通用的 JSON Schema 引擎。`x-equal-lengths` 约束 x 与 y 等长，并递归拒绝 NaN 与 Infinity；标准 JSON 本身不允许非有限数。Analyzer 版本为 2；算法版本变化后，旧缓存自然失效。

## 扩展

- **新增指标**：在对应 Adapter 返回新的 metrics 或 series。高级指标必须先定义适用类别、有效性与实际筛选用途。
- **新增后端**：从 worker 分派，保持 v1 的字段与单位；改变算法时升级 `ANALYZER_VERSION`。
- **新增校验词汇**：同时补充 `schema_validation.py` 和后端测试。
- **协议不兼容的变更**：同步修改 Schema、验证和测试，以及读取结果的调用方。

依赖版本与许可证见 [DEPENDENCIES.md](DEPENDENCIES.md)。
