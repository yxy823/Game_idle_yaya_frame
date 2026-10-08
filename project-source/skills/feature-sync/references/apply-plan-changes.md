# 应用已确认的计划变化

在 [feature-sync](../SKILL.md) 阶段 4 中、测试登记表合并之后使用本参考。字段形态和初始规划值定义在 `yaya/methodology/02-feature-list-schema.md`。下面的动作说明哪些内容可以修改；它们不重新定义字段，也不授权改写已完成的行为。

## 新增

- 用从未使用过的 ID 和权威的初始值，追加新的索引条目和对应的详情。
- 写出准确的来源小节；新行为扩展了某项已完成的能力时，写明被扩展的能力。
- 由 Product 派生的新增省略 `engineering_change`。在修正来源、修改笔记和状态，或做允许的待执行修订时，工程 Feature 上的这个字段保持不变。

## 删除

每次删除都在详情的 `notes` 中追加一条按文档语言书写、带时间戳的删除原因，时间戳用 ISO 8601 UTC，例如 `2026-10-04T12:00:00Z 删除 AC03：……`。

| 当前状态 | 已确认的动作 |
|---|---|
| `pending` | 把索引的 `status` 设为 `obsolete` |
| `blocked` | 把索引的 `status` 设为 `obsolete`；保留已记录的阻塞原因 |
| `in_progress` | 把索引的 `status` 设为 `obsolete`；警告已写的代码可能需要经明确授权的回滚 |
| `done` | 把索引的 `status` 设为 `obsolete_done`；保留 `id`、`description` 和 `acceptance_criteria`；追加一个新 Feature 来移除已实现的行为，其依赖根据实际影响选择 |
| `obsolete` 或 `obsolete_done` | 状态保持不变；在笔记中说明这一排除再次得到确认 |

不要翻译或实质性改写被删除的 `done` Feature。它的状态转换和删除笔记记录了已确认的删除；实现工作由新的删除 Feature 承担。

变成 `obsolete` 的 Feature 不能保留状态为 `planned` 的测试登记表测试：

