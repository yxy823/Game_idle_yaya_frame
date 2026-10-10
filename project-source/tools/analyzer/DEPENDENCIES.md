# Analyzer 依赖与许可记录

运行环境为 Windows x64 / CPython **3.13.16**，环境名 **yaya-analyzer**。九项运行依赖及传递依赖的版本以 [requirements.txt](requirements.txt) 为准；安装和配置见[准备与使用](README.md#准备与使用)。

| 依赖 | 固定版本 / 主许可证 | 用途 |
| --- | --- | --- |
| NumPy | 2.5.3 / BSD-3-Clause | 有界数组、直方图和颜色统计 |
| Pillow | 12.3.0 / MIT-CMU | 图像解码、像素模式转换和 PNG 输出 |
| scikit-image | 0.26.0 / BSD-3-Clause，另含 BSD-2-Clause/MIT 组件 | 四宫格灰度使用 rgb2xyz 的 Y |
| SciPy | 1.18.1 / BSD-3-Clause | scikit-image 的运行依赖 |
| networkx | 3.7 / BSD-3-Clause | scikit-image 的运行依赖 |
| imageio | 2.38.0 / BSD-2-Clause | scikit-image 的运行依赖 |
| tifffile | 2026.9.20 / BSD-3-Clause | scikit-image 的运行依赖 |
| packaging | 26.3 / Apache-2.0 OR BSD-2-Clause | scikit-image 和 lazy-loader 的版本支持 |
| lazy-loader | 0.6 / BSD-3-Clause | scikit-image 的延迟加载 |

依赖关系按安装包的 `*.dist-info/METADATA` 核对：scikit-image 声明 NumPy、SciPy、networkx、Pillow、imageio、tifffile、packaging 和 lazy-loader；imageio 依赖 NumPy/Pillow，SciPy 和 tifffile 依赖 NumPy，lazy-loader 依赖 packaging。维护夹具另需 jsonschema，不进入运行锁定文件。

版本检查只要求锁定文件中的包匹配，不卸载环境中的其他包。完整许可证保留在环境的 `Lib/site-packages/*dist-info/`。主许可证表不替代 wheel 内各组件的许可：NumPy 元数据另列有 0BSD、MIT、Zlib、CC0-1.0；NumPy/SciPy 的 OpenBLAS、LAPACK 和 GCC runtime 按随包许可及相应例外核对，Pillow 也保留附带组件许可。

项目包含自身实现和依赖声明，不附带 wheel 或 DLL。Analyzer 环境是本机开发工具，不进入正式游戏导出。依赖提供 Windows wheel，不需要本地编译链；分析运行时不下载模型或访问网络。

## 算法来源

色觉算法参考 `Studio Game Visual Analyzer/src/analyzer/metrics/accessibility.py:12–20` 和 `image_io.py:14–22`，该工具不是安装或运行依赖。

四宫格采用 Machado 2009 公布的 severity-1 矩阵（DOI：10.1109/TVCG.2009.113），以 NumPy 分块转换和排版，不复制外部程序代码。灰度使用 scikit-image 的 XYZ Y。图像基础统计和内存边界见[测量口径与限制](README.md#测量口径与限制)。
