# Graph_Map 文件格式

[关系图说明](README.md) · [框架入口](../README.md)

本页定义两张关系图共用的 Graph_Map JSON 结构、可选字段、保存格式和本地使用次数文件。图的阅读含义与维护规则见[文档关系图与开发场景图](README.md)；只有查看器格式变化时才需要修改本页。

## 文件结构

框架只接受 Graph_Map v2。图文件是 UTF-8 编码的严格 JSON：不能有注释、尾逗号、重复键或非有限数值。两张主图使用下列六个字段；查看器要求 `format`、`version`、`nodes`、`edges`、`canvas`，`documentId` 可选。本页详细说明两张图实际使用的字段，不把查看器的全部能力复制到框架。

| 字段 | 值与含义 |
| --- | --- |
| `format` | 固定字符串 `graph-map-core` |
| `version` | 固定数字 `2` |
| `documentId` | 查看器可选的 UUID 字符串；两张图均保存此字段，维护时保留，用于关联独立使用次数 |
| `nodes` | 节点对象数组，可为空 |
| `edges` | 连线对象数组，可为空 |
| `canvas` | 必须含 `gridSize`、`gridVisible`、`snapToGrid`；网格尺寸为 1–100 的有限数值，后两项为布尔值 |

节点和连线的 `id` 在同一张图内必须互不重复，是非空白字符串，最长 200 个 UTF-16 代码单元，不得使用 `Object.prototype` 的自有属性名。开发场景图用 `scene-`、`link-` 前缀区分节点和连线，这只是命名习惯。两张图的连线端点均引用存在的节点，不能引用连线。

坐标、折点与 `zIndex` 均为 −10,000,000 至 10,000,000 的有限数值。坐标使用画布单位，`x`、`y` 是节点左上角；画布平移和缩放不写入文件。节点和连线 `label` 必须为字符串，最长 100,000 字符。

## 节点字段

每个节点必须提供下列全部字段，另可保留下文说明的可选字段。

| 字段 | 格式要求 |
| --- | --- |
| `id` | 全局唯一的字符串 |
| `shape` | 两张图使用 `rounded-rect` 和 `text`；查看器的其他形状见 `D:/WebTools/Graph_Map/docs/json-appearance.md` |
| `x`、`y` | 左上角坐标 |
| `width`、`height` | 20–100,000 的有限数值 |
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
| `source`、`target` | 节点端点必须含 `kind: "node"` 和 `node`；`node` 是节点 ID。可选 `port` 为 `top`、`right`、`bottom` 或 `left`：提供时固定到该端口，省略时浮动连接节点边界。端点不含其他字段 |
| `path` | `straight`、`orthogonal` 或 `smooth` |
| `vertices` | 折点数组，可为空；每个折点恰好包含有限数值 `x`、`y` |
| `label` | 关系或条件说明，允许空字符串 |
| `stroke`、`text`、`zIndex` | 与节点对应字段使用相同规则 |
| `arrow` | `none`、`target` 或 `both` |

v2 连线不使用 `mode`，连接方式由各端点是否含 `port` 决定。查看器还支持坐标端点 `kind: "point"`，两张图未使用，契约见 `D:/WebTools/Graph_Map/docs/json-appearance.md`。

查看器支持可选 `flow` 流动配置，两张图均省略并静态显示，契约见 `D:/WebTools/Graph_Map/docs/json-appearance.md`。

公共样式对象的约束如下：

- 颜色只接受六位十六进制 `#RRGGBB`（大小写均可）或 `transparent`，不接受三位缩写、颜色名称、RGB 函数或含透明通道的八位值。
- `stroke.width` 为 0–32 的有限数值；`stroke.dash` 为 `solid`、`dashed`、`dotted` 或 `dash-dot`。
- `text.fontSize` 为 6–256 的有限数值；`text.align` 为 `left`、`center` 或 `right`。

查看器支持可选 `groups` 和 `parentId` 分组，两张图未使用，契约见 `D:/WebTools/Graph_Map/docs/json-appearance.md`。

查看器支持可选 `angle` 旋转，两张图未使用，契约见 `D:/WebTools/Graph_Map/docs/json-appearance.md`。

不写入 `workspace`、`layerId`、`viewIds`、媒体、任意元数据或 X6 `cells`。Graph_Map v2 不是思源插件 Graph Map v2。来源、维护约定等说明放在本目录的说明文件，不扩充 JSON 字段。

## 可读版附加字段与本地链接

图文件保留以下已使用的字段。它们不改变对象身份、关系条件或执行授权。