- 退役有替代项时，按下面的[测试可追溯性更新](#测试可追溯性更新)带上出处退役这些测试。
- Feature 退役且没有替代项时，删除它状态为 `planned` 的测试登记表条目，同时从它的 AC 和回归映射中删掉这些测试 ID，并把 `acceptance_mode` 设回 `null`。见 methodology 02 的 [文件 4：`docs/test-registry.json`](../../../../yaya/methodology/02-feature-list-schema.md#文件-4docstest-registryjson)。

## 修订

| 当前状态 | 已确认的动作 |
|---|---|
| `pending` | 在执行之前，更新详情中的 `description`、`affected_components` 以及验收条件的文本或 ID；保留仍然有效的已规划验证映射；明确退役被取代的已规划测试登记表条目，被撤回且没有替代的条件按 methodology 02 删除其 `planned` 条目；追加一条按文档语言书写、带时间戳的修订笔记；只有受影响时才修改索引的 `title` |
| `blocked` | 执行 `pending` 的动作，然后按 [状态流转](../../../../yaya/methodology/02-feature-list-schema.md#状态流转) 重新检查已记录的阻塞原因；阻塞仍在时保持 `blocked`，否则恢复为 `pending`，并在 `notes` 中写明已解决的前提和原因 |
| `in_progress` | 执行 `pending` 的动作，并警告当前实现可能需要调整 |
| `done` | 不修改原来的索引条目或详情。追加一个新 Feature，按新规则修订实现；它依赖原来的 ID，并在验收条件中写明新行为 |
| `obsolete` 或 `obsolete_done` | 通常不做任何事。用户想重新启用时，要求明确的决定，并追加一个新 Feature |

## 来源路径修正

- 修正计划记录或 Feature 设计稿导航中受影响的主要 `source` 路径和次要链接，需要时也包括历史导航。修正链接不代表可以改写已完成的需求或决定。对来源文档本身的修复属于阶段 3。
- 主要 Feature `source` 的变化，用 `{ feature, from, to }` 的形态记录在 `source_path_updates` 中。次要文档和链接的修正，写在普通报告和修订摘要中；不要给这个字段加上额外用途，也不要另建登记表。
- 路径修正不是实质性修订。

## 拆分、合并与依赖

- 拆分和合并遵循 [文件 3：`docs/feature-list-revisions.json`](../../../../yaya/methodology/02-feature-list-schema.md#文件-3docsfeature-list-revisionsjson) 迁移表中的 `split` 和 `merge` 行：新 Feature 使用从未用过的 ID，范围可以独立测试；原来的条目保留为 `obsolete` 或 `obsolete_done`。已完成来源的描述、验收条件和历史映射保持不变。
- 把受影响的待执行和被阻塞的依赖改写为实际的替代前提，即使它们的 ID 更大。对被阻塞的工作，替换之后重新检查已记录的恢复条件；依赖有效但尚未完成时，恢复后的工作为 `pending`，但还不能开始。
- 修改进行中工作的范围或依赖之前，明确审查它。不要改写已完成的依赖历史。
- 在第 2 版修订记录中，把每次操作记进 `migrations`，把每次依赖修改记进 `dependency_changes`。检查迁移图和执行图中是否有环、未知 ID、自依赖和已废弃的前提。
- 新增、修订、拆分、合并和退役都是增量操作。绝不因为插入会打乱数字形式的执行顺序就重新生成整个计划。

## 下游回归

普通的下游验证，按 `yaya/methodology/08-test-traceability-and-evidence.md` 的 **测试影响评估**，分配给实现这次变化的 Feature。在该 Feature 的笔记中记录受影响的行为、已经覆盖它的测试或人工检查以及覆盖缺口，供 Stage 1 使用。保留测试的归属；笔记不能拒绝必须做的检查。只有存在单独的实现、修复或独立商定的交付物时，才另建 Feature；仅仅为了重新运行某个依赖 Feature 仍然有效的测试，不另建 Feature。

## 测试可追溯性更新

已完成 Feature 的验收条件和测试 ID 绝不原地改写；Product 演进时创建带新 ID 的新 Feature。测试登记表的退役字段、数据结构版本和校验规则定义在 methodology 02 的 [文件 4：`docs/test-registry.json`](../../../../yaya/methodology/02-feature-list-schema.md#文件-4docstest-registryjson)。

- **被取代的活动测试：** 阶段 2 展示准确的测试 ID 和它的退役关系。经阶段 3 明确确认后，设置 `status: retired` 并添加 `retirement` 对象。保留原来的 ID、来源映射、路径、用例和已完成的证据。禁止为了迎合旧历史而让错误的断言保持活动。
- **测试代码清理：** 把获批的测试代码清理和当前引用清理，记在负责它的新 Feature 或未完成 Feature 的 `notes` 中，写明准确的路径、方法和预定动作。实现交给 [feature-execute](../../feature-execute/SKILL.md)；在实际执行并验证之前，报告为待完成。不要删除历史上的 Feature 或测试登记表记录。
- **仍然有效的测试：** 仍然有效的回归测试和不变量测试保持 `active`；`feature-execute` 之后通过组件交集选中它们。
- **替代 ID：** 新 Feature 声明 `affected_components`，普通的新测试 ID 在 `feature-execute` 的 Stage 1 和 2 中确定。获批的退役需要替代 ID 时，现在就根据新的验收条件规划这些 ID，并以 `planned` 状态登记，需要时使用 `path: null`。这不授权实现，也不表示已经覆盖；替代 Feature 必须在完成之前启用并执行它们。
- **没有替代项就退役活动测试** 是被禁止的；新的删除 Feature 的约定负责验证被移除的行为。
- 保持 `docs/test-registry.json` 可被机器读取；它不是叙述式的修订日志。
