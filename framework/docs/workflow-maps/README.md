# 文档关系图、开发场景图与 JSON 格式

[文档入口](../README.md) · [文档系统关系图](document-system.readable.json) · [开发场景图](game-development-workflow.readable.json)

本目录保存两张用途不同、使用同一 Graph_Map 格式的关系图。它们只在框架维护仓库保存，不进入生成项目，也不建立运行依赖或跨项目自动同步。

| 要了解什么 | 图文件 |
| --- | --- |
| 文档从哪里找到，设计、任务、实现说明和验证依据怎样关联 | [document-system.readable.json](document-system.readable.json) |
| 当前开发场景可以衔接哪些其他场景 | [game-development-workflow.readable.json](game-development-workflow.readable.json) |

## 打开与保存

在当前 Graph_Map 的 Windows Edge 页面中点击“打开图目录”，选择 `D:/A_Games/Game_idle_yaya_frame/framework/docs/workflow-maps`，再选择要看的图文件，一并读取该图和对应次数文件。打开会替换当前画布，有未保存内容时按查看器提示处理。点击“保存”或按 Ctrl+S 分别保存有修改的图和次数，单改次数不重写主图；“另存为”将两份文件保存到新目录，成功后切换关联。刷新后需重新打开目录，缩放和平移是临时视图状态。

两张图使用不同的稳定 `documentId`。个人次数另存本目录的本地 JSON，不纳入 Git；新图没有次数文件时从全图 0 次开始。节点的本地链接由查看器展示和复制，不直接打开文件。

## 文档系统关系图

上区是框架维护仓库，下区是生成后的游戏项目。节点按文档职责或产物类型组织，例如 GDD、Product、Feature、原始测试报告；不是全仓文件清单。“资源规格与准备”代表所属设计中的章节，Feature notes 归入任务详情，不为画图额外拆出文档。

每个文档节点的标题显示职责与文件名，备注说明实际位置、初始或按需创建状态，以及关键引用关系，并以固定格式登记文件路径。节点链接指向当前仓库可读的入口、分发源、模板或规范；按需产物尚未生成时，不链接虚构的项目文件。分区标题与图例是阅读辅助。填色用于区分材料类别，不表示任务状态或是否通过验证。

连线按标签理解，四类方向如下：

| 外观 | 箭头含义 | 例子 |
| --- | --- | --- |
| 灰色虚线 | 阅读入口 → 可查阅的目标 | Feature 索引 → 任务详情；项目 Progress → 执行历史 |
| 蓝色实线 | 要求或约定 → 使用、细化它的材料 | GDD → Product；共享美术规范 → UI 设计 |
| 紫色虚线 | 记录 → 所引用或按身份关联的依据、证据 | 完成证据 → 原始测试报告；局部设计 → 当前架构 |
| 橙色实线 | 来源 → 创建时复制的结果，具体动作见标签 | 分发源 → 创建后的项目入口 |

蓝线表达来源如何被采用，不表示文件超链接的书写方向；紫线可能通过 Feature ID 关联记录，不声称每种关系都有独立 JSON 字段。橙色跨区线表示创建时复制，创建后项目独立维护。所有箭头都不表示自动执行或新增授权。

例如查看“商店购买”的文档，可以从游戏职责指南进入 GDD，沿界面与获得反馈找到 UI、表现方案和资源章节；沿 Product 找到具体 Feature、局部设计与当前架构；最后由 AC、测试登记和完成证据找到实际检查原件。Progress 保留当前停点，完成历史和知识条目各自引用原记录。这条查找路径不要求每项功能都创建所有可选文档，也不代表空白项目已有商店。

### 联系与孤立的判断

当前规范要求各材料有合适的入口和用途：设计由所属目录或来源文档进入，Feature 由任务索引进入，局部设计从 notes 进入，报告由所属任务或 Progress 引用，知识条目从主题索引进入。正文维护一份，使用方引用它；规范依据见[专业来源](../../../project-source/methodology/11-specialist-workflows.md)、[Feature 结构](../../../project-source/methodology/02-feature-list-schema.md)、[架构](../../../project-source/methodology/10-architecture-overview.md)及[产物生命周期](../../../project-source/methodology/09-artifact-lifecycle.md)。

