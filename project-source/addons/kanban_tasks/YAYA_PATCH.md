# Kanban Tasks 的 Yaya 补丁

上游版本为 HolonProduction/godot_kanban_tasks `2.1`。
固定源码为 `3ca60d25e37da0eefa4c470b79bc1f44bc255ad5`。
`plugin.cfg` 保留上游版本号，本文件说明额外的本地补丁。
保留原始 MIT 许可证 `LICENSE` 和 `uuid/LICENSE`。

## 修改的文件与原因

- `plugin.gd`：退出时释放 `help_menu`，修正再次释放 File 菜单的错误。销毁插件创建的 `PluginSingletons` 容器，清理编辑上下文与快捷键节点。
- `view/edit_context.gd`：编辑上下文销毁时显式释放 `UndoRedo`，避免退出泄漏。

## 升级时保留补丁

1. 对照固定源码、本地修改和新上游版本。
2. 逐项确认上游是否修复上述问题。
3. 上游已修复时，验证后采用上游实现。
4. 尚未修复且仍可复现时，保留对应处理。
5. 核对菜单、容器与 `UndoRedo` 的释放，再更新本文件。

验证在外部项目中覆盖启用、停用和退出。保留许可证，不直接用上游目录覆盖仍需保留的修改。
