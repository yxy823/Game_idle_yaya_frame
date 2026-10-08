# 人工验收文件

本约定规定 `manual` Feature 在 Stage 4 准备、在 Stage 5 记录结论的人工验收清单。清单本身就是验收记录：用户的结论写在其中每项的 `status` 和 `comment` 里，不另建结果文件。是否适用由每个 Feature 的 `verification.acceptance_mode` 决定；`automated` Feature 不创建空的人工验收清单。项目只交换文件，不需要也不检查任何外部应用、启动器、服务或特定工具的元数据。

## 定义与准备

已批准的 Feature 在 `acceptance_criteria[].verification.manual_checks` 和 `verification.manual_regression` 中定义人工义务。Agent 用[清单模板](../templates/manual-acceptance-checklist.json.tmpl)把它们展开成清单。

- 写明入口场景、初始状态、按顺序的输入、可观察的预期反馈，以及必要的重置。
- 有关时，写明时机、构建版本或设备、参数所在的调参资源或随机种子。
- 检查在调试台中进行时，入口写调试入口、调试对象和固定局面；启动命令引用项目 `dev/debug/README.md` 的启动小节，不在清单里另写一份。检查对象是游戏原值，即采纳后游戏文件中的值：步骤不载入预设或组合，需要对比时只和游戏原值对比。
- 对照 AC 和实际实现检查覆盖情况。结构校验不能证明步骤覆盖了 AC。
- Feature notes 链接清单并记录决定，不复制清单的步骤。

使用 UTF-8 JSON（接受 UTF-8 BOM），不带注释、尾随逗号或重复的对象键：

| 字段 | 约定 |
| --- | --- |
| `schema_version` | 数字 `1`。 |
| `feature_id` | 当前的 `F0XX`。一个文件只包含一个 Feature。 |
| `title`、`description` | 可选字符串；供人阅读的内容使用项目的文档语言。 |
| `snapshot` | 未准备的草稿中为 `null`；`prepare-manual` 填入 `git_revision`、`working_tree_fingerprint` 和检查项定义的哈希 `definition_sha256`。必需字段 `uncommitted_paths` 保存绑定时与该提交不同的指纹输入路径（含未跟踪文件），去重排序，不参与定义哈希。之后不手工修改。 |
| `tests` | 非空数组，覆盖每一项已批准的人工义务。只靠自动验证的 AC 不转成人工工作。 |
| `tests[].id` | 唯一、非空，在整个验收过程中保持稳定，例如 `F001-AC01-M01`。不要按标题或数组位置匹配。 |
| `tests[].source_ref` | `AC01/1` 表示 AC01 下的第一项人工检查（从 1 开始计数）；`manual_regression` 表示该 Feature 的人工回归义务。每个当前引用都要被覆盖，多个用例可以覆盖同一个引用。这些引用属于绑定的快照，不属于单独的登记表。 |
| `tests[].title`、`tests[].expected_result` | 非空字符串，描述操作和可观察的结果。 |
| `tests[].preconditions`、`tests[].steps` | 非空字符串组成的数组；preconditions 默认为 `[]`，steps 至少要有一项。 |
| `tests[].status`、`tests[].comment` | 取 `pending`、`passed` 或 `failed`（默认 `pending`），以及记录实际观察或用户原话的字符串（默认为空）。准备时每个 status 都是 `pending`，每个 comment 都为空；之后只有这两个字段随用户的结论改变。 |

允许出现其他字段，验收逻辑会忽略它们，所以不要把必需的验收含义放进其他字段。绑定之后，`id`、`source_ref`、`title`、`preconditions`、`steps`、`expected_result` 以及文件的 `title`、`description` 都不能再改；修改 AC、步骤或预期结果，走 `feature-sync` 中的 Feature 修订路线，并准备新的清单。

清单保存在 `reports/manual-acceptance/` 下，例如 `reports/manual-acceptance/F001/manual-acceptance-checklist.json`。

