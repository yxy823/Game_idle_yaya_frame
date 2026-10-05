# 框架待办

## 撤回 Feature 时的验证字段处理

- **问题**：Feature 撤回且没有替代项时，规则只要求删除它的 `planned` 测试登记（[apply-plan-changes.md](../project-source/skills/feature-sync/references/apply-plan-changes.md)、[02 规范](../project-source/methodology/02-feature-list-schema.md)），没写清 AC 中指向这些测试的映射和 `acceptance_mode` 怎么处理；`check-feature-list.py` 仍检查作废条目的测试引用，按现有规则操作可能卡在最终校验。
- **下一步**：先决定撤回后验证字段的一致状态（例如清空映射并把 `acceptance_mode` 置回 `null`），再改规则与检查器，补一个撤回回归。

## 继承的测试方法的身份

- **问题**：`gdunit_evidence_runner.gd` 只用 `test.source_file` 构造测试身份；两个派生套件继承同一基类测试方法时，可能得到相同身份而被判重复，或与登记的派生路径不一致。只经静态推演，未实际运行。
- **下一步**：在指定外部项目中用两个共享基类测试方法的派生套件运行一次，对照 discovery、JUnit 和登记路径，确认实际错配位置后再改；不放宽重复项或缺项检查。
