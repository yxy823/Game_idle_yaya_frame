# GDScript 状态、资源、加载、错误、时间与随机数

明确区分定义与配置数据、可变的运行时状态、I/O、时间和随机数。

## Resource 与状态语义

- **[必须]** 按生命周期和状态语义选择 Node、RefCounted 或 Resource，不按方便选择。
- **[必须]** 定义与配置类 Resource 在运行时保持只读，见 [Resource 角色](../21-resources/roles-sharing-and-locality.md#角色)。可变的运行时状态通常属于单独的权威状态所属方或模型；运行时的修改永远不保存回项目定义的 `.tres` 文件（见[保存规则](../21-resources/identity-paths-and-saving.md#保存与生成)）。
- **[必须]** 代码依赖共享或缓存的 Resource 时，遵守 ResourceLoader 的缓存身份。不假设重复调用 `load()` 会返回一份新副本。

## 加载

- **[优先]** 稳定的加载期依赖使用 `preload()`；运行时才选定的依赖使用 `load()` 或 ResourceLoader。
- **[必须]** 没有明确理由或预加载策略时，不在热循环或对延迟敏感的路径中首次加载资源。
- **[必须]** 多线程 ResourceLoader 代码使用官方的请求、状态查询和获取流程。不把 `load_threaded_get()` 当作轮询操作。

## 错误与确定性

- **[必须]** 可恢复的业务失败，通过真实的结果、返回值、状态或事件契约来表示。
- **[必须]** 必需的 Node、Resource 和配置加载失败时，要能与成功得到的空值区分开。只有契约允许省略的输入才使用默认值。
- **[必须]** `push_error()` 和 `push_warning()` 用于诊断，不用于控制流程。
- **[必须]** `assert` 只用于开发期不变量。断言条件不能有副作用，因为发布（非调试）构建会忽略断言。
- **[必须]** GDScript 没有 `throw`、`try`、`except` 或 `finally`。使用明确的返回值、null 或结果契约，并用生命周期回调做清理。
- **[必须]** 可能返回 `null` 的带类型 Object 返回值要写进文档，并要求调用方检查。集合默认用 `[]` 或 `{}`，不用 `null`。
- **[优先]** 在需要可复现的玩法规则中，使用确定的、可注入的或由所属方持有的 RNG。不依赖不受控的全局 RNG 状态。
- **[必须]** 明确时间域。受缩放的玩法时间、物理时间、单调递增的经过时间，以及挂钟或日历时间，不能互相替代。
- **[必须]** Shader、特效和动画的时间不是权威的玩法状态。
- **[优先]** 纯规则保持确定：相同的显式输入和已声明的依赖产生相同的结果。

```gdscript
# 开发期不变量；这个断言不是运行时的恢复路径。
func take_damage(amount: int) -> void:
	assert(amount >= 0, "damage amount must be non-negative")
	health -= amount

# 这里空的 JSON 对象是有效的；加载失败是另一种结果。
func load_config(path: String) -> Result:
	var result := Result.new()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		result.error = "cannot open config %s: %s" % [path, FileAccess.get_open_error()]
		return result
	var contents: String = file.get_as_text()
	var read_error: Error = file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		result.error = "cannot read config %s: %s" % [path, read_error]
		return result
	var parsed: Variant = JSON.parse_string(contents)
	if not parsed is Dictionary:
		result.error = "config must contain a valid JSON object: %s" % path
		return result
	result.success = true
	result.data = parsed
	return result

func find_enemy_by_id(id: int) -> Enemy:
	for enemy: Enemy in enemies:
		if enemy.id == id:
			return enemy
	return null

class Result:
	var success: bool = false
	var data: Variant
	var error: String = ""
```

调用方先检查 `success`，再使用 `data`；失败时按项目已有的惯例处理或汇报。上面这个小小的 Result 只用来说明这种区分，不要求建立共享的 Result 框架。对于会给出错误码的文件 API，把错误码连同对应路径一起保留，并在失败处停止。可选的默认值不能把必需的加载失败，变成看似成功的空 Dictionary 或 PackedByteArray。
