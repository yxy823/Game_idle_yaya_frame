# 00 核心规则

核心规则适用于所有文件类型。做修改或相关的工程决策时，先用本页找到要读的文档，再只读与任务匹配的文档和小节。普通的状态讨论或用词讨论不需要加载工程规则。

| 文档 | 何时阅读 |
|---|---|
| `rule-precedence-and-routing.md` | 同时适用多个规则模块，或需要判断规则强度、解决规则之间的冲突 |
| `godot-version-and-authority.md` | Godot 或工具的行为与版本有关或不确定；评估升级，或文档与实际运行结果不一致 |
| `godot-resource-references.md` | 选择或修改业务 ID、Resource UID、资源路径、NodePath 或场景引用 |
| `change-scope-and-ownership.md` | 准备修改：定位实现及其影响，确定范围，保留 API、依赖、代码风格和已有工作，或评估连带修改、删除与重构 |
| `git-worktree-and-commits.md` | 每个会修改文件的任务：选择目标工作目录，检查并保留当前改动，续接任务，暂存，本地提交，以及禁止的 Git 操作 |
| `third-party-generated-and-temporary-files.md` | 涉及第三方（vendor）、生成、`.import`、缓存、备份、草稿或临时文件 |
| `validation-policy.md` | 组合多项验证关卡、判断证据是否充分，或运行 Godot 编辑器检查 |
| `completion-and-reporting.md` | 准备任务的最终汇报 |
| [technical-documentation-writing-godot](../../.agents/skills/technical-documentation-writing-godot/SKILL.md) | 编写、更新或整理项目文档。按文档类型读取该 Skill 中匹配的参考。它的写作指导不改变 `docs/` 文件的字段规则，也不改变 `methodology/` 规定的流程步骤。 |

核心规则定义跨领域的不变约束。专项模块在更窄的领域内细化这些规则，但不会悄悄取消与之无关的核心义务。
