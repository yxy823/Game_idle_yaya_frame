# 50 数据文件规则

适用于设计数据和运行时数据，例如 JSON、CSV、XLSX 和 YAML 文件，生成的规范数据，schema、迁移和数据校验器。

| 文档 | 何时阅读 |
| --- | --- |
| `data-lifecycle-and-authority.md` | 任何数据修改：从编写源到玩法使用的生命周期、权威来源、错误类别、运行时加载、打包和信任边界 |
| `schema-and-types.md` | 定义或修改字段、语义类型或某个数据领域的结构 |
| `identity-and-references.md` | 定义、重命名或引用业务 ID、别名或关联关系 |
| `normalization-and-determinism.md` | 规范化取值或写出规范输出 |
| `generation-and-derived-data.md` | 编写或修改生成器、派生字段或提交到仓库的生成数据 |
| `schema-evolution.md` | 修改 `schema_version`，或迁移持久化数据或外部数据 |
| `json.md` | 解析、写出或信任 JSON |
| `csv.md` | 解析或编写 CSV |
| `spreadsheet-and-yaml-authoring.md` | 用 XLSX 或 YAML 编写数据 |
| `validation.md` | 任何数据修改：确定需要做哪些验证 |
