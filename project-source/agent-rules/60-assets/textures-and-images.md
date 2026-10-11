# 纹理与图像

## 用途

- 先按用途给纹理分类：普通颜色、像素画、调色板或查找表、数据（遮罩、通道打包）、法线、HDR、SVG，或需要在 CPU 上读取像素。压缩、mipmap、过滤和 alpha 处理都按用途决定。
- 建议：2D 颜色纹理和像素画使用无损压缩，即 2D 预设默认的 `compress/mode = Lossless`。改用有损或 VRAM 压缩前，确认画质可以接受。

## 像素画的过滤与 mipmap

本节是项目中像素画过滤与 mipmap 规则的唯一正文。

- 注意：Godot 4 的纹理导入设置里没有过滤选项。2D 过滤由使用方的 `CanvasItem.texture_filter` 决定；设为 Inherit 时沿父节点继承，最终取项目设置 `rendering/textures/canvas_textures/default_texture_filter`，默认是 Linear。
- 像素画不等于全局最近邻。需要最近邻的节点或子树单独设置 `texture_filter`。只有绝大多数 2D 内容都需要最近邻时，才修改项目默认值，再给需要平滑缩放的内容单独设回 Linear。
- `mipmaps/generate` 在 2D 预设中默认关闭。只有纹理会被明显缩小显示时才开启，例如 Camera2D 缩小、节点缩放，或高分辨率源图在 TextureRect 里缩到小尺寸；按原尺寸或整数倍放大显示的像素画和 UI 保持关闭。
- 注意：2D 只开 `mipmaps/generate` 不会生效，因为默认的 Linear 过滤不读 mipmap。还要把使用方的 `texture_filter` 设为 Linear Mipmap（`TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`）。
- 调色板、查找表和索引纹理使用最近邻采样，不生成 mipmap，避免插值改变颜色值。
- 像素完美的显示还取决于视口、拉伸模式和整数缩放等项目设置，不靠单个纹理的设置解决。

## CPU 读取

- 注意：`Texture2D.get_image()` 从 GPU 回读数据，不在每帧或其他高频路径中调用。
- 需要经常在 CPU 上读取像素时，把素材的 Import As 设为 `Image`，或在加载时缓存一份 `Image`。

## 特殊数据

- `process/fix_alpha_border` 默认开启，会改写透明像素的颜色值。遮罩和数据纹理需要原始颜色值时关闭它。
- 开启 `process/premult_alpha` 时，使用该纹理的 CanvasItem 同时改用预乘混合：`CanvasItemMaterial` 设为 `BLEND_MODE_PREMULT_ALPHA`，自定义 Shader 使用 `render_mode blend_premul_alpha;`。
- Godot 的法线贴图使用 OpenGL 约定（Y+）。DirectX 风格（Y-）的法线贴图，把 `process/channel_remap/green` 设为 Inverted Green；`process/normal_map_invert_y` 已弃用。
- 通道打包的纹理写明每个通道的含义。
- PNG 不是 HDR 格式。HDR 源使用 `.exr` 或 `.hdr`。

## 缩放与 SVG

- `process/size_limit` 用三次插值重采样，会破坏像素。不对像素画、调色板、遮罩、图集或查找数据启用。
- 素材已由外部工具裁成精确尺寸时，以该工具的输出为准，不用导入时的缩放代替。
- SVG 按 `svg/scale` 光栅化为位图。需要更大的显示尺寸时，调高 `svg/scale` 后重新导入，不放大节点。
- 建议：SVG 中的文字先在绘图工具中转为路径，再导入。
