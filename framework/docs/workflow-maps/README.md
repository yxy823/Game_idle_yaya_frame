# 游戏项目开发场景图与 JSON 格式

[文档入口](../README.md) · [原图](game-development-workflow.json) · [可读版](game-development-workflow.readable.json)

两份图都展示[提示词库](../../prompts.json)中 `Godot 项目开发` 的全部场景及其衔接关系，不包含 `Yaya 框架维护` 场景。节点只显示提示场景名称，不复制提示词正文，不新增阶段、判断、标题或说明节点。具体操作仍查对应提示词或[场景索引](../quick-reference/scenario-index.md)。

| 文件 | 用途与维护范围 |
| --- | --- |
| [game-development-workflow.json](game-development-workflow.json) | 按分类分列的原图，使用下文的严格基础字段，节点名称不插入换行。 |
| [game-development-workflow.readable.json](game-development-workflow.readable.json) | 为实际阅读单独调整布局、文字换行、尺寸和连线外观，并保存同名场景文件链接；已有名称检查和链接维护命令默认处理此图。 |

两份图共享场景身份与关系含义，各自保留布局和样式。可读版不是原图的自动生成产物，不用一份图覆盖另一份，也不因提示词顺序变化重排整图。

## 阅读与维护

将 JSON 导入支持相应字段的 `graph-map-core` v1 查看器。可读版使用[附加字段](#可读版附加字段与场景链接)，早期严格解析器可能拒绝这些字段，不能只凭版本号相同判断兼容。导入替换当前画布；需要保留当前编辑时先导出。编辑后导出的 JSON 是新副本，不会自动更新仓库原文件。

原图节点按现有分类从左向右摆放：项目创建与接入、需求设计、任务规划、日常开发、资源、性能与数据、修复与改进、验证与收尾、项目恢复与交接、经验沉淀。可读版按实际关系调整主线和分支位置，不强制沿用分列坐标。两图的颜色只辅助辨认分类，不表示任务状态；分类名称不另建节点。

- **蓝色实线**：常见交付路径中的场景衔接，仍需满足线上的条件。
- **灰色虚线**：按需选择、替代入口、问题处理或续接关系。箭头不代表自动执行或新增授权。
- **条件标签**：说明何时可转入目标场景，不替代提示词自身的前提与完成要求。跨区长线按端点与标签辨认。

图展示场景之间的关系，不是必须逐节点执行的清单。已有 GDD、具体授权、适用验证与真实人工验收要求仍以项目规范为准。图中没有单独的“完成”节点；转入下一 Product 的线要求当前 Product 的全部适用完成条件已经满足。自动验收型 Feature 无需绕行人工验收场景。

维护时先核对 `prompts.json` 对应 Project 的分类与名称；两份图中的每个场景都恰好对应一个节点。原图 `label` 必须逐字一致；可读版允许为阅读插入 CR/LF 换行，去除换行后仍须逐字一致，不能改动空格、标点、大小写或添加编号、步骤、Skill 名称。

- **集合、名称或分类变化**：同步两份图的相关节点、分类颜色和场景链接。新增或删除场景时相应增删节点，重命名时保留身份；新增同一场景在两图使用同一新 ID，不占用旧 ID，也不因排序改变而重编号。
- **实际衔接变化**：核对两图中对应连线的方向、条件和必要布局；不把按需入口串成固定必经流程。仅修改提示词措辞且这些关系未变时，无需改图。
- **局部布局或样式变化**：只修改选定图与元素，保留其他节点、连线及有效的可读版附加字段；不为统一格式删除换行、链接或外观配置。

没有场景入口的工作不自行补成节点。Godot 场景调整后使用下文的现有检查命令核对两图；框架场景变化不加入这两份图。

本目录只在框架维护仓库保存，不进入生成项目复制清单，也不建立运行依赖或自动同步。以下格式说明足以支持日常编辑；无需读取外部项目代码。

## 文件结构

两份图都使用 UTF-8 的严格 JSON，无注释、尾逗号、重复键或非有限数值，根对象恰好包含下列五个字段。

本节及下文“节点字段”“连线和公共样式”“最小完整示例”定义原图使用的严格字段子集，不在原图对象中加入未列出的字段。可读版共用根结构与必填字段，并保留下文明确说明的附加字段；这些字段属于已核对的查看器契约，不能当成任意元数据。

| 字段 | 值与含义 |
| --- | --- |
| `format` | 固定字符串 `graph-map-core` |
| `version` | 固定数字 `1` |
| `nodes` | 节点对象数组，可为空 |
| `edges` | 连线对象数组，可为空 |
| `canvas` | 必须含 `gridSize`、`gridVisible`、`snapToGrid`；网格尺寸为 1–100 的有限数值，后两项为布尔值 |

节点和连线的 `id` 共用唯一性范围；必须为非空白字符串，最长 200 字符。本图以 `scene-` 和 `link-` 区分两类 ID，但这只是命名约定。连线端点必须引用真实节点，不可引用连线。

坐标、折点与 `zIndex` 均为 −10,000,000 至 10,000,000 的有限数值。坐标使用画布单位，`x`、`y` 是节点左上角；画布平移和缩放不写入文件。节点和连线 `label` 必须为字符串，最长 100,000 字符。

## 节点字段

原图的每个节点必须提供下列全部字段，没有可选字段。可读版另有下文说明的可选字段。

| 字段 | 格式要求 |
| --- | --- |
| `id` | 全局唯一的字符串 |
| `shape` | `rect`、`rounded-rect`、`ellipse`、`circle`、`diamond` 或 `text` |
| `x`、`y` | 左上角坐标 |
| `width`、`height` | 20–100,000 的有限数值；`circle` 的宽高差绝对值不得超过 0.01 |
| `label` | 节点文字；本图固定复用完整场景名称 |
| `zIndex` | 绘制层次，较大值靠前；不是业务图层 |
| `fill` | 填充色，格式见下节 |
| `stroke` | 描边对象，必须含 `color`、`width`、`dash` |
| `text` | 文字对象，必须含 `fontSize`、`color`、`align` |

本图统一使用圆角矩形。格式虽然支持其他形状，但不据此添加额外的业务节点。

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
| `flow` | 原图保留的唯一可选字段；省略时静态显示，不会自动补写 |

`flow` 若出现，必须同时含 `direction`（`off`、`forward`、`reverse`）和 `speed`（`slow`、`normal`、`fast`），不得增加其他字段。本图省略 `flow`，默认静态显示。

公共样式对象的约束如下：

- 颜色只接受六位十六进制 `#RRGGBB`（大小写均可）或 `transparent`，不接受三位缩写、颜色名称、RGB 函数或含透明通道的八位值。
- `stroke.width` 为 0–32 的有限数值；`stroke.dash` 为 `solid`、`dashed` 或 `dotted`。
- `text.fontSize` 为 6–256 的有限数值；`text.align` 为 `left`、`center` 或 `right`。

不写入 `workspace`、`layerId`、`viewIds`、`parentId`、媒体、任意元数据或 X6 `cells`。本格式不支持分组、多视图和思源插件 Graph Map v2。来源、维护约定等说明放在本文件，不扩充 JSON 字段。

## 可读版附加字段与场景链接

可读版保留以下已使用的字段。它们不改变场景身份、关系条件或执行授权，也不需要同步到原图。

| 位置 | 当前用途与维护要求 |
| --- | --- |
| 节点 `textSizing` | 当前使用 `content`，查看器导入时按本机字体测量文字尺寸；保存的宽高不等于已经检查实际显示。 |
| 节点 `textPadding` | `horizontal`、`vertical` 分别表示左右、上下内边距，两项均为 0–1000 的有限数值。 |
| 节点 `appearance` | 保留圆角、阴影、换行与透明度设置；当前字段为 `cornerRadius`、`shadow`、`wrap`、`opacity`、`fillOpacity`。 |
| 节点和连线 `text` | 在基础字段外保留当前的 `fontFamily`、`verticalAlign`、`hidden`、`opacity`，节点还保存 `bold`；这些是文字外观，不是新的业务属性。 |
| 连线 `appearance` | 保留已有两端箭头类型与大小、标签位置与偏移、圆角和路由间距等配置。显式 `sourceMarker` / `targetMarker` 会覆盖 `arrow` 的默认箭头；新增或修改关系时，两者都须与实际方向一致。单向衔接使用 `arrow: "target"`，显式起点标记为 `none`，避免显示成双向关系。 |
| 节点 `link` | 包含且仅包含 `kind`、`target`；本图使用 `kind: "local"` 与同名场景文件的绝对路径。 |

本地链接由 Graph_Map 展示和复制，不直接打开文件，不把文件内容打包进 JSON。`target` 最长 8192 字符，不能是空白或含控制字符；本仓库的链接命令还会检查对应场景文件确实存在。仓库移动、场景分类或名称变化后，需要按当前路径更新链接。

链接维护使用现有 [link_workflow_graph_scenarios.py](../../commands/link_workflow_graph_scenarios.py)，详细用法见[维护脚本说明](../../commands/README.md)。获准更新时，命令默认只修改可读版节点的 `link`，会替换已有链接；它先核对完整名称集合与目标文件，失败时不写入。`--check` 只检查，不修改；不要把写入命令用于只读审核，也不要用它代替新增节点或关系。

上述附加字段以本轮核对的 Graph_Map `src/core/model.ts` 和 `docs/json-appearance.md` 为依据。日常场景维护保留已生效配置，不要求每次读取外部项目；确需新增字段或改变格式时，再核对实际查看器版本，不把同为 v1 当作支持所有外观配置的保证。

## 最小完整示例

两个节点仍复用真实提示场景名称；示例只演示文件结构，不代表完整场景图。

```json
{
  "format": "graph-map-core",
  "version": 1,
  "nodes": [
    {
      "id": "example-create", "shape": "rounded-rect",
      "x": 0, "y": 0, "width": 540, "height": 120,
      "label": "准备开始新游戏，先创建空白项目", "zIndex": 1,
      "fill": "#eaf3ff",
      "stroke": { "color": "#64748b", "width": 1.5, "dash": "solid" },
      "text": { "fontSize": 20, "color": "#17283d", "align": "center" }
    },
    {
      "id": "example-environment", "shape": "rounded-rect",
      "x": 780, "y": 0, "width": 540, "height": 120,
      "label": "空白项目已经创建，现在配置开发环境", "zIndex": 1,
      "fill": "#eaf3ff",
      "stroke": { "color": "#64748b", "width": 1.5, "dash": "solid" },
      "text": { "fontSize": 20, "color": "#17283d", "align": "center" }
    }
  ],
  "edges": [
    {
      "id": "example-link",
      "source": { "node": "example-create", "port": "right" },
      "target": { "node": "example-environment", "port": "left" },
      "mode": "fixed", "path": "orthogonal", "vertices": [],
      "label": "创建后配置", "zIndex": 0, "arrow": "target",
      "stroke": { "color": "#315ea8", "width": 2.5, "dash": "solid" },
      "text": { "fontSize": 14, "color": "#334155", "align": "center" }
    }
  ],
  "canvas": { "gridSize": 10, "gridVisible": false, "snapToGrid": true }
}
```

## 依据与检查

格式依据为本次核对的独立 Graph_Map 项目 `src/core/model.ts` 中的 `GraphDocument`、`validateDocument` / `parseDocument`，以及 `docs/integration.md` 的 JSON 契约。核对位置为 `D:/WebTools/Graph_Map`；该路径仅说明格式出处，不是本仓库配置或日常运行前提。需要重新核对格式时，以实际使用的查看器版本为准，不自动引入其新增能力。

| 检查内容 | 本仓库依据 |
| --- | --- |
| 节点名称与完整集合 | [提示词库](../../prompts.json) 的 `Godot 项目开发` Project |
| 场景前提、出口和对应提示词 | [场景索引](../quick-reference/scenario-index.md)、[场景覆盖](../../review/baselines/scenario-coverage.md) |
| 任务路由、Product 顺序与 GDD 前提 | [流程总览](../../../project-source/methodology/00-overview.md) |
| 授权、验证、人工验收与完成 | [执行规范](../../../project-source/methodology/03-execute-loop.md) |
| 专业工作职责 | [专业流程](../../../project-source/methodology/11-specialist-workflows.md) |

场景集合或名称变化后，在仓库根目录使用现有只读命令分别检查两图。`python` 应使用当前个人规则指定的解释器。

```powershell
python -B framework/commands/check_workflow_graph_names.py --graph framework/docs/workflow-maps/game-development-workflow.json --summary
python -B framework/commands/check_workflow_graph_names.py --summary
python -B framework/commands/link_workflow_graph_scenarios.py --check
```

名称检查只忽略 CR/LF，核对名称多重集合并报告缺少、多余、重名及节点 ID 重复；删除 `--summary` 可查看准确字段位置和候选名称。链接检查默认针对可读版，核对场景文件及节点 `link`。两项检查都不覆盖完整格式、连线含义、正文语义或显示效果；不新增一套检查脚本或同步台账。

图内容变化还须核对两图的场景身份和关系含义一致，既有 ID 稳定、节点及连线 ID 全局无重复、所有端点存在；按实际改动检查连线条件、坐标、节点尺寸和折点。原图与可读版保留各自布局和外观，不要求坐标、端口或折点相同。

初版曾使用对应查看器的实际 `parseDocument` 校验图文件与最小示例，后续不能把旧结果当作当前修改通过。手册构建不检查这两份 JSON；名称、链接或格式检查通过也不证明标签适配与视觉体验通过，导入后的缩放、阅读和连线辨识仍由用户实际查看。
