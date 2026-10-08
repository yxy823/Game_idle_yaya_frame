# 20 场景（`.tscn`）规则

`.tscn` 是 Godot 序列化的场景状态。结构性编辑优先在 Godot 编辑器或结构化工具中完成；文本补丁只用于语义明确的小改动，并且要通过下面的验证。

| 文档 | 何时阅读 |
| --- | --- |
| [structure-and-ownership.md](structure-and-ownership.md) | 任何 `.tscn` 修改 |
| [references-groups-and-order.md](references-groups-and-order.md) | 新增、复制、重命名或移动节点，修改 NodePath、`%UniqueName`、分组、同级顺序，或直接编辑 `.tscn` 文本 |
| [ui-and-scripts.md](ui-and-scripts.md) | 修改 Control 布局或焦点、挂载脚本或连接信号 |

## 验证

| 改动 | 需要的验证 |
| --- | --- |
| 任何场景修改 | 用 Godot 4.7 加载并实例化改动的场景：依赖与 UID 能解析，挂载的脚本能编译且基类型匹配，NodePath 能解析，`_enter_tree()` 和 `_ready()` 不报错；能解析但实例化失败不算通过 |
| 用编辑器或工具保存 | 检查差异中没有无关的序列化重排、ID 变化或格式化 |
| 修改实例、继承场景或 Editable Children 的覆盖 | 保存并重新加载后，检查源场景和有代表性的派生场景或实例消费方的实例身份、owner 和覆盖 |
| 重命名、移动节点或修改 `%UniqueName` | 检查[NodePath 与重命名](references-groups-and-order.md#nodepath-与重命名)列出的每类引用 |
| 修改焦点流程 | 检查[焦点与模态对话框](ui-and-scripts.md#焦点与模态对话框)列出的打开、关闭、再次打开和焦点目标消失的情况 |
| 修改所有权、实例化、更换父节点或节点释放 | 运行时在 Remote 场景树和 Monitors 的 Orphan Nodes 中确认没有残留节点 |
| 行为变化 | 运行测试追溯与证据中[测试影响评估](../../methodology/08-test-traceability-and-evidence.md#测试影响评估)选定的范围：Required、affected 或 full |

建议：可复用的独立场景，额外用“运行当前场景”（F6）单独运行。单独运行失败时，区分两种原因：

- 隐藏的、未声明的依赖：这是场景缺陷，改为显式依赖。
- 场景声明的公共依赖没有被提供：用能提供依赖的最小测试场景验证，不为了单独运行而加入隐藏的 `/root/...` 路径。
