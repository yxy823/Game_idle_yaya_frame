---
name: feature-plan
description: 把当前已写成文档的 Product 交付范围拆成完整的 Feature。需要已有的 GDD 来源；已有计划直接复用，变化交给 feature-sync。
---

# 生成 Feature 列表

## 依据与输入

使用 `yaya/methodology/02-feature-list-schema.md` 中的 **逐个 Product 规划**、**拆分预览**、**拆分规则**、**需求覆盖核对**，以及索引、详情、修订记录和测试登记表（Registry）的约定。本 Skill 负责下面的规划步骤和组件合并，不另外维护一套数据结构。

请求的范围已有实现、但缺少 Feature 记录时，同时使用该规范中的 **接手已有实现**。在方案中复用实际的实现和测试；规划不会把被接纳的工作标为完成。

写入长期保存的文字之前，使用 `yaya/methodology/05-document-language.md`。从当前配置读取 `document_language`；保留已有的历史。长期写入之前，遵循 `AGENTS.md` 的 **Git 与提交** 中关于保留改动和提交的约定。

使用 [GDD 前提与职责](../../../yaya/methodology/01-product-doc-structure.md#gdd-前提与职责)。阅读下列来源：

- 当前 Product 已批准的交付文档；
- 它所采用的实际 GDD 主题；
- `docs/product.md`，用于确定边界、依赖和顺序。

当前交付文档缺失时，在已有授权范围内先使用 [product-author](../product-author/SKILL.md) 细化这个单元，再开始规划。查阅相关的术语、专业要求和项目规则。后续的 Product 保持为总览中的大纲，不为它们创建文档或 Feature。续接时，内容未变的已读材料直接复用。

遵循 `yaya/methodology/11-specialist-workflows.md` 的 **查找与映射来源**：通过实际链接和共享的适用范围，纳入适用的 GDD、UI、游戏表现、美术、音频、资源和本地化要求。

- 保留一个主要的 `source`。
- 可观察的要求及其来源写进具体的 AC；实现约束及其来源写进固定的 Feature 设计稿。
- 把每条相关要求映射到一个可观察的结果和一个验证动作，不写笼统的“符合 Bible”。
- 对游戏表现，只映射已采用的要求和已获授权的备选方案；允许一个任务覆盖多个组件，也允许一次表现支持多个任务。
- `meta.generated_from` 写出实际的来源位置；它不证明每个文件或后续 Product 都已经规划过。

| 已有产物 | 需要的上下文 |
| --- | --- |
| `docs/feature-list.json` | 完整的轻量索引：当前 Product、此前计划的覆盖范围、状态、ID 和前置条件 |
| `docs/features/<Feature ID>.json` | 选中的、作为前置的或可能冲突的 Feature 详情 |
| `docs/feature-list-revisions.json` | 已有的修订历史和锚点；按数据结构确定符合条件的首个基线 |
| `docs/test-registry.json` | 提出新增之前已有的组件和测试记录 |

已有的 Feature 记录无论为空还是已有内容，都可以接收当前 Product 的第一份计划。已经规划过的范围直接复用，它的变化交给 [feature-sync](../feature-sync/SKILL.md)。不要替换早先的计划。按权威数据结构，索引、修订记录和测试登记表都必须是创建器提供的文件；缺少任何一个，先按 `yaya/methodology/02-feature-list-schema.md` 的 **文件结构** 恢复，再规划：优先从 Git 恢复，不用初始内容覆盖已有的历史；无法恢复时报告缺失，不自行编造。报告缺失的当前 Product 来源或此前已写成文档的 Product 来源；未来的大纲本来就没有文件，不算不一致。

## 规划与写入

1. 根据实际来源和完成状态，确定当前 Product 及其已批准的范围：
   - 只在可运行的基础设施尚不存在时才建立它。
   - 对实际范围和前置顺序，使用 `yaya/methodology/01-product-doc-structure.md` 中的 **设计范围与边界**、已接受的架构约束和 `yaya/methodology/13-debug-console-and-validation.md` 的[界面的开发顺序](../../../yaya/methodology/13-debug-console-and-validation.md#界面的开发顺序)：新界面或使已有截图、验收失效的界面改动，拆成骨架、视觉决策、完整逻辑三个 Feature（不需要这个顺序的情况见同一节），拆法和 AC 写法按 `yaya/methodology/02-feature-list-schema.md` 的 [拆分规则](../../../yaya/methodology/02-feature-list-schema.md#拆分规则)。完整逻辑中只有读取视觉参数的部分依赖视觉决策，其余部分可以并行。
   - 规划视觉决策 Feature 时，如果 `docs/art/art-bible.md` 只有占位或零散的方向，或者外观、表现还没选定，在拆分预览中说明两种做法并请用户选：用户看描述就能决定的，先用 `design-art-direction` 定下方向；需要看画面比较的，在视觉决策 Feature 中列出要在调试台比较的候选维度（例如形状、配色、特效）。用户采纳的结果保存在调参资源中，所属文档链接它；依赖这些视觉参数的实现排在其后。
   - 同时检查 `docs/project-rules.md` 中约束本任务的工程规则。
   - 不要把一个存在冲突的 Product 拆成看似有效的计划；设计、规则或 Product 上的选择交给其已有的负责方解决。
   - 找出需要在 Stage 1 准备的实现决定：它们保存下来的局部推理写进固定的 Feature 设计稿，符合条件的跨 Feature 决定按 methodology 10 写进 ADR；不要按复杂程度选择位置，也不要创建空记录。
2. 按权威拆分规则，提出可以独立验证、一次会话能完成的结果，包括每项的结果检查和前置条件检查。以当前 Product 作为主要交付来源，在 AC 或设计稿中写出准确的 GDD/专业来源链接。在这份计划中覆盖它必要的全部范围；不要把类结构当作游戏设计写进去，也不要预先规划后续 Product。
3. 在对话中展示权威的 **拆分预览**：Feature 数量、每个 Feature 的摘要和依赖、为什么下一个是这个 Product，以及需求覆盖的对应关系。在写入任何测试登记表或 Feature 计划之前，执行其中关于确认和明确授权自主规划的规则；缺少实质性的决定时先解决。
4. 第 3 步允许写入后，按 `yaya/methodology/02-feature-list-schema.md` 的 **初始规划基线**，为符合条件的首份计划确定已提交的来源状态。然后在写入任何 Feature 计划之前，执行下面的测试登记表合并。只有合并通过校验、没有冲突时才继续。
5. 追加新的索引条目，并且只追加它们的详情文件，初始值按 `yaya/methodology/02-feature-list-schema.md` 的 **索引字段** 和 **详情字段** 填写。更新索引时间、拆分说明，以及 `meta.generated_from` 中实际新用到的 GDD 和专业来源位置。保留已有的 Feature、无关的元数据和修订历史。后续 Product 的规划不会推进同步锚点。合并成功后，不要手工改写测试登记表的数据。
6. 按下面「校验与语义审查」的顺序，依次完成语义覆盖审查、追加符合条件的 `V000` 和运行检查器。用实际的 ID 和剩余工作更新同一份方案，不另建报告文件。
7. 按 `yaya/methodology/09-records-reports-and-handoff.md` 的 **Progress** 更新 `docs/progress.md` 的当前状态和下一个允许的动作：写明这个 Product 已规划，下一步是第一个可以开始的 Feature；删掉“还没有 Feature 计划”这类已不成立的说法。因为换对话续接时先读 Progress，不更新就会被带回规划前的步骤。按 `AGENTS.md` **Git 与提交** 中 **暂存** 的要求暂存本任务负责的计划路径和 Progress，并创建本地提交 `chore(feature-plan): <行为摘要>`（摘要语言跟随 `document_language`）。这次提交是在创建计划，所以省略 `Work item`。开始时已有改动的，不要暂存整个 `docs/features/` 路径。
8. 报告结果，以及这个 Product 中第一个可以开始的 Feature。已获授权的实现使用 [feature-execute](../feature-execute/SKILL.md)；规划成功不授予后续 Product 的范围。完成后返回调用方；Skill 返回不会结束它所服务的已授权任务（methodology 03 **授权与续接**）。

## 测试登记表：`docs/test-registry.json`

这是合并辅助工具、检查器、测试选择器和完成检查共同使用的固定项目相对路径。不要添加可配置的路径，也不要在 Feature 索引的元数据中重复它。从项目根目录运行合并命令。

按 `yaya/methodology/02-feature-list-schema.md`，使用项目自带的第 4 版测试登记表和第 2 版修订记录。

写入任何 Feature 计划之前，先读取并校验测试登记表。保留每个已有的组件对象、测试 ID、测试映射、状态、路径/用例和 `full_suite_on_change` 值。为另一个 Product 添加 Feature 时，绝不能把 `tests` 重置为空数组，也不能删除独立的不变量。

为每个尚未登记的生成 `affected_components` ID 创建一条候选组件条目：

- 没有单元测试套件时，把 `unit_test_paths` 设为 `[]`。
- `source_paths` 写该组件认领的文件，是非空的 glob 列表，例如 `["game/inventory/**"]`；按 Product 规划的实现位置填写。
- 路径要求、登记时机和 Required Test Set 的纳入，按 `yaya/methodology/08-test-traceability-and-evidence.md` 的 **登记表规则** 处理。
- 新组件的 `full_suite_on_change` 设为 `false`，除非 Product 或项目规则明确把它定为横跨多处的组件。
- 生成的组件 ID 已经存在时，复用它完整的已有记录；只需要认领新目录时，候选沿用已有记录的其他字段，只在 `source_paths` 中加上新目录，合并时取并集。如果规划的约定要求不同的单元套件路径或不同的全量测试标记，把它作为冲突报告，不要覆盖。

从仓库根目录使用项目自带的合并辅助工具。临时候选文件包含一个由完整组件对象组成的 JSON 数组，或者一个带 `components` 数组的对象；它放在 `reports/scratch/<task>/`（见 methodology 09 的 **报告与清理**），不提交。

```powershell
python -B yaya/tools/features/merge-test-registry.py `
  --components <temporary-component-candidates.json>
```

辅助工具要求同目录下有 Feature 索引和修订记录。写入之前，它会校验：

- 数据结构版本；
- 组件记录；
- 仓库边界，以及当前测试路径是否存在；
- 组件 ID 和测试 ID 是否唯一；
- 测试到组件的映射。

路径的含义遵循 methodology 08 的 [登记表规则](../../../yaya/methodology/08-test-traceability-and-evidence.md#登记表规则)，历史记录的含义遵循 `yaya/methodology/02-feature-list-schema.md` 的 **文件 4**。已退役的条目还必须按共享的 `yaya/tools/lib/feature_evolution.py` 约定，具有有效的来源、原因、替代项和修订关系。

下列情况是阻塞性冲突：

- 已有测试登记表格式错误；
- 当前测试路径无效或不存在；
- ID 重复；
- 缺少组件映射；
- 已有组件的候选内容与现有记录在 `source_paths` 之外不完全相同。

只有完整的合并通过校验后，工具才会写入，并按原值保留所有已有的测试条目。路径存在不能证明测试能被发现；执行时必须确认登记的套件确实运行了测试。

候选文件示例：

```json
{
  "components": [
    {
      "id": "inventory",
      "unit_test_paths": [],
      "full_suite_on_change": false,
      "source_paths": ["game/inventory/**"]
    }
  ]
}
```

## 校验与语义审查

所有相关文件一致之后，按下面的顺序完成：

1. **语义覆盖审查**：检查器确定不了的内容，由 Agent 审查下面列出的各项。
2. **追加初始基线**：符合 `yaya/methodology/02-feature-list-schema.md` 的 **初始规划基线** 条件时，按该节第 3 步追加 `V000`；不符合时跳过。
3. **运行检查器**：`python -B yaya/tools/checks/check-feature-list.py`。它会同时检查 JSON 解析和跨文件的不变量。只有在诊断某一个错误时，才单独做语法检查。

语义覆盖审查的内容：

- 选中的 Product 是当前的、尚未规划的；它要求的范围已经覆盖，没有重复的基础设施、被排除的行为或过早的后续计划。
- 写入的 Feature 数量、边界和依赖，与已确认的预览一致；在明确的自主规划授权下，与最新的预览一致。
- 来源写出了实际的需求小节；依赖反映了真实的前置条件和适用的架构约束。
- 新记录使用数据结构的初始规划值。实际差异保留了之前的 Feature、修订锚点、测试登记表记录和独立的不变量；例外只有已批准的组件新增和符合条件的首个基线。核对它的来源提交和覆盖范围；缺少历史的已有计划不是全新的空 Feature 记录。

校验失败或存在实质性的语义缺口时，先解决，再报告完成。
