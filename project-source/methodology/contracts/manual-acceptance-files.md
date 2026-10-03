# 人工验收文件

本约定规定 `manual` Feature 在 Stage 4 使用的清单和 Stage 5 使用的结果文件。是否适用由每个 Feature 的 `verification.acceptance_mode` 决定；`automated` Feature 不创建空的人工清单。项目只交换文件，不需要也不检查任何外部应用、启动器、服务或特定工具的元数据。

## 定义与准备

已批准的 Feature 在 `acceptance_criteria[].verification.manual_checks` 和 `verification.manual_regression` 中定义人工义务。Agent 用[清单模板](../templates/manual-acceptance-checklist.json.tmpl)把它们展开成清单。

- 写明入口场景、初始状态、按顺序的输入、可观察的预期反馈，以及必要的重置。
- 有关时，写明时机、构建版本或设备、参数或随机种子。
- 对照 AC 和实际实现检查覆盖情况。结构校验不能证明步骤足够。
- Feature notes 链接清单并记录决定，不复制清单的步骤。

使用 UTF-8 JSON（接受 UTF-8 BOM），不带注释、尾随逗号或重复的对象键。输入和结果使用同一个结构：

| 字段 | 约定 |
| --- | --- |
| `schema_version` | 数字 `1`。 |
| `feature_id` | 当前的 `F0XX`。一个文件只包含一个 Feature。 |
| `title`、`description` | 可选字符串；供人阅读的内容使用项目的文档语言。 |
| `snapshot` | 未准备的草稿中为 `null`；`prepare-manual` 填入 `git_revision` 和 `working_tree_fingerprint`。用户在结果中保持这些字段不变。 |
| `tests` | 非空数组，覆盖每一项已批准的人工义务。只靠自动验证的 AC 不转成人工工作。 |
| `tests[].id` | 唯一、非空，在清单和结果中保持稳定，例如 `F001-AC01-M01`。不要按标题或数组位置匹配。 |
| `tests[].source_ref` | `AC01/1` 表示 AC01 下的第一项人工检查（从 1 开始计数）；`manual_regression` 表示该 Feature 的人工回归义务。每个当前引用都要被覆盖，多个用例可以覆盖同一个引用。这些引用属于绑定的快照，不属于单独的登记表。 |
| `tests[].title`、`tests[].expected_result` | 非空字符串，描述操作和可观察的结果。 |
| `tests[].preconditions`、`tests[].steps` | 非空字符串组成的数组；preconditions 默认为 `[]`，steps 至少要有一项。 |
| `tests[].status`、`tests[].comment` | 取 `pending`、`passed` 或 `failed`（默认 `pending`），以及记录实际观察的字符串（默认为空）。新清单中每个 status 都是 `pending`，每个 comment 都为空。 |

允许出现其他字段，验收逻辑会忽略它们，所以不要把必需的验收含义放进其他字段。返回的结果保留已知的定义和对应关系；只有 `status` 和 `comment` 承载用户的编辑。修改 AC、步骤或预期结果，走 `feature-sync` 中的 Feature 修订路线。

两份原件都保存在 `reports/manual-acceptance/` 下，通常是 `reports/manual-acceptance/F001/manual-acceptance-checklist.json` 和 `reports/manual-acceptance/F001/manual-acceptance-checklist.result.json`。

- 再次验收时，如果必须保留之前的证据，使用单独的目录。
- 这些文件名只是约定；身份由明确的路径和文件内容决定。
- 提交的结果放在别处时，把它复制进这个目录，并保留提交的原件。
- 不要用结果覆盖清单。
- 保留与 Git 处理按[报告与清理](../09-records-reports-and-handoff.md#报告与清理)执行。换到另一台机器时，需要被引用的原件，而不只是一个提交或一份 Markdown 摘要。

写完草稿后，把它绑定到最终的实现：

```powershell
python -B tools/features/record-feature-completion.py prepare-manual --feature F001 --checklist reports/manual-acceptance/F001/manual-acceptance-checklist.json
```

这一步校验覆盖情况并记录实际的快照。它不编造步骤，也不运行测试。准备过的文件不能再次绑定，所以先完成代码和契约的修改。哪些之后的编辑会让快照失效，由[内容指纹](../08-test-traceability-and-evidence.md#内容指纹)决定。

给用户一个可点击的清单路径，并简短说明怎样执行检查、怎样返回结果。不需要第二份手工维护的清单，也不强制要求报告。

## 接收用户的实际结果

记录之前，先阅读用户提交的文件和评论。

- 一份已提交的有效结果，如果每个必需用例都是 `passed`，就是用户对这份清单范围的明确接受。不要再要求一句接受的话。
- 评论之间矛盾或含义不清时，只就那个具体问题请用户澄清。
- 解析器只比较结构和状态。它不检查自然语言的含义、用户身份，也不检查是否真的有人执行了这些操作。
- 不要导入 Agent 生成的通过样例，也不要把磁盘上找到的文件当作人工验收。

```powershell
python -B tools/features/record-feature-completion.py record-acceptance --feature F001 --checklist reports/manual-acceptance/F001/manual-acceptance-checklist.json --result reports/manual-acceptance/F001/manual-acceptance-checklist.result.json
```

导入工具把 ID 和定义与未改动的原件匹配，对照当前内容检查 Feature、来源引用和原始快照，然后推导状态：

- `accepted`：所有用例都通过；
- `rejected`：有任一用例失败；
- `pending`：其他情况。

命令成功只表示实际状态已被记录，不表示验收通过或 Feature 已完成。无效文件会返回非零退出码，已记录的证据保持不变。停止这次导入并解决报告的不一致；不要退回到之前的验收。

完成证据保存原始快照，以及带项目相对路径 `checklist` 和 `result` 的 `human_acceptance.source`。完成校验会重新读取这些原件。文件缺失、定义被改动、内容过时，或结果不再全部为 `passed`，都会阻塞基于文件的验收。不会创建逐项的副本或第二份结果台账。时效按[内容指纹](../08-test-traceability-and-evidence.md#内容指纹)判断；报告不在指纹范围内，所以保存用户结果不会让已测试的实现失效。

## 对话中的决定与后续工作

用户在对话中给出明确决定时，用 `record-acceptance --feature F001 --status accepted|rejected` 记录。这个决定必须针对实际的当前范围，记录中不带文件引用。

- 一个决定只用文件路线或对话路线中的一种；绝不要求两者都有。
- 不要用对话记录绕过无效的文件。用户必须解决不一致，或做出一个新的、明确的决定。
- 即使是次要的延后处理，也需要明确的接受和一条说明。

失败按[执行规范](../03-execute-loop.md)在当前实现授权内处理；提出新需求的评论不授权这些需求。来源或验收契约变化后，在完成之前重新评估并重新进行受影响的验证。报告中的编辑性更正不需要重跑业务测试。人工验收不代替自动义务、直接的静态检查、被要求的审核条件或正常的完成检查。
