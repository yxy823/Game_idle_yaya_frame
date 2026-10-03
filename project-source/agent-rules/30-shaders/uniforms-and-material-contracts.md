# Shader 的 Uniform 与材质契约

uniform 是公开 API，由 Shader、材质和 Resource、场景、脚本、动画及项目配置共同使用。

## Uniform API

- **[必须]** uniform 的名称、类型或含义改变时，迁移每一个使用它的材质、场景、脚本、AnimationPlayer 和工具。
- **[必须]** `set_shader_parameter()` 调用与 Shader uniform 的名称完全一致，类型兼容。类型不匹配可能不会产生正常报错，并可能导致未定义行为。
- **[必须]** 提供安全的默认值和有意义的 hint。`source_color` hint 遵循[色彩空间](color-alpha-and-blending.md#色彩空间)。
- **[优先]** 材质自身的值用材质 uniform；真正逐实例的值在支持时用实例 uniform；确实在整个项目或环境中共享的值用全局 uniform。
- **[必须]** 逐实例 uniform 只支持 `canvas_item` 和 `spatial` Shader，不支持纹理和数组，每个 Shader 实际最多 16 个。
- **[必须]** 3D 网格上有多个材质时，检查各材质中对应的逐实例 uniform 名称、类型和实例索引一致。
- **[复核]** Compatibility 渲染器中用实例数据动态索引采样器数组的路径，需要针对该渲染器验证；其他渲染器支持不能作为这里支持的证据。
- **[必须]** 全局 uniform 在 ProjectSettings 的 [Shader 全局变量](../40-project-config/shader-globals.md) 中声明；不能依赖 Shader 声明里写的默认值。
- **[必须]** 不要把玩法架构建立在 CPU 高频回读 GPU 或全局 uniform 状态之上。

## 时间与权威值

- **[必须]** 内置的 `TIME` 是引擎的视觉时间，有自己的回绕和时间缩放语义。不要用它做权威的暂停、回放或玩法时钟。
- **[优先]** 确定性的视觉时间或与暂停相关的视觉时间属于契约时，使用明确的自定义时间 uniform。
- **[必须]** CPU 和 GPU 都需要一个权威值时，所有权留在 CPU 或领域一侧，把值上传给 Shader；不要把 Shader 状态回读作为权威。
