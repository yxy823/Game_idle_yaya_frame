# Shader 的语言与结构

本页规定 Shader 的语言与阶段、特殊的 Shader 类别、include 的组织和性能要求，修改任何 Shader 时读。

Shader 只负责表现，不持有权威的玩法状态。语法和语义以 Godot 4.7 为准。

## 语言与阶段

- `shader_type` 和渲染模式与实际的节点、材质和渲染器一致。来自 Godot 3、`latest` 或 `master` 资料的语法和渲染模式，先对照 4.7 核实。
- 改渲染模式会改变渲染管线行为，按 README 的验证表做渲染验证。
- 局部变量在每条控制流路径上都先初始化再读取。注意：编译通过不代表未初始化的值在各 GPU 上表现一致。
- 阶段之间的自定义数据用 `varying` 传递。离散的 ID 或类别加 `flat`，避免被插值。

## Shader 类别

- **粒子**：`particles` Shader 的状态跨帧保留。改 `CUSTOM`、`USERDATA`、`keep_data` 或开始与重启逻辑时，运行多帧并在重启后再检查。
- **天空**：使用 `TIME`、`LIGHT0_*`–`LIGHT3_*` 或 `use_half_res_pass`、`use_quarter_res_pass` 会增加辐照度立方体贴图的更新开销。引入这些用法时检查开销。
- **雾**：`fog` Shader 只作用于 FogVolume，需要启用 `Environment.volumetric_fog_enabled`。注意：体积雾只在 Forward+ 中支持。
- **texture_blit**：供 `DrawableTexture2D.blit_rect()` 使用（实验性 API）。入口函数是 `blit()`，内置变量只有 `UV`、`FRAGCOORD`、`MODULATE`、`TIME` 和输出 `COLOR0`–`COLOR3`，没有 CanvasItem 的 `TEXTURE`、`VERTEX`。

## Include

- 多个 Shader 共用的稳定逻辑才提取为 `.gdshaderinc`；不为一两行表达式建 include。
- include 之间不成环。函数和宏使用带语义前缀的名称，避免重复定义。
- 嵌套 include 超过 25 层时预处理器报错。保持 include 链浅。
- 修改、重命名或移动 include 时，同步所有 `#include` 路径，并重新编译每个直接和传递使用它的 Shader。

## 性能与首次使用卡顿

- 循环的终止必须可证明。由 uniform 控制次数的循环，用 `hint_range` 或 `clamp` 给次数设上界。
- 不加 `lowp`、`mediump` 做优化：它们主要影响移动端，本框架只做 Windows PC。
- `discard` 用于镂空和遮罩，不当作 alpha 为零时的性能优化。
- 屏幕纹理、`next_pass` 和大量采样的开销取决于覆盖面积、实例数量和硬件。需要性能结论时实测。
- 预加载 Resource 不会编译它的渲染管线。首次使用的卡顿有影响时，实测首次绘制。
