# 时间、随机数与异步测试

时间域、RNG 的归属和 `load_threaded_get()` 的生产规则见 [state-resources-and-loading.md](../10-gdscript/state-resources-and-loading.md)。本文只写测试的做法：测试控制的时钟、RNG 和异步语义，要与生产行为实际使用的一致。

## 时间与帧

- 用注入的时钟、gdUnit SceneRunner 的 `simulate_frames()` 或受控的 Timer 推进时间，不真实地等待若干秒。不要靠加长等待来修复不稳定的测试。
- 按行为实际使用的时间域写测试。暂停和 `Engine.time_scale` 是两个独立的维度，分别覆盖。
- 流逝时间的测试不硬编码渲染帧率，除非帧数本身就是契约。
- 物理行为走真实的物理帧路径。不把修改物理帧率当作加速测试的手段。
- Timer 和 SceneTreeTimer 的处理域、暂停行为、时间缩放和超时结果属于契约时，分别覆盖。
- Tween 测试推进时间或帧后，断言状态或完成情况。只有中间值是业务契约时才断言中间值，并使用浮点容差。
- 动画时长按游戏时间断言：每帧累加 `get_process_delta_time()`，不用 `Time.get_ticks_msec()` 的墙钟差值。在测试运行器中实测过，一次 0.12 秒的 Tween 只经过约 17～31 毫秒墙钟时间，按毫秒断言会稳定失败。
- 短动画可能在一次输入等待内就已播完。不要在两次模拟输入之间断言“仍在动画中”；需要检查中间状态时，用受控的时间或帧推进。
- 固定 `await` N 帧要有生命周期上的理由，不写“等两帧”这类凑数等待。

## 随机数

- 断言具体随机结果的测试，注入 `RandomNumberGenerator` 并设定 `seed`。`state` 只用于恢复之前保存的状态。
- 不把 Godot RNG 的一长串输出当作跨版本稳定的业务契约，除非项目自己维护该算法。
- 概率测试分开两类：确定的映射与边界检查；统计或性质检查。有限样本不要求与理论概率完全一致。
- 模糊或性质测试失败时，记录足以复现的种子和输入。重跑直到通过，不能消除一次不稳定的失败。

## 信号与异步

- 信号等待都有超时。`assert_signal()` 默认等待 2000 毫秒，可用 `wait_until()` 调整；`await_signal_on()` 也有超时参数。
- 信号可能在触发调用内同步发出时，先用 `monitor_signals()` 开始收集，再触发，再断言。否则 `assert_signal()` 从断言开始才收集，会错过已经发出的信号：

```gdscript
const SignalAssertImpl := preload("res://addons/gdUnit4/src/asserts/GdUnitSignalAssertImpl.gd")


func test_reset_emits_changed() -> void:
	var wallet := monitor_signals(Wallet.new()) as Wallet
	wallet.reset()
	var signal_assert := assert_signal(wallet) as SignalAssertImpl
	await signal_assert.is_emitted("changed")
```

转换类型的原因见 [gdUnit4 运行器与诊断](gdunit4-profile.md#编写测试时的约定)。

- 注意：`monitor_signals()` 默认对该对象调用 `auto_free()`。
- 收到信号后，再断言要求的载荷和事后状态，不把收到信号当作整个流程成功的证明。
- 多线程 ResourceLoader 测试轮询 `ResourceLoader.load_threaded_get_status()`，直到返回 `THREAD_LOAD_LOADED` 或失败状态，再取结果。不用 sleep 猜测已经完成。
- 测试运行器的超时与生产或领域的超时是不同的配置，不互相代替。
