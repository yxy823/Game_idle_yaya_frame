# Windows 编辑器检查

本页适用于在本机 Windows 的 Codex 受限沙箱中运行 Godot 编辑器检查（包括 `--headless --editor`）。在其他机器上，先检查实际的权限和目录行为。本页不要求每个 Feature 都启动编辑器。

- 编辑器检查通过 `require_escalated` 审批在沙箱外运行。审批被拒绝或不可用时，把这项检查汇报为未执行或被阻塞，不绕过审批。
- 输出出现 `Could not create editor data directory` 或 `Could not create editor config directory`，或访问 `AppData/Roaming/Godot` 失败时，调查环境权限。停止依赖这次运行的后续验证，不汇报为通过，也不因此修改业务代码或削弱检查。
- 检查前后对比项目根目录的列表，包括 Git 不跟踪的空目录。出现 `export_templates`、`feature_profiles`、`script_templates`、`text_editor_themes` 等意外目录时，先查明来源。只清理确认由这次运行创建的空目录，保留事先已存在的同名目录。
