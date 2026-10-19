# CSV 规则

本页记录 Godot 导入和读写 CSV 的行为，以及项目对 CSV 的编写和解析要求。编写、解析或写出 CSV 时读。

CSV 适合每行一个实体、每格一个标量值的表格数据，例如数值平衡表。

## 导入方式

- 注意：Godot 默认用翻译导入器（`csv_translation`）导入 `res://` 下的 `.csv` 文件，会把它当作翻译表处理。作为数据读取的 CSV，在导入面板把 Import As 改为 “Keep File (exported as is)”，对应 `.import` 中的 `importer="keep"`。
- 运行时读取的 CSV 是否进入导出包，遵循导出配置规则中的[打包](../41-export-config/resources-and-filters.md#打包)。

## 编写

- 用 Excel 编辑时，另存为 “CSV UTF-8” 格式。
- 数值不写千位分隔符，小数点用 `.`；日期用 ISO 格式，例如 `2026-10-03`。不依赖系统的区域设置。
- 第一行是表头。缺失、重复或未知的表头都是错误。
- 一个单元格只放一个值：
  - 固定的复合值拆成多列，例如 `cost_gold`、`cost_wood`；
  - 一对多数据放进以 ID 关联的子表。
- 单元格需要嵌套结构、多层转义或递归解析时，改用 JSON 或 Resource。

## 解析与写出

- 用 `FileAccess.get_csv_line()` 读取，用 `store_csv_line()` 写出。它们的契约：
  - 文本按 UTF-8 处理；
  - 分隔符恰好一个字符，`get_csv_line()` 不接受 `"` 作为分隔符；
  - 含分隔符的字段用双引号包住，字段内的双引号写成两个双引号；
  - 带引号的字段可以包含换行。
- 按表头名称取列，不按列的位置。
- 每个单元格读出来都是 String，按 schema 显式转换类型，转换失败是错误。注意 `to_int()` 会删除非数字字符后转换，`"x1y2"` 得到 `12`，`"abc"` 得到 `0`，都不报错。转换前先用 `is_valid_int()` 或 `is_valid_float()` 检查。
