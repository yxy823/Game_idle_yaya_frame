# Shader 验证

- **[必须]** 用目标 Godot 4.7 实际的 Shader 编译器编译；正则或第三方文本解析不算充分。
- **[必须]** 通过真实的 ShaderMaterial、Node 和渲染路径验证，不只验证孤立的源码。
- **[必须]** 渲染器、HDR 2D、视口、图集和导入设置属于效果契约时，验证这些设置。
- **[必须]** 读取屏幕的 Shader 要验证真实的后台缓冲和采样路径，包括 2D 场景树顺序、`BackBufferCopy` 的区域行为，以及 3D 不透明与透明的捕获边界。仅 Shader 编译成功不算充分。

include 使用方和粒子状态按 `includes-and-reuse.md` 与 `language-and-structure.md` 的说明验证。渲染证据遵循[视觉验证边界](../70-tests/testing-strategy.md#视觉验证边界)。
