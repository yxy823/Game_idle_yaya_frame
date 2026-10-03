# Feature 工作流程与 Godot 测试的衔接

本文只衔接两套规则的职责。它不代替本目录中的 Godot 测试实现规则，也不复制 `methodology/08-test-traceability-and-evidence.md`。

## 权限边界

- **[必须]** 项目工作流程（methodology 03 和 08）决定测什么、为什么测、选择哪些测试、何时运行，也决定测试与 Feature、验收条件（AC）、Bug 和人工验收之间的关系。
- **[必须]** 本目录管理具体的 Godot 测试实现：L0 到 L3 层级、运行器行为、测试夹具、隔离、mock 与 spy、SceneTree、输入、信号、异步行为和诊断。
- **[必须]** 测试影响评估产出的必需测试集合（Required Test Set）是最低要求。`test-selection-and-gates.md` 中针对 Godot 的影响档位可以扩大它或提升档位，但永远不能悄悄从中删除测试。

## 可追溯性与物理组织

- **[必须]** 逻辑 ID、测试目录，以及到实际路径和测试用例的映射，遵循 [测试分类](../../methodology/08-test-traceability-and-evidence.md#测试分类) 和 [登记表规则](../../methodology/08-test-traceability-and-evidence.md#登记表规则)。
- **[必须]** Godot 的 L1 Unit、L2 Integration 和 L3 Runtime Scene 是技术上的测试层级，不是与 Yaya 三个测试根目录并列竞争的物理目录。每个测试放在与它保护的契约相匹配的 Yaya 目录中。

## 执行生命周期

- **[必须]** 实现批准、基线以及 RED、GREEN 和重构步骤，遵循 [TDD 执行约定](../../methodology/08-test-traceability-and-evidence.md#tdd-执行约定)。验收、可选的独立审核和完成条件由 [执行流程](../../methodology/03-execute-loop.md) 管理。
- **[必须]** 运行器、选择器和全量套件的行为，遵循 [运行器的边界](../../methodology/08-test-traceability-and-evidence.md#运行器的边界) 和项目的实际配置。项目固定使用 gdUnit4 作为运行器；见 [GdUnit4 运行器配置](gdunit4-profile.md)。
- **[必须]** 脚本解析和 lint 的调用方式、参数与工具边界，遵循 [直接静态检查约定](../../methodology/contracts/gdscript-lint.md)。

如果两条适用的 `[必须]` 规则仍然无法同时满足，按 [规则优先级与路由](../00-core/rule-precedence-and-routing.md#规则冲突的处理流程) 报告真实的规则冲突。不要为了让测试通过而削弱任何一方的要求。
