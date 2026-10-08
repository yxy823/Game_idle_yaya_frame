# 21 Resource（`.tres` / `Resource`）规则

| 文档 | 何时阅读 |
| --- | --- |
| [roles-sharing-and-locality.md](roles-sharing-and-locality.md) | 任何 Resource 修改，包括新增或修改 `game/<对象>/tuning/` 下的调参资源 |
| [identity-saving-and-schema.md](identity-saving-and-schema.md) | 移动、重命名或保存 Resource，生成 `.tres`，修改自定义 Resource 的导出属性、默认值、`class_name` 或 `_init()`，收尾调试台的采纳 |

## 验证

| 改动 | 需要的验证 |
| --- | --- |
| 任何 `.tres` 或 Resource 脚本修改 | 用 Godot 4.7 加载改动的 Resource，检查 UID 与路径、Resource 类型或自定义类型、导出值、必填字段、不变量和依赖 |
| 修改类、属性、默认值或 schema | 加载所有受影响的仓库 Resource，并检查有代表性的消费方 |
| 复制 Resource 的代码 | 测试副本中的共享与复制关系，见[复制](roles-sharing-and-locality.md#复制) |
| 生成或保存 Resource | 按[保存](identity-saving-and-schema.md#保存)一节重新加载并检查 |
| 行为变化 | 运行测试追溯与证据中[测试影响评估](../../methodology/08-test-traceability-and-evidence.md#测试影响评估)选定的范围：Required、affected 或 full |
