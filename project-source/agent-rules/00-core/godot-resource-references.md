# Godot 资源与身份引用

本页规定业务 ID、Resource UID、路径、NodePath 与运行时身份怎样区分，以及怎样修改资源引用和场景引用。选择或修改业务 ID、Resource UID、资源路径、NodePath、`%UniqueName` 或场景引用时读。

不同的身份域分开使用。它们之间可以建立映射，但不能互相替代。

## 身份域

| 身份 | 含义 | 不能用作 |
| --- | --- | --- |
| 业务 ID | 存档、数据引用、命令、回放和迁移中持久的玩法身份 | — |
| Resource UID（`uid://`） | Godot 的 Resource 身份 | 业务 ID |
| `res://`、`user://` 路径 | 文件位置；schema 明确定义路径语义时除外 | 逻辑身份 |
| NodePath、`%UniqueName` | SceneTree 中的结构关系 | 持久的玩法身份 |
| `.tscn` 中 Node 的 `unique_id`（Godot 4.6 起写入） | 场景序列化身份 | 业务 ID、存档 ID、运行时查找键 |
| RID、Object 实例 ID | 当前会话内的运行时身份，两者互不替代 | 任何持久化或跨会话的身份 |

- 不用一个含糊的 `id: String` 同时承载业务 ID、UID、路径和 NodePath。字段名、API 名和类型要表明身份域。
- 每个身份域用自己的方式验证。笼统的“ID 存在”检查不能代替业务引用、资源、场景或运行时的验证。

## 资源引用

- 不编造、复制、重新编号或手工修补 Resource UID 或 Node 的 `unique_id`，即使只为外观一致。
- UID 与路径之间的转换使用 `ResourceUID` 和 `ResourceLoader` 的 API，不做字符串替换、拼接或猜测。
- 注意：Godot 4.7 中，`@export_file` 在文件有 UID 时保存 `uid://` 字符串。需要原始路径时改用 `@export_file_path`；读取 `@export_file` 的值时，不假设它以 `res://` 开头。
- UID 能解析只证明身份有效，不能代替对 Resource 类型、schema 或消费方的验证。
- 不机械地把 `res://` 字符串全部迁移成 `uid://`，也不把 UID 全部改回路径。按值的含义是资源身份还是位置来选。
- 移动或重命名文件不会改变业务 ID。业务 ID 迁移与文件或资源迁移是两件独立的事。
- 建议：编辑器中设置的已知静态依赖，用带类型的 Resource 或 PackedScene 导出，不用裸 String 路径加 `load()`。

## 场景引用

- 重命名 Node 或更换其父节点是一次引用迁移，会影响序列化的 NodePath、动画轨道、信号连接、脚本引用、继承场景中的覆盖和其他消费方。
- `%UniqueName` 的作用范围是它所在的场景及其 owner。重命名或移除已被使用的唯一名，就是修改场景内的引用 API。
- 删除或重命名脚本的方法、属性或信号前，搜索它的字符串引用：`.tscn` 中的 `[connection ... method="…"]`、`.tres`、`call("…")`、`Callable(obj, "…")`、`has_method("…")` 和存档字段。这些引用在编辑器中不报错，运行到才失败。
- 建议：关键子节点用带类型的导出 Node 引用或 `%UniqueName` 访问，不用递归 `find_child()` 掩盖结构依赖。
