---
name: feature-sync
description: >-
  让已有的 Feature/测试计划与已提交的 GDD、Product 交付、专业规格或项目规则的变化保持一致。用于来源变化的影响分析和当前计划的重新对齐；不用于首次拆分。
---

# 同步 Feature 列表

先使用 [GDD 前提与职责](../../../yaya/methodology/01-product-doc-structure.md#gdd-前提与职责)，再执行下面的阶段 0–6。已有的计划不能代替 GDD。

通过与已记录锚点之间的 Git 差异找出来源变化。绝不通过比较当前来源和当前计划来推断历史变化。下列情况遵循[锚点恢复与当前文档对齐](references/anchor-and-fallback.md)：

- 没有可用的锚点；
- 某个来源现在进入了范围，但不知道锚点是否覆盖过它。

按 [逐个 Product 规划](../../../yaya/methodology/02-feature-list-schema.md#逐个-product-规划) 同步对已有工作的实际影响；后续 Product 的文档发生变化，不是现在就拆分它的理由。

## 共享约定

- **计划文件和数据结构：** `docs/feature-list.json`（索引）、`docs/features/<Feature ID>.json`（详情）、`docs/test-registry.json`，以及只追加的 `docs/feature-list-revisions.json`，定义见 `yaya/methodology/02-feature-list-schema.md`。测试登记表（Registry）的含义遵循 [登记表规则](../../../yaya/methodology/08-test-traceability-and-evidence.md#登记表规则)。完整阅读索引；某个阶段需要时，再读详情、测试登记表和最后一条修订记录。
- **语言：** 新写的文字使用 `yaya/methodology/05-document-language.md`；已完成的历史和原始证据保持原样，不翻译。
- **Git：** 保留改动、目标工作目录、暂存和提交，遵循 `AGENTS.md` 的 **Git 与提交**。
- **来源的负责方：** 本流程更新计划，不更新来源文档。游戏设计边界交回 [design-gdd](../design-gdd/SKILL.md)；工程规则的写入遵循 `yaya/methodology/04-project-rules.md` 中的自查。说明影响时，阅读 methodology 01 的 **设计范围与边界**、`docs/project-rules.md` 和受影响的 Feature 设计稿。已完成 Feature 的设计稿作为历史保留。

## 监视的来源

- `docs/gdd/`：游戏设计意图、规则、状态、数值、版本范围和设计验收。
- `docs/product.md` 和已写成文档的 `docs/product/NN-xxx.md`：交付大纲、已采用的范围、边界、依赖和顺序。
- `docs/project-rules.md` 及其路由到的规则来源（`yaya/agent-rules/`）：协作、架构和技术约束。
- `docs/art/`、`docs/audio/`、`docs/ui/`、`docs/localization/` 和 `docs/presentation/` 中的专业来源，以及按 `yaya/methodology/11-specialist-workflows.md` 的 **查找与映射来源** 通过实际引用找到的其他来源路径。
- 被专业文档或 Feature AC 链接的调参资源 `game/<对象>/tuning/**/*.tres`：已验收的取值。调试台采纳后由收尾提交，再按 `yaya/methodology/13-debug-console-and-validation.md` 的 **完成后再调值** 进入本流程，差异就是资源的取值变化。

提议中的措辞不是已确认的约定。资源状态或位置的变化，对规划来说可能只是编辑性调整，但仍可能改变完成证据的内容指纹。存在 `docs/terminology.md` 时，用它统一解读差异；术语不是单独的行为来源，不改变含义的术语修改属于编辑性调整。两次同步之间，模块文件可能被新增、删除、重命名（包括数字前缀变化）或修改；四种情况都要处理。

## 阶段 0：预检和锚点

1. 读取索引、修订记录和测试登记表。缺少任何文件时，先按 `yaya/methodology/02-feature-list-schema.md` 的 **文件结构** 恢复，再路由或写入：优先从 Git 恢复，不用初始内容覆盖已有的历史；无法恢复时报告缺失，不自行编造。如果索引有效但没有 Feature，通过 [product-author](../product-author/SKILL.md) 和已获授权的 [feature-plan](../feature-plan/SKILL.md) 回到当前 Product 的准备工作。
2. 检查 Git。报告当前分支（`main` 和 `master` 都有效），不要切换分支。查看 `git status --porcelain` 和相关差异；保留无关的工作，在依赖它的写入之前，先解决与计划实际重叠的编辑。
3. **来源先提交规则：** 本次同步用到的每个来源文档，包括阶段 3 中获批的修复，都必须在任何依赖它的计划写入之前，单独、更早地提交。这样差异和下一个锚点才能对应一个实际已提交的状态。
   - 报告未提交的相关来源，并把它交回其负责方；无关的未提交路径不构成阻塞。
   - 到阶段 4 时某个来源改动仍未提交，或在写入计划期间出现，保留它，并停止依赖它的同步。
4. 使用最后一条 `revision_log` 条目的 `synced_at_commit` 作为锚点，并确认它在当前历史中。这包括 [初始规划基线](../../../yaya/methodology/02-feature-list-schema.md#初始规划基线) 下的 `R000` 基线，它的覆盖范围只限于其规划的 Product 和已采用的来源。否则使用参考[锚点恢复与当前文档对齐](references/anchor-and-fallback.md)。
5. 报告分支、锚点的哈希、日期、主题和覆盖依据（或已获授权的回退方式和检查的 HEAD），以及按状态统计的 Feature 数量。

## 阶段 1：用户的先验说明

用户提供了变化说明时直接复用；没有提供时，不带说明继续。只有检查过的变化在意图上留下实质性的歧义时才询问。把实际的回答记下来，供阶段 2 和修订条目使用；没有回答时写 `user_intent: null`。绝不根据差异编造意图。

## 阶段 2：Git 差异分析

阶段 2 不写入任何内容。

### 收集差异

```powershell
git log --format='%h %s' <anchor>..HEAD -- docs/gdd/ docs/product.md docs/product/ docs/project-rules.md yaya/agent-rules/ docs/art/ docs/audio/ docs/ui/ docs/localization/ docs/presentation/ game/*/tuning/
git diff --name-status -M <anchor> HEAD -- docs/gdd/
git diff -M <anchor> HEAD -- docs/gdd/
git diff <anchor> HEAD -- docs/product.md
git diff --stat -M <anchor> HEAD -- docs/product/
git diff --name-status -M <anchor> HEAD -- docs/product/
git diff -M <anchor> HEAD -- docs/product/
git diff --name-status -M <anchor> HEAD -- docs/project-rules.md yaya/agent-rules/
git diff -M <anchor> HEAD -- docs/project-rules.md yaya/agent-rules/
git diff --name-status -M <anchor> HEAD -- docs/art/ docs/audio/ docs/ui/ docs/localization/ docs/presentation/
git diff -M <anchor> HEAD -- docs/art/ docs/audio/ docs/ui/ docs/localization/ docs/presentation/
git diff --name-status -M <anchor> HEAD -- game/*/tuning/
git diff -M <anchor> HEAD -- game/*/tuning/
```

先看提交列表：标题表明是某个 Feature 采纳到游戏、框架同步或已有计划覆盖的规划时，只核对对应差异确实如此，把精力留给其余变化。加上通过引用找到的其他来源路径。`-M` 必须带上，这样 `02-foo.md` 改名为 `03-foo.md` 这类重命名才不会被读成一次删除加一次新增。

### 为每个差异块分类

- **实质性新增：** 新的 GDD 规则、专业约束或已采用的交付范围。
- **实质性修订：** 行为、数值、条件或含义发生变化。
- **实质性删除：** 删除了行为、新增了明确的排除项，或删除了一个模块。
- **编辑性调整：** 措辞、格式、错别字或纯重命名。它不改变任何 Feature。带内容变化的重命名，既是路径修正，也是实质性变化。

### 把变化映射到 Feature

- 对当前范围或已规划范围的新增 → 提出需要的新 Feature，除非锚点之后的规划已经覆盖了它。
- 只涉及后续、尚未规划的 Product 的新增或修订 → 留在 GDD 和 `docs/product.md` 中，推迟它的 Feature。如果整份差异都是这一类，报告被推迟的范围，然后停止，不写入；混合的差异在报告中提到被推迟的范围。
- 修订或删除 → 使用主要的 `source`、AC 和设计引用以及共享的适用范围，找出每个受影响的 Feature ID。沿着被修改的约定能影响到的传递依赖继续追查，包括没有直接链接的使用方。

后续 Product 的变化仍可能通过真实共享的约定影响已有工作；分析这种影响，但不拆分后续 Product。待执行范围发生变化时，考虑拆分或合并，并报告来源 ID 和替代 ID、边界以及依赖的变化。不要给 Feature 重新编号。

来源文件被重命名或删除时，分别列出：

- 对来源文档本身的修复（及其负责方）；
- 随计划保存的 Feature `source`、AC 或设计导航的更新。

路径修正不是实质性变化。分析阶段两者都不修复。

### 分析测试影响

- 把每个提议的 `affected_components` ID 与测试登记表比较，在方案中列出新的和存在冲突的组件记录。
- 对每个已有实现或测试、且被修订或删除的 Feature，追查它的依赖方，以及所属 Feature 或组件与变化重叠的测试。把每个测试归为 `still_valid`、`superseded`、`needs_new_coverage` 或 `uncertain`。
- 提议退役某个测试时，按 [文件 4：`docs/test-registry.json`](../../../yaya/methodology/02-feature-list-schema.md#文件-4docstest-registryjson) 写明原因、锚定的来源、替代的 Feature 和测试 ID 以及修订 ID。仅有来源变化，不是退役测试的理由。
- 遵循 methodology 08 的 **需求变化与过时的测试**：阅读受影响的测试代码（包括没有测试登记表 ID 的单元测试），写明要做的清理以及负责它的 Feature。

### 报告

用对话语言执行 [需求覆盖核对](../../../yaya/methodology/02-feature-list-schema.md#需求覆盖核对)。报告包括：

- 锚点或回退方式；
- 编辑性变化和路径重命名；
- 实质性变化，以及受影响的 ID、状态和建议的动作；
- 下游影响和测试影响；
- 与用户意图的差异；
- 尚未解决的决定。

省略没有内容的类别。

## 阶段 3：用户审阅与决定

把报告中的具体动作与已有的批准比较，只询问尚未批准的实质性选择：范围、退役、依赖之类。没有变化的动作保留原有的批准。用户取消时停止写入；笼统的意图、沉默或报告本身都不算批准。

获批的来源链接修复，通过来源自己的 Skill 完成，并按来源先提交规则，在阶段 4 的任何写入之前提交。不要嵌套启动另一次同步。无法取得授权或无法提交时，报告这一情况，保持计划不变。

修复之后，重新阅读受影响的来源，并对照原来的锚点或回退方式刷新阶段 2 的分析；修复提交不能证明之前的覆盖。复用没有变化的批准，只解决新受影响的选择。只有来源和分析都与已提交的状态一致时，才开始阶段 4。

## 阶段 4：应用已确认的变化

1. 使用 `feature-plan` 中[测试登记表：`docs/test-registry.json`](../feature-plan/SKILL.md#测试登记表docstest-registryjson)一节的合并步骤合并获批的新组件。明确解决冲突的记录；绝不覆盖它们。
2. 按[应用已确认的计划变化](references/apply-plan-changes.md)应用已确认的 Feature、测试和退役变化。索引和它的详情一起修改。

## 阶段 5：记录、校验和提交

1. 更新索引时间，并按 [文件 3：`docs/feature-list-revisions.json`](../../../yaya/methodology/02-feature-list-schema.md#文件-3docsfeature-list-revisionsjson) 追加一条第 2 版修订记录。
   - 保留权威的 `meta.generated_from` 条目，加上实际考虑过的 GDD 和专业来源位置，不声称覆盖了未来的范围。修订本身不写进索引元数据。
   - 使用可读的摘要字段，以及有类型的 `migrations` 和 `dependency_changes`；编辑性同步可以使用空数组。
   - `synced_at_commit` 必须填写：它是本次分析的已提交来源状态，也是下一个锚点。`source_path_updates` 保留重命名的可追溯性。
   - 使用回退方式，或某些来源只在 HEAD 上对齐时，见[记录修订](references/anchor-and-fallback.md#记录修订)。
2. 运行 `python -B yaya/tools/checks/check-feature-list.py`。对照获批的动作审查差异：历史已保留，来源和锚点正确，依赖真实存在，清理和替代覆盖已分配给负责的 Feature。提交之前，修正本任务造成的错误。
3. 按 `AGENTS.md` **Git 与提交** 中 **暂存** 的要求，暂存本任务负责的计划文件和获批的 Feature 设计稿导航修改。除非用户要求不提交，否则提交 `chore(feature-plan): <行为摘要>`（摘要语言跟随 `document_language`）；和首次规划一样，`feature-plan` 这个 scope 指的是计划文件。在正文中概括锚点、计划变化和校验，然后检查提交后的状态。

## 阶段 6：交接

报告下列内容：

- 锚点；
- 新增、废弃、回归和来源路径更新记录的数量；
- 下一个可以开始的 Feature（`python -B yaya/tools/checks/check-feature-list.py --eligible`），或下一个需要重新审视的 Product；
- 回滚或回归方面的警告。

用实际写入的内容刷新覆盖对应关系。把计划对齐和尚待进行的实现与验证区分开；不要把被推迟的 Product 或未解决的缺口说成已同步，后续事项保留在所属的 Feature 或 Progress 中。

完成后返回调用方；Skill 返回不会结束它所服务的已授权任务（methodology 03 **授权与续接**）。

## 异常处理

| 情况 | 必须的处理 |
|---|---|
| 没有可靠的锚点 | 按[锚点恢复与当前文档对齐](references/anchor-and-fallback.md)提出当前文档对齐，并说明历史未知 |
| 变化太广，无法分类 | 与用户一起缩小范围；不要因为文件数或行数而建议整体重新生成 |
| 差异与用户的意图冲突 | 暂停，列出不一致之处，询问是否存在非预期的来源修改 |
| 缺少当前或已写成文档的 Product 来源 | 报告缺失，并在依赖它的写入之前修复来源；未来大纲的条目本来就没有文件 |
| 原有的计划数据无效 | 报告原始错误，并商定修复范围；不要编造历史 |
| 本任务写入了无效的 JSON 或不完整的结果 | 检查它，修正本任务自己的错误并重新校验；恢复方式不清楚或与需要保留的工作重叠时，停止 |
| 文件或 Git 操作失败 | 保留错误信息；修正本任务自己的调用错误，但绝不绕过权限拒绝、重置历史、丢弃工作或扩大范围 |
