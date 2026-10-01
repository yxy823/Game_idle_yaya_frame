# 维护脚本

本目录的脚本用于框架维护，参数和详细用法见各 Python 命令的 `--help` 或[维护工具说明](../README.md)。

| 文件 | 用途 |
| --- | --- |
| [create_project.py](create_project.py) | 按复制清单创建空白项目，并建立独立 Git 仓库和初始提交。 |
| [build_blank_project_handbook.py](build_blank_project_handbook.py) | 从 Markdown 构建两本 HTML 手册，并检查链接、收录范围和图表产物。 |
| [check_scenario_prompt_paths.py](check_scenario_prompt_paths.py) | 默认读取 Godot 开发和 Yaya 维护两份提示词库，只读核对名称与场景文件路径是否一一对应。 |
| [check_workflow_graph_names.py](check_workflow_graph_names.py) | 只读核对流程图节点名与提示场景名；忽略 CR/LF 换行，输出匹配、差异、字段位置和候选名称。默认检查可读版 JSON，`--summary` 只显示统计。 |
| [link_workflow_graph_scenarios.py](link_workflow_graph_scenarios.py) | 为可读版 JSON 的节点写入或更新同名场景文件链接；先检查全部名称和文件，`--check` 只读检查。 |
| [run_project_tool_tests.py](run_project_tool_tests.py) | 对明确指定的外部项目运行现有工具回归，不创建或更新项目。 |
| [blank-project-handbook-interactions.js](blank-project-handbook-interactions.js) | HTML 手册的搜索、导航和图表缩放等交互，由构建器嵌入页面。 |
| [blank-project-handbook-page.html](blank-project-handbook-page.html) | HTML 手册共用的页面与样式模板，由构建器填入正文。 |

在仓库根目录运行 `python -B framework/commands/link_workflow_graph_scenarios.py`，默认更新可读版；用 `--graph` 指定其他图。脚本只修改节点的 `link`，会替换已有链接，名称不匹配或目标文件缺失时不写入。链接为当前仓库的绝对本地路径，仓库移动后重新运行即可；Graph_Map 仅展示和复制这些路径，不直接打开文件。

两个 Godot 场景图命令默认读取 `framework/godot-development-prompts.json`；`--prompts` 可指定待检查的单份 JSON。
