# GDScript 类型与公共 API

类型标注让 Godot 解析器检查契约；动态类型只留在解析、迁移、反射、插件这类真正动态的边界。

## 类型

- 参数、返回值（包括 `-> void`）、成员、`@onready` 成员、导出变量和信号参数都标注类型。局部变量在右侧类型明确时用 `:=`。
- 集合写成 `Array[T]` 或 `Dictionary[K, V]`。注意：Godot 4.7 不支持嵌套的带类型集合，例如 `Array[Array[int]]`、`Dictionary[String, Dictionary[String, int]]` 会解析失败；更深的结构用带类型的类或 Resource 建模。
- 出现类型不匹配或带类型集合插入失败时，修正数据或契约，不把稳定 API 放宽成 `Variant` 或去掉集合类型。
- `as` 转换 Object 类型失败时返回 `null`，调用方要检查。转换内置类型时，`as` 会强制转换，无法转换就报错，不返回 `null`；解析外部输入的数字，先用 `String.is_valid_int()` 或 `is_valid_float()` 检查。
- 可能返回 `null` 的 Object 返回值，在文档注释中写明，调用方检查。集合的空结果返回 `[]` 或 `{}`，不返回 `null`。

## 风格与命名

- 遵循 Godot 官方 [GDScript 风格指南](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_styleguide.html)：Tab 缩进、UTF-8 无 BOM、LF 换行、文件末尾有换行，命名与[代码顺序](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_styleguide.html#code-order)也按它执行。新增成员按这个顺序放；不为格式而重排无关的已有代码。
- 行长等阈值以根目录的 `gdlint.json` 为准。
- `class_name` 只给有意作为项目全局类型的脚本使用。声明了 `class_name` 的脚本，文件名用它的 `snake_case` 形式，例如 `PlayerController` 对应 `player_controller.gd`。
- 不在 Godot 扫描的目录里留下声明同一 `class_name` 的备份或草稿 `.gd`，否则全局类名冲突。这类文件的位置按[临时、备份与草稿文件](../00-core/third-party-generated-and-temporary-files.md#临时备份与草稿文件)选择。
- 建议：公共 API 的单位、副作用、失败方式或生命周期不明显时，写 `##` 文档注释。

## 导出、属性与信号

- `@export` 只用于设计期需要保存的配置，不用于运行时临时状态。能用 `@export_range`、`@export_enum`、`@export_file`、`@export_node_path`、`@export_group` 等注解表达约束时使用它们。
- 不在同一个属性上同时写 `@export` 和 `@onready`：`@onready` 会在 `_ready()` 时覆盖检查器中保存的值。Godot 对此给出默认按错误处理的 `ONREADY_WITH_EXPORT` 警告，不关闭它。
- setter 或 getter 内部直接读写该属性，访问的是底层成员，不会递归。这个例外不延伸到 setter 调用的其他函数：辅助函数给该属性赋值会再次进入 setter，造成无限递归。需要辅助函数时，让它返回计算结果，赋值留在 setter 里。
- setter 和 getter 只维护属性自身的不变量，不在里面驱动跨系统的流程。
- 静态已知的信号，用 `signal_name.emit(...)` 发出，用 `signal_name.connect(callable)` 连接。不用 Godot 3 写法的字符串 `emit_signal("name")` 或 `connect("name", ...)`。
- 信号名确实来自配置、插件或反射时，可以用 `Object.connect()` 和 `Object.emit_signal()`；在这个边界检查信号名和 Callable 是否有效。

## Lambda 与 Callable

- Lambda 通过 `.call(...)` 调用。Lambda 不能声明为 `static`；需要静态复用时写普通的静态函数。
- Lambda 在创建时按值捕获外层局部变量。在 lambda 内给外层局部变量赋值，只改变 lambda 自己的副本，外层变量不变；Godot 对此给出 `CONFUSABLE_CAPTURE_REASSIGNMENT` 警告。Array、Dictionary 和 Object 的内容修改仍然共享。需要回写结果时，写入成员变量或容器，或改用具名函数的返回值。
- 建议：复用的或超过一两行的逻辑写成具名函数，出错时栈信息能定位到它。
- 建议：逐帧路径中不用 `filter`、`map` 这类基于 Callable 的操作，除非测量表明开销可以接受。

## 稳定标识与公共 API

- 写入存档或数据文件的枚举值要显式赋值，例如 `enum Rarity { COMMON = 0, RARE = 1 }`；序列化的值不依赖声明顺序。
- 行为身份用枚举、`StringName` 或带类型的 ID，不用显示文本。
- 建议：键集合不固定的映射用 Dictionary；字段固定的记录用带类型的类或 Resource，不到处传匿名 Dictionary。
- 修改公共函数、信号、枚举、`class_name`、持久化标识符或稳定字段时，同时迁移所有消费方，按 [Godot 资源与身份引用](../00-core/godot-resource-references.md) 检查受影响的引用。
