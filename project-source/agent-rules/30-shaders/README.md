# 30 Shader 规则

适用于 Godot 4.7 下手写的 `.gdshader` 和 `.gdshaderinc` 文件。

Shader 没有行数上限。按独立的视觉职责、复用需求和验证需求拆分 Shader。

| 文档 | 何时阅读 |
| --- | --- |
| `language-and-structure.md` | 编写或修改任何 Shader：`shader_type`、渲染模式、处理函数、varying，以及粒子、天空、雾和 `texture_blit` Shader |
| `uniforms-and-material-contracts.md` | 新增或修改 uniform、材质参数、实例 uniform、`set_shader_parameter()` 调用或 Shader 时间 |
| `coordinates-and-sampling.md` | 处理 UV、屏幕、像素或纹素坐标，图集与区域，过滤，mipmap，顶点变换，或屏幕与后台缓冲采样 |
| `color-alpha-and-blending.md` | 修改色彩空间处理、`source_color`、CanvasItem `COLOR`、alpha、混合模式或 Spatial `ALPHA` |
| `performance-and-stability.md` | 修改循环、采样开销、分支与变体、精度、材质复用，或处理首次使用时的编译卡顿 |
| `includes-and-reuse.md` | 新增、修改、重命名或移动 `.gdshaderinc` |
| `validation.md` | 任何 Shader 修改：确定需要做哪些验证 |

在 ProjectSettings 中声明的全局 Shader uniform 遵循 [Shader 全局变量](../40-project-config/shader-globals.md)。

## 可选的方法参考

上面的规则规定工程约束。下列技术参考的思路对当前问题有帮助时再读；路径相对于项目根目录。

| 当前需要 | 参考 |
| --- | --- |
| 选择 Shader 方案、坐标或数据流，或权衡渲染取舍 | `.agents/skills/implementation-guidance-godot/references/shader-implementation-methods.md` |
| 排查 Shader 加载、材质与参数绑定、视觉数据流或渲染开销 | `.agents/skills/bug-diagnosis-godot/references/shader-diagnostics.md` |

每份参考都可以在已获授权的开发、指导、诊断或原型工作中单独阅读。阅读它只提供技术思路，当前任务仍保持自己的授权和验证范围。阅读参考不会启动其所属 Skill 的工作流程，也不会创建 Feature、请求 advisor，或允许运行、编辑、修复任何内容。
