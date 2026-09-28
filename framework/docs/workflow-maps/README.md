# 游戏项目开发场景图与 JSON 格式

[文档入口](../README.md) · [打开图文件](game-development-workflow.json)

`game-development-workflow.json` 展示 [提示词库](../../prompts.json) 中 `Godot 项目开发` 的全部场景及其衔接关系。节点只显示原有提示场景名称，不复制提示词正文，不新增阶段、判断、标题或说明节点。具体操作仍查对应提示词或[场景索引](../quick-reference/scenario-index.md)。

## 阅读与维护

将 JSON 导入支持 `graph-map-core` v1 的查看器。导入替换当前画布；需要保留当前编辑时先导出。编辑后导出的 JSON 是新副本，不会自动更新仓库原文件。

节点按现有分类从左向右摆放：项目创建与接入、需求设计、任务规划、日常开发、资源、性能与数据、修复与改进、验证与收尾、项目恢复与交接、经验沉淀。颜色只辅助辨认分类，不表示任务状态；分类名称不另建节点。

- **蓝色实线**：常见交付路径中的场景衔接，仍需满足线上的条件。
- **灰色虚线**：按需选择、替代入口、问题处理或续接关系。箭头不代表自动执行或新增授权。
- **条件标签**：说明何时可转入目标场景，不替代提示词自身的前提与完成要求。跨区长线按端点与标签辨认。

图展示场景之间的关系，不是必须逐节点执行的清单。已有 GDD、具体授权、适用验证与真实人工验收要求仍以项目规范为准。图中没有单独的“完成”节点；转入下一 Product 的线要求当前 Product 的全部适用完成条件已经满足。自动验收型 Feature 无需绕行人工验收场景。

维护时先核对 `prompts.json` 对应 Project 的分类与名称；每个场景恰好对应一个节点，`label` 必须逐字一致，不加编号、换行、步骤或 Skill 名称。新增或删除场景时才相应增删节点，日常关系调整只修改连线和必要布局。保留已有节点 ID；新 ID 不占用旧 ID，不因提示词排序改变而重编号。场景重命名时保留其身份并更新名称，检查所有相关连线。没有场景入口的工作不自行补成节点。

本目录只在框架维护仓库保存，不进入生成项目复制清单，也不建立运行依赖或自动同步。以下格式说明足以支持日常编辑；无需读取外部项目代码。

## 文件结构

使用 UTF-8 的严格 JSON，无注释、尾逗号、重复键或非有限数值。根对象恰好包含下列五个字段，所有对象均拒绝未定义字段。

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

每个节点必须提供下列全部字段，没有可选字段。

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
| `flow` | 唯一可选字段；省略时静态显示，不会自动补写 |

`flow` 若出现，必须同时含 `direction`（`off`、`forward`、`reverse`）和 `speed`（`slow`、`normal`、`fast`），不得增加其他字段。本图省略 `flow`，默认静态显示。

公共样式对象的约束如下：

- 颜色只接受六位十六进制 `#RRGGBB`（大小写均可）或 `transparent`，不接受三位缩写、颜色名称、RGB 函数或含透明通道的八位值。
- `stroke.width` 为 0–32 的有限数值；`stroke.dash` 为 `solid`、`dashed` 或 `dotted`。
- `text.fontSize` 为 6–256 的有限数值；`text.align` 为 `left`、`center` 或 `right`。

不写入 `workspace`、`layerId`、`viewIds`、`parentId`、媒体、任意元数据或 X6 `cells`。本格式不支持分组、多视图和思源插件 Graph Map v2。来源、维护约定等说明放在本文件，不扩充 JSON 字段。

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

修改后核对节点名称集合与提示词集合完全一致，ID 稳定无重复，所有端点存在；再检查连线条件与场景边界，以及坐标、节点尺寸和折点。初版使用上述查看器的实际 `parseDocument` 校验图文件与最小示例，无需在仓库增加校验脚本或依赖。格式通过不证明标签适配或视觉体验通过；导入后的缩放、阅读与连线辨识由用户实际查看。
