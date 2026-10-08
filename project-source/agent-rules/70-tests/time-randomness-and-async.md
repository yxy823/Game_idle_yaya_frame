# 时间、随机数与异步测试

时间域、RNG 的归属和 `load_threaded_get()` 的生产规则见 [state-resources-and-loading.md](../10-gdscript/state-resources-and-loading.md)。本文只写测试的做法：测试控制的时钟、RNG 和异步语义，要与生产行为实际使用的一致。

## 时间与帧

- 测试自己控制时间：用注入的时钟、受控的 Timer，或下面[动画与 Tween](#动画与-tween)的手动推进，不真实地等待若干秒。不要靠加长等待来修复不稳定的测试。
- 注意：gdUnit SceneRunner 的 `simulate_frames()`、`await_input_processed()` 和 `await get_tree().process_frame` 都只是等待真实的帧过去，每帧的 delta 由机器当时的快慢决定，不能用来控制流逝的时间。
- 按行为实际使用的时间域写测试。暂停和 `Engine.time_scale` 是两个独立的维度，分别覆盖。
- 流逝时间的测试不硬编码渲染帧率，除非帧数本身就是契约。
- 物理行为走真实的物理帧路径。不把修改物理帧率当作加速测试的手段。
- Timer 和 SceneTreeTimer 的处理域、暂停行为、时间缩放和超时结果属于契约时，分别覆盖。
- 固定 `await` N 帧要有生命周期上的理由，不写“等两帧”这类凑数等待。

### 动画与 Tween

断言动画的过程或时长（棋子有移动过程、淡出不短于 0.2 秒、某一刻处在半路）时，由测试推进动画时间，不让它按真实时间播放、再在旁边采样。

- **为什么不能采样真实播放**：创建 Tween 的那一帧，delta 可能就有 0.1 秒以上，和整段短动画一样长。动画可能在一帧之内播完，采样只看到终点；用逐帧 delta 累加时长也只有一帧的精度，卡在阈值附近时会偶发失败。这类测试结果取决于机器当时的快慢，属于不稳定测试，不可接受。按真实时间播放只用来检查“能播完、不报错、终态正确”。
- **Tween**：在被测代码创建 Tween 的同一帧内调用 `pause()`，再用 `custom_step(delta)` 按固定步长推进，每一步检查状态，直到收到 `finished`。SceneTree 在处理完节点之后才推进 Tween，所以在触发调用返回后、或在被测代码之后连接的信号处理函数里暂停，Tween 还没有走过一步。被测代码新建的 Tween 可以用 `SceneTree.get_processed_tweens()` 找到，生产代码不需要为测试暴露它。
- **AnimationPlayer**：`pause()` 后用 `advance(delta)` 推进，或用 `seek(time, true)` 跳到要检查的时刻。
- **步长**：选二进制下精确的值，例如 `1.0 / 128.0`，累加没有舍入误差；时长断言的精度就是一步。设置步数上限，超过上限视为没有播完。
- **只检查必要的**：时长断言“不短于”或“不长于”契约值；只有中间值是业务契约时才断言中间值，并使用浮点容差。动画好不好看由人工验收判断。
- 不要在两次模拟输入之间断言“仍在动画中”；短动画可能在一次输入等待内就已播完。

```gdscript
const STEP_SECONDS := 1.0 / 128.0
const STEP_LIMIT := 256


## 暂停 known 之后新建、正在运行的 Tween，交给测试推进。
func _hold_new_tweens(known: Array[Tween]) -> Array[Tween]:
	var held: Array[Tween] = []
	for tween in get_tree().get_processed_tweens():
		if tween.is_running() and not known.has(tween):
			tween.pause()
			held.append(tween)
	return held


## 按固定步长推进到播完，每步调用 after_step；返回推进的时长，没播完返回 -1.0。
func _step_until_finished(tween: Tween, after_step: Callable) -> float:
	var finished := [false]
	tween.finished.connect(func() -> void: finished[0] = true)
	for step in STEP_LIMIT:
		tween.custom_step(STEP_SECONDS)
		after_step.call()
		if finished[0]:
			return (step + 1) * STEP_SECONDS
	return -1.0


func test_fade_out_lasts_at_least_contract_time() -> void:
	var known := get_tree().get_processed_tweens()
	_view.start_fade_out()  # 同步创建淡出 Tween
	var held := _hold_new_tweens(known)
	assert_int(held.size()).is_equal(1)
	var alphas: Array[float] = []
	var seconds := _step_until_finished(held[0], func() -> void: alphas.append(_view.modulate.a))
	assert_float(seconds).is_greater_equal(FADE_OUT_SECONDS)
	assert_float(alphas.back()).is_equal_approx(0.0, 0.001)
```

## 随机数

- 断言具体随机结果的测试，注入 `RandomNumberGenerator` 并设定 `seed`。`state` 只用于恢复之前保存的状态。
- 不把 Godot RNG 的一长串输出当作跨版本稳定的业务契约，除非项目自己维护该算法。
- 概率测试分开两类：确定的映射与边界检查；统计或性质检查。有限样本不要求与理论概率完全一致。
- 模糊或性质测试失败时，记录足以复现的种子和输入。重跑直到通过，不能消除一次不稳定的失败。

## 信号与异步

- 信号等待都有超时。`assert_signal()` 默认等待 2000 毫秒，可以用 `wait_until()` 调整；`await_signal_on()` 也有超时参数。
- 信号可能在触发调用内同步发出时，先用 `monitor_signals()` 开始收集，再触发，再断言。否则 `assert_signal()` 从断言开始才收集，会错过已经发出的信号：

```gdscript
const SignalAssertImpl := preload("res://addons/gdUnit4/src/asserts/GdUnitSignalAssertImpl.gd")


func test_reset_emits_changed() -> void:
	var wallet := monitor_signals(Wallet.new()) as Wallet
	wallet.reset()
	var signal_assert := assert_signal(wallet) as SignalAssertImpl
	await signal_assert.is_emitted("changed")
```

转换类型的原因见 gdUnit4 运行器与诊断规则中的[编写测试时的约定](gdunit4-profile.md#编写测试时的约定)。

- 注意：`monitor_signals()` 默认对该对象调用 `auto_free()`。
- 收到信号后，再断言要求的载荷和事后状态，不把收到信号当作整个流程成功的证明。
- 多线程 ResourceLoader 测试轮询 `ResourceLoader.load_threaded_get_status()`，直到返回 `THREAD_LOAD_LOADED` 或失败状态，再取结果。不用 sleep 猜测已经完成。
- 测试运行器的超时与生产或领域的超时是不同的配置，不互相代替。
