# JSON 规则

本页记录 Godot 4.7 `JSON` 类容易出错的行为，以及项目对 JSON 数据的要求。

## 解析

- 生产加载器使用 `JSON` 实例的 `parse()`，先检查返回的 `Error`。失败时用 `get_error_line()` 和 `get_error_message()` 报告位置。
- 不用 `JSON.parse_string()` 的返回值是否为 `null` 判断失败：合法的 JSON `null` 也返回 `null`。
- 解析成功只说明语法可接受。结构和取值仍按[数据 schema、身份与迁移](schema-identity-and-migration.md)中的 schema 校验。
- 注意：Godot 的解析器比 JSON 标准宽松，以下写法都不报错：
  - 对象中的重复键，后出现的值静默覆盖前一个；
  - 对象和数组末尾多余的逗号。

  编写或生成 JSON 时避免这两种写法。需要机器检查重复键时，用 Python `json` 模块的 `object_pairs_hook`。
- 注意：解析后所有数字都是 `float`，包括 `3` 这样的整数写法。整数字段先确认值是整数，再用 `int()` 转换，不用 `typeof(value) == TYPE_INT` 判断。
- 需要精确保存的大于 2^53 的整数，写成十进制字符串。
- 注意：写出时 Dictionary 的键都会转为 String。以整数为键的映射，读回后显式转换键的类型。

## 规范写出

- 写出规范 JSON 时，显式传入 `JSON.stringify()` 的 `indent`、`sort_keys` 和 `full_precision`。它们的默认值分别是 `""`、`true`、`false`。
- 需要读回后数值完全一致的浮点数据，使用 `full_precision = true`。
- 写出前检查并拒绝 NaN 和 ±Inf。注意 `JSON.stringify()` 遇到它们不报错：`INF` 写成 `1e99999`，`-INF` 写成 `-1e99999`，NaN 写成 `null` 并打印一次警告。

## 信任

- `JSON.from_native()` 与 `JSON.to_native()` 使用 Godot 专有的编码（例如 `"i:3"`、`"f:inf"`），不作为与其他程序交换数据的格式。
- 不对不可信数据调用 `JSON.to_native()` 并传入 `allow_objects = true`：它会按数据内容重建任意对象。
- 外部数据中的类名、脚本或场景路径、资源路径、方法名，不直接用于加载、实例化或调用。先把它校验为稳定的 ID 或枚举，再通过项目自己的注册表查找。
