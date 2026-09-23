# Feature 工作流与 Godot 测试集成

本文件只连接两套规则的职责，不替代本目录中的 Godot 测试实现规则，也不复制
`methodology/08-testing-strategy.md`。

## 权威边界

- **[MUST]** Yaya Loop 负责决定测试什么、为什么测试、选择哪些测试、何时执行，
  以及测试如何关联 Feature、Acceptance Criterion、Bug 和人工验收。
- **[MUST]** 本目录负责具体的 Godot 测试实现，包括 L0-L3 层级、runner 行为、
  fixture、隔离、mock/spy、SceneTree、输入、Signal、异步和诊断处理。
- **[MUST]** Test Impact Review 生成的 Required Test Set 是最低集合；
  `test-selection-and-gates.md` 中基于 Godot 影响范围的门禁可以扩大或升级该集合，
  不能静默删减它。

## 追踪与物理组织

- **[MUST]** 逻辑 ID、测试目录和实际路径/test case 映射遵循
  [测试分类](../../methodology/08-testing-strategy.md#test-taxonomy) 与
  [Registry 规则](../../methodology/08-testing-strategy.md#registry-rules)。
- **[MUST]** Godot 的 L1 Unit、L2 Integration 和 L3 Runtime Scene 是测试技术
  层级，不是与 Yaya 三个目录根互斥的物理目录。测试应放在其所保护契约对应的
  Yaya 目录中。

## 执行生命周期

- **[MUST]** 实现批准、基线和 RED/GREEN/refactor 遵循
  [TDD 执行契约](../../methodology/08-testing-strategy.md#tdd-execution-contract)；
  验收、可选独立审查和完成条件由 [执行流程](../../methodology/03-execute-loop.md) 负责。
- **[MUST]** runner、selector 和 full-suite 遵循
  [Runner 边界](../../methodology/08-testing-strategy.md#runner-boundary) 与实际项目配置；
  本规则集的安装本身不安装或启用 gdUnit4。
- **[MUST]** 脚本解析和 lint 的调用、参数与工具边界遵循
  [直接静态检查契约](../../methodology/gdscript-lint.md)。

如果两套适用的 `[MUST]` 规则仍无法同时满足，按
`agent-rules/00-core/rule-precedence-and-routing.md` 报告真实规则冲突，不得为了
通过测试而弱化任一门禁。
