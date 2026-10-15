# Graph_Map 文件格式

[关系图说明](README.md) · [框架入口](../README.md)

两张关系图都是 Graph_Map 的 `graph-map-core` v2 主图。通用格式以 Graph_Map 自带的 graph-map-json Skill（`D:/WebTools/Graph_Map/skills/graph-map-json/SKILL.md`）为准：字段、取值范围、端点、外观和次数文件见其中的 `references/format.md` 与 `references/usage-and-legacy.md`。本页只写两张图自己的约定和校验方法；图的阅读含义与维护规则见[文档关系图与开发场景图](README.md)。

## 两张图的字段约定

格式允许而两张图没用的能力，例如组、旋转、悬空端点、`flow`，新增时先确认有阅读上的需要，不因格式支持就加。

| 对象 | 约定 |
| --- | --- |
| 根对象 | 两张图各有固定的 `documentId`，维护时保留，次数文件靠它关联 |
| ID | 文档图用 `doc-`、`relation-` 标识文档节点与连线，`caption-`、`legend-` 标识阅读辅助；场景图用 `scene-`、`link-`。节点改名保留 ID，新增对象用新 ID，不占用旧 ID |
| 节点 `shape` | 场景图统一用 `rounded-rect`；文档图的文档节点用 `rounded-rect`，分区标题与图例用 `text` |
| 节点 `textSizing` | 场景图用 `content`，打开时按本机字体重算宽高；文档图用 `fixed`，保持保存的尺寸 |
| 节点 `link` | 都用 `kind: "local"`。场景图指向同名场景文件；文档图指向实际入口、源文件、模板或规范的绝对路径 |
| 节点 `note` | 只有文档图使用，写职责、位置、创建条件和文件路径登记，格式见[节点名称与文件登记](README.md#节点名称与文件登记)；场景图不写备注 |
| 连线方向 | 单向衔接用 `arrow: "target"`；显式写 `sourceMarker`、`targetMarker` 时，两端都要和实际方向一致，起点为 `none` |

来源、维护约定等说明写在本目录的说明文件里，不扩充 JSON 字段。

## 编写与保存格式

图文件以 Graph_Map 保存出的文本为基线，校验脚本的 `matchesSaveFormat` 必须为 `true`。这样在查看器里打开再保存，不会产生键顺序、数字写法或换行造成的整图差异。`matchesSaveFormat` 为 `false` 时，按脚本报出的首个差异行改，再重跑。

- 修改现有对象时保留字段顺序和数组顺序；可选字段不存在时省略，不为了格式补写默认值。
- 用 Python 写入时，整数坐标保持 int，`json.dump` 会把 float 写成 `6562.0`。
- 整理格式时，保留现有的 ID、坐标、尺寸、换行、备注、链接、文字适配方式和箭头配置。

场景图节点使用 `textSizing: "content"`，所以 `matchesSaveFormat` 为 `true` 也不保证保存后零差异：新增节点，或改了文字、字体、字号、边距后，下次保存时尺寸可能有少量变化。已有节点以查看器保存后的尺寸为基线。

场景图的节点链接用 [link_workflow_graph_scenarios.py](../prompt-scenarios/tools/link_workflow_graph_scenarios.py) 维护，用法见[检查场景图名称与链接](../prompt-scenarios/tools/README.md#检查场景图名称与链接)。获准更新时，命令默认只修改可读版节点的 `link`，会替换已有链接；它先核对完整名称集合与目标文件，失败时不写入。`--check` 只检查，不修改；不要把写入命令用于只读审核，也不要用它代替新增节点或关系。仓库移动、场景分类或名称变化后，按当前路径更新链接。

## 本地使用次数

同目录的主图共用 `graph-usage.json`，按 `documentId` 分组保存每个节点和连线的使用次数，结构见 graph-map-json 的 `references/usage-and-legacy.md`。主图不保存 `usageCount`，由 Git 追踪结构和内容；次数文件由本仓库 `.gitignore` 忽略，备份或换机器时自行复制。修改节点文字、布局或主图文件名时保留图 ID 和元素 ID，否则已有次数会对不上。

## 依据与校验

改完图文件后，对每个改过的图运行：

```powershell
node "D:/WebTools/Graph_Map/skills/graph-map-json/scripts/validate-json.mjs" "D:/A_Games/Game_idle_yaya_frame/framework/relationship-maps/<图文件>" "D:/WebTools/Graph_Map"
```

通过的标准是退出码为 0，并且 `matchesSaveFormat` 为 `true`。脚本调用 `D:/WebTools/Graph_Map` 当前的解析器，需要 Node.js 24 或以上。

这项校验只覆盖数据格式。场景名称、链接和连线穿过节点由 README 的[依据与检查](README.md#依据与检查)列出的仓库检查负责；标签是否放得下、缩放后是否好读、连线是否容易辨认，仍要在查看器中实际看。
