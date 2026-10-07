# 调试台图标

调试窗口只用这里的线框图标，按钮通过 `Button.icon` 显示，颜色由 [debug_theme.tres](../debug_theme.tres) 的 `icon_*_color` 着色；其他位置用 `TextureRect.modulate` 着色。

## 来源与许可

- 除下面两个滑块文件外，其余 SVG 来自 [Tabler Icons](https://tabler.io/icons) 3.49.0 的 `icons/outline/`，下载地址形如 `https://cdn.jsdelivr.net/npm/@tabler/icons@3/icons/outline/<名称>.svg`。许可为 MIT，原文见同目录 [LICENSE](LICENSE)。
- 下载后只把 `stroke="currentColor"` 改成 `#ffffff`，让主题颜色能直接乘到白色线条上；路径与尺寸未改。
- `slider-grabber.svg` 与 `slider-grabber-disabled.svg` 是本项目画的滑块圆点，不属于 Tabler。

## 增加图标

1. 按上面的地址只下载要用的图标，同样把 `currentColor` 改成 `#ffffff`。
2. 运行一次 `--headless --import` 生成 `.import`，再在代码中用 `ui_kit.gd` 的 `Kit.icon("<名称>")` 引用。
