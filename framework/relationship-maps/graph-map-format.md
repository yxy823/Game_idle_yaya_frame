# Graph_Map 文件格式

[关系图说明](README.md) · [框架入口](../README.md)

文档系统关系图是 Graph_Map 的 `graph-map-core` v2 主图。通用格式以 Graph_Map 自带的 graph-map-json Skill（`D:/WebTools/Graph_Map/skills/graph-map-json/SKILL.md`）为准：字段、取值范围、端点、外观和次数文件见其中的 `references/format.md` 与 `references/usage-and-legacy.md`。本页只写这张图自己的约定和校验方法；图的阅读含义与维护规则见[文档系统关系图](README.md)。

## 字段约定

格式允许而这张图没用的能力，例如组、旋转、悬空端点、`flow`，新增时先确认有阅读上的需要，不因格式支持就加。

| 对象 | 约定 |
| --- | --- |
| 根对象 | 固定的 `documentId`，维护时保留，次数文件靠它关联 |
| ID | `doc-`、`relation-` 标识文档节点与连线，`caption-`、`legend-` 标识阅读辅助。节点改名保留 ID，新增对象用新 ID，不占用旧 ID |
| 节点 `shape` | 文档节点用 `rounded-rect`，分区标题与图例用 `text` |
| 节点 `textSizing` | 用 `fixed`，保持保存的尺寸 |
| 节点 `link` | 用 `kind: "local"`，指向实际入口、源文件、模板或规范的绝对路径 |
| 节点 `note` | 写职责、位置、创建条件和文件路径登记，格式见[节点名称与文件登记](README.md#节点名称与文件登记) |
| 连线方向 | 单向衔接用 `arrow: "target"`；显式写 `sourceMarker`、`targetMarker` 时，两端都要和实际方向一致，起点为 `none` |

来源、维护约定等说明写在本目录的说明文件里，不扩充 JSON 字段。

## 编写与保存格式

图文件以 Graph_Map 保存出的文本为基线，校验脚本的 `matchesSaveFormat` 必须为 `true`。这样在查看器里打开再保存，不会产生键顺序、数字写法或换行造成的整图差异。`matchesSaveFormat` 为 `false` 时，按脚本报出的首个差异行改，再重跑。

- 修改现有对象时保留字段顺序和数组顺序；可选字段不存在时省略，不为了格式补写默认值。
- 用 Python 写入时，整数坐标保持 int，`json.dump` 会把 float 写成 `6562.0`。
- 整理格式时，保留现有的 ID、坐标、尺寸、换行、备注、链接、文字适配方式和箭头配置。

## 本地使用次数

同目录的主图共用 `graph-usage.json`，按 `documentId` 分组保存每个节点和连线的使用次数，结构见 graph-map-json 的 `references/usage-and-legacy.md`。主图不保存 `usageCount`，由 Git 追踪结构和内容；次数文件由本仓库 `.gitignore` 忽略，备份或换机器时自行复制。修改节点文字、布局或主图文件名时保留图 ID 和元素 ID，否则已有次数会对不上。

## 依据与校验

改完图文件后，对每个改过的图运行：

```powershell
node "D:/WebTools/Graph_Map/skills/graph-map-json/scripts/validate-json.mjs" "D:/A_Games/Game_idle_yaya_frame/framework/relationship-maps/<图文件>" "D:/WebTools/Graph_Map"
```

通过的标准是退出码为 0，并且 `matchesSaveFormat` 为 `true`。脚本调用 `D:/WebTools/Graph_Map` 当前的解析器，需要 Node.js 24 或以上。

这项校验只覆盖数据格式。场景名称、链接和连线穿过节点由 README 的[依据与检查](README.md#依据与检查)列出的仓库检查负责；标签是否放得下、缩放后是否好读、连线是否容易辨认，仍要在查看器中实际看。
