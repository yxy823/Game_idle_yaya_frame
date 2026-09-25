# 项目对象与目录

[操作手册](README.md)

以下路径相对生成项目根目录。文件职责由实际使用者和权威来源决定；目录、模板或空占位文件的存在不代表相应工作已经完成。

## 主要对象及读写关系

| 对象 | 保存什么 | 主要维护者与读取方 |
| --- | --- | --- |
| `README.md` / `AGENTS.md` | 项目导航 / Agent 约束与路由 | 项目维护者；用户与所有执行 Agent |
| `agent-rules/` / `methodology/` | 按领域工程语义 / 开发和验证契约 | 所属规范；执行与审核按当前任务读取 |
| `.agents/skills/` / `.codex/agents/` | 专项方法 / researcher、independent-reviewer 角色配置 | 主 Agent 按任务选用；角色文件不证明宿主已加载 |
| `docs/methodology-config.json` | 文档语言及工具路径 | 环境维护；项目命令读取 |
| `docs/product.md` / `docs/product/` | 总体范围、模块关系 / 可观察行为与规则 | `product-author`；规划和实现读取 |
| `docs/terminology.md` | 跨模块复用的已确认定义 | `project-terminology`；不复制玩法规则 |
| `docs/project-rules.md` | 项目级 MUST、PREFER、REVIEW 约束 | 已获准规则维护；所有相关工作读取 |
| `docs/game-organization.md` | 游戏代码、场景与资源的组织和命名判断指南 | 项目结构工作按需读取；[随项目复制的指南](../../../project-source/defaults/docs/game-organization.md) |
| `docs/unadopted-ideas.md` | 未采纳设想及其原因；不代表开发承诺 | 需求讨论按需维护；采纳后链接正式来源 |
| `docs/art/`、`docs/audio/`、`docs/ui/`、`docs/localization/` | 共享方向和专业规格 | 对应 design Skill；行为仍由 Product 定义 |
| `docs/resource-requirements/` | 稳定业务范围的素材准备要求、位置与状态 | 对应专业规格及接入任务；README 只导航 |
| `docs/feature-list.json` | ID、标题、依赖、状态与详情入口 | 规划/执行；可开始任务及台账检查 |
| `docs/features/F0XX.json` | 本项范围、AC、来源、验证义务与必要 notes | 规划/执行；测试选择和完成检查 |
| `docs/features/F0XX-design.md` | 按需展开局部设计与理由 | 原任务；不拥有第二套 AC 或测试映射 |
| `docs/test-registry.json` | 组件与测试 ID、套件/case、planned/active/retired | 规划/实现；测试运行器 |
| `docs/feature-list-revisions.json` | 真实规划覆盖基线与修订 | 规划/同步；不是任意最新 Git 提交的别名 |
| `docs/feature-completion-evidence.json` | 当前完成依据的原件引用及绑定 | 完成记录工具；首个真实结果后出现 |
| `docs/architecture.md` / `docs/architecture/` | 当前结构导航 / 子系统说明及历史 ADR | 实际结构或重要决定改变时维护 |
| `docs/knowledge/` / `docs/research/` | 项目实践经验 / 外部资料研究 | 已授权的经验或调研任务；不成为需求唯一正文 |
| `docs/progress.md` / `docs/progress/` | 当前停点与下一步 / 单份已归档执行历史 | 原任务；新对话恢复事实 |
| `reports/` | 运行原件、人工验收与任务报告 | 相应工具或用户；默认不跟踪到 Git |

`source` 和引用能定位材料，不自动证明其获准、仍有效或已覆盖。测试登记、执行结果、验收决定与 `done` 是不同事实。

## 代码与开发工具

