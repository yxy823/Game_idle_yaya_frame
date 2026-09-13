# Yaya Loop 测试集成

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

- **[MUST]** Feature acceptance test 使用 Yaya 逻辑 ID `F0XX-ACyy[-NN]`，Bug
  regression test 使用 `F0XX-RTyy`，跨 Feature invariant 使用
  `INV-<DOMAIN>-NN`；实际路径和 test case 记录在 `docs/test-registry.json`。
- **[MUST]** 项目测试按保护对象放在 `tests/unit/`、`tests/features/` 或
  `tests/invariants/`。Regression 是测试来源/类型，不要求独立的
  `tests/regression/`。
- **[MUST]** Godot 的 L1 Unit、L2 Integration 和 L3 Runtime Scene 是测试技术
  层级，不是与 Yaya 三个目录根互斥的物理目录。测试应放在其所保护契约对应的
  Yaya 目录中。

## 执行生命周期

- **[MUST]** 实现前先完成 Yaya Stage 1 Test Impact Review 并获得明确批准，再
  运行 Existing Safety Net；可自动化的新行为或 Bug regression 按 RED、GREEN、
  refactor 推进。
- **[MUST]** 自动验证通过不等于 Feature 完成。先按需求确定验收方式；manual 模式须执行 Stage 5，automated 模式省略该步骤。
  后续 Stage 6 需求符合性与代码质量审查，以及适用完成检查仍须执行。
- **[MUST]** runner、selector 和 full-suite 使用项目配置与已支持参数。
  脚本解析和 lint 按 `methodology/gdscript-lint.md` 直接调用 Godot/插件入口，
  不新增包装程序或静态 manifest。
- **[MUST]** 项目只采用一个主要 Godot test runner。gdUnit4 仅在项目明确采用并
  完成配置后生效；本规则集的安装本身不安装或启用 gdUnit4。

如果两套适用的 `[MUST]` 规则仍无法同时满足，按
`agent-rules/00-core/rule-precedence-and-routing.md` 报告真实规则冲突，不得为了
通过测试而弱化任一门禁。
