# 忽略文件与原始文件

`.gdignore`、通过 FileAccess 读取原始文件、Godot 的导入可见性、Git 和导出是相互独立的问题。

## 忽略文件

- **[必须]** `.gdignore` 所在的目录不会被导入，普通的 Godot Resource 加载也看不到它。不要把运行时 Resource 放在那里。
- **[必须]** 不要用 `.gdignore` 隐藏测试运行器必须加载的测试。
- **[必须]** 不要不检查运行时和导入依赖，就只为了减少杂乱而添加 `.gdignore`。
- **[必须]** `.gdignore` 和 `.gitignore` 的语义不同，不能互相代替。

## 运行时原始文件

- **[必须]** 在导出的构建中，玩法不把对已导入源文件扩展名的目录枚举当作权威注册表。
- **[必须]** 通过 FileAccess 读取的运行时原始资源和数据，遵循[导出包含规则](../41-export-config/resources-and-filters.md#打包)。
