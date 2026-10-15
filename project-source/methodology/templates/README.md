# methodology 模板

这些模板给出流程之后要创建的文件和固定回复格式的结构，例如 Product、Feature 详情或 ADR。它们是结构的唯一来源；没有本地化副本。

项目的初始 Feature 记录（`docs/feature-list.json`、`docs/feature-list-revisions.json`、`docs/test-registry.json`、`docs/progress.md` 和 `docs/project-rules.md`）不是模板。项目创建时直接把它们复制进 `docs/`，之后由项目自行维护。

## 使用模板

1. 从 `docs/methodology-config.json` 读取 `document_language`，按[文档语言](../05-document-language.md)确定取值。
2. 机器键、枚举值、ID、路径、命令字符串和占位符保持原样。
3. 用 `document_language` 书写供人阅读的标题和正文。模板的标题与说明是中文；`document_language` 不是中文时，把它们渲染成该语言。保留每个必需的小节和约束。
4. 不建立本地化模板的并行目录。

*斜体*的行是要替换成项目内容的说明；其余都是要保留的结构。Markdown 正文写成自然段落，不按固定宽度折行；列表、表格、代码和图需要的换行要保留。JSON 等结构化模板不要重新排版。

## 模板一览

| 模板 | 产出 |
| --- | --- |
| `product.md.tmpl` | `docs/product.md`：交付的预拆分、GDD 来源对应、边界、依赖和建议顺序 |
| `product-module.md.tmpl` | 一份 `docs/product/NN-<delivery>.md`：当前 Product 的交付范围、来源链接、集成和验收场景。轮到该 Product 时才写 |
| `feature-detail.json.tmpl` | 由 Product 派生的 Feature 详情。没有 `engineering_change` 字段 |
| `engineering-feature-detail.json.tmpl` | Bug、重构或维护 Feature 的详情，带必需的 `engineering_change` 字段 |
| `feature-design.md.tmpl` | `docs/features/F0XX-design.md` 的可选提纲。只使用有帮助的小节；AC 和测试义务留在 Feature JSON 中 |
| `feature-completion-evidence.json.tmpl` | `docs/features/F0XX-evidence.json`：一个 Feature 的测试运行，以及需要时的人工验收，每项都绑定一个 Git 修订和工作区指纹。审核不记录在这里 |
| `manual-acceptance-checklist.json.tmpl` | 一个 Feature 的人工检查及用户的结论，按[人工验收文件](../contracts/manual-acceptance-files.md)准备和记录 |
| `feature-learning-summary.md.tmpl` | Stage 8 经验反馈的回复格式，包括明确的“无新增经验”结果。不保存为文件 |
| `architecture-overview.md.tmpl`、`architecture-subsystem.md.tmpl` | 可选的 `docs/architecture.md` 和子系统地图：模块、职责、依赖和相关的运行流程，与生成的引用事实分开 |
| `architecture-decision-record.md.tmpl` | 一份可选的 ADR，记录一项重要的技术选择。Feature notes 和架构地图链接到它，不复制它 |
| `ui-draft-readme.md.tmpl` | 草稿界面目录中的 `README.md`：依据、讨论与不讨论的内容、场景、结论和写入去向。目录命名见 `design-ui-spec` 的[草稿界面](../../../.agents/skills/design-ui-spec/SKILL.md#草稿界面) |

字段含义和校验规则见 [Feature 列表与测试追溯结构](../02-feature-list-schema.md)，工程 Feature 规则见[工程变更流程](../07-engineering-change.md)，测试选择见[测试追溯与证据](../08-test-traceability-and-evidence.md)。架构地图和 ADR 遵循[架构概览](../10-architecture-overview.md)；只为真实的决定创建 ADR。
