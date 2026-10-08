# gdUnit4 运行器与诊断

项目固定使用 `addons/gdUnit4/` 中的 gdUnit4，版本以其 `plugin.cfg` 为准。测试的选择和完成证据见 [测试追溯与证据](../../methodology/08-test-traceability-and-evidence.md)；本文写包装脚本的实际行为，以及编写测试时要配合的地方。

## 运行方式

所有测试都通过包装脚本运行，从项目根目录执行：

```text
python -B yaya/tools/testing/run-gdunit-tests.py --target tests/unit/<suite>.gd
python -B yaya/tools/testing/run-gdunit-tests.py --feature F0XX --scope auto
```

`--target` 用于迭代和诊断，不产生完成证据；`--feature` 的范围选项见[运行时的测试影响选择](../../methodology/08-test-traceability-and-evidence.md#运行时的测试影响选择)。

- 包装脚本用 `docs/methodology-config.json` 中的 Godot 可执行文件，以 `--path <项目> --debug --ignore-error-breaks --script res://yaya/tools/testing/gdunit_evidence_runner.gd -rd <运行目录>` 启动。
- 每个选择器生成一个 `-a <路径>` 参数。`--continue` 对应 gdUnit 的 `-c`；不加时，gdUnit 在第一个失败处停止，后面的用例不执行。先写失败测试时要看到每个用例各自的失败原因，加 `--continue`。
- 不使用 `--headless`：gdUnit 在无头模式下拒绝运行，因为 InputEvent 不会传递。测试窗口以最小化方式运行。
- 进程归属依赖 Windows Job Object，只支持 Windows。
- `--timeout-seconds` 设置墙钟上限，默认 120 秒。超时即失败，并结束本次创建的整个进程树。
- 标准输入已关闭，测试不能等待控制台输入。

每次运行有自己的目录 `reports/gdunit-wrapper/<F0XX 或 focused>/run-<id>/`：

| 文件 | 内容 |
| --- | --- |
| `result.json` | 选择范围、实际命令、选择器、进程结果、错误和原始报告的哈希 |
| `engine.log` | 按顺序合并的 stdout 与 stderr |
| `discovery.json` | gdUnit 实际发现的用例，包括展开后的参数化用例 |
| `report_*/results.xml` | JUnit 报告 |
| `report_*/diagnostics.jsonl` | 会话钩子记录的诊断和已声明的预期诊断 |

## 判定

结论只看 `result.json` 的 `status`，以及脚本最后输出的 `TEST VERDICT: PASS` 或 `TEST VERDICT: FAIL - <原因>`。不要根据 gdUnit 的退出码或控制台末行推断通过。失败时先读 `result.json` 的 `errors`，再读同目录的 `engine.log`。

包装脚本在以下情况判失败，完整的失败条件见 08 的[什么情况下运行失败](../../methodology/08-test-traceability-and-evidence.md#什么情况下运行失败)：

- Godot 进程退出码不是 0，或超时。gdUnit 有失败用例时返回 100，只有孤立节点时返回 101，两者都失败。
- JUnit 报告缺失或不止一份，或者计数与用例节点不一致。
- 有失败、跳过或标记为 flaky 的用例。
- `discovery.json` 与 JUnit 用例不一致，或者选中的套件、源码中声明的 `test_` 方法没有执行。
- `diagnostics.jsonl` 缺失或不完整，或者出现任何未声明的诊断（见[诊断监控](#诊断监控)）。
- Feature 运行期间源码指纹发生变化。

## 编写测试时的约定

- 套件直接或经 `class_name`、脚本路径间接继承 `GdUnitTestSuite`，测试方法以 `test_` 开头。包装脚本按源码声明核对执行；无法解析的 `extends` 表达式直接失败。
- 共享基类只放辅助函数和生命周期方法，不写 `test_` 方法；要复用同一组断言，在每个套件里各写一个 `test_` 方法去调用它。继承来的 `test_` 方法在多个套件中可能得到相同的测试身份，无法形成完成证据；测试入口会在启动 Godot 之前报告这种基类。
- 不用跳过、`-i` 忽略列表或过滤来绕过失败。被跳过的用例本身就让运行失败。
- `project.godot` 设置了 `flaky_check_enable=false`，失败的用例不会重试。不要打开重试来掩盖不稳定。
- `await` 每一个协程断言，包括 `assert_signal(...).is_emitted()`、`is_not_emitted()` 和 `assert_error(...)` 的各个匹配方法。漏写 `await` 时，测试不等断言完成就继续，失败可能不被计入。
- 这些方法的实现是协程，但 `assert_signal()`、`assert_error()` 返回的抽象类型把它们声明为普通方法，直接 `await` 会触发 `REDUNDANT_AWAIT` 警告，运行判失败。先 `preload` 实现脚本（`res://addons/gdUnit4/src/asserts/GdUnitSignalAssertImpl.gd`、`GdUnitGodotErrorAssertImpl.gd`，它们没有 `class_name`），把断言对象转换为该类型后再 `await`，写法见下方示例。
- `GdUnitSceneRunner` 的 `await_input_processed()` 等方法在抽象基类中声明，经 `scene_runner()` 的返回类型调用时，`await` 会触发 `REDUNDANT_AWAIT` 警告。需要等待输入处理时，写 `var runner := scene_runner(SCENE) as GdUnitSceneRunnerImpl` 再等待；等待信号时用套件的 `await_signal_on()`。不删除必需的等待，也不修改插件。
- 局部变量和参数不要用基类生命周期方法的名字：`before`、`after`、`before_test`、`after_test`。同名会触发 `SHADOWED_VARIABLE_BASE_CLASS` 警告，见[常见警告](../10-gdscript/typing-and-api.md#常见警告)。
- 同一套件的各个用例共用一个套件实例，成员变量不会在用例之间自动清空。每个用例自己的记录在 `before_test()` 中重建，或放进用例开始时新建的对象。不要把已释放的节点留在成员数组里，需要的属性在节点存活时先取出。

## 诊断监控

`project.godot` 的 `[gdunit4]` 节开启了 `report/godot/push_error`、`report/godot/script_error` 和 `report/verbose_orphans`，并注册了会话钩子 `yaya/tools/testing/gdunit_diagnostic_session.gd`。注意：gdUnit 的 push_error 监控同时记录 `push_warning()`。

包装脚本另外解析 `engine.log` 中的原生记录，即 `ERROR`、`WARNING`、`SCRIPT ERROR`、`SHADER ERROR` 标题加 `at:` 源码位置行。解析覆盖整个进程生命周期，包括 gdUnit 自身监控不到的 `before_test()`、`after()` 和退出清理阶段。这不是在任意输出中搜索错误字样。

- 任何未声明的错误、警告、脚本错误或 Shader 错误都让运行失败。出现新警告时，调查并修复来源，不要抑制。
- 不全局关闭监控，不修改 `[gdunit4]` 的 report 设置，不放宽包装脚本或会话钩子。
- 不为了让测试通过，删除或降级有效的生产诊断。

### 预期的错误与警告

错误或警告本身就是被测契约时，在测试中用限定范围的断言声明它，并同时断言对应的结果或事后状态：

```gdscript
const ErrorAssertImpl := preload("res://addons/gdUnit4/src/asserts/GdUnitGodotErrorAssertImpl.gd")


func test_remove_unknown_item_reports_error() -> void:
	var inventory := Inventory.new()
	var remove_missing := func() -> void: inventory.remove_item(&"missing")
	var error_assert := assert_error(remove_missing) as ErrorAssertImpl
	await error_assert.is_push_error("Unknown item: missing")
	assert_int(inventory.item_count()).is_equal(0)
```

- 只有 `is_push_error()`、`is_push_warning()` 和 `is_runtime_error()` 匹配成功时，会话钩子才把对应的一次诊断记为预期。`is_success()` 不豁免任何诊断。Shader 错误无法声明为预期。
- 每次匹配只豁免一次出现。同样的诊断多出现一次，仍然失败。
- 这些方法按完整消息相等比较，也接受 gdUnit 的参数匹配器。被测代码的消息里不拼入绝对路径、行号等易变内容。

## 日志与错误处理

- 普通业务测试不把 stdout 或日志文本当作唯一的成败依据，断言结构化结果。消息本身是开发者或工具诊断的契约时，可以断言文本。
- `push_error()` 和 `push_warning()` 不代替失败控制流。可能失败的操作返回结构化结果，测试断言这个结果。
- 捕获失败后走回退路径的代码，测试原始失败能否识别、回退后的结果，以及要求的诊断。

## 孤立节点

- 运行结束时仍有孤立节点，gdUnit 返回 101，包装脚本判失败。没有可接受的“基线”孤立节点。
- JUnit 报告不记录孤立节点，定位时读 `engine.log` 中 gdUnit 的孤立节点输出。
- 测试创建的 Node 用 `auto_free()` 登记，或在 `after_test()` 中释放。`scene_runner()` 只自动释放它从场景路径实例化的场景；传入手动创建的节点时，仍要用 `auto_free()` 登记。
- 注意：已移出场景树、但 `queue_free()` 还没执行的 Node 也算孤立节点。需要时 `await await_idle_frame()` 等待删除完成，不关闭孤立节点检测。
- 孤立节点检测不能证明文件、信号、线程、Timer 和 Resource 已经清理，这些按 [fixtures-and-isolation.md](fixtures-and-isolation.md) 处理。

## ProjectSettings 快照

gdUnit 在每个套件和每个用例前后为 ProjectSettings 拍快照。恢复时只写回快照中存在、且恢复时仍存在的键的值：新增的键不会删除，删除的键不会恢复。

- 新增或删除 ProjectSettings 键的测试，自己清理，或在隔离的进程中运行。
- 调用 `ProjectSettings.save()` 的测试，在隔离的进程中运行，并有自己的清理。其他测试不写 `project.godot`，见[Autoload 与 ProjectSettings](production-isolation.md#autoload-与-projectsettings)。
- 快照不覆盖 InputMap、`Engine.time_scale`、暂停等其他全局状态，这些按[全局状态](fixtures-and-isolation.md#全局状态)恢复。

## 运行器版本变更

更新 `addons/gdUnit4/`，或修改 `yaya/tools/testing/` 与 `[gdunit4]` 配置时，重新核对：测试发现与 `discovery.json`、JUnit 字段、诊断监控与会话钩子、协程断言、孤立节点退出码，以及 ProjectSettings 快照的行为。核对完成之前，不删除针对旧版本的绕行代码。
