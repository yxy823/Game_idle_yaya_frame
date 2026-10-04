# 测试选择与 Godot 验证

测试范围只有 [methodology 08](../../methodology/08-test-traceability-and-evidence.md) 的 Required Test Set、affected 集合和 full 全量套件。选择规则、全量条件、零测试与运行失败条件，都以 08 为准。本文补充两件事：在 Feature 流程中怎样运行测试，以及哪些 Godot 改动需要扩大验证。

## 职责分工

- 08 和 [执行流程](../../methodology/03-execute-loop.md) 决定测什么、何时运行，以及测试与 Feature、验收条件、Bug 和人工验收的关系。本模块规定测试怎样写、怎样运行。
- 单元、集成和运行时场景测试是写法上的层级（见 [test-levels.md](test-levels.md)），不是测试目录。目录和登记表映射见[测试分类](../../methodology/08-test-traceability-and-evidence.md#测试分类)和[登记表规则](../../methodology/08-test-traceability-and-evidence.md#登记表规则)。
- Required Test Set 是下限。本文的条件只能扩大验证，不能从中删除测试。
- 实现批准、基线和 RED、GREEN、重构步骤，遵循 [TDD 执行约定](../../methodology/08-test-traceability-and-evidence.md#tdd-执行约定)。解析和 lint 遵循[直接静态检查约定](../../methodology/contracts/gdscript-lint.md)。

## 运行测试

- 迭代时用 `--target` 运行直接相关的套件，获得快速反馈。它不产生完成证据。
- 完成证据用 `--feature F0XX --scope auto` 运行。只运行新增或修改的用例不能宣布完成。
- 修改测试源码后，确认用例出现在 `discovery.json` 中并通过，再运行相关的已有套件。
- 修复失败后，按[失败处理](../../AGENTS.md#失败处理)重新运行。
- 汇报时列出新增或更新的测试，以及 gdUnit 之外实际执行的检查和结果。

## 扩大验证的 Godot 改动

影响分析要覆盖继承、信号与事件、Resource 和场景引用、注册表、生成数据、Autoload 与全局 API，以及动态加载。只靠文本搜索不足以确定影响范围；不确定时选稍大的子系统范围。

下列改动需要额外的验证，写进 Stage 1 的验证计划。gdUnit 之外的检查与测试结果一起报告，不写进 `full_suite_reasons`。

| 改动 | 额外验证 |
| --- | --- |
| 公开 API、信号载荷或时序、Resource 的 schema 或默认值、稳定 ID、枚举、Command 类型、Autoload API | 已知使用方的测试。跨场景的信号连接或生命周期，用集成或运行时场景测试 |
| SceneTree 生命周期 | 使用真实 SceneTree 的集成测试 |
| 输入或 UI 连接 | 走真实输入路径的测试，见 [input-and-command-testing.md](input-and-command-testing.md)。不需要截图 |
| Command 或领域规则 | Command 和领域测试。适配层或连接也改变时，才加输入或 UI 测试 |
| Autoload 的注册、启动或公开状态；`project.godot` 中改变行为的设置 | 受影响的套件，加一次全新的 Godot 进程启动 |
| 导入管线 | 重新导入后的证据 |
| 数据解析器、schema、规范化器或生成器 | 全部受管理的数据集重新生成并加载，以及受影响的运行时使用方 |
| 共享的基础场景或 Resource 的默认值 | 有代表性的实例和使用方 |
| 共享测试夹具或测试辅助代码 | 依赖它的全部套件；影响不确定时运行 full |
| 隔离问题或不稳定测试的修复 | 受影响的套件一起反复运行；可能存在跨套件污染时运行 full |
| 导出或打包 | [41-export-config](../41-export-config/README.md) 的导出验证 |
| 渲染器、窗口或平台行为 | 在目标环境运行。测试进程不能证明这些语义 |

## 需要 full 运行的 Godot 改动

修改以下内容时，属于 08 所说的“广泛影响”或“无法可靠界定受影响组件”，运行 full，并把原因记为 `full_suite_reasons`：

- 共享的核心或领域基础构件；
- 全局的 Event 或 Command 基础设施；
- 主要 Autoload 的核心行为；
- 测试隔离基础设施：共享夹具、`[gdunit4]` 配置、`tools/testing/`；
- 基础 schema 或序列化基础设施；
- 覆盖面广的生成器；
- 跨模块的大型重构；
- 已知的全局状态污染。

full 指项目的全部自动化测试，不包括导出或多平台验证；这些由上表单独触发。
