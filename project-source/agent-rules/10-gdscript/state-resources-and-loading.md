# GDScript 状态、加载、错误、时间与随机数

把定义数据、可变的运行时状态、I/O、时间和随机数分开处理。

## Resource 与加载

- 定义与配置类 Resource 在运行时只读，规则见 Resource 角色、共享与复制中的[角色](../21-resources/roles-sharing-and-locality.md#角色)。
- `load()` 和 `preload()` 返回 ResourceLoader 缓存中的同一个实例。需要独立副本时显式复制，复制方式见[复制](../21-resources/roles-sharing-and-locality.md#复制)。
- 建议：编写时就确定的依赖用 `preload()` 或导出引用；运行时才选定的用 `load()`。不在逐帧路径中首次加载资源。
- 后台加载用 `ResourceLoader.load_threaded_request()`，再用 `load_threaded_get_status()` 查询进度，状态为 `THREAD_LOAD_LOADED` 后才调用 `load_threaded_get()`。加载未完成时调用 `load_threaded_get()` 会阻塞调用线程，不能拿它轮询。

## 错误与失败

- 可恢复的业务失败通过返回值、结果对象、状态或信号表达。`push_error()` 和 `push_warning()` 只做诊断，不承担控制流程。
- 必需的文件、Resource 或配置加载失败时，返回能与“成功得到空值”区分的结果。只有契约允许缺省的输入才回退到默认值。
- 文件 API 失败时，保留错误码和对应路径，并在失败处停止：`FileAccess.open()` 返回 `null` 时读 `FileAccess.get_open_error()`，读取后检查 `get_error()`。
- `assert()` 只检查开发期不变量。条件表达式不能有副作用，因为发布构建不执行断言。

## 时间域

受缩放的玩法时间、物理时间、单调递增的经过时间和系统日历时间不能互相替代：

| 时间域 | 来源 | 用途 |
| --- | --- | --- |
| 玩法时间 | `_process(delta)`、受暂停和 `Engine.time_scale` 影响的 Timer 或 SceneTreeTimer | 随游戏推进、可暂停的玩法 |
| 物理时间 | `_physics_process(delta)` | 固定步长的移动与碰撞 |
| 单调经过时间 | `Time.get_ticks_msec()`、`Time.get_ticks_usec()` | 测量时长和超时 |
| 系统日历时间 | `Time.get_unix_time_from_system()` 等 `_from_system` 方法 | 日期、存档时间戳、离线时长 |

- 暂停与 `Engine.time_scale` 是两个独立的维度。修改计时逻辑时，分别确认暂停时和时间缩放后的行为。
- 系统时钟可以被用户或操作系统调整。用它计算离线收益等跨会话时长时，处理时间倒退和异常大的跨度。
- Shader、特效和动画的时间不是权威的玩法状态。

## 随机数

- 需要可复现的玩法规则，使用所属方持有或注入的 `RandomNumberGenerator`，每个领域一个实例，不用全局的 `randi()`、`randf()`。
- 用 `seed` 初始化 RNG；`state` 只用于保存后恢复到同一位置。
- 玩法 RNG 的种子可以从外部设定，例如由存档或所属方的方法传入。调试台的固定局面靠同一种子重播出同样的过程，要求见[固定局面、试播与测试状态](../../methodology/13-debug-console-and-validation.md#固定局面试播与测试状态)。
- 不把 Godot RNG 输出的具体数列当作跨引擎版本保持不变的业务契约，除非项目自己实现并持有该算法。
- 建议：纯规则保持确定，相同的显式输入和依赖得到相同的结果。
