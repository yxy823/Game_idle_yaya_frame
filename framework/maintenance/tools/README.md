# 维护工具

[框架入口](../../README.md#维护命令)

本目录保存面向全仓文档的维护检查脚本，并说明框架仓库怎样使用分发给项目的术语检查、措辞检查，以及提交钩子。命令在仓库根目录、使用已确认的 Python 3.12+ 运行；`-B` 禁止生成字节码缓存，参数细节以 `--help` 为准。

| 工具 | 用途 |
| --- | --- |
| 仓库链接检查 [check_repository_links.py](check_repository_links.py) | 检查维护侧与生成项目中的 Markdown 链接和锚点，以及提示词正文中的路径与标题引用 |
| 孤立文档扫描 [find_orphan_docs.py](find_orphan_docs.py) | 扫描全仓文档的文本引用，列出孤立候选 |

术语检查、措辞检查是分发给项目的脚本，在框架仓库中指定框架的术语表和词表运行，见[检查术语用词](#检查术语用词)与[检查措辞](#检查措辞)；这两项与链接检查、链接文字检查在提交时由[提交钩子](#提交钩子)自动运行。用户每次向 Claude Code 发消息时，[用词提示钩子](#用词提示钩子)按框架术语检查消息正文。

## 检查链接与锚点

文档移动、改名、改标题或整理后，在仓库根目录运行：

```powershell
python -B framework/maintenance/tools/check_repository_links.py
```

分发源中的链接按生成项目的目录编写，在源目录里直接解析会失真。所以脚本分两部分检查：

- **维护侧**：仓库中 `project-source/` 和 `references/` 以外的 Markdown。
- **分发侧**：按[复制清单](../../project-creation/project-files.json)复制到系统临时目录后的项目，报告中的路径映射回 `project-source/` 的源文件。

两部分都调用分发给项目的 [check-markdown-links.py](../../../project-source/tools/checks/check-markdown-links.py)，检查规则与默认排除见项目检查与测试工具的[check-markdown-links.py](../../../project-source/tools/README.md#check-markdown-linkspy)。临时副本不初始化 Git，运行后删除。

另外检查两份[提示词库](../../prompt-scenarios/prompts/)正文中的纯文本引用：

- **路径**：以 `framework/`、`project-source/`、`.agents/` 开头的路径要存在，含 `*` 的按通配匹配。生成项目内的路径（如 `docs/`、`yaya/`）不核对。
- **标题**：`<文件> 的「标题」` 写法（“的”可省略）中，标题要是该 Markdown 文件中的标题。不带目录的文件名（如 `AGENTS.md`）只在维护提示词库中按仓库根目录解析；Godot 提示词中的同名文件指生成项目里的文件，跳过。

失效项以 `<提示词库>:<条目所在行>  <条目名>: <引用>` 报告。检查只能发现不存在的路径和标题，引用是否重复、是否指向正确的对象仍由作者核对。

加 `--check-link-text` 时，两部分另外运行分发给项目的 [check-link-text.py](../../../project-source/tools/checks/check-link-text.py)，与链接检查共用同一份临时副本，列出链接文字与目标标题不符的链接，分发侧的路径同样映射回源文件；提示词正文不比较链接文字。比较规则见项目检查与测试工具的[check-link-text.py](../../../project-source/tools/README.md#check-link-textpy)。[提交钩子](#提交钩子)在不带选项的链接检查通过后，再带这个选项运行一次。

退出码：`0` 没有失效链接，加 `--check-link-text` 时也没有不符合的链接文字；`1` 存在失效链接或不符合的链接文字；`2` 检查没能完成，例如生成项目副本创建失败或子检查异常退出，原因写在标准错误中。

## 检查术语用词

修改[框架术语](../../terminology.md)的“不用的说法”列，或统一用词之后，在仓库根目录运行分发给项目的检查脚本，指定框架术语文件，扫描全仓的 Markdown（包括 `project-source/`）、两份提示词库和关系图数据。提示词库的正文会原样显示在用户的快捷浮窗里；关系图的节点说明也是给人读的文字，提交钩子会检查暂存的这两类 JSON，全仓检查时也要包括：

```powershell
python -B project-source/tools/checks/check-terminology.py --terms framework/terminology.md --include "*.md" --include "framework/prompt-scenarios/prompts/*.json" --include "framework/relationship-maps/*.json" --exclude references
python -B project-source/tools/checks/check-terminology.py --terms framework/terminology.md --include "*.md" --include "framework/prompt-scenarios/prompts/*.json" --include "framework/relationship-maps/*.json" --exclude references --discover
```

只检查本次改过的文件时，把文件直接写在命令后面，改过的提示词 JSON 也一样，例如 `python -B project-source/tools/checks/check-terminology.py --terms framework/terminology.md AGENTS.md framework/prompt-scenarios/prompts/yaya-maintenance-prompts.json`。不用 `--include` 选单个文件：不带目录的 `--include README.md` 会选中所有目录中的 `README.md`。

这项检查只比对文字，不解析链接，所以直接扫描源目录，不需要像链接检查那样先复制成生成项目。检查规则、参数、输出格式和退出码见项目检查与测试工具的[check-terminology.py](../../../project-source/tools/README.md#check-terminologypy)。

## 检查措辞

写完或改过文档后，在仓库根目录运行分发给项目的措辞检查；它默认读取脚本同目录的配置 `project-source/tools/checks/wording-check.json`，框架仓库和生成项目用的是同一份配置：

```powershell
python -B project-source/tools/checks/check-wording.py <改过的文件>
python -B project-source/tools/checks/check-wording.py --include "*.md" --include "framework/prompt-scenarios/prompts/*.json" --level hard
python -B project-source/tools/checks/check-wording.py --list
```

第一条列出硬性命中和待复核的命中，第二条只查全仓规则文件中的硬性命中，第三条列出全部检查项。框架仓库按同一套路径规则识别规则文件：根 `AGENTS.md`、`project-source/Project_AGENTS.md`、模板 `project-source/defaults/docs/project-rules.md`、`project-source/agent-rules/`、`project-source/methodology/`、两处 `skills/` 中的 `SKILL.md` 与 `references/`、两份提示词库，以及框架侧的场景速查手册入口 `framework/prompt-scenarios/scenarios/README.md` 和 `framework/maintenance/design-guidelines/` 下的文件。配置格式、判定方式、参数和退出码见项目检查与测试工具的[check-wording.py](../../../project-source/tools/README.md#check-wordingpy)。

## 提交钩子

仓库根目录的 `.githooks/pre-commit` 在每次 `git commit` 时运行。本次暂存了 `.md` 或 `.json` 文件，或者暂存了框架 Skill 时，它运行下表中适用的检查，任何一项失败就拒绝提交：

| 检查 | 范围 | 失败条件 |
| --- | --- | --- |
| [检查术语用词](#检查术语用词)，`--terms framework/terminology.md` | 本次新增、修改或改名的 `.md` 与 `.json` 文件，删除的不查 | 有不用的说法 |
| [检查措辞](#检查措辞) `--level hard` | 同上 | 规则文件中有硬性检查项的命中 |
| [检查链接与锚点](#检查链接与锚点) | 整个仓库，因为改标题或删文件会让其他文档中的链接失效 | 有失效链接 |
| 链接文字检查：同一脚本加 `--check-link-text` | 同上；链接检查通过后才运行，因为带这个选项时失效链接也会让脚本失败，分开运行才能分别报告两项 | 有链接文字与目标标题不符的链接 |
| Skill 目录一致性（钩子内置，没有单独的脚本） | 本次暂存了 `.agents/skills/` 或 `.claude/skills/` 下的任何文件时，比较暂存区中两个目录的内容 | 两个目录不同。Codex 读前者，Claude Code 读后者，所以两份必须相同 |

既没有暂存 `.md` 或 `.json` 文件，也没有暂存框架 Skill 时直接通过；只暂存了框架 Skill 中的非文档文件时，只运行 Skill 目录一致性检查。钩子检查工作区中的文件内容，不是暂存区；它用 PATH 中的 `python` 运行检查。被拒绝后，按输出中的位置改正文档，重新 `git add` 再提交。

钩子不随 clone 自动启用。新 clone 本仓库后，在仓库根目录运行一次：

```powershell
git config core.hooksPath .githooks
```

同一目录还有下文的[提交说明钩子](#提交说明钩子)和[提交后生成 Q&A 页面](#提交后生成-qa-页面)钩子，启用这一次就一起生效。

生成项目使用分发源中的另一份钩子，由创建器启用，见项目检查与测试工具的[提交钩子](../../../project-source/tools/README.md#提交钩子)。

## 提交说明钩子

`.githooks/commit-msg` 用[检查术语用词](#检查术语用词)检查提交说明，有不用的说法就拒绝提交。它把整份说明从标准输入交给术语检查的 `--stdin-text`。提交钩子只查暂存的文件，所以提交说明由这个钩子单独检查。

用 `-m` 或 `-F` 提交时，`#` 开头的行也会写进提交说明，所以钩子不跳过它们，只截掉 `git commit -v` 附带的差异；用编辑器写说明时，git 模板里的注释行也一起检查。找不到 python 时拒绝提交并单独说明原因。

说明改名时只写新名称；直接写出旧名称会被拒绝，旧名称已登记在术语表里，不需要在提交说明里重复。

## 提交后生成 Q&A 页面

`framework/qa/pages/` 下的 HTML 页面被根 `.gitignore` 忽略，不提交。仓库根目录的 `.githooks/post-commit` 在每次提交完成后检查：这次提交改了 `framework/qa/` 下的文件或 `project-source/skills/qa-explainer/scripts/` 下的渲染脚本时，运行 `node project-source/skills/qa-explainer/scripts/qa-build.mjs framework/qa`，重新生成全部主题页和首页。

- 提交已经完成，生成失败不会撤销提交，只在终端打印一行提示，按提示手动运行同一条命令查看错误。
- 只改了主题文件、还没提交时，页面不会更新；想提交前先看效果，手动运行同一条命令。
- 用 PATH 中的 `node` 运行；启用方式与提交钩子相同。

## 用词提示钩子

仓库根目录的 `.claude/settings.json` 注册 Claude Code 的 `UserPromptSubmit` 钩子，运行分发源中的 `project-source/tools/checks/check-prompt-terminology.py --terms framework/terminology.md`：用户消息中有[框架术语](../../terminology.md)登记的不用说法时，提示 Agent 按个人沟通规则中的用词对照规则列出对照表；钩子不拦截消息，也不记录。这份配置随仓库提交，Claude Code 打开本仓库时直接生效，不需要另外启用；用户本机的 `.claude/settings.local.json` 不受影响。

提示内容、不输出的情况和退出码见项目检查与测试工具的[用词提示钩子](../../../project-source/tools/README.md#用词提示钩子)。生成项目从分发源 `project-source/defaults/.claude/settings.json` 得到自己的一份，读取项目的 `docs/terminology.md`。

## 检查孤立文档

在仓库根目录运行；使用 Python 标准库，不需要安装依赖：

```powershell
python -B framework/maintenance/tools/find_orphan_docs.py
```

检查范围：

- **检查目标**：递归检查所有 Markdown，但不检查导航类文件（`README.md`、`index.md`、`*index.md`）和下表中的路径。
- **引用来源**：在源码和文档文本中搜索引用。导航类文件虽然不被检查，仍会作为引用来源统计，避免把它们引用的文档误报为孤立。
- **排除**：根目录 `tmp/`、`references/` 和 `.claude/` 中的材料默认既不检查，也不作为引用来源。

| 默认不检查的路径（相对仓库根目录） | 原因 |
| --- | --- |
| `project-source/agent-rules/*` | 已认可由领域 README 按任务条件读取规则的路径。 |
| `framework/prompt-scenarios/scenarios/*` | 场景对应关系与索引入口由下述专用检查覆盖。 |
| `framework/qa/*` | 主题文件由生成的首页 `index.html` 列出，Q&A 的[主题](../../qa/README.md#主题)一节说明有意不在 Markdown 中另列。 |
| `project-source/addons/resources_spreadsheet_view/LICENSE.md` | 保留的第三方插件许可。 |

目录通配也包含子目录。这张表维护在脚本的 `DEFAULT_TARGET_EXCLUDE` 中，只排除列出的路径，不是对所有 `NAV_ONLY` 结果的豁免；终端和 JSON 输出的 `target_exclusions` 会列出本次生效的排除规则。

每个文件会得到一个分类（终端同时显示代码和中文说明）：

| 分类代码 | 含义 |
| --- | --- |
| `NONE` | 未识别到其他文件引用；可能没有入口，也可能是引用写法未被识别。 |
| `NAV_ONLY` | 仅被按文件名规则归为导航类的文件引用；需要核对这些入口的用途。 |
| `HISTORY_ONLY` | 有历史引用、无普通引用；可以同时有导航引用。 |
| `READ` | 存在导航、历史规则之外的普通文件引用；不证明实际读写或执行。 |

怎样理解分类：

- 分类只看引用来源的路径或文件名，不分析正文含义。
- README 里写“某种任务下读取此文档”是有效的条件读取入口，但同样计为 `nav`；面向人阅读的场景页、来源与许可说明，也可能正常地只通过索引或 README 查阅。
- 已认可的对象按上表排除；其余 `NAV_ONLY` 要逐个核对入口用途，不要为了变成 `READ` 而人为添加没有用途的引用。
- 对于必须参与执行的规则，还要核对“任务入口 → 条件读取入口 → 规则正文”这条链是否连通。

输出中的字段：

| 字段 | 含义 |
| --- | --- |
| `reader` / `nav` / `history` | 引用来源分别是普通文件、导航类文件、历史材料；数字是命中的行数 |
| `link` / `path` / `name` | 引用写法分别是 Markdown 链接、路径文本、唯一文件名文本。路径后缀和文件名子串可能误指其他文件，要核对实际目标，不能据此删除文档 |
| `*` | 该行含有“读取”“更新”等动作词，只是提示，不说明实际执行过 |

参数：

| 参数 | 作用 |
| --- | --- |
| `--root` | 指定要检查的目录 |
| `--targets` | 显式选择检查目标；可以借此重新检查导航文件和上表中的路径 |
| `--nav` | 调整哪些文件算导航类 |
| `--json` | 输出完整的结构化结果，`explanations` 中附中文释义；分类代码、计数和引用字段不变 |
| `--out` | 写入报告文件，父目录必须已存在；临时报告放在根目录 `tmp/` 下。不指定就不写文件 |
| `--exclude` | 替换目录排除规则（默认排除 Git、缓存、根目录 `tmp/` 和 `references/` 等）。它同时影响检查目标和引用来源，被它排除的文件不能再用 `--targets` 选回 |
| `--fail-on-orphan` | 存在 `NONE` 时返回 `1`；其他分类不会导致失败 |

默认情况下，扫描完成即返回 `0`。

### 提示词与场景排除后如何防漏

继续使用现有检查，不把场景是否配对交给孤立文档的文本命中推断：

- [提示词与场景路径检查](../../prompt-scenarios/tools/README.md#提示词与场景路径检查)核对两份预设提示词库与同名场景页：新增提示词但缺少场景，或新增场景但没有对应提示词，都会返回 `1`。
- 调整场景入口时，核对[场景速查索引](../../prompt-scenarios/scenarios/scenario-index.md)是否包含对应页面、链接是否有效。

路径检查不检查索引收录或正文。提示词或场景变更时按现有的 [prompt-and-graph-maintenance-yaya](../../../.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md) 同步，普通孤立文档扫描不会自动调用它。
