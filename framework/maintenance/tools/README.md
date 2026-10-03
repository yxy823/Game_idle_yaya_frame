# 维护工具

[框架入口](../../README.md#维护命令)

本目录保存面向全仓文档的维护检查脚本。命令在仓库根目录、使用已确认的 Python 3.12+ 运行；`-B` 禁止生成字节码缓存，参数细节以 `--help` 为准。

## 检查孤立文档

在仓库根目录运行；使用 Python 标准库，不需要安装依赖：

```powershell
python -B framework/maintenance/tools/find_orphan_docs.py
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

- [提示词与场景路径检查](../../prompt-scenarios/tools/README.md#提示词与场景路径检查)核对两份集中提示词库与同名场景页：新增提示词但缺少场景，或新增场景但没有对应提示词，都会返回 `1`。
- 调整场景入口时，核对[场景索引](../../prompt-scenarios/scenarios/scenario-index.md)是否包含对应页面、链接是否有效。

路径检查不检查索引收录或正文。提示词或场景变更时按现有[提示词与关系图维护 Skill](../../../.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md)同步，普通孤立文档扫描不会自动调用它。
