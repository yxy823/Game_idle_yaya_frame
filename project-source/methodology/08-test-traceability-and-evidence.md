# 08 · 测试追溯与证据

> 本文决定一项修改需要哪些测试、为什么选它们，以及它们的结果怎样算作完成证据。怎样编写 Godot 测试见 [yaya/agent-rules/70-tests](../agent-rules/70-tests/README.md)；gdUnit 运行器的实现细节见 [gdunit4-profile.md](../agent-rules/70-tests/gdunit4-profile.md)。

## 目标

项目增长时，测试层必须能确定地回答四个问题：

1. 哪些测试验证当前 Feature 的验收条件？
2. 哪些已有的单元套件保护 Feature 改动的组件？
3. 哪些历史 Bug 的回归测试必须重跑？
4. 需要哪些跨 Feature 的不变量检查和全量套件检查？

Agent 从 Feature 记录和测试登记表（Registry）推导这些答案，不凭记忆或直觉。

## 测试分类

物理目录按测试保护的对象划分：

```text
tests/
├── unit/        # 局部代码或组件契约
├── features/    # Product Feature 与验收行为
└── invariants/  # 跨 Feature 的架构与领域规则
```

`regression` 说明测试的来历，不是第四个目录。回归测试放在它所保护的那一层，通常是 `features/F0XX/`，偶尔是 `unit/<component>/`。

