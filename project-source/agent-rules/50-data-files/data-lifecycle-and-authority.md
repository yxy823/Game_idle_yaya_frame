# 数据生命周期与权威来源

编写、解析、校验、规范化和玩法使用这几个环节保持分开。

## 规范生命周期

```text
Authoring Source
-> Parse
-> Structural Schema Validation
-> Semantic Validation
-> Reference Resolution
-> Normalization
-> Canonical Runtime Configuration
-> Freeze
-> Gameplay Read-only Consumption
```

上面的流程依次为：编写源 → 解析 → 结构 schema 校验 → 语义校验 → 引用解析 → 规范化 → 规范运行时配置 → 冻结 → 玩法只读使用。

外部数据不从解析器的输出直接进入玩法。

## 权威来源

- **[必须]** 每个数据领域声明自己的权威编写源，以及唯一的规范运行时表示。
- **[必须]** 玩法使用经过校验的规范配置，不使用解析器输出的原始 Dictionary、Array 或 Variant。
- **[必须]** 定义数据和配置数据在运行时默认只读，与 [Resource 的角色](../21-resources/roles-sharing-and-locality.md#角色) 中的定义 Resource 相同。
- **[必须]** 原始的 Dictionary、Array 和 Variant 值只留在解析、迁移、扩展或确实动态的边界上；稳定的运行时 schema 使用带类型的模型。
- **[必须]** 玩法和运行时代码不把状态写回 XLSX、YAML 或 CSV 文件等设计编写源。

## 错误

- **[必须]** 区分语法失败、schema 或类型失败、语义失败和引用失败。
- **[必须]** 生产数据校验遇到 Critical 和 Error 结果时失败关闭（拒绝放行）。Agent 不把 Error 降级为 Warning 来换取通过状态。
- **[必须]** 诊断信息指出源文件；能获取时，还指出工作表、行、实体、字段、值、约束和引用目标。

## 运行时加载与打包

在编辑器中可见，不能证明原始运行时数据在导出的包里。

- **[必须]** 通过 FileAccess 加载的原始 `res://` JSON、CSV 或 TXT 文件遵循[导出包含规则](../41-export-config/resources-and-filters.md#打包)。
- **[优先]** 合适时，把规范数据转换为 `.tres`、自定义 Resource 或二进制格式，通过 ResourceLoader 加载，不维护一条原始文件的运行时路径。
- **[必须]** 嵌入项目的原始数据，与外部的 `user://` 或 mod 数据，属于不同的信任与打包领域。

## 信任边界

- **[必须]** 项目编写的可信数据，与不可信的玩家、mod、网络或其他外部数据，使用不同的信任策略。
- **[必须]** 可能出现拒绝服务或病态输入时，不可信数据有明确的大小、深度、形状和 schema 约束。
