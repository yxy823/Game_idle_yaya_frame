# Shader 的 Uniform 与材质契约

uniform 是跨文件的 API：材质、场景、脚本、动画轨道和项目配置都按名称引用它。

## 材质 uniform

- 改 uniform 的名称、类型或含义时，迁移每个使用它的材质、场景、脚本、AnimationPlayer 轨道和工具。
- `set_shader_parameter()` 的参数名区分大小写，与 Shader 中的 uniform 名完全一致，不是检查器中首字母大写的显示名。传入值的类型与 uniform 类型对应。
- 注意：修改 ShaderMaterial 的 uniform 会影响所有共用这个材质的对象。
- 给 uniform 提供安全的默认值，并按它的用途加 hint。`source_color` 的用法见[颜色与 Alpha](coordinates-sampling-and-color.md#颜色与-alpha)。
- 建议：逐对象不同的值用实例 uniform，不为每个对象复制 ShaderMaterial；整个项目共享的值用全局 uniform。

## 实例 uniform

- `instance uniform` 只能用于 `canvas_item` 和 `spatial` Shader，不支持采样器、矩阵和数组，每个 Shader 最多 16 个。
- 网格有多个材质时，各材质中同一实例 uniform 的名称、索引和类型必须都相同，否则只有先找到的材质的参数生效。冲突时用 `instance_index(n)`（0–15）指定索引。
- Compatibility 渲染器中，采样器数组只能用编译期常量做索引。用实例 uniform 选择纹理时，用 `switch` 分支逐个采样。

## 全局 uniform

- 全局 uniform 在 ProjectSettings 的 Shader Globals 中声明名称、类型和默认值。Shader 中给 `global uniform` 写的默认值会被忽略。
- 编辑器保存 Shader 时，该全局 uniform 必须已在项目设置中存在且类型一致，否则编译失败。全局 uniform 不支持数组。
- 项目设置中的 `color` 与 `vec4` 是不同的类型（`color` 会额外保存线性值），按语义选择，不互换。
- 全局 uniform 只放整个项目或环境共享的数据，不放单个对象的状态。
- 建议：静态的全局 uniform 在项目设置中声明，不在启动时用 `RenderingServer.global_shader_parameter_add()` 动态添加。
- 重命名、删除全局 uniform 或修改其类型时，迁移每个使用它的 Shader、脚本、场景和材质。
- 场景树中只有树顺序上的第一个 `ShaderGlobalsOverride` 生效，它被移除后恢复项目级的值。多个系统需要临时覆盖时，由一个协调者管理唯一的 `ShaderGlobalsOverride`。

## 时间与权威值

- 内置 `TIME` 按 `Engine.time_scale` 缩放后的帧步长增加，不随 SceneTree 暂停而停止，超过 `rendering/limits/time/time_rollover_secs`（默认 3600 秒）后回到 0。它只用于视觉动画。
- 视觉时间需要随暂停停止、可确定回放或与玩法时钟同步时，用自定义的时间 uniform 从 CPU 传入。
- CPU 和 GPU 都需要的值，权威保存在 CPU 一侧再上传给 Shader。不回读 GPU 结果或全局 uniform 作为玩法状态。
