# Codex 沙箱中运行 Godot

本页适用于在本机 Windows 的 Codex 受限沙箱中启动任何 Godot 进程：编辑器检查（包括 `--headless --editor` 和资源扫描）、gdUnit 测试运行器、`--check-only` 脚本解析、lint CLI，以及运行游戏或场景。在其他机器或其他执行环境中，先检查实际的权限和目录行为。本页不要求每个 Feature 都启动编辑器。

- 这些命令都通过 `require_escalated` 审批在沙箱外运行。受限沙箱里的 Godot 即使能启动，也可能读不到用户数据目录或系统证书库，结果不可信。审批被拒绝或不可用时，把这项检查汇报为未执行或被阻塞，不绕过审批。
- 环境检查 `check-project-environment.py --require-ready` 只运行 `--version`。它在沙箱里通过，不代表 Godot 能在沙箱里运行脚本和测试。

## 沙箱故障的特征

出现下列输出时，停止依赖这次运行的后续验证，不汇报为通过，也不因此修改业务代码或削弱检查；申请提权后重新运行。

| 输出 | 已观察到的原因 |
| --- | --- |
| 进程以 signal 11 崩溃，或退出码为 `0xC0000005`（十进制 `3221225477` 或 `-1073741819`） | 沙箱内无法访问 Godot 的用户数据目录；开放该目录后不再崩溃 |
| `Failed to read the root certificate store.` | 沙箱阻止读取系统证书库；测试运行器把这条错误判为失败 |
| `Could not create editor data directory`、`Could not create editor config directory`，或访问 `AppData/Roaming/Godot` 失败 | 沙箱阻止写入编辑器的数据和配置目录 |

## 编辑器运行后的检查

运行编辑器检查前后，对比项目根目录的列表，包括 Git 不跟踪的空目录。出现 `export_templates`、`feature_profiles`、`script_templates`、`text_editor_themes` 等意外目录时，先查明来源。只清理确认由这次运行创建的空目录，保留事先已存在的同名目录。