| 位置 | 当前用途与维护要求 |
| --- | --- |
| 节点 `textSizing` | 开发场景图使用 `content`，导入时按字体测量每个显式换行后的行宽，宽度取最大行宽加左右边距，高度取行数 × 字号 × 1.4 加上下边距，向上取整且不小于 20；文档图使用 `fixed` 保持保存尺寸。省略时按固定尺寸显示；其他模式见查看器文档。 |
| 节点 `textPadding` | `horizontal`、`vertical` 分别表示左右、上下内边距，两项均为 0–1000 的有限数值。 |
| 节点 `appearance` | 可选对象；`opacity`、`fillOpacity` 为 0–1，`cornerRadius` 为 0–1000，`shadow`、`wrap` 为布尔值。省略时透明度为 1、无阴影、启用换行；圆角矩形默认圆角为 12。 |
| 节点和连线 `text` | 可选 `fontFamily`（两图使用 `system`，解析为 `Segoe UI, Microsoft YaHei, sans-serif`）、`verticalAlign`（`top`、`middle`、`bottom`，默认 `middle`）、`hidden`（布尔值，默认 `false`）、`opacity`（0–1，默认 1）；节点还使用 `bold`（布尔值，默认 `false`）。其他字体与文字样式见查看器文档。 |
| 连线 `appearance` | 可选对象；字段约束见下表。显式 `sourceMarker` / `targetMarker` 覆盖 `arrow` 的默认箭头；新增或修改关系时，两者都须与实际方向一致。单向衔接使用 `arrow: "target"`，显式起点标记为 `none`。 |
| 节点 `link` | 包含且仅包含 `kind`、`target`；两图使用 `kind: "local"`。场景图指向同名场景文件，文档图指向实际入口、源文件、模板或规范的绝对路径。 |
| 节点 `note` | 只有文档图使用，保存职责、位置、创建条件和文件路径登记；开发场景图不写备注。备注参与搜索，不替换 `label`，不绘制在画布上。 |

`textPadding` 可省略，默认左右 12、上下 8。查看器把实际边距限制到对应尺寸的一半以内；`wrap` 开启时，X6 在扣除边距后的框内换行，并在放不下时截断。文字尺寸、换行和截断检查必须使用实际字体和渲染结果。

| 连线 `appearance` 字段 | 约束与省略时的行为 |
| --- | --- |
| `opacity` | 0–1，默认 1 |
| `sourceMarker`、`targetMarker` | 两图使用 `none`、`block`；其他标记见查看器文档。省略时由 `arrow` 决定 |
| `sourceMarkerSize`、`targetMarkerSize` | 1–100 的有限数值；省略时块状箭头宽 9、高 7 |
| `labelPosition` | 0–1 的路径长度比例，默认 0.5 |
| `labelOffset` | −1000–1000 的有限数值，默认 0 |
| `labelPadding` | 0–1000 的有限数值；省略时沿用 X6 标签背景边距 |
| `rounded`、`radius` | 前者为布尔值，默认 `false`；后者为 0–1000，启用圆角时默认 10 |
| `jump` | `none`、`arc`、`gap` 或 `sharp`，默认 `none` |
| `routerPadding` | 0–1000 的有限数值；省略时沿用 X6 正交路由间距 |
| `curve` | `default`、`soft`、`basis`、`cardinal`、`catmull-rom`、`natural` 或 `step`；默认不指定曲线 |

`note` 是可选纯文本字符串，最长 100000 个 UTF-16 代码单元，保留换行；在 JSON 字符串内用 `\n` 表示换行。省略表示无备注，不能使用数组、对象或 `null`，编号也是字符串内容。Graph_Map 原样保留备注并支持导入导出，不渲染 Markdown 或 HTML。

本地链接由 Graph_Map 展示和复制，不直接打开文件，不把文件内容打包进 JSON。`target` 最长 8192 字符，不能是空白或含控制字符；本仓库的链接命令还会检查对应场景文件确实存在。仓库移动、场景分类或名称变化后，需要按当前路径更新链接。

