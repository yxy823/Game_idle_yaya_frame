# 项目文档目录

这里保存游戏设计、交付计划、实现说明和实际记录。新项目的大多数文档只有用途与待定说明，台账为空；按当前任务补充，不必一次写满。文档默认使用中文，语言与工具路径见 `methodology-config.json`。

## 设计与交付

| 文件或目录 | 用途 |
| --- | --- |
| [gdd/](gdd/README.md) | 游戏目标、玩法规则与体验设计；后续交付引用这里的真实设计 |
| [gdd/open-questions.md](gdd/open-questions.md) | 当前设计中尚未解决、会影响后续决定的问题 |
| [unadopted-ideas.md](unadopted-ideas.md) | 尚未采纳的候选想法，不代表开发承诺；与当前必须解决的开放问题分开 |
| [terminology.md](terminology.md) | 本游戏已确认术语、定义与别名的唯一正文 |
| [ui/](ui/README.md) | 界面布局、状态与交互设计 |
| [presentation/](presentation/README.md) | 一次游戏表现的目标、组成部分、时序与采用方案 |
| [art/art-bible.md](art/art-bible.md) | 共用的美术方向与视觉规范 |
| [audio/sound-bible.md](audio/sound-bible.md) | 共用的音乐、音效与声音规范 |
| [localization/localization-spec.md](localization/localization-spec.md) | 游戏本地化范围、目标语言与表达格式；不同于开发文档的语言设置 |
| [product.md](product.md)、[product/](product/README.md) | 交付范围与推进顺序总览，以及当前交付单元的详细要求 |
| [features/](features/README.md) | 单项 Feature 的任务详情、验收条件及按需编写的局部设计 |

## 实现、进度与工具记录

| 文件或目录 | 用途 |
| --- | --- |
| [game-organization.md](game-organization.md) | 理解游戏逻辑、表现、协作与代码目录的分工 |
| [architecture.md](architecture.md) | 当前实现结构与关键依赖；需要时链接子系统说明和重要架构决定 |
| `project-rules.md` | 本项目的工程约束；游戏玩法要求仍归 GDD |
| `feature-list.json` | Feature 索引、依赖与当前状态 |
| `feature-list-revisions.json` | 需求与任务计划的修订记录 |
| `test-registry.json` | 组件、需求和测试的对应关系，由项目工具读取 |
| `progress.md`、[progress/](progress/README.md) | 当前停点、下一步及按规范保存的执行历史 |
| [research/](research/README.md) | 按需保存的调研材料与结论 |
| [knowledge/](knowledge/README.md) | 按主题查找开发经验、适用条件与失败教训 |
| `methodology-config.json` | 文档语言、Python 和 Godot 可执行路径 |

完成依据 `feature-completion-evidence.json`、具体设计正文和架构决定等按实际工作产生，初始不预填。命令及原始测试报告分别从[工具说明](../tools/README.md)和[报告目录](../reports/)查找；文档存在不代表已经实现、验证或验收。
