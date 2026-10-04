# 00 核心规则

核心规则适用于所有文件类型。做修改或相关的工程决定时，先用下表找到要读的文件，只读与任务匹配的小节。普通的状态或用词讨论不需要加载工程规则。

| 文件 | 何时阅读 |
| --- | --- |
| `windows-godot-sandbox.md` | 在本机 Windows 的 Codex 受限沙箱中启动任何 Godot 进程（编辑器检查、gdUnit 测试、脚本解析、lint）之前，或 Godot 在沙箱中崩溃、报证书库错误时 |
| `rule-precedence-and-routing.md` | 同时适用多个模块、规则看起来冲突，或怀疑某条规则有错 |
| `godot-version-and-authority.md` | 行为与 Godot 或工具版本有关且不确定、评估升级，或文档与实际运行不一致 |
| `godot-resource-references.md` | 选择或修改业务 ID、Resource UID、资源路径、NodePath、`%UniqueName` 或场景引用 |
| `third-party-generated-and-temporary-files.md` | 涉及 `addons/` 或其他第三方文件、生成文件、`.import`、`.godot/`、备份或临时文件 |

任务范围、Git 与提交、验证与完成汇报对每个修改任务都适用，写在 [AGENTS.md](../../AGENTS.md#任务范围)。
