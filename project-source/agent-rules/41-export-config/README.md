# 41 导出配置规则

覆盖 `export_presets.cfg`、导出目标、打包过滤、自定义导出 feature、密钥与签名、`EditorExportPlugin`，以及实际导出的验证。`project.godot` 中的运行时设置见 `40-project-config`。

| 文件 | 何时阅读 |
| --- | --- |
| `presets-and-targets.md` | 任何导出配置修改都读：预设、输出路径、构建模式、模板、目标身份、导出凭据与签名 |
| `resources-and-filters.md` | 修改导出的资源选择或过滤器，新增运行时通过 `FileAccess` 读取的原始文件，或排除测试与编辑器插件 |
| `features-and-export-plugins.md` | 新增、重命名或读取自定义导出 feature，按预设读取 ProjectSettings，或编写、修改 `EditorExportPlugin` |

## 验证

导出配置的修改只有实际导出才能证明。每次验证记录使用的预设名、导出模式（debug、release 或仅 PCK/ZIP）和解析后的产物路径。

| 改动类型 | 需要的验证 |
| --- | --- |
| 任何导出配置修改 | 用对应的预设和模式实际导出，检查导出进程的返回结果和位于解析路径上的产物；其他目录或之前残留的同名产物不算 |
| 资源过滤器、原始文件 | 检查导出包内确实包含或不包含相关路径；从本次导出的产物启动，确认运行时读取成功 |
| 自定义 feature、`EditorExportPlugin` | 实际导出后启动产物，按明确的就绪或成功条件做冒烟测试 |
| 仅 PCK 或 ZIP 导出 | 它不是完整的可执行导出；用 `--main-pack` 或项目的启动方式加载，验证加载契约 |
| 目标、模板或预设 | 检查该目标和模式要求的完整产物集合，不只看一个文件 |
| 只改签名 | 做对应目标的 release 导出和签名检查；其他行为没变时，不需要运行无关的玩法测试 |