链接维护使用 [link_workflow_graph_scenarios.py](../prompt-scenarios/tools/link_workflow_graph_scenarios.py)，用法见[检查场景图名称与链接](../prompt-scenarios/tools/README.md#检查场景图名称与链接)。获准更新时，命令默认只修改可读版节点的 `link`，会替换已有链接；它先核对完整名称集合与目标文件，失败时不写入。`--check` 只检查，不修改；不要把写入命令用于只读审核，也不要用它代替新增节点或关系。

上述附加字段以 Graph_Map 的 `src/core/model.ts`、`src/core/text-sizing.ts`、`src/core/x6-mapping.ts` 和 `docs/json-appearance.md` 为依据。日常维护保留已经生效的配置；新增字段或改变格式时，核对实际使用的查看器版本。

## 编写与保存格式

以 Graph_Map 解析后通过 `JSON.stringify(document, null, 2)` 保存的文本为格式基线：UTF-8 无 BOM、LF 换行、两空格缩进，字符串保留中文原文，文件结尾不补换行。本仓库的 `.editorconfig` 已为图文件设置对应例外，场景链接工具沿用已有字段顺序并采用相同缩进和结尾格式。

JSON 键顺序不改变数据含义，但查看器会按解析器的顺序重建对象；编写顺序不同会在下一次保存时产生大量逐行差异。修改现有对象时保留顺序，新增对象按下表排列当前使用的字段；可选字段不存在时省略，不为了格式补写默认值。节点和连线数组保留已有顺序。

| 对象 | 当前使用的字段顺序 |
| --- | --- |
| 根对象 | `format`、`version`、`documentId`、`nodes`、`edges`、`canvas` |
| 节点 | `id`、`shape`、`x`、`y`、`width`、`height`、`label`、`zIndex`、`fill`、`stroke`、`text`、`textPadding`、`note`、`textSizing`、`link`、`appearance` |
| 连线 | `id`、`source`、`target`、`path`、`vertices`、`label`、`stroke`、`arrow`、`text`、`zIndex`、`appearance` |
| `stroke` | `color`、`width`、`dash` |
| `text` | `fontSize`、`color`、`align`、`fontFamily`、`bold`（节点）、`opacity`、`verticalAlign`、`hidden` |
| 节点 `appearance` | `opacity`、`fillOpacity`、`cornerRadius`、`shadow`、`wrap` |
| 连线 `appearance` | `opacity`、`sourceMarker`、`targetMarker`、`sourceMarkerSize`、`targetMarkerSize`、`labelPosition`、`labelOffset`、`labelPadding`、`rounded`、`radius`、`jump`、`routerPadding`、`curve` |
| 连线端点 | `kind`、`node`、`port` |
| 连线折点 | `x`、`y` |
| `link` | `kind`、`target` |
| `textPadding` | `horizontal`、`vertical` |
| `canvas` | `gridSize`、`gridVisible`、`snapToGrid` |

整理格式时，保留现有的 ID、坐标、尺寸、换行、备注、链接、文字适配方式和箭头配置。开发场景图的节点使用 `textSizing: "content"`，打开时按本机字体重新计算宽高：已有节点以查看器保存后的尺寸为基线，新增节点或改变文字、字体、字号、边距后，下次保存时尺寸可能有少量变化。统一字段顺序可以避免整图字段重排造成的差异，但不能保证不同字体环境下的文字测量完全相同。

新增可选字段或查看器格式变化时，核对实际 `parseDocument` / `validateDocument` 和保存入口，再更新本节对应顺序。日常局部维护沿用现有文件与本节，无需把查看器作为本仓库的运行依赖。

## 最小完整示例

两个节点仍复用真实提示场景名称；示例只演示文件结构，不代表完整场景图。

```json
{
  "format": "graph-map-core",
  "version": 2,
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
        "kind": "node",
        "node": "example-create",
        "port": "right"
      },
      "target": {
        "kind": "node",
        "node": "example-environment",
        "port": "left"
      },
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

## 本地使用次数

查看器的主图契约不要求已有独立次数文件；缺少 `documentId` 时，文件保存流程生成 UUID。框架的两张图均已有稳定 UUID，必须保留。同目录的主图共用可选的 `graph-usage.json`，按 `documentId` 分组，每组按节点或连线 ID 保存使用次数；不同图中的相同元素 ID 互不影响。修改节点文字、布局或主图文件名时保留图 ID；节点重命名也保留元素 ID。主图不保存 `usageCount`，继续由 Git 追踪结构和内容，次数文件由本仓库 `.gitignore` 单独忽略。

次数文件的完整结构如下，示例 ID 仅演示格式：

```json
{
  "format": "graph-map-usage",
  "version": 2,
  "graphs": {
    "163c207d-a618-4953-8219-095116dbb0a2": { "example-create": 3 },
    "7614b3eb-00d1-4d55-b91b-4095d5db7e63": { "node-1": 1 }
  }
}
```

根对象只含 `format`、`version`、`graphs` 三个字段。分组键是主图的 `documentId`；组内的键是元素 ID，值是 0–9007199254740991 的非负安全整数。未设置的元素按 0 次显示，显式 0 也有效。次数文件不存在时按全图 0 次打开；任何分组的格式错误或权限错误都会拒绝打开并保留原会话。不在图中的 ID 不显示，下次保存当前图次数时只清理当前图的分组。

使用次数仍通过属性输入或 −1/+1 修改，可撤销并用于搜索和排序。次数独立参与未保存提醒。“导出 JSON”下载主图副本，“导出次数”下载只含当前图分组的次数副本，均不清除未保存状态。备份或换机器时复制整个目录，包括全部主图和 `graph-usage.json`；Git 克隆不包含个人计数，需自行迁移。

打开图时使用“打开图目录”，才能同时读到主图和次数文件；日常只改次数不会产生主图的 Git 差异。

## 依据与校验

格式依据为独立的 Graph_Map 项目 `src/core/model.ts` 中的 `GraphDocument`、`validateDocument` / `parseDocument`，`src/core/file-document.ts` 中的拆分与次数契约，以及 `docs/json-appearance.md` 和 `docs/integration.md`。核对位置为 `D:/WebTools/Graph_Map`；该路径仅说明格式出处，不是本仓库配置或日常运行前提。需要重新核对格式时，以实际使用的查看器版本为准，不自动引入其新增能力。

格式或字段变化时，可以用实际查看器的 `parseDocument` 校验图文件和最小示例，再比较“解析后重新序列化的文本”与图文件是否一致。已有的通过结果只在内容和覆盖范围没变时复用。这些检查只覆盖数据格式；标签是否放得下、缩放后是否好读、连线是否容易辨认，仍要在查看器中实际看。
