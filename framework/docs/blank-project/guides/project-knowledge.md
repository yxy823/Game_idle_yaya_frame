# 项目知识、架构与交接

[返回手册](../README.md) · 相关：[目录参考](../reference/project-layout.md)、[工程变更](engineering-changes.md)

项目文件让下一次接手的人理解需求、当前任务和重要决定。每类内容放在一个负责它的地方，其他文件用链接连接，避免同一段历史到处复制。

## 信息应该放在哪里

| 信息 | 主要位置 | 其他记录如何使用 |
| --- | --- | --- |
| 玩家需要的行为、规则、数值与业务术语 | `docs/product.md`、`docs/product/` | Feature 指向具体来源 |
| 本任务 AC、影响组件、验证计划 | `docs/features/F0XX.json` | Progress 链接当前 Feature |
| 本任务局部决定、占位资源、Bug 经验、TODO | Feature 的 `notes` | 历史和后续任务引用，避免再抄一遍 |
| 当前做到了哪里、阻塞、待决定与下一步 | `docs/progress.md` | 新会话先读取 |
| 一项任务或获批批次的执行历史 | `docs/progress/<key>.md` | 当前 Progress 保留索引 |
| 当前模块、状态归属、依赖方向 | `docs/architecture.md`、子系统文档 | 执行与复审读取相关部分 |
| 重要技术选择的原因与取舍 | `docs/architecture/adr-NNNN-<slug>.md` | 架构地图与 Feature 链接该决定 |
| 可复用工程约束 | `docs/coding_rules.md`、`agent-rules/` | 读取现有规则，新增按明确授权处理 |
| 实际工具路径和命令 | `docs/methodology-config.json` | 其他说明只链接配置 |
| 本次真实执行输出 | `reports/` | 完成依据和任务记录引用原件 |

```mermaid
flowchart LR
    P[Product 行为来源] --> F[Feature 与 AC]
    A[架构地图与 ADR] --> F
    C[Coding Rules 与工程规则] --> F
    F --> T[Test Catalog 与验证]
    T --> R[真实报告]
    R --> E[完成依据]
    F --> N[Feature notes 长期局部记录]
    H[Progress 当前状态] -. 链接 .-> F
    H -. 链接 .-> E
    H -. 链接 .-> Z[Progress 历史归档]
```

这张图表示信息关系，不要求每个项目创建全部可选文档。

## 读取工程规则

项目根 `AGENTS.md` 是路由入口，`docs/coding_rules.md` 保存协作和通用架构原则，`agent-rules/` 按实际修改领域提供具体工程语义。流程和测试追踪由 `methodology/` 负责。

| 修改领域 | 对应规则入口 |
| --- | --- |
| 所有任务 | [00-core](../../../../project-source/agent-rules/00-core/README.md) |
| GDScript | [10-gdscript](../../../../project-source/agent-rules/10-gdscript/README.md) |
| Scene / `.tscn` | [20-scenes](../../../../project-source/agent-rules/20-scenes/README.md) |
| Resource / `.tres` | [21-resources](../../../../project-source/agent-rules/21-resources/README.md) |
| Shader | [30-shaders](../../../../project-source/agent-rules/30-shaders/README.md) |
| 项目配置 | [40-project-config](../../../../project-source/agent-rules/40-project-config/README.md) |
| 导出配置 | [41-export-config](../../../../project-source/agent-rules/41-export-config/README.md) |
| JSON、CSV 等规范数据 | [50-data-files](../../../../project-source/agent-rules/50-data-files/README.md) |
| 图像、音频、字体和导入资产 | [60-assets](../../../../project-source/agent-rules/60-assets/README.md) |
| 测试、fixture、运行器 | [70-tests](../../../../project-source/agent-rules/70-tests/README.md) |

领域可叠加，例如测试 `.gd` 同时遵循脚本和测试规则，Resource fixture 同时遵循资源和测试规则。先读相应 README，再按路由读具体规则，避免每次加载全部规则或遗漏跨领域约束。

## 何时需要架构地图

当仅从源码已经难以看清模块职责、状态归属和依赖方向时，建立 `docs/architecture.md`。复杂子系统展开到单独文件，总览保持可浏览。

地图应指向实际模块，解释谁拥有状态、谁可以调用谁，以及为什么这样划分。需要说明运行过程时，在子系统文档记录触发、参与者、状态变化、结果、Godot 生命周期和失败处理。使用 flowchart 展示依赖，用 sequenceDiagram 展示交互顺序，用 stateDiagram-v2 展示真实状态转换；只画能帮助读者判断的内容。

生成的引用关系只说明解析器看到了什么。动态加载、运行时 Signal 和状态归属不能仅靠文本搜索确定。观察、推断、提议和已实现行为要区分，图表也不是依赖设计的自动批准。

## 何时使用 ADR

