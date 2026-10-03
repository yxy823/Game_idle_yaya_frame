# Shader 的坐标、采样与颜色

每个坐标和像素尺寸都写明所在的空间；色彩空间、alpha 表示和混合模式属于渲染契约。

## 坐标与区域

- UV、`SCREEN_UV`、渲染像素、窗口像素和纹素之间不直接混用，换算写在代码里。
- `TEXTURE_PIXEL_SIZE` 只对应内置的 `TEXTURE`。自定义采样器的纹素尺寸用 `textureSize()` 计算或用 uniform 传入。
- 像素完美显示由视口、拉伸和整数缩放决定（见[视口、窗口与拉伸](../40-project-config/subsystem-settings.md#视口窗口与拉伸)），不在 Shader 中加吸附补丁。
- 使用 `skip_vertex_transform` 或 `world_vertex_coords` 时，注明 `VERTEX` 和下游 varying 所在的空间。
- 启用区域的 Sprite2D 中，`UV` 是整张纹理的 UV。只处理区域的效果用 `REGION_RECT` 换算：它是归一化的 `(x, y, width, height)`，只能在 `canvas_item` 的 `fragment()` 中读取。偏移采样时把坐标限制在区域或图集单元内。

## 过滤与 Mipmap

- 像素画的过滤与 mipmap 选择见[像素画的过滤与 mipmap](../60-assets/textures-and-images.md#像素画的过滤与-mipmap)。采样器的 `filter_*`、`repeat_*` hint 是效果契约的一部分。
- 用 `textureLod()` 读取更高的 LOD 时，确认该纹理导入时生成了 mipmap。
- 调色板查找和精确颜色查找用 `texelFetch()`，或关闭过滤和 mipmap，并验证颜色索引没有被插值或压缩改变。

## 屏幕纹理与后台缓冲

- 2D：第一个使用 `hint_screen_texture` 的节点绘制前，Godot 自动把全屏复制到后台缓冲，之后的节点不再触发复制；树顺序上更早已有启用的 `BackBufferCopy` 时不自动复制。重叠的屏幕效果需要看到前一个的结果时，在两者之间放 `BackBufferCopy`。
- `BackBufferCopy` 只复制一个区域时，在区域外读取屏幕纹理的结果未定义。
- 3D：屏幕纹理在不透明通道之后、透明通道之前捕获，透明物体不在其中。读取 `hint_screen_texture`、`hint_depth_texture` 或 `hint_normal_roughness_texture` 的材质本身走透明管线，也不出现在其他材质的屏幕纹理中。

## 颜色与 Alpha

- sRGB 颜色纹理和颜色 uniform 标 `source_color`。数据纹理、遮罩、法线、LUT 和索引纹理不标。
- 没有明确的色彩空间理由时，不加 `pow()` 之类的 gamma 补丁；alpha 不做 gamma 变换。
- 改写 CanvasItem 的 `COLOR` 时，有意保留或绕过纹理颜色和 `modulate`、`self_modulate` 的效果。
- 预乘 alpha 的颜色用 `blend_premul_alpha`，不对 RGB 重复预乘。
- 透明边缘有瑕疵时，同时检查导入、过滤、图集留边、alpha 和混合模式，不只改 Shader。
- Spatial Shader 中读或写 `ALPHA` 都会让材质进入透明管线，即使始终写入 `1.0`。例外：同时使用 `ALPHA_SCISSOR_THRESHOLD` 或 `ALPHA_HASH_SCALE`、且不使用 `ALPHA_ANTIALIASING_EDGE` 时走 alpha 裁剪。
- 只在需要透明时使用 Spatial `ALPHA`，并检查排序、阴影、深度写入和屏幕纹理中的可见性。
