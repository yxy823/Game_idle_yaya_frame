# 资源 Analyzer

Analyzer 在独立进程中分析图像源文件，输出有限数值的 JSON 与色觉四宫格 PNG。结果说明源像素的统计特征，不代替 Godot 实际渲染、显示设备或人工观察。

## 准备与使用

Analyzer 使用独立的 Python 3.13.16 环境 `yaya-analyzer`，项目 `docs/methodology-config.json` 的 `analyzer_python_executable` 指向其解释器。同一台电脑上使用这套锁定依赖的项目可以共用环境；创建项目时不会自动配置。调试台音频分析用的 GAA 依赖与这套锁定版本兼容，可以装进同一环境，`audio_analyzer_python_executable` 指向同一个解释器。

第一次在这台电脑上使用时：

1. 用户在终端建环境：`conda create --name yaya-analyzer python=3.13.16 pip --yes`。
2. 用户运行 `conda env list`，找到环境目录，其解释器是目录中的 `python.exe`。
3. 用户把锁定依赖装进环境，在项目根目录运行：

   ```powershell
   & '<解释器路径>' -m pip install --only-binary=:all: -r 'yaya/tools/analyzer/requirements.txt'
   & '<解释器路径>' -m pip check
   $LASTEXITCODE
   ```

4. Agent 或用户在项目配置中填写 `"analyzer_python_executable": "<解释器路径>"`。

安装需要联网，只使用 Windows wheel；分析运行时不联网。全部九项运行依赖和传递依赖锁定在 `requirements.txt`。维护回归另需 `jsonschema`，不进入运行依赖。依赖版本和许可见[Analyzer 依赖与许可记录](DEPENDENCIES.md)。

算法修订号见结果中的 `analyzer.version`。依赖缺失或版本不符时返回 `dependency_missing`。

## 运行一次分析

1. 在 `reports/asset-analyzer/jobs/` 下写请求文件，例如 `image.json`：

   ```json
   {"path": "D:/Games/MyGame/assets/images/example.png", "asset_type": "image", "modules": ["image_cvd_grid"], "parameters": {}, "force": false}
   ```

   - `path`：图像源文件的绝对路径。
   - `asset_type`：固定为 `image`。
   - `modules`：省略时运行全部图像模块；`[]` 只运行基础统计；显式列表只加指定模块。基础分析始终运行，未知模块返回 `invalid_modules`。
   - `parameters`：省略或为空时使用默认值。公共参数见 `capabilities.json`，模块参数见对应声明；不接受未选模块的参数。
   - `force`：`true` 时绕过结果缓存。
2. 在项目根目录运行：

   ```powershell
   & '<analyzer_python_executable>' -B yaya/tools/analyzer/worker.py --request reports/asset-analyzer/jobs/image.json --output reports/asset-analyzer/jobs/image.result.json
   ```

3. 读取 UTF-8 JSON，检查 `status` 和 `errors`。可捕获的分析失败也写结构化结果，不能只看退出码。`--output` 模式的 stdout 为空，结果完整写入后原子发布；省略该参数时输出单份 JSON 到 stdout。
4. 用完删除请求文件，结果文件按需要保留在 `reports/`。

Godot 用 `OS.create_process` 传入上述参数和自己的 `--parent-pid`，轮询进程结束后读取唯一结果路径。worker 每次分析一个文件，不排队或批量比较。父进程退出时 worker 退出并清理请求文件。

## 测量口径与限制

| 类别 | 实现与适用范围 |
| --- | --- |
| 图像 | 第一帧源像素的尺寸、模式、Alpha 及透明、不透明、半透明比例，Alpha 摘要与分布 |
| 颜色 | 排除 alpha=0 的像素，其余等权；RGB、HSV 饱和度统计按全图分块累计。不超过 262,144 像素时提供精确色数和频率；更大图像按固定步长采样调色板，报告样本数和警告，精确色数为 unsupported |
| 亮度与对比 | 编码 sRGB 通道加权的 luma、标准差及直方图，标明 proxy；不做 ICC、EXIF 旋转或线性光校准，也不模拟 Godot 导入、Shader 或显示变换 |
| 色觉四宫格 | `cvd_grid.value.path` 为 PNG 绝对路径；左上正常、右上灰度、左下 protan、右下 deutan。Machado 2009 severity=1 在线性 sRGB 中计算，灰度采用 XYZ Y，再编码回 sRGB；裁剪到 sRGB，保留 Alpha |

参数与资源限制：

