# 10 GDScript 规则

适用于项目自有的 `.gd` 文件，包括测试脚本。第三方插件代码按[第三方代码与素材](../00-core/third-party-generated-and-temporary-files.md#第三方代码与素材)处理，除非任务明确负责它的补丁或 fork。

| 文档 | 何时阅读 |
| --- | --- |
| [typing-and-api.md](typing-and-api.md) | 任何 `.gd` 修改 |
| [structure-and-dependencies.md](structure-and-dependencies.md) | 新增脚本或模块，修改职责、依赖方向、模块间通信、Autoload 使用、Command 与 Query，或调试台或其他调试工具 |
| [state-resources-and-loading.md](state-resources-and-loading.md) | 代码读写 Resource、加载资源、处理加载或 I/O 失败，或使用时间、计时与随机数 |
| [godot-lifecycle-and-input.md](godot-lifecycle-and-input.md) | 使用节点生命周期回调、`await`、计时器、Tween 或 AnimationPlayer、播放完成信号、切换场景，或接收输入 |
| [editor-tools-static-state-and-concurrency.md](editor-tools-static-state-and-concurrency.md) | 使用 `@tool` 或编辑器 API、`static var`、对象池或线程 |

信号规则按问题分在不同文档：

- 声明与 emit、connect 的 API：[typing-and-api.md](typing-and-api.md#导出属性与信号)。
- 通信方向：[structure-and-dependencies.md](structure-and-dependencies.md#依赖方向)。
- 连接的生命周期与等待：[godot-lifecycle-and-input.md](godot-lifecycle-and-input.md#信号与异步)。
- 在代码还是编辑器中连接：[信号连接方式](../20-scenes/ui-and-scripts.md#信号连接方式)。

## 验证

解析与 lint 的运行命令、退出码和结果解读见 [GDScript lint 的约定与证据](../../methodology/contracts/gdscript-lint.md)。

| 改动 | 需要的验证 |
| --- | --- |
| 任何 `.gd` 修改 | 用 Godot 4.7 `--check-only` 解析改动的脚本和依赖它们的脚本；第三方解析器的结果不能代替 |
| 任何 `.gd` 修改 | 对整个 `res://` 运行 lint CLI，范围和阈值由根目录的 `gdlint.json` 决定 |
| 新建 `.gd` | `--check-only` 不生成 `.uid`；运行 [首次 Godot 扫描](../../tools/README.md#首次-godot-扫描)的命令生成同名 `.uid`，与脚本一起提交。漏掉的由 [`check-godot-resource-format.py`](../../tools/README.md#check-godot-resource-formatpy) 发现 |
| 行为变化 | 运行测试追溯与证据中[测试影响评估](../../methodology/08-test-traceability-and-evidence.md#测试影响评估)选定的范围：Required、affected 或 full |
| 生命周期、Node、Resource、Input、Autoload 或线程的运行时语义变化 | 在上一行的测试中包含真实 SceneTree 路径上的集成或运行时测试 |

不为通过检查而新增或扩大 `gdlint:ignore*`、`@warning_ignore` 或排除项，也不为此修改 `gdlint.json`。唯一例外是用户在讨论中同意保留的指标超标，写法见[用户同意保留的超标](../../methodology/contracts/gdscript-lint.md#用户同意保留的超标)；Agent 不能自行新增这种例外，也不能调高已有的钉住值。
