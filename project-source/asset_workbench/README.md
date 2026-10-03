# 资源工作台

资源工作台是开发期工具，用于在 Godot 中预览、试调和比较图像、音频、Shader、粒子与动画，并按需分析源文件。它不属于正式游戏内容，正式导出时排除 `ui/` 与 `analyzer/`；`examples/` 只有在正式场景不再引用时才能排除。

| 目录 | 内容 | 入口 |
| --- | --- | --- |
| `ui/` | 候选浏览、试调、保存与分析窗口的 GDScript 界面；不注册全局服务 | 由示例工作台场景加载 |
| `analyzer/` | 可选的源文件分析后端（Python），独立于音频播放，不写回 Cue | [Analyzer 说明](analyzer/README.md)，依赖与许可见 [DEPENDENCIES.md](analyzer/DEPENDENCIES.md) |
| `examples/` | 四个可运行的工作台与消费场景、示例 Cue、预设和素材 | [示例说明](examples/README.md) |

工作台与示例共用的表现组件位于 `components/feedback/`，见[表现反馈组件](../components/feedback/README.md)。
