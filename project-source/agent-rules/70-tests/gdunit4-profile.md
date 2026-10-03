# GdUnit4 运行器配置

本文记录项目固定使用的 gdUnit4 运行器在编写和运行测试时需要注意的行为。`docs/methodology-config.json` 提供 Godot 可执行文件及其实测版本。测试选择、运行记录和完成证据在 [methodology 08](../../methodology/08-test-traceability-and-evidence.md) 中规定。

## 启动与进程限制

项目自己的包装脚本直接调用配置的 Godot 可执行文件：

```text
<godot> --path <project> --debug --ignore-error-breaks --script res://tools/testing/gdunit_evidence_runner.gd -rd <unique-run-directory> -a <target> [-c]
```

Godot 选项写在脚本路径之前。这种启动方式不使用第三方提供的批处理启动器、`--remote-debug` 或默认的 `--headless` 开关。

- 每次运行都有有限的墙钟时间上限，用 `--timeout-seconds` 设置（默认 120 秒）。等待超过上限的测试会让本次运行失败。
- 标准输入已关闭，所以测试不能等待控制台输入。
- stdout 和 stderr 按顺序写入同一份日志。
- 每次运行把引擎日志、测试发现、JUnit 和诊断报告保存在 `reports/gdunit-wrapper/` 下自己的目录中。诊断失败时到那里读取。缺失、有歧义或过期的 JUnit 不能让一次运行成立。运行目录的布局、`result.json` 以及进程与超时处理，见 [基于原件的完成判定](../../methodology/08-test-traceability-and-evidence.md#基于原始结果的完成判断与语义时效)。

## 测试发现与判定

- **[必须]** GDScript 测试套件继承 `GdUnitTestSuite`，每个测试用例使用运行器发现测试所要求的 `test_` 前缀。
- **[必须]** 聚焦执行通过项目的判定包装脚本，确认要求的测试套件和测试用例已被发现并执行。仅凭运行器的退出码不能证明这一点。
- **[必须]** 项目的测试命令使用 `tests/` 下配置的查找根目录，以及项目自己的包装脚本 `tools/testing/run-gdunit-tests.py`，调用方式见 [运行时的测试影响选择](../../methodology/08-test-traceability-and-evidence.md#运行时的测试影响选择)。
- **[必须]** 当前的运行器配置监控脚本错误、未预期的 `push_error()`、未预期的 `push_warning()`、孤立节点和不稳定结果。执行了零个测试的运行不是 PASS，见[运行器与测试发现](test-selection-and-gates.md#运行器与测试发现)。
- **[必须]** 固定版本运行器的 push-error 监控也会捕获警告。用限定范围的 GdUnit 预期诊断断言声明预期的错误或警告；只有该断言是协程时才 `await` 它。不要全局关闭监控。

### 测试函数体之外的诊断

在固定版本的运行器中，`STARTED` 早于 `before_test()`，随后启动的监控会清除这个钩子产生的诊断。套件的 `after()` 和退出清理同样缺少可靠的 JUnit 诊断覆盖。因此，包装脚本在整个生命周期中识别 Godot 原生的标题、消息和源码位置记录，测试横幅也不会关闭这些检查。这不是在任意输出中搜索错误字样。

- 项目自己的会话钩子 `tools/testing/gdunit_diagnostic_session.gd`，把诊断和正面匹配上的限定范围断言记录到当前报告的 `diagnostics.jsonl` 中。它观察公开的执行上下文、信号和监控条目，不修改第三方代码的状态。
- 每条诊断 ID 和源记录把每项豁免绑定到本次运行。额外出现的未匹配诊断仍然导致失败。
- 诊断证据缺失、不完整或不匹配时失败关闭。钩子启动之前和关闭之后的原生记录，受同样的检查。
- JUnit、非零的进程退出码和超时仍是相互独立的失败来源。固定版本的 JUnit 写出器会省略孤立节点记录，但运行器的孤立节点退出码 101 仍会让包装脚本判定失败。

## 协程断言

- **[必须]** await GdUnit 的协程断言。特别是 `assert_signal(...).is_emitted(...)` 和 `is_not_emitted(...)` 必须 `await`；省略它可能悄悄跳过断言。
- **[必须]** 协程断言同样遵循 `time-randomness-and-async.md` 中关于有界等待和观察者顺序的规则。

## 清理与 ProjectSettings

- **[优先]** 测试拥有的对象用 `auto_free()` 登记，或执行在测试边界之前完成的显式 teardown。
- **[必须]** 固定版本的运行器会对尚未执行的 `queue_free()` 报告误报的孤立节点。需要时等待真实的空闲或删除条件；不要用关闭孤立节点检测来绕过。
- **[必须]** 运行器的 `ProjectSettings` 快照只在以下情况下可靠：恢复的是拍快照时已存在、恢复时仍存在的键的值。
- **[必须]** 新增或删除 `ProjectSettings` 键的测试使用显式清理或进程隔离；不依赖运行器快照恢复键的集合。
- **[必须]** 通过 `ProjectSettings.save()` 测试持久化的测试，在明确隔离的进程中运行，并有自己的清理契约。其他测试遵循 [Autoload 与 ProjectSettings 规则](production-isolation.md#autoload-与-projectsettings)。

## 运行器版本变更

- **[必须]** 配置的运行器版本改变时，重新验证测试发现、诊断监控、报告字段、协程行为、孤立节点处理和 `ProjectSettings` 恢复。只有完成这些核实后，才删除针对特定版本的绕行方案。
