# Shader 全局变量

全局 Shader uniform 是项目级的 GPU API。本文负责它们在 ProjectSettings 中的声明；Shader 一侧的 uniform 规则见 [Shader 的 Uniform 与材质契约](../30-shaders/uniforms-and-material-contracts.md)。

## 全局变量

- **[必须]** 持久的全局 uniform 的名称、类型和默认值由项目配置定义。Shader 一侧的回退值或默认值不能代替项目声明。
- **[必须]** 重命名、删除全局 uniform 或修改其类型时，迁移每一个使用它的 Shader、脚本、场景和材质。
- **[必须]** 在项目 API 或全局 API 中，不要随意把 Color 和 vec4 当作语义可互换。
- **[必须]** 全局 uniform 只用于确实在整个项目或环境中共享的数据，不用于为单个对象图方便的状态。
- **[必须]** CPU 和 GPU 都需要一个值时，权威留在 CPU 一侧，见[时间与权威值](../30-shaders/uniforms-and-material-contracts.md#时间与权威值)。
- **[优先]** 静态的全局 uniform 在项目配置中声明，不在正常启动时动态添加。
- **[优先]** 合适时，用 `ShaderGlobalsOverride` 表达临时覆盖或场景局部覆盖。
- **[必须]** 只有 SceneTree 顺序中的第一个 `ShaderGlobalsOverride` 生效；相互独立的系统不能通过多个覆盖悄悄争用。
- **[必须]** 多个场景或系统需要临时覆盖时，由单一的协调负责方管理，并验证移除它后会恢复项目级的全局值。
