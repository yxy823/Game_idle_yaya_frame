# 02 · Feature 列表与测试追溯结构

## 按任务阅读

本文按记录文件和规划规则分节，按当前任务只读需要的小节：

| 当前任务 | 阅读 |
| --- | --- |
| 规划一个 Product 的 Feature | [逐个 Product 规划](#逐个-product-规划)、[拆分预览](#拆分预览)、[拆分规则](#拆分规则)、[需求覆盖核对](#需求覆盖核对)，以及要写入的[索引](#文件-1docsfeature-listjson)、[详情](#文件-2docsfeaturesf0xxjson)和[测试登记表](#文件-4docstest-registryjson) |
| 写第一份计划的基线 | [初始规划基线](#初始规划基线) |
| 源同步 | [同步记录](#同步记录)、[状态流转](#状态流转)、[已退役的测试](#已退役的测试) |
| 执行 Feature 时查字段 | [详情字段](#详情字段)、[验收模式](#验收模式)、[Feature 设计与实现说明](#feature-设计与实现说明)、[完成证据](#文件-5docsfeaturesf0xx-evidencejson) |
| 接手已有实现 | [接手已有实现](#接手已有实现) |
| 工具报错 | [机器校验的不变量](#机器校验的不变量) |

## 文件结构

```text
docs/
├── feature-list.json
├── features/
│   ├── F001.json
│   ├── F001-design.md       # Optional detailed design for this Feature
│   ├── F001-evidence.json   # Completion evidence, created by the recording tool
│   ├── F002.json
│   └── ...
├── feature-list-revisions.json
└── test-registry.json
```

这些 JSON 文件统一使用项目工具写出的格式：两空格缩进、数组元素各占一行、保留中文原文、文件末尾一个换行。手工编辑时保持这个格式，这样工具写回时不会产生格式差异。

Feature 索引保持轻量。每个 Feature 的详情文件保存：

- 该 Feature 的行为；
- 稳定的验收条件（AC）ID；
- 组件影响；
- 验证映射；
- 工程分类；
- 备注。

`docs/test-registry.json` 是测试登记表（Registry），供机器读取，把组件映射到可复用的测试。给人读的值使用 `document_language`；机器协议字段保持不变。

项目创建时会提供索引、修订日志和测试登记表，三者都是空数组。即使还没规划第一个 Feature，这三个文件也必须存在。缺少某个文件属于需要修复的问题；不要用重新初始化的空 Feature 记录代替丢失的记录。

## 文件 1：`docs/feature-list.json`

```json
{
  "meta": {
    "generated_from": [
      "docs/gdd/**/*.md",
      "docs/product.md",
      "docs/product/**/*.md",
      "docs/project-rules.md"
    ],
    "generated_at": "2026-05-23T05:46:48Z",
    "notes": "Decompose in dependency order and keep each Feature independently verifiable."
  },
  "features": [
    {
      "id": "F001",
      "title": "Create the project shell and open an empty main window",
      "status": "done",
      "depends_on": [],
      "estimated_scope": "small",
      "completed_at": "2026-05-16T10:30:00Z"
    },
    {
      "id": "F002",
      "title": "Show the first interactive Product behavior",
      "status": "pending",
      "depends_on": ["F001"],
      "estimated_scope": "medium",
      "completed_at": null
    }
  ]
}
```

### 索引字段

| 字段 | 要求 |
| --- | --- |
| `id` | 必须是 `F` 加三位数字。索引从 `F001` 起按顺序列出 ID，中间不留空缺。ID 永不复用。 |
| `title` | 非空、可读的动词短语。 |
| `status` | `pending`、`in_progress`、`done`、`obsolete`、`obsolete_done` 或 `blocked`。 |
| `depends_on` | 已存在 Feature 的 ID，不重复，不含该 Feature 自身。前置 Feature 的 ID 可以更大。依赖图不能有环。 |
| `estimated_scope` | `small` 或 `medium`。更大的工作要在写定计划前继续拆分；校验器拒绝 `large`。 |
| `completed_at` | 状态为 `done` 或 `obsolete_done` 时，填有效的 ISO 8601 时间戳；其他状态填 `null`。 |

Feature 数量从 `features` 数组计算。详情文件、修订日志和测试登记表使用[文件结构](#文件结构)中的固定路径；索引的元数据不再重复这些路径。

Feature ID 记录的是分配顺序，不是执行顺序：

- 一个 `pending` Feature 的全部前置 Feature 都是 `done` 时，它才可以开始。多个 Feature 都可开始时，ID 顺序只用于在其他条件相同时排定先后。
- `python -B yaya/tools/checks/check-feature-list.py --eligible` 会校验 Feature 记录，并以 JSON 输出可开始的 Feature 集合。
- `pending`、`in_progress` 或 `blocked` 的 Feature 不能依赖 `obsolete` 或 `obsolete_done` 的 Feature。源同步会把它改接到替代 Feature 上。
- 已完成 Feature 的依赖作为历史保持不变。

## 文件 2：`docs/features/F0XX.json`

来自 Product 的 Feature：

```json
{
  "id": "F042",
  "description": "The player can place a wooden-wall blueprint and complete construction so the finished wall blocks pathfinding.",
  "affected_components": ["building", "pathfinding"],
  "acceptance_criteria": [
    {
      "id": "AC01",
      "text": "Selecting Wooden Wall enters placement mode.",
      "verification": {
        "automated_tests": [],
        "manual_checks": []
      }
    },
    {
      "id": "AC02",
      "text": "The completed wall blocks pathfinding.",
      "verification": {
        "automated_tests": [],
        "manual_checks": []
      }
    }
  ],
  "verification": {
    "acceptance_mode": null,
    "regression_tests": [],
    "manual_regression": null
  },
  "source": "product/04-building.md#wooden-wall",
  "notes": ""
}
```

工程 Feature：

```json
{
  "id": "F043",
  "description": "Repair reopening the detail panel after a scene transition while preserving the documented panel behavior.",
  "affected_components": ["detail_panel", "scene_lifecycle"],
  "acceptance_criteria": [
    {
      "id": "AC01",
      "text": "The documented reopen behavior is restored.",
      "verification": {
        "automated_tests": [],
        "manual_checks": []
      }
    }
  ],
  "verification": {
    "acceptance_mode": null,
    "regression_tests": ["F043-RT01"],
    "manual_regression": null
  },
  "source": "product/03-detail-panel.md#reopen-behavior",
  "notes": "",
  "engineering_change": "bug"
}
```

### 详情字段

| 字段 | 要求 |
| --- | --- |
| `id` | 与索引条目和文件名主干一致。 |
| `description` | 非空，写可观察的结果。来自 Product 的 Feature 写玩家或用户得到什么。工程 Feature 写技术修复或维护的结果，不写流程状态。 |
| `affected_components` | 非空数组，元素是不重复、稳定的 `lower_snake_case` 组件或领域 ID。使用语义上的组件，不用文件路径。 |
| `acceptance_criteria` | 非空的条件对象数组。每个对象有 `ACxx` 形式的 ID、非空的 `text` 和一个 `verification` 对象。纯字符串不是有效的条件。条件 ID 不重复，并按列表顺序递增。删除条件后编号可以跳过，删掉的编号永不复用。 |
| `acceptance_criteria[].verification.automated_tests` | 不重复的验收测试 ID，格式为 `F0XX-ACyy` 或 `F0XX-ACyy-NN`；`F0XX` 是本 Feature，`ACyy` 是本条件。 |
| `acceptance_criteria[].verification.manual_checks` | 来自人工验收计划的检查项，不重复、非空、具体。自动计划下为空。这个列表由验收模式决定，不反过来决定模式。 |
| `verification.acceptance_mode` | `manual`、`automated` 或 `null`。见[验收模式](#验收模式)。 |
| `verification.regression_tests` | 本 Feature 创建的回归测试 ID，不重复，格式为 `F0XX-RTyy`，其中 `F0XX` 是本 Feature 的 ID。不是 Bug 的 Feature 留空，除非写明理由。 |
| `verification.manual_regression` | 已有自动回归测试，或不涉及 Bug 回归时，填 `null`。否则写一项具体、可重复的人工回归检查，并说明自动化不现实的原因。非 `null` 时要求 `acceptance_mode: "manual"`。 |
| `verification.test_impact` | 可选；不需要额外测试范围时省略。出现时只能有 `additional_tests` 和 `full_suite_reasons` 两个字段；模板里两者都有。Stage 2 在最终测试运行前把批准的额外范围存在这里。该字段计入快照指纹。 |
| `verification.test_impact.additional_tests` | `{ "id": "...", "reason": "..." }` 对象的数组；测试 ID 来自测试登记表且不重复，理由非空。可以引用其他 Feature 的测试。准备阶段被引用的测试可以是 `planned`，但本 Feature 完成时必须是 `active`。追加测试不改变测试归属，也不代替本 Feature 自己的 AC 与回归映射。 |
| `verification.test_impact.full_suite_reasons` | 在自动触发条件之外，批准运行全量测试的理由，不重复、非空。`full_suite_on_change: true` 的组件会自动触发全量，不写在这里。空数组表示没有额外升级。 |
| `source` | 一个精确的主要来源：Product 交付章节、GDD 章节或专业规格。没有单一来源文档的技术工作用 `infrastructure`。见下文的来源规则。 |
| `notes` | 字符串，初始为空。保存任务提醒、占位、TODO、推迟处理的边界情况、简短的 Bug 经验，以及指向 Feature 设计稿或其他记录的相对链接。实现决定及其理由不论长短，都写进 [Feature 设计稿](#feature-设计与实现说明)。 |
| `engineering_change` | 可选。出现时只能是 `bug`、`refactor` 或 `maintenance`。来自 Product 的 Feature 不写这个字段。 |
| `bug_diagnosis` | 只允许与 `engineering_change: bug` 一起出现；其他情况为 `null` 或省略。对象只能有 `actual`、`expected`、`source`、`reproduction` 和 `root_cause`。`actual`、`expected`、`source` 是非空字符串。`reproduction` 是非空的有序步骤列表，步骤不重复、非空。调查期间 `root_cause` 可以是 `null`。每个 `done` 的 Bug，以及正在完成的 Bug，都需要非空且已确认的 `root_cause`。不是 Bug 的 Feature 不编造诊断证据。 |

条件 ID 是永久标识。不要给已完成 Feature 的条件重新编号。之后 Product 行为发生变化时，新建一个 Feature 来修改或取代原有行为。

### 验收模式

Stage 1 在填写验证列表之前决定 `verification.acceptance_mode`。依据是已确认的 GDD 设计、Product 交付范围，以及专业或工程意图：

- `manual`：只要有任何条件依赖人的感知或判断，就必须用这个模式，例如视觉呈现、动画手感、音频、音效、音乐或游戏手感。至少一个条件有 `manual_checks`，或者设置了 `manual_regression`。manual 计划也可以映射自动测试。
- `automated`：只有每个条件都能自动验证时才允许。此时每个条件至少列出一个自动测试，没有条件带 `manual_checks`，`manual_regression` 为 `null`。因此使用人工回归检查的 Bug 要用 `manual`。
- `null`：尚未决定的草稿。`done` 的 Feature，以及正在完成的 Feature，不能是 `null`。

空列表和以前的 PASS 结果都不能决定模式。Stage 1 在批准材料中说明这项决定；Stage 5 只适用于 `manual`。

### 来源

GDD 和专业需求走同一套规划、影响评估和 AC 映射，见 [查找与映射来源](11-specialist-workflows.md#查找与映射来源)：

- 来自 Product 的 Feature 用其当前的 Product 交付章节作为 `source`，并在 AC 或设计稿中链接所依据的 GDD 设计。
- 次要来源从 AC 或设计稿中链接。不要为它们新增 JSON 字段，也不要在 `source` 里放多个路径。
- 校验器只检查 `source` 是非空文本。由负责规划的 Agent 核实来源存在、有权威性并覆盖该 Feature。
- 有约束力的需求永远不能只写在 `notes` 里；`notes` 只保存过程信息。

### 已记录的测试影响

测试运行器总是把已记录的 `test_impact` 与它从测试登记表推导出的范围合并。批准的追加测试和全量理由只存在 Feature 详情里；不要另建计划文件，也不要另设额外范围的命令。修改 `test_impact` 后，要重新评估受影响的范围，之前的快照证据随之失效。

## Feature 设计与实现说明

`docs/features/F0XX-design.md` 是固定位置，保存 Feature 的实现设计、局部技术决定及其理由。内容包括边界、状态归属、生命周期、迁移、接口和所采用的约束。

- 这类内容再短也存在这里。不要在 JSON `notes` 里放一份简写，也不要按复杂程度另选文档。
- `notes` 只放提醒和相对链接 `[Design](F0XX-design.md)`。
- 有设计内容要保存时再创建这个文件；不要求空文件。不要再加 JSON 记录或设计状态记录文件。
- Stage 0 读取所选 Feature 及其相关依赖的设计稿。

`implementation-guidance-godot` Skill 把为某个 Feature 请求的实现指导写进同一个文件，工程 Feature 也一样。主 Agent 可以自己准备指导；交给 advisor 准备需要该 Skill 规定的明确授权。不属于任何 Feature 的工作按 [独立技术决定](10-architecture-overview.md#独立技术决定) 处理，不要虚构一个 Feature，也不要在 `reports/` 下另写指南。

设计稿开头是“对外接口与接入要点”：后续 Feature 接入时需要的接口、信号、完成约定和已知的坑，几行就够。依赖它的 Feature 先读这一节，需要时再读全文。Feature 完成时按实际实现更新它。

设计稿解释本次改动：

- 目标和边界，并链接 Product 和 AC；
- 与本次改动有关的当前行为；
- 实质约束本次改动的规则，以及它们怎样应用；
- 职责、接口和状态归属；
- 重要的运行、失败和生命周期流程；
- 必要的实现顺序，以及验证方式的理由；
- 实际结果和有意义的偏差。观察写明是实测还是推断，推断的标为待核实。

写清必要的依赖关系，不写逐个函数的做法；普通实现细节由实现的 Agent 决定。有用的解释需要多长就写多长。[feature-design.md.tmpl](templates/feature-design.md.tmpl) 是可选提纲；不适用的小节可以省略。

对游戏功能，设计稿记录 Stage 1 对照 `docs/game-organization.md` 核对的结果：

- 谁拥有这次涉及的业务状态；
- 哪些状态只属于表现层本地；
- 请求、当前状态和一次性事件分别表示什么。

动画时机影响玩法时，设计稿写明时机输入、打断条件，以及由谁判定有效结果。只解释与本次改动有关的契约。这个模型不要求拆出独立对象，也不要求全局事件总线。

链接仓库规则和记录时，使用相对设计稿的路径，并带上有用的小节锚点。说明它们怎样应用，不复制规则原文，也不罗列读过的每个文件。对受版本影响的外部资料，写明适用的版本，并把证据和假设分开。设计稿链接下列记录，不重复其内容：

- AC、组件影响和测试映射留在 Feature JSON 和测试登记表中。
- 任务状态和阻塞留在 Progress（进度记录）中。

按 [专业工作与来源](11-specialist-workflows.md)，设计稿也可以说明范围内额外的测量、时长、显示或试听义务。

Stage 1 把设计稿作为方案准备，Stage 2 保存批准的设计，Stage 3 让它与实现保持一致。这些步骤分别定义在 [Stage 1C](03-execute-loop.md#1c-设计决定与实现指导)、[Stage 2](03-execute-loop.md#stage-2--标记-in_progress-并保存验证计划) 和 [Stage 3](03-execute-loop.md#stage-3--基线tdd-与实现)。

已获授权的任务只交付实现指导时：

- 按 Stage 1C 准备方案，按 Stage 2 保存批准的设计，但不执行 Stage 2 的其余步骤。
- 保存批准的设计不等于授权实现，也不授权修改 Feature 状态、验证计划或测试登记表。
- 原任务的负责方在已授权范围内维护 `notes` 中的链接，然后以所请求的指导结束任务。

实现任务仍在 Stage 2 保存批准的设计。

对当前某个子系统的详细描述放在 `docs/architecture/<subsystem>.md`；重要的跨 Feature 理由可以写成 ADR。Feature 设计稿链接它们。不要把同一份子系统描述复制到每个 Feature。

完成后，设计稿保留为该 Feature 的记录。之后的行为变化要新建 Feature 和设计稿，并更新当前架构。可以用更正说明或替代链接澄清记录，但不要把过去的决定改写成好像一直如此。设计 Markdown 计入验证指纹，不享有 JSON `notes` 的豁免。

## 文件 3：`docs/feature-list-revisions.json`

- `feature-plan` 写入[初始规划基线](#初始规划基线)。
- 之后每次与 GDD、Product、专业或项目规则来源同步，`feature-sync` 都追加一条记录。
- `engineering-change-plan` 只新建工程 Feature、没有来源变化时，不追加记录。

初始内容是 `{"schema_version": 2, "revision_log": []}`。根对象和每条记录都使用 `schema_version: 2`。只有 schema 版本 2 有效（测试登记表是 3）；工具不读取、也不转换其他格式。已写入的记录永不改写。

### 初始规划基线

第一次 Product 规划之前，如果 Feature 索引和修订日志都为空，就随这次规划写入基线。空的复制项目，或者只有工程 Feature，都不能建立来源覆盖。续接被中断的第一次规划时，要从任务上下文和 Git 历史确认两点：起始状态同样为空，以及所采用的来源版本。仅凭修订日志为空不能证明这两点。

1. 写计划之前，确认所采用的每个 GDD、Product、专业和规则来源，都已经通过各自的流程和授权提交。
2. 把来源的 HEAD 解析成完整的提交哈希。如果来源无法提交，或采用的状态不清楚，报告缺少的前提。不要用脚手架提交代替。
3. 核对已写计划的语义覆盖后，追加下面这条记录。把它纳入最终的 Feature 记录校验和计划提交。
4. 定稿前，确认所采用来源的内容仍与记录的提交一致。

| 字段 | 初始值 |
| --- | --- |
| `revision_id`、`schema_version` | `R000`、`2` |
| `anchor_commit`、`synced_at_commit` | 同一个已核实的完整来源 HEAD 哈希，即本次计划采用的版本 |
| `revised_at`、`user_intent` | 实际时间戳；提供的规划意图，或 `null` |
| `summary`、`added` | 用文字说明初始基线、当前 Product，以及所采用来源的覆盖范围和局限；本次计划新增的 Feature ID |
| `migrations`、`dependency_changes` | 空数组；这条记录表示初始规划，不表示来源变化 |

`check-feature-list.py` 校验 R000 是第一条记录、`user_intent` 存在（字符串或 `null`）、`added` 列出已存在且不重复的 Feature ID，以及两个数组为空；检查器会拒绝 `anchor_commit` 与 `synced_at_commit` 二者不同。

不要创建引用自身的计划提交、单独的基线文件或新的 schema 字段。基线只覆盖已规划的范围和实际采用的来源，不覆盖所有 Product，也不覆盖 HEAD 上的所有文件。

之后的 Product 规划保留完整的修订日志，永远不向前移动锚点，否则会掩盖早期工作中尚未同步的变化。续接时保留已记录的基线。Feature 记录里已有 Feature 但没有基线时，不要只因为日志为空就补加 `R000`。这时由 `feature-sync` 核实之前的覆盖，或在授权下与当前文档对齐。

### 同步记录

`feature-sync` 判断计划实际吸收了哪个来源状态，并处理缺失基线的情况。只编辑 Feature 文件不能建立来源基线。记录字段保存判断结果：

- 普通记录写明比较的两个来源状态：`anchor_commit` 是改动前的状态，`synced_at_commit` 是改动后的状态。
- 经批准与当前文档对齐、以此代替未知历史时，两个字段都写所检查的 HEAD，并在 `summary` 中说明这个局限。这样可以确定下一个基线，又不声称存在更早的差异。

首次进入计划的 GDD 或专业来源，即使文件早于记录的锚点，也需要同样的覆盖核对；见 [查找与映射来源](11-specialist-workflows.md#查找与映射来源)。

同步记录包含以下字段：

```json
{
  "schema_version": 2,
  "revision_id": "rev-contract-01",
  "revised_at": "2026-05-20T08:30:00Z",
  "anchor_commit": "e25178b4c0d2a9f61b3e7c58d0a4f92e6b1c3d70",
  "synced_at_commit": "78cfcb91a6e04d2b8f3c7a59e1d06b4c2f8a9e35",
  "user_intent": "Revise the inventory contract",
  "summary": "Replace the superseded behavior and reconnect pending work",
  "migrations": [
    {
      "kind": "revise",
      "from": ["F002"],
      "to": ["F004"],
      "reason": "The approved GDD change replaces the earlier contract",
      "source": {"path": "docs/gdd/inventory.md#capacity", "anchor_commit": "78cfcb91a6e04d2b8f3c7a59e1d06b4c2f8a9e35"}
    }
  ],
  "dependency_changes": [{"feature": "F003", "before": ["F002"], "after": ["F004"]}]
}
```

记录在类型化关系之外，还可以带可读的摘要字段。源同步更新这些字段时，保持它们的结构：

| 摘要字段 | 结构 |
| --- | --- |
| `added`、`obsoleted`、`depends_on_warnings` | 受影响 Feature ID 的数组 |
| `revised_via_new_feature` | `{ "original": "F0XX", "regression": "F0YY" }` 的数组 |
| `source_path_updates` | `{ "feature": "F0XX", "from": "product/old-path.md", "to": "product/new-path.md" }` 的数组 |

字段规则：

- `revision_id` 不重复，由字母、数字、点、连字符和下划线组成。
- `anchor_commit` 和 `synced_at_commit` 是 Git 提交标识，`revised_at` 是 ISO 8601 时间戳，`summary` 非空。
- 每条迁移只能有 `kind`、`from`、`to`、`reason` 和 `source`。其中提到的每个 Feature ID 都必须存在。
- 迁移的 `source` 只能有 `path` 和 `anchor_commit`：
  - `path` 是相对仓库的路径，可以以 `#section` 结尾。
  - `anchor_commit` 等于记录的 `anchor_commit` 或 `synced_at_commit`；已删除的来源路径指向改动前的提交。
- 源同步核实真实的 Git 差异。校验器检查类型化关系，不检查它是否经过批准。

| `kind` | 数量与动作 |
| --- | --- |
| `add` | `from` 为空；一个或多个 `to` ID。 |
| `revise` | 一个 `from`，一个 `to`。pending 或 in_progress 的 Feature 可以保留原 ID；已完成的契约要用新 ID。 |
| `split` | 一个 `from`；至少两个新追加的 `to` ID，且不与 `from` 重叠。来源 Feature 保留为 `obsolete` 或 `obsolete_done`。 |
| `merge` | 至少两个 `from`；一个新追加的 `to` ID，且不与 `from` 重叠。来源 Feature 保留为 `obsolete` 或 `obsolete_done`。 |
| `retire` | 一个或多个 `from`；零个或多个 `to` ID，且不与 `from` 重叠。来源 Feature 保留为 `obsolete` 或 `obsolete_done`。移除已实现的行为需要替代的实现工作。 |

替代 ID 一律追加；永不重新编号或删除条目。拆分、合并或修订时，检查所有下游依赖边；执行顺序不能只写在文字说明里。

- `dependency_changes` 中每个 `feature` 最多一条。其 `before` 和 `after` 列表只含不重复、已存在的 ID，且不含该 Feature 自身。
- 同一 Feature 的连续变化必须首尾相接：每个 `before` 等于上一次的 `after`。最新的 `after` 等于当前的 `depends_on`。
- 迁移关系图和依赖图都不能有环。

可读的摘要数组可以作为历史保留；`migrations` 和 `dependency_changes` 才是供机器读取的关系。

## 文件 4：`docs/test-registry.json`

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
    }
  ],
  "tests": [
    {
      "id": "F052-RT01",
      "components": ["inventory"],
      "path": "tests/features/F052/inventory_regression_test.gd",
      "case": "test_f052_rt01_reopen_inventory_after_scene_change",
      "status": "active"
    }
  ]
}
```

| 字段 | 要求 |
| --- | --- |
| `meta.schema_version` | 整数 `3`。只有 schema 版本 3 有效（修订日志是 2）；工具不读取、也不转换其他格式。 |
| `components[].id` | 不重复的 `lower_snake_case` 组件 ID。 |
| `components[].unit_test_paths` | 已存在的单元测试套件文件或目录路径，不重复；组件没有单元测试套件时为 `[]`。示例假定 `tests/unit/inventory` 存在。 |
| `components[].full_suite_on_change` | 布尔值。 |
| `tests[].id` | 不重复的逻辑测试 ID。ID 格式本身表示测试的类型、所属 Feature 和条件；不要另设字段保存这些信息。所属 Feature 必须存在。 |
| `tests[].components` | 非空数组，元素是来自 `components` 的组件 ID，不重复。 |
| `tests[].path` | 测试文件路径。状态为 `active` 时必填且文件必须存在；`planned` 或 `retired` 时为 `null` 或路径。 |
| `tests[].case` | `null` 或非空的测试用例名。 |
| `tests[].status` | `planned`、`active` 或 `retired`。 |
| `tests[].retirement` | 状态为 `retired` 时必填，其他状态不允许出现；见[已退役的测试](#已退役的测试)。 |

测试登记表中的路径相对仓库，不带 `res://` 前缀。单元测试套件路径和 active 测试路径解析后必须仍在仓库内。登记和选择测试时，拒绝绝对路径、带盘符的路径、`..` 片段，以及解析到仓库外的链接。

ID 格式，以及这些字段对测试选择、登记时机和完成的含义，定义在 [登记表规则](08-test-traceability-and-evidence.md#登记表规则)。

### 已退役的测试

`retired` 条目保留原 ID，因而也保留它的所属 Feature 和条件；同时保留历史上的 `path` 和 `case`。它的 `retirement` 对象只能有以下字段：

```json
{
  "reason": "The approved GDD contract supersedes this assertion",
  "source": {"path": "docs/gdd/inventory.md#capacity", "anchor_commit": "78cfcb91a6e04d2b8f3c7a59e1d06b4c2f8a9e35"},
  "replacement": {"feature_id": "F004", "test_ids": ["F004-AC01"]},
  "revision_id": "rev-contract-01"
}
```

校验器检查退役链：

- `revision_id` 指向一条 schema 版本 2 的修订记录。该记录中有一条迁移的 `source` 与之相同，并在 `to` 中列出 `replacement.feature_id`。对属于某个 Feature 的测试，这条迁移还要在 `from` 中列出所属 Feature。不变量测试没有所属 Feature，只需来源和替代对得上。
- `replacement.test_ids` 非空，且不含被退役的测试本身。每个替代测试都在测试登记表中存在，属于 `replacement.feature_id`，并出现在该 Feature 的 AC 或回归映射中，这样执行计划才会真正选中它。
- 只有当替代测试所属的 Feature 是 `pending`、`in_progress` 或 `blocked` 时，替代测试才可以是 `planned`。这是一个可见的覆盖缺口，永远不算通过的证据。已完成的替代 Feature 需要 active 的覆盖，或另一条完全可追溯的退役链。
- 退役链不能成环。缺少出处或缺少替代时校验失败；不要为了通过校验编造理由或替代。

所属 Feature 为 `done`、`obsolete` 或 `obsolete_done` 的 `planned` 测试也会校验失败。Feature 被退役且没有替代时，删除它在测试登记表中的 `planned` 条目，这些测试从未实现。

被取代的测试从未写过时，已退役测试的 `path` 可以是 `null`。已知的历史路径要保留，不要清空。删除来源时可以一并删掉已退役的测试文件。退役不会移除可运行的测试函数：实现时要有意替换或删除被取代的断言，这样完整发现运行的才是当前契约。

经批准修订 `pending` 或 `in_progress` 的 Feature 时，可以从当前详情中删除某个条件。剩余和新增的条件继续使用递增的 ID，删掉的编号不再使用，这样后来的条件永远不会占用已退役的测试 ID。

- 已退役的验收测试保留其 ID 中编码的条件；这个条件不必留在当前详情里。测试的所属 Feature 和完整的退役链仍须通过校验。
- `planned` 和 `active` 的验收测试必须指向当前存在的条件。
- 这不允许改写已完成的 Feature，也不允许把计划中的替代测试当作已通过。

已完成 Feature 的条件、测试 ID 和已归档的完成证据都是历史记录。不要为了模仿当前行为而改写它们。哪些测试构成有效的安全网，以及正在完成的 Feature 可以引用哪些状态的测试，定义在 [登记表规则](08-test-traceability-and-evidence.md#登记表规则)。

## 文件 5：`docs/features/F0XX-evidence.json`

每个 Feature 有自己的完成证据文件，以 schema 版本 9 保存它的测试运行引用和人工验收记录，结构见[模板](templates/feature-completion-evidence.json.tmpl)。第一次记录时由工具创建；各 Feature 互不覆盖，等待验收期间推进别的 Feature 也不会丢失原 Feature 的记录。只能通过 `yaya/tools/features/record-feature-completion.py` 写入，并用它的 `validate --feature F0XX` 命令检查。什么算证据、何时结果为 `not_required`、证据何时失效，定义在 [基于原始结果的完成判断与语义时效](08-test-traceability-and-evidence.md#基于原始结果的完成判断与语义时效)。

## notes 中的 Bug 经验

带 `engineering_change: bug` 的 Feature 通过自动验证、并完成所需的人工验收后，追加一段简洁的 `BUG learning`，字段见[标准字段](07-engineering-change.md#bug-经验的提升)。

不要保存走不通的调试记录或临时猜测。

## 状态流转

```text
pending ──execute Stage 2──→ in_progress ──Stage 7 after applicable completion checks──→ done
   │                              │
   │                              └──explicitly abandoned──→ pending
   ├──source synchronization retires work──→ obsolete
   └──invalid prerequisite──→ blocked

in_progress ──source synchronization retires work──→ obsolete

blocked ──prerequisite validity restored──→ pending
blocked ──source synchronization retires work──→ obsolete

done ──source synchronization retires or replaces implemented behavior──→ obsolete_done
```

`blocked` 标记一个 `pending` Feature：它需要的来源决定、输入或依赖契约无效或无法获得。

- 在详情的 `notes` 中记录具体的阻塞原因和恢复条件。
- `blocked` 不允许保留损坏的依赖 ID 或已作废的前置 Feature。
- 有效的 Feature 只是在等一个尚未完成的依赖时，保持 `pending`；它只是暂时还不能开始。
- 已经 `in_progress` 的 Feature 保持该状态，在当前执行记录中写明阻塞。不要切换成 `blocked`，那会丢掉它的执行状态。

在已获授权的源同步或续接中，对照当前来源和依赖重新检查已记录的阻塞：

- 修订可以更新被阻塞的工作；依赖替换必须把它包括在内。
- 只有已记录的前提重新有效且可获得时，才把 `blocked` 恢复为 `pending`，并在 `notes` 中追加原因。之后照常检查全部前置 Feature 是否都已 `done`。
- 恢复本身不开始执行，也不建立完成。
- 确认撤回时使用 `obsolete`，并把原来的阻塞原因和退役原因作为历史保留。

`in_progress → done` 的流转遵循[执行循环](03-execute-loop.md)的 Stage 7。它要求：

- 已决定的验收计划；
- 需要的测试和直接静态检查；
- 用户明确提出的审核条件（如有）。

按 Stage 6，独立审核是可选的；完成记录不含审核次数。Agent 针对当前代码快照运行明确的证据检查，并记录实际结果。

## 机器校验的不变量

字段规则列在上面的各张表中。`python -B yaya/tools/checks/check-feature-list.py` 还会跨字段、跨文件检查以下规则：

- **文件：**索引、修订日志和测试登记表都存在。它们和每个 `docs/features/F*.json` 都能解析为 JSON，且没有重复键。
- **索引与详情：**索引 ID 的集合等于详情文件名主干的集合，每个详情的 `id` 等于其文件名主干。
- **依赖：**每个前置 Feature 都存在且不是自身，依赖图无环。`pending`、`in_progress` 或 `blocked` 的 Feature 不能依赖 `obsolete` 或 `obsolete_done` 的 Feature。
- **组件：**每个 `affected_components` ID 都存在于测试登记表的 `components` 中。
- **测试引用：**详情的 `automated_tests`、`regression_tests` 或 `test_impact.additional_tests` 中的每个测试 ID 都存在于测试登记表中。测试登记表中测试 ID 编码的 Feature 存在。`planned` 或 `active` 的验收测试指向其 Feature 当前存在的条件。
- **计划中的测试：**`planned` 测试不能属于 `done`、`obsolete` 或 `obsolete_done` 的 Feature。
- **测试登记表：**`meta.schema_version` 是整数 `3`。每个 `unit_test_paths` 条目和每个 `active` 测试路径都存在于仓库内。`full_suite_on_change` 是布尔值。
- **验收模式：**模式已决定时，检查项要符合[验收模式](#验收模式)。`automated` 的每个条件都有自动测试，没有 `manual_checks`，也没有 `manual_regression`；`manual` 至少有一条 `manual_checks` 或一个 `manual_regression`。
- **测试影响：**`test_impact` 出现时，只能有 `additional_tests` 和 `full_suite_reasons`。
- **已完成的 Feature：**`done` 的 Feature 有已决定的 `acceptance_mode`。它引用的每个测试都是 `active`，或是可追溯的 `retired`。
- **已完成的 Bug：**`done` 的 Bug 有 `regression_tests` 或 `manual_regression`，并且 `bug_diagnosis.root_cause` 非空。
- **修订与退役：**规则见[文件 3](#文件-3docsfeature-list-revisionsjson) 和[已退役的测试](#已退役的测试)。

`--completion-feature F0XX` 对正在完成的 Feature 应用 done 规则，并且要求它引用的每个测试（包括追加测试）都是 `active`。

`yaya/tools/lib/test_selection.py` 中的测试选择由运行器和 `record-feature-completion.py` 使用。它在最终阶段还额外要求每个条件至少有一个自动测试或人工检查。

一起编辑相关文件后，在仓库根目录运行严格校验器：

```powershell
python -B yaya/tools/checks/check-feature-list.py
```

它总是检查完整的 Feature 记录。

## 逐个 Product 规划

先满足 [GDD 前提](01-product-doc-structure.md#gdd-前提与职责)。在 `docs/product.md` 中预拆分约定的交付范围，然后按实际执行顺序，一次细化并交付一个 Product。

- Feature 的规划单位是当前的 `docs/product/NN-<delivery>.md`，连同它批准的范围和 GDD 引用。
- `docs/product.md` 保存候选边界、来源映射、依赖和建议顺序。
- 文件编号是稳定的身份标识，不表示每个 Product 都要一次细化或规划完。

1. 根据用户的请求、预拆分顺序，以及已有 Feature 的 `source` 和状态，确定当前 Product。阅读与之有关的 Progress 了解背景。重新查看所依据的 GDD 设计和早期交付的实际结果。然后在当前授权内，用 `product-author` 编写或更新这个 Product 的交付文档。拆分前先解决不清楚的范围和必要的跨系统规则；不要为了确定一条共享规则就去细化未来的 Product。
2. 在一次规划中，把当前 Product 完整的必要范围拆成可独立验证的 Feature。只纳入这个范围需要的基础设施，复用已有基础设施和已完成的前置 Feature。如果必须先交付另一个 Product，就调整顺序，而不是同时提前规划两个 Product。
3. 后续 Product 在 `product.md` 中保持为简洁的预拆分条目。不要编写它们的详细交付文档，不要分配它们的 Feature ID，也不要写它们的 AC 或测试登记。只在当前决定需要时读取它们的 GDD 依赖。
4. 先完成当前 Product 所需的 Feature，再拆分下一个 Product。核对 Feature 的实际完成情况和剩余范围。以下情况都不能证明实现已完成：没有可开始的 Feature、计划为空、Product 文档自称已完成。`pending`、`in_progress` 和 `blocked` 的工作都算未完成；明确撤回的范围按退役规则处理。
5. 完成后，对照当前 GDD 和已经学到的东西，重新审视下一个候选。需要时调整预拆分，编写该 Product 的交付文档，再在当前授权内拆分它。Stage 8 遵循[授权与续接](03-execute-loop.md#授权与续接)；仅仅完成并不授权规划或实现下一个 Product。

`feature-plan` 以追加到同一份 Feature 记录的方式，写入第一个及之后每个 Product 的初始拆分。它从当前已用的最大 ID 之后分配新 ID，并保留之前的 Feature、测试登记表记录和修订历史。所选范围已有计划时，复用它；需求变化走 `feature-sync`，不要重复规划或重新生成计划。

`feature-sync` 对照已规划和已完成的工作，分析 GDD、Product、专业和项目规则来源的变化，包括实际的下游依赖。

- 只影响后续、尚未规划的候选的变化，按需更新它的预拆分，不创建详细的 Product 文档或 Feature。
- 这个候选成为当前 Product 时，完整阅读它所依据的 GDD 和专业设计，即使这些编辑早于最近一次同步锚点。
- 全局的来源锚点不能证明每个 Product 都已细化或拆分。`meta.generated_from` 只列出来源位置，不表示覆盖范围。

使用 Product 顺序、Feature 的来源和状态，以及普通的 Progress 记录。不要新增 Product 队列、登记表、完成标记或第二份 Feature 记录。这条规则保护已有计划不被改动；它不授权删除未来的 Feature，也不授权改写已完成的历史。

### 拆分预览

每个当前 Product 做初始拆分时，在写入它的 Feature 索引条目、详情、修订日志或测试登记表（包括组件合并）之前，先在对话中给出简洁的预览。Product 编写或接手已有实现时调用规划，也同样适用。把预览作为规划方案的一部分给出：

- 指明 Product 及其批准的范围。说明要新增的 Feature 数量，以及 Feature 记录前后的总数。区分复用的工作和新增的条目。数量从完整的结果推导，不按预设配额。
- 用紧凑的表格或列表列出每个拟定的 Feature：暂定标签、标题、一句话的范围和可观察结果、前置 Feature。说明选择这个粒度的理由，以及排除项和尚未决定的选择。
- 在同一份方案中附上[需求覆盖核对](#需求覆盖核对)；预览不代替覆盖核对或详细的 AC。

默认情况下，要等用户确认这份具体的拆分后再写入。批准 Product 意图，或笼统地要求规划或实现，都不等于批准用户还没看到的拆分。已确认且未变的方案可以跨轮次复用；不要就同一个决定再问一次。如果数量、工作边界或依赖发生实质变化，刷新预览，并在写入前解决变化的决定。

用户在限定范围内明确授权自主拆分并续接时，写入前展示预览，然后不再等待批准直接继续。授予这种权限的 Goal 也算数；仅仅使用 Goal 模式不算。这个例外也覆盖该授权内刷新的预览。缺失的 Product 决定和范围变化仍需要用户决定。

写入并校验后，用实际的 ID、数量和剩余工作刷新同一份方案。接受预览只授权记录计划；它不授权后续实现，也不代替人工验收。不要新增预览文件、批准字段或状态；Feature 记录校验器不检查这一步。

## 接手已有实现

在 Product 或 Feature 记录之前就已存在实现时，交付规划之前仍需要一份实质性的 GDD。

- 如果没有 GDD，在用户的范围内把设计缺口交回 `design-gdd`。代码可以为这项工作提供参考，但不能悄悄变成已批准的设计。
- 依据足够清楚的设计，用 `product-author` 划定当前交付边界。批准的游戏设计变更通过 `design-gdd` 处理，范围内的数值变更通过 `design-balance` 处理。
- 对所请求的当前交付应用逐个 Product 规划。已有实现不免除前置 Feature 的完成要求，也不扩大规划范围。后续候选保持在预拆分层级。

已有 Feature 覆盖该结果时，复用它。没有覆盖时，围绕可独立验证的结果创建普通的、来自 Product 的 Feature；不要按想象中的历史编码步骤拆，也不要每个源文件建一个 Feature。从已确认的意图推导 AC。在常规的需求覆盖核对中，把每个条件映射到实现、可用的测试和剩余缺口。不要为了迁就缺陷而削弱 AC，也不要只为重跑测试而创建重复工作。

这样创建的记录以 `status: "pending"` 和 `completed_at: null` 开始。在 `notes` 中：

- 说明实现早于正式记录；
- 链接已核实的文件、提交和决定；
- 写出剩余的实现或验证工作。

缺失的历史保持未知；不要编造更早的 Feature、批准、RED 运行或验收日期。已完成的记录及其证据按常规的演进规则保留。

只做文档的任务，在完成已授权的 Product 和计划写入、所需检查和提交后结束。把已实现的范围与正式完成分开报告。已授权的交付按[已有实现的交付](03-execute-loop.md#已有实现的交付)从当前状态核实并完成。不要为这种情况新增状态、接手记录文件或证据格式。

## 拆分规则

1. 每个 Feature 是最小的、可独立验证的完整行为或工程结果。
2. 按上面的规则只规划当前 Product。复用或建立它所需的可运行基础设施，然后按它的 Feature 依赖推进。
3. 最终的 Feature 是 `small` 或 `medium`；更大的工作继续拆分。
4. 来自 Product 的 Feature 依据已确认的 GDD 和专业来源实现其 Product 交付范围；不编造缺失的设计规则。
5. 工程 Feature 保持 GDD 设计和已批准的交付意图不变，除非实质性的改动已通过它自己的流程获得批准。
6. 每个 Feature 声明语义上的 `affected_components`；集合保持最小且有意义。
7. 每个条件都有稳定的 `ACxx` ID，按列表顺序递增。
8. 能做确定性自动化时，`bug` Feature 必须有回归覆盖。只有给出自动化不现实的具体理由，才允许使用明确、可重复的人工回归检查。
9. `refactor` Feature 写明行为保持不变的证据。
10. `maintenance` Feature 写明技术上的成功条件，以及要保持的兼容性或不变量。

检查每个拟定结果是否有具体的前提条件、动作或工程检查，以及可观察的结果。只有一个类名、文件名或层名，不构成完整的 Feature。技术结果即使没有面向玩家的界面，也可以独立验证；不要强制每个 Feature 都包含 UI、持久化和每一层代码。

“只做表现”“只做逻辑”和“跨层”描述的是范围，不是 Feature 类型或字段。当商店购买规则、界面反馈及其连接构成一个连贯、有边界的结果时，可以由一个 Feature 交付。在它的 AC、设计稿和验证计划中写明规则结果、感知结果和集成检查。只有在结果能独立验证或存在真实依赖时才拆分。两层模型不要求分开建 Feature，也不要求先实现逻辑。

对每个 `depends_on` 条目，弄清前置 Feature 提供的是什么：一项能力、一个契约、一个可运行的基础，还是一个已接受的决定。问一问：没有它，当前 Feature 还能否正确完成并验证。

- 保留真实的依赖和适用的架构约束；不要把编号或偏好的顺序写成依赖。
- 不明显的依赖，在拆分预览或 Feature 设计稿中解释，不新增 schema 字段或单独的清单。
- 复用已完成的前置 Feature，以及 [Product 前提的区分](01-product-doc-structure.md#交付成果与前提)。

界面工作按 [依赖实现前的视觉原型](13-prototypes.md#依赖实现前的视觉原型) 处理：

- 把所需的独立视觉基础规划成普通 Feature，并让需要其决定的逻辑通过 `depends_on` 链接到它。
- 视觉基础 Feature 要确定参数时，AC 写成“把样例实际使用的参数作为待验收值写入<专业文档的对应小节>”，不写“写回确认后的参数”；写入时机和采纳方式见[视觉原型的验证与采纳](13-prototypes.md#验证与采纳)。
- 范围较窄的检查可以留在已规划的 Feature 内。
- 复用已验证的基础。
- 不要让无关逻辑等待全部美术，也不要新建单独的原型状态或类型。
- 接入视觉基础的 Feature，在 notes 写明原型接入后的去留，默认保留为对照工具，规则见[视觉原型的验证与采纳](13-prototypes.md#验证与采纳)。
- AC 涉及玩家可见的动画或反馈时，核对它的参数在表现文档或 UI 规格中有所属位置；没有时，先交给 `design-game-presentation` 或 `design-ui-spec` 补上，不让参数只留在设计稿里。

## 需求覆盖核对

在规划或源同步报告中，用一张小表或清晰的列表，把以下环节连起来：**来源需求 → Feature 与 AC → 测试或检查动作 → 缺口或下一步**。

- 初始拆分覆盖当前 Product 批准的全部范围。
- 源同步覆盖变化的需求及其实际的下游影响，包括删除。
- 纯文字修改和后续尚未规划的 Product 只需简短说明如何处理，不建占位 Feature，也不审计全部 Product。

双向阅读需求和 AC 的含义。查找缺失的行为、没有依据或重复的范围，以及大到无法独立验证的 Feature。仅有来源链接、匹配的 ID 或 `done` 状态，都不能证明已覆盖。区分已经具备的验证和仍需规划或编写的测试与检查；不要为了填满报告编造测试 ID 或 PASS 结果。

交接前，对照实际写入的文件刷新报告：

- 写出每个未映射的需求、尚未决定的选择，以及剩余的实现或验证。不要把不完整的计划称为已完全同步。
- 明确写出已批准的排除项和推迟的范围。
- 可执行的后续事项放在负责的 Feature 或当前 Progress 中并附链接，不放进单独的覆盖记录文件。

规划对齐不代表行为已经实现或测试过。

## 职责分工

| 操作 | 负责方 | 主要修改的文件 |
| --- | --- | --- |
| 当前 Product 的初始拆分 | `feature-plan` | 追加索引条目、详情和需要的组件；使用项目提供的修订日志和测试登记表，并保留其历史 |
| GDD、Product、专业或项目规则的源同步 | `feature-sync` | 索引、详情、修订日志、需要的组件和受影响的测试追溯 |
| 创建 Bug、重构或维护 Feature | `engineering-change-plan` | 索引、工程详情和需要的组件；测试计划在执行时定稿 |
| Feature 执行和完成说明 | `feature-execute` | 状态、验证映射、测试登记表、notes、Progress、实现和测试文件 |
| 选择坏味道候选 | `engineering-refactor-select` | 只读选择；把选中的候选交回 `engineering-change-plan` |