“没有人链接它”“缺少必要来源”和“完全没有关联”是不同问题。报告等末端产物可以只有入口，不必人为添加回链或连到所有文档。图只展示现有契约中的主要关系，不能代替对具体游戏项目中实际正文、来源覆盖和证据原件的核对，也不能凭图中有线就认定关联已经落实。

### 维护与检查

文档职责、路径、产物归属或实际引用契约改变时，由[提示词与关系图维护 Skill](../../../.agents/skills/prompt-and-graph-maintenance-yaya/SKILL.md)局部更新对应节点、备注、链接和连线；不把新增一份同类报告或 Feature 当作新增节点。节点改名保留 ID，不按文件数、排序或当前任务状态重画整个系统。图不保存另一套流程正文、任务状态或孤立文件台账。

文档图使用 `doc-`、`relation-` 标识文档节点与连线，`caption-`、`legend-` 标识阅读辅助。核对实际链接、全局 ID 唯一性、端点、单向箭头、节点尺寸和保存格式，并沿本次受影响的具体查找场景检查关系含义。开发场景的名称与链接脚本只处理场景图；文档图的全仓覆盖扫描按下文显式调用，不接入每次维护或提交。

### 节点名称与文件登记

固定产物在标题独立一行显示准确文件名，例如 `feature-list.json`；按需同类产物显示约定名称，例如 `F0XX.json`、`F0XX-design.md`。目录型节点显示入口名及同类文件模式。所属设计中的资源章节仍保存在原设计文件内，不为节点创建独立文件。

每个 `doc-` 节点在 `note` 的独立行登记路径，冒号后留一个空格，一行只写一个路径；仍使用现有 `note` 字符串，不增加 Graph_Map 字段：

```text
文件： framework/docs/terminology.md
项目文件： docs/features/F[0-9][0-9][0-9].json
```

`文件：` 后是框架仓库相对路径；`项目文件：` 后是生成项目相对路径。分发源到项目的换算只读取[复制清单](../../commands/project-files.json)，不另建源与目标映射。同一模板复制到两个位置时，两处分别检查。引用链接仍指向能打开的源文件或规范，路径登记可以描述尚未生成的可选产物。

路径区分大小写，使用 `/`；`*`、`?`、`[0-9]` 只匹配当前目录的一段名称，独立的 `**` 匹配零层或多层目录。标题中的 `F0XX.json` 是给人阅读的示例，登记使用 `F` 加三位数字的模式；编号是否有效仍由 Feature 规范与检查器判断。按职责选择准确文件或类型目录，不能用整个仓库的通配规则掩盖遗漏。

### 按需检查文档覆盖

用户需要找出未纳入文档图的文件时，在仓库根目录显式运行：

```powershell
python -B framework/docs/workflow-maps/check_document_graph_coverage.py
```

命令只读现有文件、复制清单和文档图，不更新图、不写报告、不生成项目。默认扫描框架与分发源的 Markdown、Markdown/JSON 文档模板，以及文档目录、提示词库、复制清单和项目环境配置中的 JSON；包含 README 与索引页。第三方插件、缓存、个人图谱次数、临时文档、代码配置和素材数据不在文档覆盖范围内。项目区核对分发源对应的目标路径，不扫描已有外部项目；尚未创建的可选产物不会被当作缺失文件。

输出检查总数、覆盖数和未覆盖路径；`--json` 还列出每个文件命中的节点 ID。`--root` 可指定框架仓库，`--graph` 可指定图文件，相对图路径以该仓库为基准。全部覆盖返回 `0`，存在未覆盖文件返回 `1`，图或路径登记无法读取、格式错误返回 `2`。覆盖只表示路径归入了某个职责节点，正文是否被使用、引用是否正确仍须另行判断。

