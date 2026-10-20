# 活动覆盖表

[职责设计准则](README.md)

本页规定怎样用一张表检查生成项目的流程有没有漏掉环节。表里写每一种产出物在讨论、编写、审核、变更后同步四种活动上各由谁负责，默认还是按需触发。表本身在本页末尾，随流程变化维护。

## 为什么用表格

流程的漏洞多数不是写错了某条规则，而是某个产出物缺了一项活动，或者活动存在、却只在用户想起时才做。例如 GDD 原来有讨论（`design-gdd` 复用 `grill-me` 的共享提问方法）和审核（`plan-review` 的 GDD 审查要点），但两者都是按需的，Agent 收到“形成草稿”就直接写稿，写完直接预拆分 Product。逐条读规则看不出这种问题，因为每条规则本身都没错；把产出物和活动排成表，空格和“按需”就一眼可见。

TLA+ 行为模型查不出这类漏洞，因为它只检查建进模型的环节，原因见问答[TLA+ 行为模型能找出流程里漏掉的环节吗？](../../qa/review-and-verification.md#tla-行为模型能找出流程里漏掉的环节吗)。

## 四种活动

| 活动 | 含义 | 例子 |
| --- | --- | --- |
| 讨论 | 动笔前和用户澄清选择或含义 | `grill-me`、`product-spec-elicitor`、`wayfinder`，或某个 Skill 里的提问规则 |
| 编写 | 创建和修改这个产出物 | `design-gdd`、`product-author` |
| 审核 | 检查这个产出物 | `plan-review`、各个 `review-*` 独立审核、人工验收 |
| 变更后同步 | 上游改了，或它自己改了，谁把下游跟上 | `feature-sync`、术语检查、行为模型检查配置的 `covers` |

## 每一格怎样写

- 写负责的 Skill 或规范入口，再在括号里写触发方式：默认（流程规定必做）或按需（用户要求或 Agent 判断时才做）。
- 这项活动对这个产出物确实不需要时，写“不需要”和理由，例如 Progress 不需要讨论。
- 找不到负责方时写“缺口”，并在[当前的表](#当前的表)下方的缺口清单里写明处理。

判断一格是不是漏洞，看这个产出物错了的代价：会传给多少下游、发现时要改多少文件。“按需”本身不是漏洞；错了代价高、又容易被跳过时，才把它改成默认，并放在代价最高的那个节点，例如 GDD 只在第一次预拆分 Product 前默认审一次，不是每版草稿都审。补漏洞时沿用根 `AGENTS.md` 的约束：不新增 Stage、状态文件、评分或审批流程。

## 什么时候更新

- 分发源新增或删除一种产出物，或新增、删除一个负责讨论、审核或同步的 Skill 时，同一次修改里更新表中受影响的行。
- 用户或试用暴露出某个产出物漏了一项活动时，先查表：表里写的和实际不符，改表和对应规则；表里本来就是空格，按上面的判断补上。
- 实质调整流程后，或觉得流程又在漏环节时，用一个独立的实例按本页对整张表重新审核一次，因为写规则的人容易默认自己写的流程是完整的。

## 当前的表

路径相对生成项目根目录。标为“缺口”的格子汇总在表下的缺口清单；补上一处，就同时改表、删掉清单里的那一行。

| 产出物 | 讨论 | 编写 | 审核 | 变更后同步 |
| --- | --- | --- | --- | --- |
| GDD（含设计范围与边界） | `design-gdd` 复用共享提问方法（按需）；核心术语先确认（默认） | `design-gdd`（默认） | 作者自查（默认）；第一次预拆分前 `plan-review`（默认）；其他时候 `plan-review`（按需） | `feature-sync`（按需）；执行 Feature 前只查它自己的来源。缺口：只影响已完成 Feature 的改动 |
| 开放问题 `docs/gdd/open-questions.md` | `grill-me` 或共享提问方法（按需） | `design-gdd`、`design-balance` 在写入任务中（默认） | 预拆分前的 GDD 审核一并检查（默认） | 问题解决时写回所属主题并删除（默认） |
| 未采纳想法 `docs/unadopted-ideas.md` | `grill-me`（按需） | `design-gdd`；用户要求暂存时 `grill-me`（按需） | 不需要：它不采纳需求 | 进入比较或被采纳时迁走（默认） |
| 项目术语 `docs/terminology.md` | 写 GDD 正文前一次列出候选表（默认）；其他时候 `grill-me`（按需） | `terminology-register`（默认） | 用户确认候选表（默认）；术语检查和提交钩子（默认） | GDD、Product 编写和 Stage 3 文档检查点（默认）。缺口：改名不传到玩家可见文本 |
| 数值模型 `docs/gdd/balance/` | `design-balance` 复用共享提问方法（按需） | `design-balance`（默认） | 作者计算检查（默认）；`review-balance`（按需） | 影响内容数据时重新生成（默认）；`feature-sync` 同 GDD |
| Product 总览 `docs/product.md` | `product-spec-elicitor`（按需） | `product-author`（默认） | 作者自查（默认）；`plan-review`（按需） | 每次 Product 收尾后重新审视（默认） |
| 当前 Product `docs/product/NN-<delivery>.md` | `product-spec-elicitor`（按需） | `product-author` 在规划前细化（默认） | 作者自查（默认）；拆分预览让用户看到范围（默认） | Stage 3 文档检查点；Product 收尾清理过时内容（默认） |
| Feature 记录与设计稿 `docs/features/` | 拆分预览和 1D 批准材料（默认） | `feature-plan`、`feature-sync`、`engineering-change-plan`、`feature-execute` | 用户确认预览和 1D 材料（默认）；`check-feature-list.py`（默认）；独立审核（按需） | `feature-sync`（执行前默认）；设计稿在 Stage 3 对齐实现（默认） |
| 测试登记表 `docs/test-registry.json` | 不需要：来自 1D 已批准的验证计划 | `feature-plan`、`feature-execute`（默认） | `check-feature-list.py`；Product 收尾跑全量测试（默认） | `feature-sync` 的测试影响分析（默认） |
| 架构文档 `docs/architecture/` | 不需要：决定在 1C、1D 讨论 | 实现任务在 Stage 3（默认） | 生成页面时检查入口（默认）；审核时对照（按需） | Stage 3 文档检查点（默认） |
| ADR | 1D 决定项（默认） | Stage 2、3（默认） | 用户在 1D 批准（默认） | 决定改变时标为 Superseded（按需） |
| 行为模型 `docs/architecture/models/` | 未确定的组合逐题问用户（默认） | `behavior-model-check` 在 1C（默认） | TLC 跑正确版本、错误版本、可达性检查（默认） | `covers` 列出之后改过的代码；工程变更方案点名要更新的模型（默认） |
| 项目规则 `docs/project-rules.md` | 写入前输出自检报告（默认） | 当前已获授权的任务（默认） | 自检报告加用户决定（默认） | `feature-sync`（默认） |
| Art Bible | 用户看图选定参考（默认） | `design-art-direction`（默认） | 用户看图确认（默认）；`review-art`（按需） | 改方向时对照已接入素材（默认） |
| Sound Bible | 要听才能定的标“待试听”（默认） | `design-audio-direction`（默认） | `review-audio`（按需） | `feature-sync` 监视。缺口：改方向后不对照已接入的音频 |
| UI 规格 `docs/ui/` | 草稿界面（默认）；实质缺口才提问（按需） | `design-ui-spec`（默认） | Stage 4 按界面任务试用（默认）；`review-ux`（按需） | 调试台采纳的变化写回规格（默认） |
| 游戏表现文档 `docs/presentation/` | 实质缺口才提问（按需） | `design-game-presentation`（默认） | 人工验收（默认）；`review-art`、`review-audio`（按需） | 最终验证前更新采纳的组合（默认） |
| 资源规格 | 关键方案未定时交回表现或 UI（默认） | `design-visual-asset-spec`、`design-audio-asset-spec`（默认） | 文件到达时检查（默认）；`review-assets`（按需） | 规格变化后重新判断已交付成品（默认） |
| 本地化规范 | `design-localization-spec`（按需） | `design-localization-spec`（按需） | `review-localization`（按需） | `feature-sync` 监视（默认） |
| 玩家可见文本（翻译表） | 缺口：“语气与用词”为空时没有默认的讨论点 | 引入它的 Feature（默认） | Stage 3 核对理解（默认）；用户阅读（manual 时） | 缺口：术语改名后不搜翻译表 |
| 内容数据 | Stage 1 批准材料写明做法（默认） | `content-data-authoring`（默认） | 不变量测试（默认）；`review-balance`（按需） | 公式变化后重新生成（默认） |
| 人工验收清单 | 不需要：来自 1D 已批准的计划 | `manual-acceptance`（默认） | 用户实际验收（默认） | 绑定后内容变化逐项核对（默认） |
| Progress | 不需要：过程记录 | `feature-execute`、`feature-plan`（默认） | 不需要：不代表批准或验收 | 每次更新删掉不成立的说法（默认） |
| Lessons | 不需要：Agent 自己的失误 | Stage 7 和用户纠正后（默认） | 用户批准升级（默认） | 达到次数时提出升级（默认） |
| 知识 `docs/knowledge/` | 不需要：已发生的经验 | Stage 7 前定稿（默认） | 作者核对准确性（默认） | 被证明错误时删除（默认）。缺口：引擎升级后不复核 |
| 问答 `docs/qa/` | 回复结尾提议（默认） | `qa-explainer`（按需） | 不需要：只解释，不作依据 | 收尾核对时更新（默认） |

### 缺口清单

| 缺口 | 错了会怎样 |
| --- | --- |
| GDD 或专业文档的改动只影响已完成的 Feature 时，`feature-sync` 可能一直不跑；Product 收尾也不核对 | 已实现的行为和 GDD 悄悄分开，后面的 Product 在旧行为上开发 |
| 玩家可见文本的语气和称呼没有默认的讨论点 | 第一个有文字的 Feature 自定语气，后面都沿用，发现时要改整张翻译表 |
| 术语改名不搜翻译表；术语检查不读 CSV | 游戏里显示旧名称 |
| Sound Bible 改方向后不对照已接入的音频，Art Bible 有这一条 | 已接入的音效和新方向不一致 |
| 引擎补丁升级不复核写明旧版本的知识条目 | Agent 照失效的变通做法实现 |
