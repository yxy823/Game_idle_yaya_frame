# 20 场景（`.tscn`）规则

`.tscn` 文件是序列化的 Godot 场景状态，不是可以随意编辑的普通文本。

| 文档 | 何时阅读 |
| --- | --- |
| `structure-and-ownership.md` | 编辑序列化的场景状态、节点层级或 owner 归属 |
| `instancing-inheritance-and-overrides.md` | 修改场景实例、继承场景或实例上的本地覆盖 |
| `references-groups-and-order.md` | 修改 ExtResource 或 SubResource 的 ID、Node 的 `unique_id` 值、NodePath、唯一名、分组、节点名或同级顺序 |
| `ui-and-scripts.md` | 修改 UI 布局或焦点、脚本绑定或信号连接 |
| `validation.md` | 任何场景修改：确定需要哪些验证 |

项目规则不单凭行数、节点数或树深度拆分场景。