调试台自身的测试是唯一的例外，放在 `dev/debug/` 下：共享代码的测试在 `dev/debug/_shared/tests/`，本项目调试对象的测试在 `dev/debug/<对象>/tests/`。因为 `tests/` 下的测试不依赖 `dev/`，调试台测试不能放进 `tests/`；依赖方向测试检查的是游戏，所以留在 `tests/invariants/`。全量运行同时选择 `tests/` 和 `dev/debug/`，见[运行时的测试影响选择](#运行时的测试影响选择)。

逻辑 ID 说明一个已登记的测试为什么存在：

- `F012-AC01` 或 `F012-AC01-02`：Feature F012 条件 AC01 的自动验收验证。
- `F052-RT01`：Bug 修复 Feature F052 创建的回归测试。
- `INV-LIFECYCLE-01`：跨 Feature 的不变量测试。

普通的底层单元测试不需要逻辑 ID，除非它同时作为验收、回归或不变量证据。

回归测试证明一个具体缺陷不会再出现；不变量测试证明一条概括后的跨 Feature 规则。Bug 的 Guardrail 怎样成为不变量，见 [Bug 经验的提升](07-engineering-change.md#bug-经验的提升)。

## Feature 的可追溯性

Feature 详情使用稳定的验收条件 ID：

```json
{
  "id": "F012",
  "affected_components": ["save", "scene_lifecycle"],
  "acceptance_criteria": [
    {
      "id": "AC01",
      "text": "玩家可以保存并重新载入当前进度。",
      "verification": {
        "automated_tests": ["F012-AC01"],
        "manual_checks": ["在运行中的游戏里保存、重新载入，确认可见状态一致。"]
      }
    }
  ],
  "verification": {
    "acceptance_mode": "manual",
    "regression_tests": [],
    "manual_regression": null,
    "test_impact": {"additional_tests": [], "full_suite_reasons": []}
  }
}
```

`ACxx` ID 是稳定的历史标识。不要因为 Product 需求后来演变，就给已接受的条件重新编号。之后的变化创建新的 Feature，而不是改写已完成 Feature 的历史。

`affected_components` 是一小组稳定的领域或组件 ID，例如 `inventory`、`save`、`combat` 或 `scene_lifecycle`。使用语义组件，不用单个文件路径。

## `docs/test-registry.json`

测试登记表固定位于 `docs/test-registry.json`，把被改动的组件映射到保护它们的测试。本文是它的规则的唯一正文；Skill 和其他 methodology 文档链接到这里。

```json
{
  "meta": {
    "schema_version": 3
  },
  "components": [
    {
      "id": "inventory",
      "unit_test_paths": ["tests/unit/inventory"],
      "full_suite_on_change": false
    },
    {
      "id": "scene_lifecycle",
      "unit_test_paths": ["tests/unit/scene_lifecycle"],
      "full_suite_on_change": true
    }
  ],
  "tests": [
    {
      "id": "F052-RT01",
      "components": ["inventory", "scene_lifecycle"],
      "path": "tests/features/F052/scene_transition_regression_test.gd",
      "case": "test_f052_rt01_reopen_inventory_after_scene_change",
      "status": "active"
    },
    {
      "id": "INV-LIFECYCLE-01",
      "components": ["scene_lifecycle"],
      "path": "tests/invariants/lifecycle/stale_node_reference_test.gd",
      "case": "test_inv_lifecycle_01_stale_node_reference_is_not_reused",
      "status": "active"
    }
  ]
}
```

### 登记表规则

- 组件 ID 是稳定的 `lower_snake_case` 标识。
- `unit_test_paths` 列出保护该组件的单元套件文件或目录，使用相对仓库根目录的路径。只要该组件受影响，这些套件就必须运行。上面非空的示例假定这些套件已经存在。
- 没有单元套件的组件写 `unit_test_paths: []`。绝不预填将来的目录。在 Stage 1 提出新的单元套件，在已批准的 Stage 3 创建后登记其路径，并把它们纳入 Required Test Set。
- 已登记的套件路径缺失或被删除，属于登记表错误，不是一张空的安全网。不要静默过滤它。删除一条登记需要明确的理由和用户批准。合并与严格校验会检查路径存在；只有实际运行才能证明测试被发现和执行（见[什么情况下运行失败](#什么情况下运行失败)）。
- `full_suite_on_change: true` 表示任何触及该组件的 Feature 在完成前都必须运行全量套件。
- 唯一的逻辑 ID 决定测试身份：
  - `F0XX-ACyy` 或 `F0XX-ACyy-NN`：该 Feature 该条件的验收测试；
  - `F0XX-RTyy`：该 Feature 的回归测试；
  - `INV-<DOMAIN>-NN`：不属于任何 Feature 或条件的不变量。`DOMAIN` 以大写字母或数字开头，由大写字母、数字、下划线或连字符组成。
- 不另存 `kind`、`source_feature` 或 `criterion_id` 字段。
- `status` 取 `planned`、`active` 或 `retired`。
- `planned` 让 `tests` 中的条目可以在测试文件存在之前就为 TDD 登记。它不适用于 `unit_test_paths`。
- 正在完成的 Feature 只能引用 `active` 且可解析的自动测试。已完成的 Feature 可以保留对 retired 测试的映射，只要它们能按 schema 的替代契约追溯。
- retired 测试保留它的 ID，并记录原因、Product 变更来源或修订，以及替代的 Feature 或测试。它不进入活动的安全网。严格校验会检查这条替代链；完成检查仍要求当前 Feature 有 active 的直接验证。
- 移动测试文件时更新 `path`；逻辑测试 ID 保持不变。

### 调试台组件

新项目的测试登记表预置组件 `debug_console`，本节是它的唯一定义：

- **覆盖范围**：调试入口 `dev/debug/debug_main.*`、项目挂钩 `dev/debug/debug_project.gd`、共享代码 `dev/debug/_shared/`，以及本项目的调试对象 `dev/debug/<对象>/`。游戏中的调参资源属于各自的游戏组件，不属于它。
- **登记的测试**：`unit_test_paths` 为 `["dev/debug/_shared/tests"]`；项目新增调试对象的专有测试时，把 `dev/debug/<对象>/tests` 加进同一列表。依赖方向测试登记为 active 不变量 `INV-DEBUG_CONSOLE-01`（`tests/invariants/debug_dependency_test.gd`），组件为 `debug_console`。
- **何时出现在 `affected_components`**：Feature 修改上面覆盖范围内的文件时，包括登记新的插槽、候选或固定局面；新建调参资源或新增调参字段时也写上，因为同时要在对应的 `slot.gd` 补中文名（见[调参资源](../agent-rules/21-resources/roles-sharing-and-locality.md#调参资源)），共享测试会检查。调试台本身的修改按[调试台的修改](07-engineering-change.md#调试台的修改)建维护 Feature。
- 只改游戏代码、不新建调参资源或字段时，依赖方向测试由测试选择规则中的[扩大验证的 Godot 改动](../agent-rules/70-tests/test-selection-and-gates.md#扩大验证的-godot-改动)作为附加测试加入，不必把 `debug_console` 写进 `affected_components`。

## 测试影响评估

`feature-execute` 在 Stage 1、实现之前做测试影响评估。Required Test Set 是：

```text
Required Test Set =
    当前 Feature 的验收测试
  + 当前 Feature 的回归测试
  + affected_components 的 unit_test_paths
  + 组件与 affected_components 相交的 active 回归测试
  + 组件与 affected_components 相交的 active 不变量测试
  + verification.test_impact 中已批准的附加测试
```

受影响组件的每个已登记套件都进入 Required Test Set。空的 `unit_test_paths` 数组不增加单元选择器。

affected 集合是 Required Test Set 加上受影响组件的 active 验收测试。

- 依赖或 API 分析显示有实质影响时，Agent 可以加入其他组件的相关测试，并记录确切原因。
- Agent 不能删除上面推导出的任何要求。已批准的退役改变的是 Product 或测试登记表的契约，绝不会变成运行器的排除项。
- [test-selection-and-gates.md](../agent-rules/70-tests/test-selection-and-gates.md) 中的 Godot 影响条件可以扩大验证范围，例如加入全新进程启动或重新导入检查。把这些补充写进 Stage 1 的验证计划。不是 gdUnit 运行的检查与结果一起报告，不写进 `full_suite_reasons`。

一般的下游回归属于实施这项变更的 Feature。把受影响的行为和覆盖缺口从它的 notes 带进 Stage 1，用组件选择或已批准的附加测试处理，不改变它们的归属。重跑仍然有效的测试不需要另一个 Feature。单独的实现、修复或另行商定的交付物，才可能需要另建 Feature。

满足下列任一条件时，必须运行全量套件：

- 某个受影响的登记表组件设置了 `full_suite_on_change: true`；
- 基础设施或工具链的修改确实对项目产生广泛影响（只有维护标签不算）；
- 依赖或工具链的升级可能影响广泛的行为；
- 影响分析无法可靠地界定受影响的组件；
- 用户明确要求。

`test-selection-and-gates.md` 中的全量触发条件同样适用；把它们记为 `full_suite_reasons`。对其他局部 Feature，除非项目规则另有规定，在适用的验收之前做针对性验证就够了。

## 运行时的测试影响选择

运行器通过 `yaya/tools/lib/test_selection.py` 读取当前 Feature 和测试登记表。没有单独的计划命令、计划文件或计划哈希。

Stage 1 获批后，Stage 2 把额外的义务保存在 Feature 的 `verification.test_impact` 中：

- `additional_tests: [{id, reason}]`
- `full_suite_reasons: [reason]`

运行器始终包含这些义务。影响分析和补充由 Agent 判断；脚本只把记录下来的映射转换为选择结果。

从项目根目录用配置的 Python 解释器运行：

```text
python -B yaya/tools/testing/run-gdunit-tests.py --feature F0XX --scope auto
```

运行器使用 `docs/methodology-config.json` 中的 Godot 路径。`--godot-binary <path>` 是可选的单次覆盖。

| 选项 | 含义 |
| --- | --- |
| `--scope auto`（默认） | 运行包含 Required 的 affected 集合；需要全量时升级为一次 full 运行。 |
| `--scope required`、`affected`、`full` | 用于迭代的显式范围。`full` 递归选择 `tests/`，项目有 `dev/debug/` 时同时选择它；空的分层目录不增加义务。 |
| `--phase baseline` | 排除尚不存在的 planned 测试。baseline 运行从不授权完成。 |
| `--target <path>` | 聚焦诊断或 TDD 诊断。它从不产生完成证据。 |

输出列出选择理由、去重后的选择器和任何全量理由。最终选择会拒绝无法解析或已 retired 的直接映射，以及缺失的路径。

运行器执行去重后的套件和目录选择器，所以选中一个套件可能顺带运行额外的用例。用例级的义务按实际运行的用例核对。发现、JUnit 用例和诊断怎样匹配，见 [gdunit4-profile.md](../agent-rules/70-tests/gdunit4-profile.md)。

### 什么情况下运行失败

出现下列任一情况时，运行失败，绝不算作 PASS：

- 选中的路径或已登记的套件路径缺失或无效；
- 选中的路径、定点运行或全量运行发现的测试数为零；
- 必需的用例或套件缺失或被跳过，或最终的自动映射没有实现；
- 发现的用例（包括展开后的每个参数化用例）与实际执行的 JUnit 用例不完全一致；
- 测试源码中声明的套件没有被发现；
- 出现运行时诊断、超时或运行器故障。

这份清单是这些失败情况的唯一说明；其他文档链接到这里。

源码声明只用来发现遗漏的套件，从不证明执行。声明扫描通过直接继承、仓库脚本路径和项目的 `class_name` 基类来解析 `GdUnitTestSuite` 的继承关系。套件之外名为 `test_*` 的辅助方法不算义务；无法解析的基类表达式会导致失败，而不是静默丢掉一个套件。

同一快照上一次成功的全量运行满足 Required 和 affected 集合，不需要重跑它们。必需的全量升级没有成功的全量结果时，保持阻塞。人工验收清单或手工填写的 `approved_unavailable` 标签都不能把它变成自动 PASS。

## 基于原始结果的完成判断与语义时效

### 没有自动义务：`not_required`

最终验证时，只有在 `manual` 验收计划有效、Required 和 affected 集合都为空、且没有全量义务时，运行器才返回 `not_required`。

- 正常调用运行器。它检查当前计划和同一快照上尚未解决的失败，然后以退出码 0 结束，在 stdout 输出 JSON 状态。它不启动 Godot，不读取引擎配置，也不创建运行报告。
- 这种结果不调用 `record-tests`。记录实际的人工验收时会创建完成证据，其中 `test_runs: []`。适用的静态检查仍然必需。
- baseline 选择也可能为空，因为新的 planned 测试还不存在。
- 显式的 `--scope full` 或 `--require-test` 仍然要求真实运行，[什么情况下运行失败](#什么情况下运行失败)中的失败条件仍然适用。
- `not_required` 从不清除之前失败或未完成的最终运行。

### 运行记录

每次 Feature 调用创建一个 `reports/gdunit-wrapper/<Feature-ID>/run-<id>/` 目录；聚焦运行使用 `reports/gdunit-wrapper/focused/run-<id>/`。运行器在准备之前写一个 `result.json`（schema 1），执行后在同一个文件里写入最终结果。它记录 Feature、phase、scope、选中的路径、真实命令、源码指纹、进程结果和错误，以及原始报告的引用和哈希。用例身份和总数需要时从原始报告读取，不复制进更多摘要。文件布局和发现检查见 [gdunit4-profile.md](../agent-rules/70-tests/gdunit4-profile.md)。

完成判断只读取当前 Feature 的运行目录：

- 该目录中被引用的结果损坏，或历史无效（包括 Feature ID 不匹配），都会阻塞完成。在授权范围内调查并解决损坏；一次新的通过运行不能抹掉它。
- 更早的历史无效时，在 stderr 输出警告并给出受影响的路径。保留原件，允许新的运行；这个警告不决定当前运行的结果。
- 读取快照出错时，当前结果记为失败，且不启动 Godot。文件系统写入失败按写入失败报告，绝不报告为已保存的结果。
- 不读取其他 Feature 的目录和聚焦运行。

各次尝试按每个 Feature 的序号排序，序号根据可读且头部有效的结果计算，不依据文件时间戳。序号相同的尝试不能清除另一次尝试。

- 对同一个 Feature 和同一份内容，未解决的最终失败不能被更早的成功或之后范围更窄的运行掩盖。
- 恢复需要一次之后的、覆盖失败范围的成功运行。保留原来的失败，并诊断其原因。
- 没有命令、选择器或进程的 `auto` 准备记录尚未选定范围。用之后的一次 affected 运行恢复它；同一快照的义务要求全量时，用 full 运行恢复。这不放宽从实际 full 失败中恢复的要求，也不接受不一致的 `auto` 记录。
- baseline 和聚焦运行从不授予最终完成。

没有单独的日志、执行锁、调用记录、判定文件、过程报告或会话收据。

### 记录结果

```powershell
python -B yaya/tools/features/record-feature-completion.py record-tests --feature F0XX --run reports/gdunit-wrapper/F0XX/run-<id>/result.json
```

- 只有覆盖义务需要多次不同的运行时，才重复 `--run`。一次全量运行就覆盖 Required 和 affected。
- 辅助工具根据当前 Feature、测试登记表和原始报告计算覆盖。调用方提供的通过标签或总数不能产生 PASS。
- 导入失败会清除之前的引用。
- 完成证据（格式见 [文件 5：`docs/features/F0XX-evidence.json`](02-feature-list-schema.md#文件-5docsfeaturesf0xx-evidencejson)）保存测试引用和实际的人工验收。它不保存审核计数、Required/affected/full 的总数，也不缓存关卡状态。
- 解析和 lint 结果由 Agent 直接评估。

哈希、与当前源码的绑定和运行身份，用来发现意外的过时复用或被改动的文件。这些可在本地编辑的记录不是防止有人改写全部证据的安全签名。文件修改时间和时钟精度从不授权完成。不要为了得到绿色结果而加 sleep，或重跑没有变化的失败。

### 内容指纹

`working_tree_fingerprint` v2 对已跟踪且未被忽略的源内容计算哈希。证据只对它生成时所针对的指纹有效。

包含：

- GDD、Product、规则、测试、运行器和配置；
- Feature 与测试登记表中的语义数据：AC 文本、验证（包括已批准的测试影响）、受影响组件，以及登记表的选择器、状态和退役信息；
- `docs/gdd/`、`docs/terminology.md`、`docs/project-rules.md`、专业规范、表现文档（包括已采纳的备选方案和资源小节）、Feature 设计 Markdown，以及架构和 ADR 文档；
- 修订记录中的迁移关系、修订 ID 和来源锚点，以及嵌套的测试状态；
- 新增或未知的契约字段；
- `docs/knowledge/` 和 `docs/research/` 下的非 Markdown 文件；
- 下面未排除的其他所有 Markdown 文件。

排除：

- Feature 顶层的过程字段：`status`、时间戳和 `notes`；
- Progress 的 Markdown 和当前历史；
- `docs/knowledge/` 和 `docs/research/` 下的说明性 Markdown；
- 修订记录条目的时间戳、摘要和 notes；
- 运行产物和报告；
- 调试台运行时保存的插槽预设（`dev/debug/*/slots/**/presets/`）、组合（`dev/debug/*/combos/`）和待收尾记录 `dev/debug/adoption-log.md`；`dev/debug/adoption-queue/` 中排队的采纳仍参与指纹，因为排队的移动之后会改写游戏文件；
- 普通的 `README.md` 文件（不区分大小写），但 `.agents/`、`yaya/agent-rules/`、`yaya/methodology/`、`docs/gdd/`、`docs/product/` 和 `docs/features/` 下的除外，因为它们保存的是说明或约束性契约。

由此可知：

- 知识和调研是参考材料，从不保存可执行的输入、需求、规则或验证契约。
- 把较长的设计从 JSON `notes` 移到 Markdown，不会让这份 Markdown 获得 notes 的豁免。
- 把 README 移进上面列出的目录会改变指纹。实质性的 GDD 入口可以命名为 `README.md`，它仍是约束性来源。需求和验证规则保存在各自的权威文件里，不放在使用说明 README 中。
- 指纹是全局的，不按 Feature 的引用过滤。即使不需要修改 Feature 计划，编辑性措辞、将来的 GDD 章节、资源状态或位置的修改，也可能让当前证据失效。在最终验证之前的 Stage 3 检查点定稿这些文档；之后的修改按正常的时效规则处理。
- 移动 Progress 正文，或整理知识与调研的 Markdown，从不让测试失效。文档修改仍要核对其中的事实、链接和示例，但不需要重跑业务测试。
- 已完成的 Feature 记录不会被自动重新打开。

Git 状态：

- 项目创建时提供初始提交。验证需要一个有效的当前提交；Git 状态缺失或损坏会导致失败。
- 指纹也覆盖已暂存的文件和未被忽略的未跟踪文件。删除或重命名一个被包含的文件会改变内容身份；已经缺失但仍在 Git 索引中的路径不贡献任何内容。之后暂存或提交这次删除或重命名，指纹保持不变。
- Git 修订是来源信息。语义内容相同的提交让运行证据保持有效，但不能补上缺少的测试、就绪状态、人工验收或审核。

已批准的验收模式为 manual 时，人工验收是绑定到自身快照的独立证据。验收之后的语义或源码变化必须重新验收。运行记录按[报告与清理](09-records-reports-and-handoff.md#报告与清理)处理：失败的运行保留以供诊断，当前完成检查或验收引用的证据要保留。

### 补充证据

性能、长时间运行和其他专业证据按 [定稿与证据](11-specialist-workflows.md#定稿与证据) 处理。运行证据的导入只支持实际的 gdUnit 结果。其他测量、显示或试听义务保留在各自的 AC 和设计验证计划中，由所属任务和任何被要求的独立审核评估。不要伪造 gdUnit 运行证据，也不要用补充结果豁免必需的测试。

## TDD 执行约定

Feature 有自动义务时，正常的 Feature 流程是：

```text
测试影响评估
        ↓
Stage 1 明确的人工批准
        ↓
运行已有安全网的 baseline
        ↓
编写并登记新的验收测试或回归测试
        ↓
RED：证明新测试因预期中缺失或损坏的行为而失败
        ↓
实施最小的、自洽的修改
        ↓
GREEN：新测试通过
        ↓
必要的局部重构 + 重跑相关测试；对下一个行为重复这个循环
        ↓
Stage 3 文档检查点
        ↓
运行最终的 affected 或必要的 full 范围 + 静态检查
        ↓
Stage 5 明确的人工验收（只用于已批准的 manual 模式）
        ↓
Stage 6 独立审核（只在被要求时）
        ↓
完成检查
```

对于正式记录之前就已实现的行为，按 [已有实现的交付](03-execute-loop.md#已有实现的交付) 把现在的验证与已经无法产生的 baseline 和 RED 证据分开。新的行为变化和修复按上面的流程进行。

实现之前就已存在的 baseline 失败要报告。不要把它归到当前 Feature，也不要作为范围扩大而悄悄修复。

RED、GREEN 和重构按每一个小的可观察行为进行，而不是先写完全部测试、再做全部实现。一个条件可能需要多个循环。测试聚焦可观察的契约；有实质意义的重构之后重跑相关测试。聚焦和 TDD 的结果从不代替最终的 affected 或 full 证据。

完成证据由下列命令检查，其余由 Agent 评估：

- 有自动义务时，Stage 4 把核实过的运行结果导入该 Feature 的 `docs/features/F0XX-evidence.json`。需要人工验收时，Stage 5 记录清单中实际的人工结论。
- `yaya/tools/features/record-feature-completion.py validate --feature F0XX` 检查这份证据。
- `yaya/tools/checks/check-feature-list.py --completion-feature F0XX` 检查完成时专有的 Feature 和测试登记表契约。
- 解析和 lint 输出，以及用户明确提出的任何审核条件，由 Agent 按[Stage 0–8 `feature-execute` 执行循环](03-execute-loop.md)评估。证据辅助工具不能证明静态检查或审核已经运行，也不能代替必需的人工决定。

[Stage 6 · 可选的独立审核](03-execute-loop.md#stage-6--可选的独立审核)中被要求的审核，在源码和验证都没有变化时，复用当前成功的运行结果。修复改变了快照时，重新计算当前义务，重复适用的 Stage 4 验证（包括[没有自动义务：`not_required`](#没有自动义务not_required)的情况），然后重新进行受影响的验收。一次成功的全量运行覆盖 Required 和 affected；不要只为填第二个字段而再跑一次 Required。

Stage 1 先按 [验收模式](02-feature-list-schema.md#验收模式) 选择 `verification.acceptance_mode`，再填写对应的检查。

- automated 模式跳过 Stage 5，不记录虚假的人工验收。manual 模式需要用户实际提交文件，或在对话中给出明确决定，见[人工验收文件](contracts/manual-acceptance-files.md)。

## 需求变化与过时的测试

GDD 设计、Product 交付范围或专业要求变化时，之前的测试不会自动保持权威。`feature-sync` 在源同步报告中评估受影响的测试。之后由实施这项变化的 Feature 在其 Stage 1 做测试影响评估。结果分为：

- 契约仍然有效 → 测试保持 active；
- 契约已改变 → 通过新的 Feature 创建或更新验证；
- 契约已被取代 → 有意识地让过时的测试退役；
- 新行为 → 新增验收测试 ID；
- Bug 修复 → 新增回归覆盖，除非确定性的自动化不可行。

登记表中的退役不会删除可执行的测试：gdUnit 会发现选中套件和目录路径下的每个方法，包括仍留在这些文件里的 retired 用例。除了登记表，还要阅读受影响的测试代码；普通单元测试可能没有逻辑 ID。源同步报告指出过时的断言、方法和文件、受影响的当前引用，以及所属的 Feature。获批后，把需要的清理动作记进该 Feature 的 `notes`。规划阶段不编辑测试代码，也不声称清理已经完成。

在该 Feature 已批准的实现期间：

- 删除或替换被取代的断言；
- 更新受影响的 active 映射、`unit_test_paths`，以及当前的需求引用和用法引用；
- 在已批准的范围内删除过时的空套件及其登记；
- 保留共用这些文件、仍然有效的用例，保留不受影响的回归和不变量测试；
- 保留 retired 的登记表记录及其 ID、来源、路径、用例和来历。已完成的 Feature 记录和之前的证据不是清理对象。

用正常的验证和作者自检检查最终差异、受影响的引用、当前的发现结果和原始结果。必需的清理没有完成，就说明修改没有完成；只有 `retired` 标签或一条 TODO 不够。待办工作保留在所属 Feature 的 notes 或当前 Progress 中，交接时报告实际完成的清理和剩余工作。无关的清理不在范围内。不需要单独的清理记录文件、检查器或无条件的全量运行。

绝不只为了满足一个 Product 或 Feature 契约已被取代的测试而修改实现。

## 运行器的边界

[项目环境准备](06-project-environment.md#项目环境准备)通过检查之后，固定的运行器从 `docs/methodology-config.json` 读取 Godot 可执行文件，并根据 Feature 和测试登记表选择测试。GdUnit 的发现机制、参数、JUnit 身份和会话诊断构成这套实现。证据导入会校验实际的 gdUnit 报告。没有可配置的适配器，也没有测试根目录或命令的第二份副本。

gdUnit4 插件位于 `addons/gdUnit4/`，项目测试放在 `tests/unit`、`tests/features` 和 `tests/invariants` 这几个根目录下，调试台测试放在 `dev/debug/` 下。这套分类是项目约定，不是 gdUnit4 对目录的要求。