孤立文档的文本引用检查使用[命令清单中的独立入口](../../commands/README.md#检查孤立文档)，它默认排除 README 与索引页作为目标；两个工具回答的问题不同。

## 游戏项目开发场景图

[game-development-workflow.readable.json](game-development-workflow.readable.json) 展示 [Godot 开发提示词库](../../prompt_scenarios/prompts/godot-development-prompts.json)的全部场景及其衔接关系，不包含 `Yaya 框架维护` 场景。节点只显示提示场景名称，不复制提示词正文，不新增阶段、判断、标题或说明节点。具体操作仍查对应提示词或[场景索引](../../prompt_scenarios/scenarios/scenario-index.md)。

图中保存为阅读调整的布局、文字换行、尺寸和连线外观，以及同名场景文件链接和三条替代表达备注。已有名称检查和链接维护命令默认处理此文件；提示词顺序变化不要求重排整图。

### 阅读与维护

节点按实际关系安排主线和分支位置，维护时保留已有布局。颜色只辅助辨认分类，不表示任务状态；分类名称不另建节点。

- **蓝色实线**：常见交付路径中的场景衔接，仍需满足线上的条件。
- **灰色虚线**：按需选择、替代入口、问题处理或续接关系。箭头不代表自动执行或新增授权。
- **条件标签**：说明何时可转入目标场景，不替代提示词自身的前提与完成要求。跨区长线按端点与标签辨认。

图展示场景之间的关系，不是必须逐节点执行的清单。已有 GDD、具体授权、适用验证与真实人工验收要求仍以项目规范为准。图中没有单独的“完成”节点；转入下一 Product 的线要求当前 Product 的全部适用完成条件已经满足。自动验收型 Feature 无需绕行人工验收场景。

维护时先核对 `godot-development-prompts.json` 的分类与名称；每个场景都恰好对应一个节点。节点 `label` 允许为阅读插入 CR/LF 换行，去除换行后仍须逐字一致，不能改动空格、标点、大小写或添加编号、步骤、Skill 名称。

- **集合、名称或分类变化**：更新相关节点、分类颜色和场景链接。新增或删除场景时相应增删节点，重命名时保留身份；新增节点使用新的唯一 ID，不占用旧 ID，也不因排序改变而重编号。
- **实际衔接变化**：核对对应连线的方向、条件和必要布局；不把按需入口串成固定必经流程。仅修改提示词措辞且这些关系未变时，无需改图。
- **局部布局或样式变化**：只修改选定元素，保留其他节点、连线、换行、链接、备注及有效的外观配置。
- **编写或保存 JSON**：遵循下文的[编写与保存格式](#编写与保存格式)，保留查看器保存后的字段顺序和已测量尺寸。

没有场景入口的工作不自行补成节点。Godot 场景调整后使用下文的现有检查命令核对图文件；框架场景变化不加入图中。

以下格式说明适用于两张图，足以支持日常编辑；无需读取外部项目代码。

## 本地使用次数

每张主图的稳定 UUID `documentId` 关联同目录的 `graph-usage.<documentId>.json`，后者按节点或连线 ID 保存使用次数。修改节点文字、布局或主图文件名时保留图 ID；节点重命名也保留元素 ID。主图不保存 `usageCount`，继续由 Git 追踪结构和内容，次数文件由本仓库 `.gitignore` 单独忽略。

次数文件的完整结构如下，示例 ID 仅演示格式：

```json
{
  "format": "graph-map-usage",
  "version": 1,
  "documentId": "163c207d-a618-4953-8219-095116dbb0a2",
  "counts": { "example-create": 3 }
}
```

根对象恰好含上述四个字段，`documentId` 与主图一致；`counts` 的键是元素 ID，值是 0–9007199254740991 的非负安全整数。未设置的元素按 0 次显示，显式 0 也有效。次数文件不存在时按全图 0 次打开；格式、权限或图 ID 错误会拒绝打开并保留原会话。不在图中的 ID 不显示，下次保存次数时清理。

使用次数仍通过属性输入或 −1/+1 修改，可撤销并用于搜索和排序。次数独立参与未保存提醒。“导出 JSON”下载主图副本，“导出次数”下载次数副本，均不清除未保存状态。备份或换机器时同时复制主图和对应次数文件；Git 克隆不包含个人计数，需自行迁移。

旧图可用“导入 JSON”打开；首次 Ctrl+S 会先成功保存次数，再移除主图内嵌字段并保存稳定图 ID。已经拆分的图使用“打开图目录”，避免漏读次数。开发场景图的已有次数已迁移，日常只改次数不会产生主图 Git 差异。

## 文件结构

图文件使用 UTF-8 的严格 JSON，无注释、尾逗号、重复键或非有限数值，两张主图根对象均恰好包含下列六个字段。

下文定义根结构、必填字段和图中已使用的可选字段。这些字段属于已核对的查看器契约，不能当成任意元数据。

| 字段 | 值与含义 |
| --- | --- |
| `format` | 固定字符串 `graph-map-core` |
| `version` | 固定数字 `1` |
| `documentId` | 稳定 UUID 字符串，关联同目录的独立次数文件；维护现有图时保留 |
| `nodes` | 节点对象数组，可为空 |
| `edges` | 连线对象数组，可为空 |
| `canvas` | 必须含 `gridSize`、`gridVisible`、`snapToGrid`；网格尺寸为 1–100 的有限数值，后两项为布尔值 |

节点和连线的 `id` 在各自图内共用唯一性范围；必须为非空白字符串，最长 200 字符。开发场景图以 `scene-` 和 `link-` 区分两类 ID，但这只是命名约定。连线端点必须引用真实节点，不可引用连线。

坐标、折点与 `zIndex` 均为 −10,000,000 至 10,000,000 的有限数值。坐标使用画布单位，`x`、`y` 是节点左上角；画布平移和缩放不写入文件。节点和连线 `label` 必须为字符串，最长 100,000 字符。

## 节点字段

每个节点必须提供下列全部字段，另可保留下文说明的可选字段。

| 字段 | 格式要求 |
| --- | --- |
| `id` | 全局唯一的字符串 |
| `shape` | `rect`、`rounded-rect`、`ellipse`、`circle`、`diamond` 或 `text` |
| `x`、`y` | 左上角坐标 |
| `width`、`height` | 20–100,000 的有限数值；`circle` 的宽高差绝对值不得超过 0.01 |
| `label` | 节点文字；开发场景图固定复用完整场景名称，文档图显示职责与固定文件名或命名模式 |
| `zIndex` | 绘制层次，较大值靠前；不是业务图层 |
| `fill` | 填充色，格式见下节 |
| `stroke` | 描边对象，必须含 `color`、`width`、`dash` |
| `text` | 文字对象，必须含 `fontSize`、`color`、`align` |

开发场景图统一使用圆角矩形。文档图的文档节点使用圆角矩形，分区标题与图例使用 `text`；不因格式支持其他形状就增加业务对象。

## 连线和公共样式

| 字段 | 格式要求 |
| --- | --- |
| `id` | 全局唯一的字符串 |
| `source`、`target` | 必须含 `node` 和 `port`；`node` 是节点 ID，`port` 为 `top`、`right`、`bottom` 或 `left` |
| `mode` | `floating` 或 `fixed`；固定模式使用指定端口，浮动模式仍必须提供端口字段 |
| `path` | `straight`、`orthogonal` 或 `smooth` |
| `vertices` | 折点数组，可为空；每个折点恰好包含有限数值 `x`、`y` |
| `label` | 关系或条件说明，允许空字符串 |
| `stroke`、`text`、`zIndex` | 与节点对应字段使用相同规则 |
| `arrow` | `none`、`target` 或 `both` |
| `flow` | 可选的连线流动配置；省略时静态显示，不会自动补写 |

`flow` 若出现，必须同时含 `direction`（`off`、`forward`、`reverse`）和 `speed`（`slow`、`normal`、`fast`），不得增加其他字段。两张图都省略 `flow`，默认静态显示。

公共样式对象的约束如下：

- 颜色只接受六位十六进制 `#RRGGBB`（大小写均可）或 `transparent`，不接受三位缩写、颜色名称、RGB 函数或含透明通道的八位值。
- `stroke.width` 为 0–32 的有限数值；`stroke.dash` 为 `solid`、`dashed` 或 `dotted`。
- `text.fontSize` 为 6–256 的有限数值；`text.align` 为 `left`、`center` 或 `right`。

不写入 `workspace`、`layerId`、`viewIds`、`parentId`、媒体、任意元数据或 X6 `cells`。本格式不支持分组、多视图和思源插件 Graph Map v2。来源、维护约定等说明放在本文件，不扩充 JSON 字段。

## 可读版附加字段与本地链接

图文件保留以下已使用的字段。它们不改变对象身份、关系条件或执行授权。

| 位置 | 当前用途与维护要求 |
| --- | --- |
| 节点 `textSizing` | 开发场景图使用 `content`，导入时按本机字体测量；文档图使用 `fixed` 保持所排尺寸。保存的宽高不等于已经检查实际显示。 |
| 节点 `textPadding` | `horizontal`、`vertical` 分别表示左右、上下内边距，两项均为 0–1000 的有限数值。 |
| 节点 `appearance` | 保留圆角、阴影、换行与透明度设置；当前字段为 `cornerRadius`、`shadow`、`wrap`、`opacity`、`fillOpacity`。 |
| 节点和连线 `text` | 在基础字段外保留当前的 `fontFamily`、`verticalAlign`、`hidden`、`opacity`，节点还保存 `bold`；这些是文字外观，不是新的业务属性。 |
| 连线 `appearance` | 保留已有两端箭头类型与大小、标签位置与偏移、圆角和路由间距等配置。显式 `sourceMarker` / `targetMarker` 会覆盖 `arrow` 的默认箭头；新增或修改关系时，两者都须与实际方向一致。单向衔接使用 `arrow: "target"`，显式起点标记为 `none`，避免显示成双向关系。 |
| 节点 `link` | 包含且仅包含 `kind`、`target`；两图使用 `kind: "local"`。场景图指向同名场景文件，文档图指向实际入口、源文件、模板或规范的绝对路径。 |
| 节点 `note` | 场景图保存同一场景的三种自然描述，以 `1. `、`2. `、`3. ` 分行；文档图保存职责、位置与创建条件。备注参与搜索，不替换 `label`，不绘制在画布上。 |

`note` 是可选纯文本字符串，最长 100000 个 UTF-16 代码单元，保留换行；在 JSON 字符串内用 `\n` 表示换行。省略表示无备注，不能使用数组、对象或 `null`，编号也是字符串内容。Graph_Map 原样保留备注并支持导入导出，不渲染 Markdown 或 HTML。

开发场景图的三条备注分别完整表达同一场景，编号不表示执行步骤。编写时以当前提示词库中的场景名称及正文为依据，保留关键前提、任务对象与授权边界；提示词含义变化时同步核对备注。正式提示词仍由提示词库维护，备注只帮助辨认和搜索场景。

本地链接由 Graph_Map 展示和复制，不直接打开文件，不把文件内容打包进 JSON。`target` 最长 8192 字符，不能是空白或含控制字符；本仓库的链接命令还会检查对应场景文件确实存在。仓库移动、场景分类或名称变化后，需要按当前路径更新链接。

链接维护使用现有 [link_workflow_graph_scenarios.py](../../prompt_scenarios/tools/link_workflow_graph_scenarios.py)，详细用法见[维护脚本说明](../../commands/README.md)。获准更新时，命令默认只修改可读版节点的 `link`，会替换已有链接；它先核对完整名称集合与目标文件，失败时不写入。`--check` 只检查，不修改；不要把写入命令用于只读审核，也不要用它代替新增节点或关系。

上述附加字段以本轮核对的 Graph_Map `src/core/model.ts` 和 `docs/json-appearance.md` 为依据。日常场景维护保留已生效配置，不要求每次读取外部项目；确需新增字段或改变格式时，再核对实际查看器版本，不把同为 v1 当作支持所有外观配置的保证。

## 编写与保存格式

以 Graph_Map 解析后通过 `JSON.stringify(document, null, 2)` 保存的文本为格式基线：UTF-8 无 BOM、LF 换行、两空格缩进，字符串保留中文原文，文件结尾不补换行。本仓库的 `.editorconfig` 已为图文件设置对应例外，场景链接工具沿用已有字段顺序并采用相同缩进和结尾格式。

JSON 键顺序不改变数据含义，但查看器会按解析器的顺序重建对象；编写顺序不同会在下一次保存时产生大量逐行差异。修改现有对象时保留顺序，新增对象按下表排列当前使用的字段；可选字段不存在时省略，不为了格式补写默认值。节点和连线数组保留已有顺序。

| 对象 | 当前使用的字段顺序 |
| --- | --- |
| 根对象 | `format`、`version`、`documentId`、`nodes`、`edges`、`canvas` |
| 节点 | `id`、`shape`、`x`、`y`、`width`、`height`、`label`、`zIndex`、`fill`、`stroke`、`text`、`textPadding`、`note`、`textSizing`、`link`、`appearance` |
| 连线 | `id`、`source`、`target`、`mode`、`path`、`vertices`、`label`、`stroke`、`arrow`、`text`、`zIndex`、`appearance` |
| `stroke` | `color`、`width`、`dash` |
| `text` | `fontSize`、`color`、`align`、`fontFamily`、`bold`（节点）、`opacity`、`verticalAlign`、`hidden` |
| 节点 `appearance` | `opacity`、`fillOpacity`、`cornerRadius`、`shadow`、`wrap` |
| 连线 `appearance` | `opacity`、`sourceMarker`、`targetMarker`、`sourceMarkerSize`、`targetMarkerSize`、`labelPosition`、`labelOffset`、`labelPadding`、`rounded`、`radius`、`jump`、`routerPadding`、`curve` |
| 连线端点 | `node`、`port` |
| 连线折点 | `x`、`y` |
| `link` | `kind`、`target` |
| `textPadding` | `horizontal`、`vertical` |
| `canvas` | `gridSize`、`gridVisible`、`snapToGrid` |

格式整理保留现有 ID、坐标、尺寸、换行、备注、链接、适配策略和箭头配置。当前节点使用 `textSizing: "content"`，打开时按本机字体重新计算宽高；已有节点以查看器保存后的尺寸为基线，新增节点或改变文字、字体、字号、边距后可能在下次保存时出现少量尺寸变化。统一字段顺序能消除整图重排字段的差异，不能保证文字测量结果在不同字体环境中完全相同。

新增可选字段或查看器格式变化时，核对实际 `parseDocument` / `validateDocument` 和保存入口，再更新本节对应顺序。日常局部维护沿用现有文件与本节，无需把查看器作为本仓库的运行依赖。

## 最小完整示例

两个节点仍复用真实提示场景名称；示例只演示文件结构，不代表完整场景图。

```json
{
  "format": "graph-map-core",
  "version": 1,
  "documentId": "163c207d-a618-4953-8219-095116dbb0a2",
  "nodes": [
    {
      "id": "example-create",
      "shape": "rounded-rect",
      "x": 0,
      "y": 0,
      "width": 540,
      "height": 120,
      "label": "准备开始新游戏，先创建空白项目",
      "zIndex": 1,
      "fill": "#eaf3ff",
      "stroke": {
        "color": "#64748b",
        "width": 1.5,
        "dash": "solid"
      },
      "text": {
        "fontSize": 20,
        "color": "#17283d",
        "align": "center"
      }
    },
    {
      "id": "example-environment",
      "shape": "rounded-rect",
      "x": 780,
      "y": 0,
      "width": 540,
      "height": 120,
      "label": "空白项目已经创建，现在配置开发环境",
      "zIndex": 1,
      "fill": "#eaf3ff",
      "stroke": {
        "color": "#64748b",
        "width": 1.5,
        "dash": "solid"
      },
      "text": {
        "fontSize": 20,
        "color": "#17283d",
        "align": "center"
      }
    }
  ],
  "edges": [
    {
      "id": "example-link",
      "source": {
        "node": "example-create",
        "port": "right"
      },
      "target": {
        "node": "example-environment",
        "port": "left"
      },
      "mode": "fixed",
      "path": "orthogonal",
      "vertices": [],
      "label": "创建后配置",
      "stroke": {
        "color": "#315ea8",
        "width": 2.5,
        "dash": "solid"
      },
      "arrow": "target",
      "text": {
        "fontSize": 14,
        "color": "#334155",
        "align": "center"
      },
      "zIndex": 0
    }
  ],
  "canvas": {
    "gridSize": 10,
    "gridVisible": false,
    "snapToGrid": true
  }
}
```

## 依据与检查

格式依据为本次核对的独立 Graph_Map 项目 `src/core/model.ts` 中的 `GraphDocument`、`validateDocument` / `parseDocument`，`src/core/file-document.ts` 中的拆分与次数契约，以及 `docs/json-appearance.md` 和 `docs/integration.md`。核对位置为 `D:/WebTools/Graph_Map`；该路径仅说明格式出处，不是本仓库配置或日常运行前提。需要重新核对格式时，以实际使用的查看器版本为准，不自动引入其新增能力。

开发场景图的业务依据如下；文档图的来源与检查范围见上文“文档系统关系图”。

| 检查内容 | 本仓库依据 |
| --- | --- |
| 节点名称与完整集合 | [Godot 开发提示词库](../../prompt_scenarios/prompts/godot-development-prompts.json) |
| 场景前提、出口和对应提示词 | [场景索引](../../prompt_scenarios/scenarios/scenario-index.md)、[场景覆盖](../framework-maintenance/baselines/scenario-coverage.md) |
| 任务路由、Product 顺序与 GDD 前提 | [流程总览](../../../project-source/methodology/00-overview.md) |
| 授权、验证、人工验收与完成 | [执行规范](../../../project-source/methodology/03-execute-loop.md) |
| 专业工作职责 | [专业流程](../../../project-source/methodology/11-specialist-workflows.md) |

场景集合或名称变化后，在仓库根目录使用现有只读命令检查图文件。`python` 应使用当前个人规则指定的解释器。

```powershell
python -B framework/prompt_scenarios/tools/check_workflow_graph_names.py --summary
python -B framework/prompt_scenarios/tools/link_workflow_graph_scenarios.py --check
```

名称检查只忽略 CR/LF，核对名称多重集合并报告缺少、多余、重名及节点 ID 重复；删除 `--summary` 可查看准确字段位置和候选名称。链接检查默认针对可读版，核对场景文件及节点 `link`。两项检查都不覆盖完整格式、连线含义、正文语义或显示效果；不新增一套检查脚本或同步台账。

图内容变化还须核对既有 ID 稳定、节点及连线 ID 全局无重复、所有端点存在；按实际改动检查场景身份、连线条件、坐标、节点尺寸、折点及保存格式。

格式或字段变化时可使用对应查看器的实际 `parseDocument` 校验图文件与最小示例，并比较解析后再次序列化的文本与图文件；既有通过结果只在内容与覆盖仍有效时复用。名称、链接、格式或序列化检查通过也不证明标签适配与视觉体验通过，导入后的缩放、阅读和连线辨识仍由用户实际查看。