```text
项目根/
├── main/                     最小启动和装配入口
├── game/                     游戏独有模块、场景、状态与资源
├── components/               实际可复用能力
├── assets/                   共享资产（按真实需要组织）
├── examples/asset_workbench/  可独立运行的分发示例
├── addons/                   第三方插件及已记录补丁
├── tools/
│   ├── checks/               环境与 Feature 台账检查
│   ├── features/             组件合并与完成记录命令
│   ├── lib/                  验证快照、解析及共享实现
│   ├── testing/              gdUnit 运行、报告与验证支持
│   ├── asset_workbench/      编辑期资源试调工具
│   └── asset_analyzer/       图像/音频源文件分析
└── tests/
    ├── unit/                 组件级自动测试
    ├── features/             Feature 验收与回归
    └── invariants/           跨任务不变量
```

最小入口不是预建完整游戏架构。代码、场景和资源可按业务模块相邻放置；存档、设置和全局 UI 按实际所有者组织。工程规则的编号目录不要求游戏照搬同样层级，也不要求新增 Bootstrap、Autoload、事件总线或每类脚本一个目录。

四类工作台及消费示例不替换正式主场景。`.git/` 由创建器建立；`.godot/`、运行报告、真实测试套件与可选设计等按实际活动产生。初始空测试目录和占位 Product 不提供任何通过证据。

## 复制与重命名

完整映射只维护在 [project-files.json](../../project-files.json)。主要重命名与复制关系包括：

- **项目入口：** `Project_AGENTS.md → AGENTS.md`、`Project_README.md → README.md`。
- **方法与角色：** `skills/ → .agents/skills/`、`agents/ → .codex/agents/`。新增 Skill 位于已选中的整个 skills 目录时无需重复列映射。
- **其他材料：** 默认文档、工程规则、方法、代码、工具及插件按清单复制。

`framework/`、根维护规则和完整提示词库不进入项目。创建器不做变量渲染，不自动安装分析器依赖；复制选择不等于每个被复制组件已被项目采用。

## 模板与按需记录

`methodology/templates/` 提供 Product、Feature、工程变更、详情/索引/修订、测试登记、完成证据、人工清单、Progress、知识、项目规则、架构和 ADR 的格式参考。它们不是需要一次性填满的任务清单。正式 JSON 保留所属契约必需字段；可选 Feature 设计按解释需要省略不适用章节。

| 产物 | 位置与注意事项 |
| --- | --- |
| 初始化事实 | `reports/initialization.md`；后续记增量 |
| gdUnit 原件 | `reports/gdunit-wrapper/<Feature-ID 或 focused>/run-<id>/`；保留真实结果与失败 |
| 人工清单与结果 | `reports/manual-acceptance/`；原清单和用户结果分开保存 |
| Feature 自定义结果 | `reports/features/<Feature-ID>/` |
| 其他维护报告 | `reports/maintenance/<任务>/` |
| 临时输入与验证副本 | `reports/scratch/<任务>/`；名称不授予删除权限 |

临时目录不能保存重要代码或决定的唯一副本。当前验收、失败调查及知识引用依赖的报告需要保留，归组须同时调整读写方与引用，工具原件固定路径不随意搬动。

## Git 与 Godot 扫描的区别

Git 的默认范围如下，具体模式以 [默认 gitignore](../../../project-source/defaults/.gitignore) 为准。

- **默认忽略：** Godot 缓存、派生翻译缓存、报告和本机秘密；`.env.example` / `.env.template` 可保留。
- **按项目规则跟踪：** 源素材、必要 `.import`、`.gd.uid`、导出预设、插件、Skill 与正式文档。

还需区分扫描、导入与证据保留：

- `.gdignore` 控制 Godot 扫描，不决定 Git 是否跟踪或文件是否可删除。
- `.import` 是导入配置，`.godot/` 是缓存，两者不能一并当作垃圾清空。
- 报告未进 Git 时，本地提交不保证另一位置拥有验证原件。

文档选择依据见 [知识、设计与记录](knowledge-and-records.md)，专业材料职责见 [专业来源与资源](specialist-work.md)。
