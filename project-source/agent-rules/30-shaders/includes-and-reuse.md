# Shader 的 Include 与复用

用 `.gdshaderinc` 承载稳定的共享 Shader 逻辑，但不要拆出一堆细碎的 include。

## Include

- **[优先]** 多个 Shader 确实共用稳定的逻辑，或属于一个连贯的工具领域时，提取为 `.gdshaderinc`。
- **[必须]** 不要创建一次性的细小 include 片段，以免 Shader 行为比重复几处简单表达式还难追踪。
- **[必须]** include 依赖图中不能有环。
- **[必须]** 各 include 中的函数和宏使用稳定、带语义前缀的名称，避免符号冲突；重复定义不是受支持的复用方式。
- **[必须]** include 链的深度明显低于 Godot Shader 预处理器的上限 25。不要构建接近该上限的依赖链。
- **[必须]** include 文件的名称和职责要有语义且保持稳定。
- **[必须]** 修改一个 include，等于修改它的每一个传递使用方。重新编译并验证每个直接和传递使用它的 Shader。
- **[必须]** 重命名或移动 include 是跨 Shader 的依赖迁移；只解析 include 本身不算充分验证。