某项技术选择跨多个 Feature、长期约束项目或代价较高时，可建立 ADR。记录问题、约束、候选方案、决定、收益、接受的成本、依据和有用的重新考虑条件。普通局部选择保留在 Feature notes 即可。

```mermaid
stateDiagram-v2
    [*] --> Proposed
    Proposed --> Accepted: 在现有任务授权中确认
    Accepted --> Superseded: 后续决定取代并互相链接
```

这些是普通 Markdown 状态，不需要注册表。`Accepted` 说明决定得到确认，不证明相关 API 或运行行为已经测试；`Superseded` 保留旧理由并链接替代 ADR。真实任务已经确认的决定直接沿用，不额外增加一轮批准。

架构地图保存当前结构，ADR 保存跨任务理由，Feature notes 保存局部决定，Progress 保存当前链接。按需更新边界变化，不为每次改函数写 ADR，也不把缺少可选地图当成门禁失败。

## 资源、数据与占位内容

空白项目不指定业务素材目录。资源文件按游戏模块与实际资产流程组织，修改前核对源文件、运行资源、导入信息和生成缓存的归属。

占位内容使用 `_placeholder_` 前缀，并在当前 Feature notes 说明用途、替换方式和未完成的验收。替换素材时核对引用、UID/路径与实际场景；外观、声音、动画和手感仍按需求保留人工验收。

数据格式改变时核对已有内容和加载方，再决定版本、迁移与兼容范围。资产来源和许可证按现有规则记录。工具生成的输出不应成为可复用脚本或重要项目决定的唯一副本。

## Progress 如何帮助继续任务

当前 Progress 只需清楚记录：活动 Feature 或获批批次、真实阶段、阻塞、待决定事项、下一步，以及计划和报告链接。不能从“下一步实施”这句话推断用户已经批准。

任务完成后将执行历史归档一份到 `docs/progress/<key>.md`，保留原文和证据链接；已有归档先读取，不能覆盖或重复复制。未解决问题仍留在当前交接中。移动历史不要求翻译原文，新写的项目知识遵循 `document_language`。

接手时按 Progress → 当前 Feature → 相关历史/证据 → 实际差异的顺序读取，核对已有授权和现在的代码。历史完成与当前内容是否重新验证是不同事实；后续迁移不应伪造过去曾做过的检查。

## 换到新线程继续

对话过长、经过多次压缩，或需要换一个任务继续时，可以让原线程先生成交接提示词。按实际需要使用，不设置必须换线程的压缩次数。

1. 在原线程发送提示词库中“Godot 项目开发 → 验证与收尾 → 整理进度与任务交接”，填入当前任务与用途。Agent 只整理必要的现有 Progress/历史，并生成一个完整的交接代码块。
2. 检查输出是否包含原始目标与最新要求、实际项目/worktree 路径、当前分支、修改归属、真实停点、已有授权、实际检查和下一步。交接内容应当已经填好具体信息；未知事项保留为未知。
3. 在同一个实际项目目录或原 worktree 中打开新任务，把整个代码块复制过去。复制的是原线程生成的结果；库中的提示词用于让原线程整理上下文。原线程输出后停止实施，避免两边继续改同一份文件。
4. 新线程先读取项目规则、相关记录与实际差异，确认原任务现场后，从真实阶段继续。已有具体授权仍然有效；未取得的人工验收、未运行的检查和失效的旧结果仍须如实处理。

交接摘要帮助定位事实，项目原文和实际文件仍需核对。无需为了换线程提交未完成代码、清空工作区、另开分支、重建台账或重跑所有检查；未提交修改按项目规则确认归属并保留。若原线程仍有命令运行，交接写明已知状态，新线程先确认是否结束及结果是否可用，再继续相关操作。

框架维护中的未完成任务使用“Yaya 框架维护 → 维护与复盘 → 生成新线程交接提示词”。该入口只读仓库与会话，保留框架和具体游戏的职责边界，不建立维护 Progress 或交接状态文件。两类正式提示词都只维护在 [提示词库](../../../prompts.json)，这里不复制正文，也不自动创建或投递新任务。

## 报告保留与清理

当前验证、人工验收、未解决失败或后续工作需要的报告继续保留。默认报告不进入 Git，因此代码提交不保证另一台机器拥有报告原件。需要跨目录或跨机器交接时说明实际可用证据，缺失原件不能靠提交说明补成通过。

清理报告是明确的维护动作：读取拟处理目录和当前引用，只清理已理解且获授权的输出。目录较旧、后面有成功运行、文件未被 Git 跟踪，都不自动授权删除。测试运行器不会自动清理旧报告，也不需要额外的保留登记表。

依据：[历史与报告规范](../../../../project-source/methodology/09-artifact-lifecycle.md)、[架构与 ADR 规范](../../../../project-source/methodology/10-architecture-overview.md)。
