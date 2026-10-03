# 测试夹具与隔离

每个测试都能单独运行、按任意顺序运行、重复运行，不泄漏可变状态。

## 夹具

- 可变的夹具按每个测试单独创建。套件级共享的夹具只读，或有经过验证的完整重置。
- 测试不依赖声明顺序、运行器的执行顺序，也不依赖另一个测试是否已经运行。
- 普通的夹具构建器只创建满足领域不变量的状态。只有针对恢复或校验的测试，才构造无效或损坏的状态。

## Node 与 Resource

- 测试创建的 Node 和场景有明确的释放方。注意：`remove_child()` 不释放 Node；`queue_free()` 延迟到帧末执行。正确性依赖删除已经完成时，等待真实的删除条件。孤立节点的判定见[孤立节点](gdunit4-profile.md#孤立节点)。
- 经 ResourceLoader 加载并缓存的定义或配置 Resource，测试不直接修改它，然后指望下一个测试拿到干净的副本。需要修改时使用副本。
- 用 `ResourceLoader.CACHE_MODE_IGNORE` 绕过缓存时，注意外部依赖仍从缓存复用；依赖也要隔离时用 `CACHE_MODE_IGNORE_DEEP`。

## 全局状态

- 测试修改的进程级状态，在 teardown 中恢复，或用进程隔离。包括 Autoload 的可变状态、`static var`、注册表与缓存、InputMap、ProjectSettings、`Engine.time_scale` 和 `SceneTree.paused`。
- gdUnit 只恢复已存在 ProjectSettings 键的值（见 [ProjectSettings 快照](gdunit4-profile.md#projectsettings-快照)）。其他全局状态，自己拍快照并恢复。
- 不为测试在生产代码中加重置后门，见[测试与调试后门](production-isolation.md#测试与调试后门)。

## 文件与信号

- 写 `user://` 的测试使用测试自己的子目录，只清理自己创建的路径，不递归清空 `user://`。
- 生命周期超过单个用例的信号连接、订阅和观察者注册，在 teardown 中断开。

## 清理

- 关键清理放在断言失败后仍会执行的位置：`after_test()`、`after()` 或 `auto_free()`。不要只在成功路径的末尾清理。
- 测试注入的按下状态（`Input.action_press()` 或按下事件），在 teardown 中释放。
- 用例结束时，不留下仍会修改其他测试状态的 Timer 或异步工作。
- 清理无法恢复可信的基线时，让受影响的测试或套件失败，不继续产出看似可信的通过结果。
