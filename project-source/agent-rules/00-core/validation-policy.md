# Validation Policy

Defines evidence rules shared by all specialized validation modules.

## Evidence composition

- **[MUST]** Every changed artifact and affected behavior must satisfy every applicable validation route. Multiple modules add their requirements together.
- **[MUST]** Include relevant tests and the project's supported lint, parsing and type checks when applicable to the changed artifacts. Use configured entrypoints; do not invent an unsupported checker or install a new toolchain solely to fill a generic checklist.
- **[MUST]** A higher-level PASS does not override a lower-level failure.
- **[MUST]** A gate is PASS only if the applicable check was actually executed and completed successfully.
- **[MUST]** Do not substitute one validation class for another unless project rules explicitly define that check as equivalent for the affected contract.
- **[PREFER]** Use repository-provided validation scripts/entrypoints when they encode the supported workflow instead of rebuilding an ad-hoc alternative.
- **[MUST]** Validation wrappers must preserve required underlying failure semantics; a wrapper exit 0 cannot erase a known underlying failure.
- **[PREFER]** Use the tool's supported exit status or structured result instead of console-text guessing.

## Failure handling

- **[MUST]** Do not obtain green status by weakening lint thresholds, expanding ignores, skipping failing tests, disabling error monitoring, lowering schema severity, removing gates, or rewriting rules.
- **[MUST]** Treat a validation failure as evidence requiring classification; do not assume the checker is wrong merely because it blocks completion.
- **[MUST]** After fixing a gate failure, rerun that gate and any additional checks made necessary by the fix.
- **[MUST]** Run all validation routes applicable to the change, not every imaginable expensive gate.
- **[PREFER]** When material impact scope is uncertain, choose a slightly broader relevant validation scope rather than claiming an unjustifiably precise minimum.

## Environment and reporting

- **[MUST]** Environment-specific evidence only proves the environment semantics it actually exercises.
- **[MUST]** When a specialized rule requires fresh process/import/export/target runtime evidence, an existing editor/session result is not a substitute.
- **[MUST]** If an applicable required gate cannot run, report it as not executed/blocked with the reason and unresolved risk. Never assume PASS.
- **[MUST]** Manual acceptance and automated validation are distinct evidence types and must not be reported as each other.
- **[MUST]** Validation artifacts such as logs/JUnit/temp exports follow generated/temp ownership rules and must not silently become production source.

## Windows editor checks

本节适用于项目根 `AGENTS.md` 中“本机 Godot 编辑器检查”所限定的环境；权限与审批要求遵循该入口。

| 触发条件 | 必须执行 |
| --- | --- |
| 出现 `Could not create editor data directory`、`Could not create editor config directory` 或 `AppData/Roaming/Godot` 访问失败 | 按环境权限排查，停止依赖该次成功结果的后续验证；不报告通过，不据此修改业务代码或弱化门禁 |
| 编辑器检查前后 | 比较项目根目录列表，包含 Git 不记录的空目录；新增 `export_templates`、`feature_profiles`、`script_templates` 或 `text_editor_themes` 等异常目录时先核对来源，只对确认由本次运行产生且为空的目录按现有清理规则处理，保留已有同名目录 |
