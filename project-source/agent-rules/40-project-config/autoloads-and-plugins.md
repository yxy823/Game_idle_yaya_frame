# Autoload 与编辑器插件

两者都登记在 `project.godot` 中：Autoload 是有顺序、具有全局生命周期的应用依赖；编辑器插件是在编辑器中运行的代码。

## Autoload

- 只有确实需要全局生命周期或全局所有权时才用 Autoload，例如存档、设置、进度、音频和场景切换。不要把它当作便利的服务定位器，也不放单个场景的状态。
- 名称使用稳定的 PascalCase，不与任何 `class_name` 重名。建议：Autoload 脚本不声明 `class_name`。
- 脚本 Autoload 必须继承 Node；需要固定的内部节点树时用场景 Autoload。
- 列表顺序决定实例化顺序。存在启动依赖时不按字母重排。建议：复杂的启动依赖用明确的初始化方法表达，不依赖碰巧形成的 `_ready` 顺序。
- Autoload 对外提供查询方法、有业务含义的命令和信号，不让外部直接改字段。它启动时不依赖主场景或 HUD 已经存在，运行期间不释放自己。
- 注意：每次运行游戏都会实例化 Autoload，包括 headless 测试和 `-s` 脚本；带 `@tool` 的 Autoload 还会在编辑器中运行。启动代码保持轻量，不假定窗口、存档或网络已就绪。
- 测试用的 Autoload 不写进生产 `project.godot`，见[测试与生产隔离](../70-tests/production-isolation.md#autoload-与-projectsettings)。
- Autoload 不指向 `dev/` 下的脚本或场景。正式导出排除 `dev/`，调试台由调试入口挂载，见[入口与依赖方向](../../methodology/13-debug-console-and-validation.md#入口与依赖方向)。
- 负责存档的 Autoload 在 `_ready` 中不读档、不开自动保存，由主场景开始时触发读档。存档位置可配置，例如提供设置存档路径的方法：调试入口的项目挂钩 `dev/debug/debug_project.gd` 在切到主场景之前，用它把存档指到只供调试的 `user://` 文件，固定局面因此不会覆盖真实进度。

## 事件总线

- 只有信号要穿过多个场景或模块边界、直接连接会形成信号迷宫时，才用 Autoload 事件总线。邻近对象仍由父节点或协调者直接连接。
- 总线只声明带类型参数的信号，按领域分组，不放状态。使用方通过 `Events.score_changed.connect(...)` 这样的信号对象 API 连接。

## 编辑器插件

- 注意：插件文件存在不等于已启用。启用状态保存在 `project.godot` 的 `[editor_plugins]` 中。
- 不要为完成一次 Agent 任务而长期启用插件。启用新插件前，确认它必要且与 Godot 4.7 兼容。
- 禁用插件时，清理它添加的 Autoload、停靠面板、设置和编辑器状态，但不删除用户的项目资源。
- 从导出中排除插件文件，不会删除 `project.godot` 中插件注册的 Autoload。插件拥有的 Autoload 在禁用时注销，或在导出时剥离。
- 仅在编辑器中运行的插件功能不能成为导出后玩法的前提。
- 第三方插件遵循第三方代码规则，默认不改它们的代码风格。
- 编辑器内执行与游戏内执行的区分见[编辑器与工具代码](../10-gdscript/editor-tools-static-state-and-concurrency.md#编辑器与工具代码)。
