# Analyzer 依赖与许可记录

核对日期：2026-09-21。运行使用 [requirements.txt](requirements.txt) 明确版本，安装后核对实际包元数据；不解析 latest/stable 别名。版本升级需重新测试、更新本文件及锁定文件。

| 依赖 | 固定版本 / 许可证 | 用途与核对来源 |
| --- | --- | --- |
| PyAV | 18.1.0 / BSD-3-Clause | 音频流解码；[官方发布包](https://pypi.org/project/av/18.1.0/) 提供 cp311-abi3-win_amd64 wheel，支持 Python 3.12 |
| NumPy | 2.5.3 / BSD-3-Clause | 有界数组、峰值/RMS/直方图/颜色统计；[官方发布包](https://pypi.org/project/numpy/2.5.3/) |
| Pillow | 12.3.0 / MIT-CMU | 图像读取与像素模式转换；[官方发布包](https://pypi.org/project/pillow/12.3.0/) |
| pyloudnorm | 0.2.0 / MIT | 成熟的 BS.1770-4 集成响度、TECH 3342 LRA；[版本源码](https://github.com/csteinmetz1/pyloudnorm/tree/v0.2.0)、[发布包](https://pypi.org/project/pyloudnorm/0.2.0/) |
| SciPy | 1.18.1 / BSD-3-Clause | pyloudnorm 所需滤波；[官方发布包](https://pypi.org/project/scipy/1.18.1/)；不额外建立 DSP 框架 |

已在 Windows 11 / CPython 3.12.13 上实际安装全部二进制 wheel，不需要编译链。包元数据和完整许可证随安装保留在 Analyzer 环境的 `Lib/site-packages/*dist-info/`（Pillow、NumPy、PyAV、pyloudnorm 的 `licenses/`，SciPy 的 `LICENSE.txt`）。NumPy/SciPy/Pillow wheel 附带其他组件的许可也应随依赖保留，不能仅用表中主许可证替代。

PyAV 18.1.0 的 Windows wheel 实际链接 **FFmpeg 8.1.2**，从 `av._core.ffmpeg_version_info` 与 `library_meta` 核对，所有已链接 FFmpeg 库报告 **LGPL version 3 or later**。PyAV 的 BSD 许可不覆盖这些库。`av.library_versions` 为：libavutil 60.26.102、libavcodec 62.28.102、libavformat 62.12.102、libavdevice 62.3.102、libavfilter 11.14.102、libswscale 9.5.102、libswresample 6.3.102；实际结果 JSON 携带这些库版本。

项目只包含自身的适配器与依赖声明，不附带 wheel 或 DLL；Analyzer 环境属于本机开发环境，不进入正式游戏导出。如需分发这些二进制，需按具体 wheel 及 FFmpeg [官方许可说明](https://ffmpeg.org/legal.html) 保留其许可与相应源码获取方式，不能把整套依赖称为纯 BSD/MIT。

选择依据：这些版本在核对时有维护中的正式发布、Windows wheel、明确许可，可本地离线执行；适配器直接得到数组和数值，避免解析人类日志。依赖装在独立的 Analyzer 环境中，不改动项目其他工具使用的 Python 环境。五个包中 SciPy 是响度依赖，未引入服务器、数据库、原生自编译扩展或模型。

没有采用独立的 FFmpeg/ffprobe CLI：核对日 FFmpeg 官方最新版本为 9.0.2，但官方不提供自有的 Windows 可执行发行。PyAV 自带的库已满足解码需求，并省去独立可执行路径、日志解析和子进程管理。这里锁定的是 PyAV wheel 中的 8.1.2，**没有声称正在使用 FFmpeg 9.0.2**。相关能力均在 Adapter 中，未来可替换。

没有采用 librosa、OpenCV 或大型风格模型：基础指标不需要高级音乐/视觉分析。未以 NumPy 自行实现 BS.1770 或 LRA，响度交给已有成熟库。
