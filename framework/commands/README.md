# 维护命令

本页是全部维护命令用法的唯一说明。命令都在仓库根目录、使用已确认的 Python 3.12+ 运行；`-B` 禁止生成字节码缓存。参数细节以各命令的 `--help` 为准。

脚本跟随作用对象存放：只服务一个对象的放在该对象目录下的 `tools/`，创建器、复制清单和跨多处使用的放在本目录。

| 位置 | 命令 | 用途 |
| --- | --- | --- |
| `framework/commands/` | [create_project.py](create_project.py) | 按复制清单创建空白项目，并建立独立 Git 仓库和初始提交 |
| | [project-files.json](project-files.json) | 唯一复制清单，每项只有 `source` 与 `target` |
| | [find_orphan_docs.py](find_orphan_docs.py) | 扫描全仓文档的文本引用，列出孤立候选及引用文件、行号 |
| `framework/prompt-scenarios/tools/` | [check_scenario_prompt_paths.py](../prompt-scenarios/tools/check_scenario_prompt_paths.py) | 只读核对两份提示词库的名称与场景文件路径是否一一对应 |
| | [check_workflow_graph_names.py](../prompt-scenarios/tools/check_workflow_graph_names.py) | 只读核对开发场景图节点名与 Godot 提示词名称 |
| | [link_workflow_graph_scenarios.py](../prompt-scenarios/tools/link_workflow_graph_scenarios.py) | 为开发场景图节点写入或更新同名场景文件链接；`--check` 只读 |
| `framework/relationship-maps/tools/` | [check_document_graph_coverage.py](../relationship-maps/tools/check_document_graph_coverage.py) | 按文档系统图登记的路径检查文档覆盖，只读、显式调用 |

外部项目的工具回归入口是 [tests/external-project/run_project_tool_tests.py](../tests/external-project/run_project_tool_tests.py)，用法见下文「按需检查」。

新增维护脚本按上述规则放置并在上表登记。回归测试与夹具放在 `framework/tests/`。

## 创建空白项目

```powershell
python -B framework/commands/create_project.py --output D:\Games\MyGodotGame
```

