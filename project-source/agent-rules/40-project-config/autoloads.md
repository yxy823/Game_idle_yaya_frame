# Autoload 配置

Autoload 是有顺序、具有全局生命周期的应用依赖。

## 身份与生命周期

- **[必须]** Autoload 名称使用稳定的 PascalCase；重命名或删除时迁移所有使用方。
- **[必须]** Autoload 名称不能与无关的 `class_name` 冲突。Autoload 背后的脚本通常不需要 `class_name`。
- **[必须]** 脚本 Autoload 继承 Node。全局服务确实需要稳定的内部 Node 树时，使用场景 Autoload。
- **[必须]** 存在启动依赖时，Autoload 列表的顺序有语义；不要按字母排序。
- **[优先]** 复杂的启动依赖用明确的初始化或引导阶段表达，不依赖碰巧形成的 `_ready` 顺序。
- **[必须]** Autoload 启动时不要求玩法主场景或 HUD 已经存在，除非这个依赖是引导过程有意设计的一部分。
- **[必须]** Autoload Node 具有全局生命周期，在应用正常运行期间不释放自己。

## 适用范围

- **[必须]** 只有真正需要全局生命周期或全局所有权时才使用 Autoload。不要把它当作为任意依赖提供便利的服务定位器。
- **[必须]** 每个解析项目的操作都会运行 Autoload，包括编辑器和子进程，所以它的启动代码要安全、轻量。
- **[必须]** 临时的测试 Autoload 使用隔离的测试配置或插件生命周期，不能长期污染生产 `project.godot`。
- **[必须]** 在新的 Godot 进程中从磁盘验证持久化的 Autoload 修改。
- **[必须]** 插件注册的 Autoload 遵循[编辑器插件](editor-plugins.md#插件)中的插件清理规则。
- **[优先]** 合适的用途包括：跨场景的持久数据（存档、设置、进度）、聚焦的全局服务（音频、场景切换、本地化、输入映射）、聚焦的事件总线和只读的全局配置。
- **[必须]** Autoload 不含表现内容，主要供其他对象读取。对外提供查询、有意义的命令和信号，不让外部随意修改字段。
- **[必须]** 不要把单个场景的状态、仅为方便的全局变量或宽泛的领域行为放进 Autoload，以免它膨胀成 God Object。

### 聚焦的事件总线示例

只有在信号要穿过多个场景或模块边界转发、否则会形成信号迷宫时，才使用事件总线。邻近对象之间的通信仍通过父节点或协调者直接连接。

```gdscript
# res://autoload/events.gd，注册为 Events Autoload
extends Node

signal player_died
signal score_changed(new_score: int)
signal level_completed(level_id: String)
```

使用方通过带类型的信号对象 API 使用它：

```gdscript
Events.player_died.emit()
Events.score_changed.connect(_on_score_changed)
```

总线信号按领域分组，保持总线聚焦；不要把它变成通用的服务定位器。