- 公共默认值：`series_points=256`、`palette_size=8`、`max_image_pixels=8000000`；数值范围见 `capabilities.json`。
- 四宫格参数 `cvd_max_panel_pixels=2073600` 可调低至 1，不能超过硬上限。大图等比缩小，结果记录 source_size、panel_size 和 image_size；基础统计仍针对原图。
- 图像按 256×256 分块统计，调色板最多采样 262,144 个源像素，不保留全图浮点 RGB 副本。
- 图像 worker 的 Windows Job 提交内存硬限为 256 MiB。`execution` 记录 `peak_commit_bytes` 与 `peak_working_set_bytes`，后者包含的共享页不等于提交内存。
- 可捕获的分配超限返回结构化失败；预算设置失败不开始分析。原生崩溃、强制终止或 Python 无法继续执行时不保证产生结果文件，调用方不能把文件缺失当成成功。
- worker 在计算库导入前设置 `OPENBLAS_NUM_THREADS=1`、`OMP_NUM_THREADS=1`，不限制 Godot 进程的内存。

支持 PNG、JPEG、WebP、BMP、TGA、TIFF，扩展名声明在能力文件中；扩展名不能保证具体编码可解码。内嵌资源、AtlasTexture、`.tres`、`.res` 不是图像源文件，不导出替代素材。

## 缓存与运行目录

`reports/asset-analyzer/` 已被项目忽略，Godot 不导入其中的缓存：

- `cache/<key>.json`：键包含源路径、内容 SHA-256、参数、Analyzer 类型与版本、全部锁定后端版本、Schema 版本、排序去重的模块及版本。输出路径与 force 不改变键。按 Schema 和完整身份检查缓存；无效或超过 2 MiB 时重算，失败和部分失败不缓存。
- `cache/<key>/cvd-grid.png`：先原子发布图，再发布缓存 JSON。缓存命中时检查路径、PNG 可读性及尺寸；图丢失或损坏时重算。
- `jobs/`：调用方创建和清理请求与结果。原子写入临时文件放在各自目标目录，成功或可捕获失败后清理。

同图可以由两个 worker 同时分析，临时文件独立。Windows 读者短暂占用目标时，PNG、缓存及输出 JSON 的原子替换每隔 50 ms 重试，最多 1 秒；持续失败返回错误。清理缓存前先等待相关 worker 退出。

强制重算覆盖同键缓存；旧键不自动淘汰，可以按项目需要删除缓存，不建立数据库。

## 故障处理

- 分析失败、超限和依赖缺失通过结果的 `failed` 或 `partial` 状态报告。
- 源文件在计算中变化时拒绝写缓存，返回 `asset_changed`。
- 参数类型与范围不合法时返回结构化错误。
- 输入问题区分 `source_not_file`、`unsupported_format`、`corrupt_file` 和 `decode_failed`。
- `--output` 写入失败时退出码为 1，stderr 给出 `output_write_failed`，stdout 为空；此时不能保证结果文件存在。正常写出的结果仍按 JSON status 判断。

## 结构与协议

| 位置 | 职责 |
| --- | --- |
| `worker.py` | 独立进程入口、版本检查、图像分析与缓存、父进程监控；不创建子进程 |
| `image_adapter.py` | 图像基础指标 |
| `feature_runner.py`、`features/image_cvd_grid.py` | 模块发现、选择、失败保留及色觉四宫格 |
| `atomic_output.py` | 同盘临时文件与原子发布 |
| `memory_budget.py` | Windows 提交内存限制与高水位测量 |

请求与结果单份 UTF-8 JSON 均不超过 2 MiB。请求必须是对象，path 和 asset_type 必须是字符串，否则返回 `invalid_request`。

结果包含 schema_version、status、asset、analyzer、metrics、series、warnings、errors 和 cache。`analyzer.backend` 映射各依赖名称到具体版本。单值、不可用值和序列示例：

```json
{"status":"available","value":1920,"unit":"px","reason":""}
{"status":"not_applicable","value":null,"unit":"","reason":"No visible pixels"}
{"status":"available","kind":"histogram","x":[0,255],"y":[0.25,0.75],"x_unit":"alpha 0..255","y_unit":"ratio"}
```

结果状态为 success、partial 或 failed。指标区分 available、not_applicable、unsupported 和 failed；不可用指标的 value 为 null，并说明原因。个别模块失败时保留其他结果，整体为 partial。错误使用 code/message，不从 stderr 文本推断测量值。

结果 Schema 为 v1，算法版本为 3。运行时校验器解释当前 Schema 词汇，`x-equal-lengths` 检查 x/y 等长，并递归拒绝 NaN 和 Infinity。算法或模块版本改变后旧缓存自然失效。

## 扩展

图像功能放在 `features/<功能名>.py`：声明 ASSET_TYPE=image、VERSION、METRICS，以及需要的 DEFAULTS、LIMITS 和 ARTIFACTS，提供 `run(path, params, context)`，返回 metrics、series、warnings。顶层不导入计算库；模块自动发现，不增加登记表。context 提供基础 metrics 和 artifact_dir，产物使用 atomic_target 发布。

新增计算库时同步依赖锁定文件和许可。修改算法时更新对应模块 VERSION 或 ANALYZER_VERSION；扩展校验词汇时同步 Schema、校验器和测试。协议不兼容变更同时修改结果读取方。