创建器按清单预检、复制和重命名，再建立独立 Git 仓库与本地初始提交。目标路径、复制映射、失败处理与执行边界的完整契约见[框架、创建器与项目边界](../docs/operation-manual/foundations/framework-and-project.md#创建器用法)。

## 提示词与场景路径检查

```powershell
python -B framework/prompt-scenarios/tools/check_scenario_prompt_paths.py
```

默认合并两份提示词库的名称，检查 `framework/prompt-scenarios/scenarios/<Project>/<分类>/<提示词名称>.md` 是否一一对应。名称与路径规则见[提示词与场景准则](../docs/framework-maintenance/design-guidelines/prompts-and-scenarios.md)。

- **可选参数**：`--prompts <JSON> [<JSON> ...]`、`--scenarios <目录>`；每份只允许一个 Project，跨文件重复 Project 也会报错。
- **检查范围**：只读检查缺少、多余、重复与非法路径；场景目录根级的 `README.md`、`scenario-index.md` 是导航排除项。
- **退出码**：`0` 集合一致；`1` 缺少或多余；`2` 输入或结构错误。
- **不检查**：正文 H1、具体步骤、授权与语义由作者自查；也不验证实际运行结果。

## 检查场景图名称与链接

```powershell
python -B framework/prompt-scenarios/tools/check_workflow_graph_names.py --summary
python -B framework/prompt-scenarios/tools/link_workflow_graph_scenarios.py --check
```

两个命令默认读取 `framework/prompt-scenarios/prompts/godot-development-prompts.json` 和开发场景图，`--prompts`、`--graph` 可分别指定其他文件。

- **名称检查**：只忽略 CR/LF，报告缺少、多余、重名及节点 ID 重复；去掉 `--summary` 可查看字段位置和候选名称。
- **链接写入**：去掉 `--check` 时只修改节点的 `link`，会替换已有链接；名称不匹配或目标文件缺失时不写入。链接是当前仓库的绝对本地路径，仓库移动后重新运行即可。只读审核不运行写入命令。

两项检查都不覆盖完整格式、连线含义或显示效果；图的维护规则见[关系图说明](../relationship-maps/README.md)。

## 检查文档图覆盖

仅在用户需要找出未纳入文档系统图的文件时运行：

```powershell
python -B framework/relationship-maps/tools/check_document_graph_coverage.py
```

命令只读现有文件、复制清单和文档图，不更新图、不写报告、不生成项目。默认扫描框架与分发源的 Markdown、Markdown/JSON 文档模板，以及文档目录、提示词库、复制清单和项目环境配置中的 JSON，包含 README 与索引页；第三方插件、缓存、个人图谱次数、临时文档、代码配置和素材数据不在范围内。项目区核对分发源对应的目标路径，不扫描已有外部项目；尚未创建的可选产物不会被当作缺失。

- **参数**：`--json` 列出每个文件命中的节点 ID；`--root` 指定框架仓库；`--graph` 指定图文件，相对路径以该仓库为基准。
- **退出码**：`0` 全部覆盖；`1` 存在未覆盖文件；`2` 图或路径登记无法读取、格式错误。
- **结果含义**：覆盖只表示路径归入了某个职责节点，正文是否被使用、引用是否正确仍须另行判断。它与下文的孤立文档检查回答不同问题。

## 检查孤立文档

在仓库根目录运行；使用 Python 标准库，不需要安装依赖：

```powershell
python -B framework/commands/find_orphan_docs.py
```

默认递归检查 Markdown，排除 `README.md`、`index.md`、`*index.md` 这些导航类文件以及下表路径作为检查目标；它们仍作为引用来源参与统计，避免把其引用的其他文档误报成孤立。搜索源码和文档文本，根目录 `tmp/` 中的临时材料不作为检查目标或引用来源。

| 默认不检查的路径（相对仓库根目录） | 原因 |
| --- | --- |
| `project-source/agent-rules/*` | 已认可由领域 README 按任务条件读取规则的路径。 |
| `framework/prompt-scenarios/scenarios/*` | 场景对应关系与索引入口由下述专用检查覆盖。 |
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

分类按引用来源的路径或文件名判断，不分析正文语义。README 中的“在某种任务下读取此文档”属于有效的条件读取入口，也会被计为 `nav`；面向人的场景页、来源与许可说明也可能正常地通过索引或 README 查阅。已认可的对象按上表路径排除；其余 `NAV_ONLY` 仍需核对，不应为变成 `READ` 人为增加无用途的引用。对必须参与执行的规则，还要核对“任务入口 → 条件读取入口 → 规则正文”是否连通。

引用来源 `reader`、`nav`、`history` 分别指普通文件、导航类文件、历史材料，计数为命中行数。引用写法 `link`、`path`、`name` 分别指 Markdown 链接、路径文本、唯一文件名文本；路径后缀与文件名子串可能误指其他文件，仍需核对实际目标，不能据此删除文档。输出中的 `*` 只表示该行含读取或更新等动作词，不是实际执行证据。

`--root` 指定检查目录，`--targets` 显式选择目标时可重新检查导航文件及上表路径，`--nav` 调整导航文件规则，`--json` 输出完整结构化结果并在 `explanations` 中附中文释义；原有分类代码、计数和引用字段保持不变。只有显式指定 `--out` 才写报告，父目录须已存在，临时报告放在根目录 `tmp/` 下。`--exclude` 替换的是同时影响目标和引用来源的目录排除规则（默认排除 Git、缓存、根目录 tmp/ 等），其命中的文件不能被 `--targets` 重新选入。默认扫描完成返回 `0`；使用 `--fail-on-orphan` 时，存在 `NONE` 返回 `1`，其他分类不会触发失败。

### 提示词与场景排除后如何防漏

继续使用现有检查，不把场景是否配对交给孤立文档的文本命中推断：

- [提示词与场景路径检查](#提示词与场景路径检查)核对两份集中提示词库与同名场景页：新增提示词但缺少场景，或新增场景但没有对应提示词，都会返回 `1`。
- 调整场景入口时，核对[场景索引](../prompt-scenarios/scenarios/scenario-index.md)是否包含对应页面、链接是否有效。

路径检查不检查索引收录或正文。提示词或场景变更时按现有[提示词与关系图维护 Skill](../../.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md)同步，普通孤立文档扫描不会自动调用它。

## 按需检查

维护层回归使用系统临时目录，覆盖复制、路径映射、文档指纹与人工验收文件契约：

```powershell
python -B -m unittest discover -s framework/tests/repository -p test_*.py
```

文档指纹和人工文件测试只建立中立 Git 夹具，不创建业务项目或运行游戏；合成结果不证明真实人工体验。

项目工具回归需要明确指定、且已对应本次修改的外部项目：

```powershell
python -B framework/tests/external-project/run_project_tool_tests.py --project D:\Games\MyGodotGame
```

这个入口只运行已有 unittest，不创建或配置项目、不写示例业务台账，也不执行 Godot、人工验收或发布；所测项目的机器配置与无关文件保留。仅静态任务不执行这些回归命令。

真实引擎、lint、gdUnit、Analyzer 协议、资源工作台、保存/恢复、渲染、规模和消费导出夹具按实际变化选择，放置位置、依赖与结果边界见各夹具目录的说明：[工具回归](../tests/external-project/tool-regression/README.md)、[资源工作台](../tests/external-project/workbench/README.md)、[编辑器插件](../tests/external-project/plugins/README.md)。Python 工具通过与真实引擎运行分别记录；夹具文件存在也不证明本轮已执行。
