# 10 GDScript 规则

适用于项目自有的 `.gd` 文件，包括项目自有的测试脚本。第三方插件代码遵循核心规则中的第三方规则，除非任务明确负责其补丁或 fork。

阅读与修改内容匹配的文档即可；一个 `.gd` 文件不需要读遍所有主题。

| 文档 | 何时阅读 |
| --- | --- |
| `typing-and-api.md` | 编辑 GDScript 语法、声明、命名、导出、属性、公共 API 或控制流；声明信号，或选择 emit 与 connect 的 API；只在需要时查看其中的示例 |
| `structure-and-dependencies.md` | 修改职责、依赖方向、模块间通信（命令向下，信号向上）或全局服务 |
| `state-resources-and-loading.md` | 修改状态或 Resource 的使用、加载、错误处理、时间或随机数 |
| `godot-lifecycle-and-input.md` | 使用节点生命周期回调、CharacterBody 移动、信号连接的生命周期、`await`、切换场景或输入事件处理 |
| `editor-tools-static-state-and-concurrency.md` | 修改 `@tool` 或编辑器代码、静态状态、线程，或 Godot 特有的性能行为 |
| `validation.md` | 任何 GDScript 修改：确定需要哪些验证 |

信号规则按问题分在不同文档：信号声明以及 emit 与 connect 的 API 在 `typing-and-api.md`；通信方向在 `structure-and-dependencies.md`；连接的生命周期与等待在 `godot-lifecycle-and-input.md`；编辑器连接与代码连接的选择在[场景 UI 与脚本绑定](../20-scenes/ui-and-scripts.md#信号连接方式)。输入动作（Input Action）的语义由 [InputMap 配置](../40-project-config/input-map.md) 规定。

仓库根目录的 `gdlint.json` 负责配置 linter 的数值阈值。
