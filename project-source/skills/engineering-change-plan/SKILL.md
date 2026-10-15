---
name: engineering-change-plan
description: >-
  准备 Bug、重构或维护类 Feature，保持已确认的 GDD 设计和交付范围不变。分诊职责归属和证据，取得缺少的批准，追加工程计划，然后交给已获授权的执行。中文触发：修复已完成功能的回归 Bug、按选定的坏味道重构、升级依赖或修工具。游戏设计发生变化或含义不清时，交给 design-gdd；还没选定重构哪个坏味道时，先用 engineering-refactor-select。
---

# 规范一次工程变更

## 依据

分类、Bug 归属、各模式需要的证据和 AC、Feature 写入以及 Bug 经验的提升，遵循 `yaya/methodology/07-engineering-change.md`。产物使用 `yaya/methodology/02-feature-list-schema.md` 中对应的数据结构，语言遵循 `yaya/methodology/05-document-language.md`。长期写入之前，遵循 `AGENTS.md` 的 **Git 与提交**。

开始项目工程工作之前，使用 [GDD 前提与职责](../../../yaya/methodology/01-product-doc-structure.md#gdd-前提与职责)。本 Skill 准备工程工作；[feature-execute](../feature-execute/SKILL.md) 执行它。准备工作不代表人工验收。

## 分诊与方案

阅读约束本任务的 `docs/project-rules.md`、路由到的工程规则，以及相关的已有 Feature 设计稿和架构决定。调查或修改游戏行为时，还要使用 `yaya/methodology/01-product-doc-structure.md` 的 **设计范围与边界** 以及相关的 GDD 和专业来源。提出的工程规则修改遵循 `yaya/methodology/04-project-rules.md` 中的自查和授权；技术修复不能悄悄修改工程约束或游戏设计边界。

把一份报告当作变更处理之前，先使用 methodology 07 的 **反馈评估**，即使没有选用分诊 Skill 也要这样做。[feedback-triage](../feedback-triage/SKILL.md) 以直接入口的形式提供同样的检查。缺陷需要查找原因时，通过 [bug-diagnosis](../bug-diagnosis/SKILL.md) 使用其中的 **因果诊断**，只收集本次准备需要的证据。已完成的评估和诊断直接复用；按 Bug 约定，缺少的因果证据可以在初始方案中明确标为缺失。

1. 阅读实际已确认的 GDD、Product 交付范围、专业或技术约定、当前 Progress 和相关历史。区分游戏行为和项目工具，按 methodology 07 的 **分类边界** 选择一种模式。按下列去向转交：
   - GDD 意图有变化或含义不清：[design-gdd](../design-gdd/SKILL.md)；
   - 限定范围的数值设计：[design-balance](../design-balance/SKILL.md)；
   - 交付范围：[product-author](../product-author/SKILL.md)；
   - 专业要求有变化或含义不清：`yaya/methodology/11-specialist-workflows.md` 中对应的专业入口。

   按权威归属表，未完成的工作中引入的缺陷留在那个 Feature 中处理。
2. 按工程变更流程，只收集所选模式必需的证据。未确认的根本原因保持为未知。没有指定具体内容的重构，使用 [engineering-refactor-select](../engineering-refactor-select/SKILL.md)，带着选中的候选回到这里。
3. 阅读 Feature 索引和相关详情。如果这项工作依赖一个尚未规划的当前 Product，先用 [feature-plan](../feature-plan/SKILL.md) 完成这个前提。独立的工具工作使用其已写成文档的技术约定；只要项目已经有实际的 GDD，它可以在没有详细业务 Product 的情况下，向一个有效的空 Feature 记录追加工程 Feature。阅读测试登记表（Test Registry），提出可以复用的或新的受影响组件。
4. 提出能独立验证的最小 Feature；`large` 的工作要拆分。展示 ID、标题、模式、依赖、受影响的组件、稳定的验收条件、预计涉及的文件或区域，以及验证义务。已有批准覆盖这份方案时直接沿用，只解决缺少的实质性决定。

对 `bug`，用准确的、已确认的 GDD/Product/专业小节，或已写成文档的框架/工具约定作为 `source`。对 `refactor` 和 `maintenance`，使用 `infrastructure`，除非有单一的权威来源负责被保持的约定。新的独立 Bug 按权威约定填写 `bug_diagnosis`；其他模式不要编造诊断。长期保存的证据保持简洁，并链接执行归档。

业务工作正在进行时遇到项目工具的阻塞问题：

- 保留进行中的工作及其证据。
- 按 `AGENTS.md` **Git 与提交** 中的 **暂存** 和 **提交**，在任务指定的工作目录中完成这次有边界的修复，让它改动的路径、证据和逻辑提交与业务工作分开。
- 在依赖它的修改之前，先解决具体重叠的编辑。
- 修复后，通过已有的 Progress/Feature 记录回到暂停的工作。
- 不要引入改动归属追踪流程，也不要只为了得到一个干净的目录而创建 worktree。

## 写入与交接

获得批准后，在写入 Feature 计划之前，按 `feature-plan` 中[测试登记表：`docs/test-registry.json`](../feature-plan/SKILL.md#测试登记表docstest-registryjson)一节的合并步骤合并缺少的组件。候选格式、冲突处理和已有记录的保留都由该步骤负责。临时候选文件不提交。

使用权威的初始规划值，追加索引条目和对应的工程详情；保留已完成的历史和工程分类。这次操作不追加修订记录条目，因为没有发生针对权威来源的同步。

校验和本地计划提交遵循工程变更流程的 **Feature 写入规则**。宣布计划就绪之前，对照已批准的范围、组件登记和被保留的历史检查实际差异。提交中写上所属 Feature 的 `Work item` 引用。

报告创建的 Feature 和剩余工作。把 Bug 的复现与回归义务以及权威的经验记录要求传给执行阶段；准备阶段不运行测试，也不登记验收。只有具体范围已获授权时，执行才继续使用 `feature-execute`；否则停在缺少的决定上。完成后返回调用方；Skill 返回不会结束它所服务的已授权任务（methodology 03 **授权与续接**）。
