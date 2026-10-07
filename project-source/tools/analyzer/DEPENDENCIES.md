# Analyzer 依赖与许可记录

运行环境为 Windows x64 / CPython **3.13.16**，环境名 **yaya-analyzer-2**。全部运行依赖和传递依赖的版本以 [requirements.txt](requirements.txt) 为准；不解析 latest/stable 别名。安装和配置步骤见 [README](README.md#准备与使用)。不同依赖代次使用不同环境名，避免重装同名环境破坏旧项目的 Analyzer 副本。

| 依赖 | 固定版本 / 许可证 | 用途与核对来源 |
| --- | --- | --- |
| PyAV | 18.1.0 / BSD-3-Clause | 唯一音频流解码后端；Windows wheel 内含 FFmpeg 库 |
| NumPy | 2.5.3 / BSD-3-Clause | 有界数组、峰值/RMS/直方图/颜色统计；[官方发布包](https://pypi.org/project/numpy/2.5.3/) |
| Pillow | 12.3.0 / MIT-CMU | 图像读取与像素模式转换；[官方发布包](https://pypi.org/project/pillow/12.3.0/) |
| pyloudnorm | 0.2.0 / MIT | 成熟的 BS.1770-4 集成响度、TECH 3342 LRA；[版本源码](https://github.com/csteinmetz1/pyloudnorm/tree/v0.2.0)、[发布包](https://pypi.org/project/pyloudnorm/0.2.0/) |
| SciPy | 1.18.1 / BSD-3-Clause | 响度滤波、Welch/FFT 窗函数、polyphase 重采样与真峰值；[官方发布包](https://pypi.org/project/scipy/1.18.1/) |
| librosa | 1.0.0 / ISC | 只调用 pYIN；短窗 RMS、包络、能量、频谱和音名换算由 NumPy/SciPy 实现 |
| Numba | 0.68.0 / BSD-3-Clause | librosa pYIN 的 JIT 内核；随包保留第三方许可 |
| llvmlite | 0.50.0 / BSD-2-Clause AND Apache-2.0 WITH LLVM-exception | Numba 所需 LLVM 绑定与运行库 |
| scikit-image | 0.26.0 / BSD-3-Clause，另含 BSD-2-Clause/MIT 组件 | 四宫格灰度使用 rgb2xyz 的 Y；保留后续色彩空间换算的库基础，当前不计算 CIEDE2000 |
| SoundFile | 0.14.0 / BSD-3-Clause | librosa 安装依赖；不另建音频解码入口，wheel 的 libsndfile 另有 LGPL |
| soxr | 1.1.0 / LGPL-2.1-or-later | librosa 安装依赖；本工具重采样使用 SciPy，不直接调用 soxr |

其余锁定的传递依赖按包元数据记录主许可证，版本不在此重复维护：

| 依赖 | 主许可证 | 用途 |
| --- | --- | --- |
| scikit-learn、joblib、threadpoolctl、narwhals | BSD-3-Clause（前三项）、MIT（narwhals） | librosa 的算法与计算支持依赖 |
| lazy-loader、decorator、cloudpickle | BSD-3-Clause、BSD-2-Clause、BSD-3-Clause | 延迟加载、装饰器与序列化支持 |
| msgpack | Apache-2.0 | librosa 的序列化依赖 |
| pooch、platformdirs | BSD-3-Clause、MIT | librosa 的数据/缓存支持依赖；worker 不调用下载或示例音频接口 |
| requests、urllib3、certifi、charset-normalizer、idna | Apache-2.0、MIT、MPL-2.0、MIT、BSD-3-Clause | pooch 的传递依赖；安装这些包不意味着分析联网 |
| cffi、pycparser | MIT-0、BSD-3-Clause | SoundFile 的绑定依赖 |
| imageio、tifffile、networkx | BSD-2-Clause、BSD-3-Clause、BSD-3-Clause | scikit-image 的传递依赖 |
| packaging、typing_extensions | Apache-2.0 OR BSD-2-Clause、PSF-2.0 | 版本与类型支持 |

全部 33 项运行依赖已在 CPython 3.13.16 上通过 `pip --only-binary=:all:` 安装并核对版本，`pip check` 无冲突，不需要本地编译链。维护夹具另装 jsonschema，它不进入运行锁定文件。包元数据和完整许可证保留在环境的 `Lib/site-packages/*dist-info/`。表中的主许可证不替代 wheel 内各组件的完整许可：NumPy 元数据还列有 0BSD、MIT、Zlib、CC0-1.0；NumPy/SciPy 的 OpenBLAS、LAPACK 和 GCC runtime 等按随包许可及相应例外核对，Pillow 也保留附带组件许可。

PyAV 18.1.0 的 Windows wheel 实际链接 **FFmpeg 8.1.2**，从 `av._core.ffmpeg_version_info` 与 `av._core.library_meta` 核对，所有已链接 FFmpeg 库报告 **LGPL version 3 or later**。PyAV 的 BSD 许可不覆盖这些库。`av.library_versions` 为：libavutil 60.26.102、libavcodec 62.28.102、libavformat 62.12.102、libavdevice 62.3.102、libavfilter 11.14.102、libswscale 9.5.102、libswresample 6.3.102；实际结果 JSON 携带这些库版本。

soxr 的 Python 包和 libsoxr 都声明 **LGPL-2.1-or-later**；对应文件为 `soxr-1.1.0.dist-info/licenses/LICENSE.txt`、`LICENSE-libsoxr.txt`、`COPYING.LGPL`，其 PFFFT 组件另见 `LICENSE-PFFFT.txt`。SoundFile 的 libsndfile 许可保留在 `_soundfile_data/COPYING`（LGPL 2.1），关联编解码组件的 BSD/LGPL 许可和源码位置见随 wheel 安装的 `licensing/license_notes.md`。这些许可不会因当前不直接调用这两个包而消失。

项目只包含自身的实现与依赖声明，不附带 wheel 或 DLL；Analyzer 环境属于本机开发环境，不进入正式游戏导出。若分发这些二进制，应按具体 wheel、LGPL 组件及 FFmpeg [官方许可说明](https://ffmpeg.org/legal.html) 核对许可与对应源码获取要求，不能把整套依赖称为纯 BSD/MIT。

选择依据：锁定包提供可安装的 Windows wheel，运行直接得到数组和数值，不解析人类日志，不依赖网络服务或外部模型。librosa 只承担 pYIN，避免自行实现概率音高跟踪；Machado 矩阵由 NumPy 计算，scikit-image 只承担色彩空间换算。响度仍交给 pyloudnorm，不自行实现 BS.1770 或 LRA。

没有采用独立的 FFmpeg/ffprobe CLI：PyAV 自带的库已满足解码需求，省去独立可执行路径、日志解析和子进程管理。worker 不创建分析子进程；线程变量、内存硬限制与 Numba 缓存位置见 README。

## 算法来源

两个外部 Analyzer 只作为设计参考，不作为安装或运行依赖，也不复制其 CLI、配置和报告系统：

- 音频参考 `Studio Game Audio Analyzer/src/game_audio_analyzer/metrics/temporal.py:39–52,77–91` 的包络、95% 能量区间和完整滑窗，`spectrum.py:14–98` 的声道功率与频谱口径，`levels.py:8–23` 的重叠分块真峰值，`timbre.py:29–71` 的 pYIN 适用性。框架按流式解码重新实现；短窗 RMS 按当前契约取最响声道，pYIN 上界扩至 4000 Hz 并校验最低频率的两周期条件。
- 色觉参考 `Studio Game Visual Analyzer/src/analyzer/metrics/accessibility.py:12–20` 和 `image_io.py:14–22`。沿用 Machado 2009 公布的 severity-1 矩阵数值（DOI：10.1109/TVCG.2009.113），重新实现分块转换与四宫格排版，不复制外部程序代码。灰度使用 scikit-image 的 XYZ Y。
