# 70 测试规则

本模块规定怎样编写和运行项目的 gdUnit4 测试。测什么、选哪些测试、结果怎样算完成证据，由 [methodology 08](../../methodology/08-test-traceability-and-evidence.md) 决定。测试范围只有 08 的 Required Test Set、affected 集合和 full 全量套件，本模块不另设范围或档位。

| 文件 | 何时阅读 |
| --- | --- |
| `test-levels.md` | 任何测试修改都读：选择单元、集成或运行时场景测试，使用测试替身，判断视觉、覆盖率或性能证据 |
| `gdunit4-profile.md` | 运行 `tools/testing/run-gdunit-tests.py` 或解读其失败；测试预期的错误或警告；处理孤立节点或 ProjectSettings；修改 gdUnit4 配置、版本或 `tools/testing/` |
| `test-selection-and-gates.md` | 在 Feature 流程中运行测试，或判断哪些 Godot 改动需要 gdUnit 之外的验证或 full 运行 |
| `fixtures-and-isolation.md` | 创建或修改测试夹具；测试创建 Node、修改全局状态、写文件或连接信号 |
| `time-randomness-and-async.md` | 测试时间、帧、动画（Tween、AnimationPlayer）、随机数、信号等待或多线程加载；断言动画过程或时长时必读 |
| `input-and-command-testing.md` | 测试输入、UI 交互或 Command |
| `production-isolation.md` | 修改测试目录、导出过滤、测试或编辑器 Autoload；测试写入 `res://`、`user://` 或 `project.godot`；生产代码需要为测试开接口 |

## 验证

| 改动类型 | 需要的验证 |
| --- | --- |
| 新增或修改测试 | 解析与 lint（[直接静态检查约定](../../methodology/contracts/gdscript-lint.md)）；`--target` 运行改动的套件，确认用例出现在 `discovery.json` 且通过；完成前按 08 运行 `--feature F0XX --scope auto` |
| 修改共享测试夹具或辅助代码 | 运行依赖它的全部套件；影响不确定时运行 full |
| 修复隔离问题或不稳定测试 | 受影响的套件一起反复运行；可能存在跨套件污染时运行 full |
| 修改 `project.godot` 的 `[gdunit4]` 节、`tools/testing/` 或 `addons/gdUnit4/` | full 运行，并按[运行器版本变更](gdunit4-profile.md#运行器版本变更)核对 |
| 修改测试目录、导出过滤或测试 Autoload | 一次全新的 Godot 进程启动，以及 [41-export-config](../41-export-config/README.md) 要求的导出验证 |
