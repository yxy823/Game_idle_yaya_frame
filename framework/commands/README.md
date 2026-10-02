# 维护命令清单

本页是全部维护命令的唯一清单，包含随对象放置的命令及其位置；参数和详细用法见各 Python 命令的 `--help` 或[维护工具说明](../README.md)。

与具体对象绑定的命令随对象放置。`commands/` 只放公共或无明确归属的命令。

| 命令位置（相对 framework/） | 用途 |
| --- | --- |
| [commands/create_project.py](create_project.py) | 按复制清单创建空白项目，并建立独立 Git 仓库和初始提交。 |
| [commands/find_orphan_docs.py](find_orphan_docs.py) | 扫描文档的文本引用，按普通、导航和历史引用分类，列出孤立候选及引用文件、行号。 |
| [docs/handbook/build_blank_project_handbook.py](../docs/handbook/build_blank_project_handbook.py) | 从 Markdown 构建两本 HTML 手册，并检查链接、收录范围和图表产物。 |
| [prompt_scenarios/tools/check_scenario_prompt_paths.py](../prompt_scenarios/tools/check_scenario_prompt_paths.py) | 默认读取 Godot 开发和 Yaya 维护两份提示词库，只读核对名称与场景文件路径是否一一对应。 |
| [prompt_scenarios/tools/check_workflow_graph_names.py](../prompt_scenarios/tools/check_workflow_graph_names.py) | 只读核对流程图节点名与提示场景名；忽略 CR/LF 换行，输出匹配、差异、字段位置和候选名称。默认检查可读版 JSON，`--summary` 只显示统计。 |
| [prompt_scenarios/tools/link_workflow_graph_scenarios.py](../prompt_scenarios/tools/link_workflow_graph_scenarios.py) | 为可读版 JSON 的节点写入或更新同名场景文件链接；先检查全部名称和文件，`--check` 只读检查。 |
| [tests/external-project/run_project_tool_tests.py](../tests/external-project/run_project_tool_tests.py) | 对明确指定的外部项目运行现有工具回归，不创建或更新项目。 |

创建器的唯一复制映射为同目录的 [project-files.json](project-files.json)。手册构建的[页面模板](../docs/handbook/assets/blank-project-handbook-page.html)与[交互源码](../docs/handbook/assets/blank-project-handbook-interactions.js)保存在构建器的 `assets/`；它们不是独立命令。按被测对象选择的维护夹具，其调用前提、参数和副作用见[专项验证说明](../docs/framework-maintenance/validating-framework.md#lint-与运行器专项入口)。

在仓库根目录运行 `python -B framework/prompt_scenarios/tools/link_workflow_graph_scenarios.py`，默认更新可读版；用 `--graph` 指定其他图。脚本只修改节点的 `link`，会替换已有链接，名称不匹配或目标文件缺失时不写入。链接为当前仓库的绝对本地路径，仓库移动后重新运行即可；Graph_Map 仅展示和复制这些路径，不直接打开文件。

两个 Godot 场景图命令默认读取 `framework/prompt_scenarios/prompts/godot-development-prompts.json`；`--prompts` 可指定待检查的单份 JSON。

## 检查孤立文档

在仓库根目录运行；使用 Python 标准库，不需要安装依赖：

```powershell
python -B framework/commands/find_orphan_docs.py
```

默认递归检查 Markdown，排除 `README.md`、`index.md`、`*index.md` 这些导航文件作为检查目标；它们仍作为引用来源参与统计。搜索源码和文档文本，不读取生成的 HTML。`NONE` 表示没有其他文件提及，`NAV_ONLY` 表示只有导航引用，`HISTORY_ONLY` 表示只有导航或历史引用；`READ` 仅表示存在其他类别的文本引用，不证明实际读写或执行。路径后缀与唯一文件名也会作为线索，需人工核对，不能据此删除文档。

`--root` 指定检查目录，`--targets` 显式选择目标时可以选中导航文件，`--nav` 调整导航文件规则，`--json` 输出完整结构化结果；只有显式指定 `--out` 才写报告，父目录须已存在。`--exclude` 会替换默认排除项，同时影响目标和引用来源。默认扫描完成返回 `0`；使用 `--fail-on-orphan` 时，存在 `NONE` 返回 `1`，其他分类不会触发失败。
