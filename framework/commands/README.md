# 维护命令清单

本页是全部维护命令的唯一清单，包含随对象放置的命令及其位置；参数和详细用法见各 Python 命令的 `--help` 或[维护工具说明](../README.md)。

与具体对象绑定的命令随对象放置。`commands/` 只放公共或无明确归属的命令。

| 命令位置（相对 framework/） | 用途 |
| --- | --- |
| [commands/create_project.py](create_project.py) | 按复制清单创建空白项目，并建立独立 Git 仓库和初始提交。 |
| [commands/find_orphan_docs.py](find_orphan_docs.py) | 扫描文档的文本引用，按普通、导航和历史引用分类，列出孤立候选及引用文件、行号。 |
| [docs/workflow-maps/check_document_graph_coverage.py](../docs/workflow-maps/check_document_graph_coverage.py) | 按文档图备注的文件路径检查文档覆盖；只读、显式调用，范围与结果含义见[图谱说明](../docs/workflow-maps/README.md#按需检查文档覆盖)。 |
| [prompt_scenarios/tools/check_scenario_prompt_paths.py](../prompt_scenarios/tools/check_scenario_prompt_paths.py) | 默认读取 Godot 开发和 Yaya 维护两份提示词库，只读核对名称与场景文件路径是否一一对应。 |
| [prompt_scenarios/tools/check_workflow_graph_names.py](../prompt_scenarios/tools/check_workflow_graph_names.py) | 只读核对流程图节点名与提示场景名；忽略 CR/LF 换行，输出匹配、差异、字段位置和候选名称。默认检查可读版 JSON，`--summary` 只显示统计。 |
| [prompt_scenarios/tools/link_workflow_graph_scenarios.py](../prompt_scenarios/tools/link_workflow_graph_scenarios.py) | 为可读版 JSON 的节点写入或更新同名场景文件链接；先检查全部名称和文件，`--check` 只读检查。 |
| [tests/external-project/run_project_tool_tests.py](../tests/external-project/run_project_tool_tests.py) | 对明确指定的外部项目运行现有工具回归，不创建或更新项目。 |

创建器的唯一复制映射为同目录的 [project-files.json](project-files.json)。按被测对象选择的维护夹具，其调用前提、参数和副作用见[专项验证说明](../docs/framework-maintenance/validating-framework.md#lint-与运行器专项入口)。

在仓库根目录运行 `python -B framework/prompt_scenarios/tools/link_workflow_graph_scenarios.py`，默认更新可读版；用 `--graph` 指定其他图。脚本只修改节点的 `link`，会替换已有链接，名称不匹配或目标文件缺失时不写入。链接为当前仓库的绝对本地路径，仓库移动后重新运行即可；Graph_Map 仅展示和复制这些路径，不直接打开文件。

两个 Godot 场景图命令默认读取 `framework/prompt_scenarios/prompts/godot-development-prompts.json`；`--prompts` 可指定待检查的单份 JSON。

## 检查孤立文档

在仓库根目录运行；使用 Python 标准库，不需要安装依赖：

```powershell
python -B framework/commands/find_orphan_docs.py
```

默认递归检查 Markdown，排除 `README.md`、`index.md`、`*index.md` 这些导航类文件以及下表路径作为检查目标；它们仍作为引用来源参与统计，避免把其引用的其他文档误报成孤立。搜索源码和文档文本，根目录 `tmp/` 中的临时材料不作为检查目标或引用来源。

| 默认不检查的路径（相对仓库根目录） | 原因 |
| --- | --- |
| `project-source/agent-rules/*` | 已认可由领域 README 按任务条件读取规则的路径。 |
| `framework/prompt_scenarios/scenarios/*` | 场景对应关系与索引入口由下述专用检查覆盖。 |
| `project-source/addons/sound_manager/UPSTREAM.md` | 保留的上游来源说明。 |
| `project-source/asset_workbench/examples/effects_composition/example_brackeys_license.md` | 保留的素材原始许可说明。 |
| `project-source/addons/resources_spreadsheet_view/LICENSE.md` | 保留的第三方插件许可。 |

目录通配覆盖其子目录；排除项维护在脚本的 `DEFAULT_TARGET_EXCLUDE`，不是对所有 `NAV_ONLY` 的统一豁免。终端和 JSON 的 `target_exclusions` 会列出本次生效的目标排除规则。终端输出同时显示分类代码和中文说明：

| 分类代码 | 含义 |
| --- | --- |
| `NONE` | 未识别到其他文件引用；可能没有入口，也可能是引用写法未被识别。 |
| `NAV_ONLY` | 仅被按文件名规则归为导航类的文件引用；需要核对这些入口的用途。 |
| `HISTORY_ONLY` | 有历史引用、无普通引用；可以同时有导航引用。 |
| `READ` | 存在导航、历史规则之外的普通文件引用；不证明实际读写或执行。 |

分类按引用来源的路径或文件名判断，不分析正文语义。README 中的“在某种任务下读取此文档”属于有效的条件读取入口，也会被计为 `nav`；面向人的场景页、来源与许可说明也可能正常地通过索引或 README 查阅。已认可的对象按上表路径排除；其余 `NAV_ONLY` 仍需核对，不应为变成 `READ` 人为增加无用途的引用。对于必须参与执行的规则，应核对“上层任务入口 → 条件读取入口 → 规则正文”是否连通，以及读取条件是否明确；只有泛泛列名而没有适用条件时，仍需检查是否缺少实际使用入口。

引用来源 `reader`、`nav`、`history` 分别指普通文件、导航类文件、历史材料，计数为命中行数。引用写法 `link`、`path`、`name` 分别指 Markdown 链接、路径文本、唯一文件名文本；路径后缀与文件名子串可能误指其他文件，仍需核对实际目标，不能据此删除文档。输出中的 `*` 只表示该行含读取或更新等动作词，不是实际执行证据。

`--root` 指定检查目录，`--targets` 显式选择目标时可重新检查导航文件及上表路径，`--nav` 调整导航文件规则，`--json` 输出完整结构化结果并在 `explanations` 中附中文释义；原有分类代码、计数和引用字段保持不变。只有显式指定 `--out` 才写报告，父目录须已存在，临时报告放在根目录 `tmp/` 下。`--exclude` 替换的是同时影响目标和引用来源的目录排除规则（默认排除 Git、缓存、根目录 tmp/ 等），其命中的文件不能被 `--targets` 重新选入。默认扫描完成返回 `0`；使用 `--fail-on-orphan` 时，存在 `NONE` 返回 `1`，其他分类不会触发失败。

### 提示词与场景排除后如何防漏

继续使用现有检查，不把场景是否配对交给孤立文档的文本命中推断：

- [提示词与场景路径检查](../README.md#提示词与场景路径检查)核对两份集中提示词库与同名场景页：新增提示词但缺少场景，或新增场景但没有对应提示词，都会返回 `1`。
- 调整场景入口时，核对[场景索引](../prompt_scenarios/scenarios/scenario-index.md)是否包含对应页面、链接是否有效。

路径检查不检查索引收录或正文。提示词或场景变更时按现有[提示词与关系图维护 Skill](../../.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md)同步，普通孤立文档扫描不会自动调用它。
