# 项目文档目录

这里保存游戏设计、交付计划、实现说明和实际记录。本页是 `docs/` 唯一的目录说明。文档按当前任务补充，不必一次写满。

## 设计与交付

| 文件或目录 | 用途 |
| --- | --- |
| [gdd/](gdd/README.md) | 游戏目标、玩法规则与体验设计；后续交付引用这里的真实设计 |
| [gdd/open-questions.md](gdd/open-questions.md) | 当前设计中尚未解决、会影响后续决定的问题 |
| [unadopted-ideas.md](unadopted-ideas.md) | 没有当前待决设计问题依赖的设想；已采纳规则的备选值仍随规则保存，不代表开发承诺 |
| [terminology.md](terminology.md) | 本游戏已确认术语、定义与别名的唯一正文 |
| [ui/](ui/README.md) | 独立界面及跨界面共享控件的布局、状态与交互设计 |
| [presentation/](presentation/README.md) | 一次游戏表现的目标、组成部分、时序与采用方案 |
| [art/art-bible.md](art/art-bible.md) | 共用的美术方向、视觉规范与共享资源规格 |
| [audio/sound-bible.md](audio/sound-bible.md) | 共用的声音方向、反馈规范与共享资源规格 |
| [localization/](localization/localization-spec.md) | 游戏本地化范围、目标语言、术语译名与表达格式；不同于开发文档的语言设置 |
| [product.md](product.md)、[product/](product/README.md) | 交付范围与推进顺序总览，以及当前交付单元的详细要求 |
| [features/](features/README.md) | 单项 Feature 的任务详情、验收条件及按需编写的局部设计 |

## 实现、进度与工具记录

| 文件或目录 | 用途 |
| --- | --- |
| [game-organization.md](game-organization.md) | 理解游戏逻辑、表现、协作与代码目录的分工 |
| [architecture.md](architecture.md) | 当前实现结构与关键依赖；子系统说明和架构决定按需保存在 `architecture/` 并由它链接 |
| [project-rules.md](project-rules.md) | 本项目的工程约束；游戏玩法要求仍归 GDD |
| `feature-list.json` | Feature 索引、依赖与当前状态 |
| `feature-list-revisions.json` | 需求与任务计划的修订记录 |
| `test-registry.json` | 组件、需求和测试的对应关系，由项目工具读取 |
| [progress.md](progress.md)、[progress/](progress/README.md) | 当前停点、下一步及按规范保存的执行历史 |
| [research/](research/README.md) | 按需保存的调研材料与结论 |
| [knowledge/](knowledge/README.md) | 按主题查找开发经验、适用条件与事实类陷阱 |
| [lessons.md](lessons.md) | Agent 自己的流程失误及出现次数，够了就提出升级 |
| `methodology-config.json` | 文档语言、Python 和 Godot 可执行路径 |
| `.gdignore` | 让 Godot 编辑器不导入本目录 |

以下内容按实际工作产生，不预先建立：

- 每个 Feature 的完成证据 `features/F0XX-evidence.json`；
- GDD、UI、表现等目录下的具体设计正文；
- `architecture/` 下的子系统说明和架构决定。

命令见[项目检查与测试工具](../yaya/tools/README.md)，项目自己的常用脚本见[项目脚本](../dev/tools/README.md)，原始测试报告在[报告目录](../reports/)。文档存在不代表已经实现、验证或验收。
