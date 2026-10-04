# 场景引用、分组、ID 与顺序

Resource UID、场景节点的 `unique_id`、NodePath 和 `%UniqueName` 的身份规则见 [Godot 资源与身份引用](../00-core/godot-resource-references.md)。本页只补充 `.tscn` 文件内的要求。

## 序列化 ID

- `ExtResource` 和 `SubResource` 的 ID 是文件内的引用标识，不为美观复制或重新编号。SubResource 的先后顺序跟随依赖关系，不手工重排。
- Godot 4.6 起，`.tscn` 的 `[node]` 条目带有 `unique_id`；保存场景时，Godot 给缺少或重复该值的节点分配新值。手工编辑文本时不改写、不重新编号已有的值。复制 `[node]` 条目时删去复制来的 `unique_id`，不自己编造新值。没有 `unique_id` 的节点合法，不手工补填。
- 以文本方式修改 `.tscn` 后，用 [`resave_godot_files.gd`](../../tools/README.md#resave_godot_filesgd) 重新保存一次，让文件与编辑器保存的格式一致。
- Godot 4.6 起，场景和资源文件头不再写 `load_steps`，加载时也不读取它。不手工添加或维护 `load_steps`。

## NodePath 与重命名

重命名节点或更换父节点是一次[场景引用迁移](../00-core/godot-resource-references.md#场景引用)。在 `.tscn` 中检查：

- NodePath 属性和 `node_paths` 列表；
- 动画轨道路径；
- `[connection]` 条目中的 `from` 和 `to`；
- 子节点的 `parent` 路径和 owner；
- 继承场景和实例上的覆盖；
- 代码中的 `$`、`%` 和 `get_node()` 路径。

给节点启用 `unique_name_in_owner`，或复制带唯一名的子树之前，确认名字在整个 owner 范围内唯一，而不只是在同级节点之间唯一。出现冲突时，选定新名字，更新每一处使用该 `%Name` 的代码和场景，再验证引用能解析。

## 分组与顺序

- 分组是行为声明。移除或改名分组前，找出所有调用 `is_in_group()`、`get_nodes_in_group()`、`call_group()` 的消费方。分组命名和遍历顺序遵循[分组](../40-project-config/subsystem-settings.md#分组与层)。
- 不创建以 `_` 开头的自定义分组；Godot 用下划线开头的分组名做内部用途。
- 同级顺序决定 2D 绘制顺序、Container 布局、处理顺序和焦点顺序，在实例和继承场景中也一样。不为美观按字母重排节点。