- 再次验收时，如果必须保留之前的清单，使用单独的目录。
- 文件名只是约定；身份由明确的路径和文件内容决定。
- 保留与 Git 处理按[报告与清理](../09-records-reports-and-handoff.md#报告与清理)执行。换到另一台机器时，需要被引用的清单原件，而不只是一个提交或一份 Markdown 摘要。

写完草稿后，把它绑定到最终的实现：

```powershell
python -B yaya/tools/features/record-feature-completion.py prepare-manual --feature F001 --checklist reports/manual-acceptance/F001/manual-acceptance-checklist.json
```

这一步校验覆盖情况，记录实际的快照和检查项定义的哈希。它不编造步骤，也不运行测试。准备过的文件不能再次绑定，所以先完成代码和契约的修改。哪些之后的编辑会让快照失效，由[内容指纹](../08-test-traceability-and-evidence.md#内容指纹)决定。

交给用户之前发现清单草稿有错时，可以删除这份未使用的清单，重新编写并绑定，并在 notes 记录原因；交给用户之后不得改动检查项的定义。

给用户一个可点击的清单路径，并简短说明怎样执行检查、怎样返回结论：直接在对话中说明，或者自己把清单中的 `status` 改成 `passed` 或 `failed` 并写上备注。两种方式记录到同一个位置，用户只需选一种。不需要第二份手工维护的清单，也不强制要求报告。

## 记录用户的结论

用户的结论只写在清单中：

- **用户在对话中给出结论**：Agent 把对应检查项的 `status` 改为 `passed` 或 `failed`，`comment` 写明“来自对话”和用户的原话；部分不通过时，只改用户实际指出的项。用户的话含糊、没有覆盖全部检查项，或备注之间矛盾时，只就具体问题请用户澄清，不推断结论。
- **用户自己编辑清单**：先阅读用户改过的状态和备注，再记录。
- 不要替用户把检查项改成 `passed`，也不要把磁盘上找到的文件或测试通过当作人工验收。

然后记录：

```powershell
python -B yaya/tools/features/record-feature-completion.py record-acceptance --feature F001 --checklist reports/manual-acceptance/F001/manual-acceptance-checklist.json
```

工具确认检查项的定义与绑定时一致，对照当前内容检查 Feature 和来源引用，然后推导状态：

- `accepted`：所有用例都通过；
- `rejected`：有任一用例失败；
- `pending`：其他情况。

命令成功只表示实际状态已被记录，不表示验收通过或 Feature 已完成。同一份清单在同一快照上已经记录过同样的结论时，工具给出提示，不需要重复记录。无效文件会返回非零退出码，已记录的证据保持不变；停止这次记录并解决报告的不一致，不要退回到之前的验收。

### 绑定之后内容又有变化

清单绑定之后项目内容又变了，例如等待验收期间按 [Stage 0 · 选择 Feature 并加载上下文](../03-execute-loop.md#stage-0--选择-feature-并加载上下文)中的等待例外完成了另一个 Feature，`record-acceptance` 会停下，并列出绑定之后可能变化的文件。这份清单宁多勿漏：除了绑定提交之后确实改过的文件，还包括绑定时尚未提交的全部路径，其中可能有内容一直没变的文件，例如本 Feature 绑定时还没提交、之后原样提交的代码。

- 逐个核对这些文件。先确认它绑定之后是否真的改过；只是把绑定时的内容原样提交的，按没有变化处理。真正改过的文件都不涉及本 Feature 实际检查的范围（它自己改过的代码、场景、资源，以及它依赖的专业文档和规格）时，加 `--confirm-unrelated-changes` 重新记录。清单会写进验收记录，供之后核对。
- 有一个真正改过的文件涉及本 Feature，或者无法确认它是否改过时，不能沿用这次验收：按 Stage 4 重新验证，准备新的清单，请用户重新验收。
- 自动测试不沿用：回到原 Feature 时，在当前内容上重新运行并记录。

完成证据在 `human_acceptance.source.checklist` 中保存清单的项目相对路径。完成校验会重新读取清单：文件缺失、定义被改动，或状态不再全部为 `passed`，都会阻塞完成。时效按[内容指纹](../08-test-traceability-and-evidence.md#内容指纹)判断；报告不在指纹范围内，所以修改清单中的状态不会让已测试的实现失效。

## 后续工作

失败按[Stage 0–8 `feature-execute` 执行循环](../03-execute-loop.md)在当前实现授权内处理。用户在验收期间从调试台采纳了新值时，按 [Stage 5 · 明确的人工验收（仅 manual 模式）](../03-execute-loop.md#stage-5--明确的人工验收仅-manual-模式) 作为拒绝处理。提出新需求的评论不授权这些需求。即使是次要的延后处理，也需要用户明确接受并写一条说明。来源或验收契约变化后，在完成之前重新评估并重新进行受影响的验证。报告中的编辑性更正不需要重跑业务测试。人工验收不代替自动义务、直接的静态检查、被要求的审核条件或正常的完成检查。
