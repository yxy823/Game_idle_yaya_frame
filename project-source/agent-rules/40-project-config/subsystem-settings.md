# 子系统设置

只读要修改的子系统对应的小节。

## 音频

- 音频总线名称是跨文件的 API。重命名或删除总线时，迁移使用它的播放器、代码、动画和混音设置。注意：播放器指定的总线不存在时会静默回退到 Master，迁移遗漏不会明显报错。
- `audio/buses/default_bus_layout` 指向的 Resource 必须能加载。
- 配置的驱动、混音采样率和延迟不一定是运行时的实际状态。行为依赖它们时，在运行时从 AudioServer 读取确认。

## 物理

- 不要为了让测试更快而修改 `physics/common/physics_ticks_per_second`。修改它时，检查阻尼与手感的变化，并在渲染帧率低时检查 `physics/common/max_physics_steps_per_frame`。
- 开关物理插值、更换物理后端或在独立线程运行物理时，检查移动、相机和跨线程访问物理的代码。

## 本地化

- 翻译文件只有登记在 `internationalization/locale/translations` 中才会在运行时生效。
- 显式设置 `internationalization/locale/fallback`，不碰巧依赖英语或编辑器的语言区域。
- 注意：`internationalization/locale/test` 也作用于导出的项目。只在编辑器中测试某个语言区域时，用 `editor` feature 覆盖（`internationalization/locale/test.editor`）。
- 翻译重映射把源资源和各语言区域的资源绑在一起，迁移时一起改。

## 渲染器与 HDR

- 配置的渲染器不一定是运行时实际使用的（驱动不可用时可能回退）。行为依赖渲染器时，在运行时确认。
- 不要只为了简化某个 Shader 或效果而更换项目的渲染器。
- HDR 2D 改变所有 Shader 和颜色的结果。开关它时做有代表性的渲染验证。

## 视口、窗口与拉伸

- **显示基线由项目决定**：基础视口尺寸、拉伸模式与宽高比处理、渲染器合称显示基线，按 GDD 的美术风格和目标显示器比例选择（平台固定为 Windows PC），在第一个 Feature 开工前确定，因为界面骨架和调试台中的视觉决策都按它检查。新项目的默认值（1600×900、`canvas_items`、`expand`，渲染器未设置即 Forward+）只是起点，不代表已经决定。决定写进 `docs/architecture.md` 的“独立技术决定”；渲染器的选择满足 ADR 条件时写成 ADR（见 `yaya/methodology/10-architecture-overview.md`）。常见取舍：界面多、要适配多种窗口的游戏用 `canvas_items` + `expand`；像素风用 `viewport` 加整数缩放；2D 游戏优先考虑 Compatibility 渲染器，需要 Forward+ 专有效果时再换。决定时写明三项各自的选择和理由；渲染器即使保留默认的 Forward+，也写出与 Compatibility 比较后的理由，不写“沿用默认”。
- 基础视口尺寸（`display/window/size/viewport_width`、`viewport_height`）与初始窗口尺寸是不同的设置。
- 明确设置拉伸模式和宽高比处理，并同时检查世界相机和 UI。
- 像素完美输出由视口、拉伸、导入、采样和布局共同决定。变换的像素吸附、顶点的像素吸附和 UI 的像素吸附是三个独立的设置。
- 玩家的窗口偏好通过运行时 API 保存到 `user://`，不改写 `project.godot`。

## 分组与层

- 自定义全局分组名使用稳定的 `snake_case`。注意：在项目设置中声明全局分组不会把任何节点加入分组。
- 物理层、导航层和避障层各有 32 个，2D 与 3D 渲染层各有 20 个。各类层的命名空间相互独立。
- 重命名层只改显示名。改变层的用途或移动它的位是迁移，要更新所有场景和代码；`collision_layer` 和 `collision_mask` 分别处理。
- 代码中的层号使用项目定义的命名常量。
- 清除层的显示名不能证明该位未被使用；搜索场景和代码后再复用。
