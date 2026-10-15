# 30 Shader 规则

适用于 Godot 4.7 下手写的 `.gdshader` 和 `.gdshaderinc`。

| 文件 | 何时阅读 |
| --- | --- |
| `language-and-structure.md` | 任何 Shader 修改都读：`shader_type`、渲染模式、varying、粒子、天空、雾和 `texture_blit` Shader、include、性能与首次使用卡顿 |
| `uniforms-and-material-contracts.md` | 新增、修改或删除 uniform（含实例 uniform 和全局 uniform），调用 `set_shader_parameter()`，使用 `ShaderGlobalsOverride` 或 `TIME` |
| `coordinates-sampling-and-color.md` | 处理 UV、屏幕或纹素坐标、图集区域、顶点变换、过滤与 mipmap、屏幕纹理与后台缓冲，或修改 `source_color`、`COLOR`、`ALPHA`、混合模式 |

## 方法参考

需要技术思路时可以读下列参考（路径相对于项目根目录）。阅读参考不启动所属 Skill 的流程，也不扩大当前任务的授权和验证范围。

| 当前需要 | 参考 |
| --- | --- |
| 选择 Shader 方案、坐标或数据流，权衡渲染取舍 | `.agents/skills/implementation-guidance/references/shader-implementation-methods.md` |
| 排查 Shader 加载、材质与参数绑定、视觉数据流或渲染开销 | `.agents/skills/bug-diagnosis-godot/references/shader-diagnostics.md` |

## 验证

编译成功只证明语法和类型正确。渲染证据的边界见[视觉验证边界](../70-tests/test-levels.md#视觉验证边界)。

| 改动类型 | 需要的验证 |
| --- | --- |
| 任何 Shader 修改 | 用 Godot 4.7 编译：在编辑器中打开或运行用到它的场景，读取编译错误；正则或第三方解析不算 |
| 渲染模式、混合、alpha、坐标或颜色 | 在真实的 ShaderMaterial、节点和项目渲染器下运行，按视觉验证边界留下渲染证据 |
| 屏幕空间效果 | 另换一种分辨率或放进 SubViewport 运行；读屏幕纹理时，2D 检查场景树顺序和 `BackBufferCopy` 区域，3D 检查不透明与透明的捕获边界 |
| `.gdshaderinc` 修改、重命名或移动 | 重新编译每个直接和传递引用它的 Shader |
| 粒子 Shader | 运行多帧，并在重启粒子后再检查 |
| 效果依赖渲染器、HDR 2D、视口、图集或导入设置 | 在项目实际使用的这些设置下运行 |
| uniform 改名、改类型或删除 | 搜索并确认材质、场景、脚本和动画轨道已迁移，运行使用它们的场景 |
