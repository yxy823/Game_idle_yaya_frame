# Graph_Map 文件格式

[关系图说明](README.md) · [文档入口](../README.md)

本页定义两张关系图共用的 Graph_Map JSON 结构、可选字段、保存格式和本地使用次数文件。图的阅读含义与维护规则见[关系图说明](README.md)；只有查看器格式变化时才需要修改本页。

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

不写入 `workspace`、`layerId`、`viewIds`、`parentId`、媒体、任意元数据或 X6 `cells`。本格式不支持分组、多视图和思源插件 Graph Map v2。来源、维护约定等说明放在本目录的说明文件，不扩充 JSON 字段。

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
| 节点 `note` | 只有文档图使用，保存职责、位置、创建条件和文件路径登记；开发场景图不写备注。备注参与搜索，不替换 `label`，不绘制在画布上。 |

`note` 是可选纯文本字符串，最长 100000 个 UTF-16 代码单元，保留换行；在 JSON 字符串内用 `\n` 表示换行。省略表示无备注，不能使用数组、对象或 `null`，编号也是字符串内容。Graph_Map 原样保留备注并支持导入导出，不渲染 Markdown 或 HTML。

本地链接由 Graph_Map 展示和复制，不直接打开文件，不把文件内容打包进 JSON。`target` 最长 8192 字符，不能是空白或含控制字符；本仓库的链接命令还会检查对应场景文件确实存在。仓库移动、场景分类或名称变化后，需要按当前路径更新链接。

链接维护使用 [link_workflow_graph_scenarios.py](../../commands/link_workflow_graph_scenarios.py)，用法见[场景图名称与链接检查](../../commands/README.md#检查场景图名称与链接)。获准更新时，命令默认只修改可读版节点的 `link`，会替换已有链接；它先核对完整名称集合与目标文件，失败时不写入。`--check` 只检查，不修改；不要把写入命令用于只读审核，也不要用它代替新增节点或关系。

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

## 依据与校验

格式依据为本次核对的独立 Graph_Map 项目 `src/core/model.ts` 中的 `GraphDocument`、`validateDocument` / `parseDocument`，`src/core/file-document.ts` 中的拆分与次数契约，以及 `docs/json-appearance.md` 和 `docs/integration.md`。核对位置为 `D:/WebTools/Graph_Map`；该路径仅说明格式出处，不是本仓库配置或日常运行前提。需要重新核对格式时，以实际使用的查看器版本为准，不自动引入其新增能力。

格式或字段变化时可使用对应查看器的实际 `parseDocument` 校验图文件与最小示例，并比较解析后再次序列化的文本与图文件；既有通过结果只在内容与覆盖仍有效时复用。名称、链接、格式或序列化检查通过也不证明标签适配与视觉体验通过，导入后的缩放、阅读和连线辨识仍由用户实际查看。
