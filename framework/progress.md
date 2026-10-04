# 框架待办

## 三消 Demo 实测问题修复

- **待人工确认**：Godot 编辑器开着时 Agent 修改了 `project.godot`，编辑器窗口重新获得焦点时会不会提示“文件已在外部修改”。自动化无法测试，需要用户在编辑器中试一次；结果决定 [tools README](../project-source/tools/README.md#resave_godot_filesgd) 中“先重新加载当前项目”的提醒是否需要调整。
- **临时材料**：本机工作清单 `tmp/match-three-validation/`（问题清单、步骤记录、提示词）在用户确认不再需要后删除。

## Godot 项目手册补充教程线

- **问题**：[Godot 项目手册](godot-project-manual/README.md)目前以按专题查阅的参考页为主，缺少带着读者从创建项目一路做到第一个 Feature 完成的递进式教程。
- **下一步**：结合一个已按框架开发的实际项目编写，再确定章节、目录位置和示例内容。教程只写步骤和当时为什么这样做，规则正文链接到现有参考页。
- **待决定**：使用哪个实际项目作为素材。

## 生成项目的框架目录收拢

- **问题**：生成项目根目录里，框架自带的 `methodology/`、`agent-rules/`、`tools/`、`asset_workbench/` 与游戏内容平铺在一起。
- **下一步**：框架审核已合并回 `main`；在最新基础上把这四个目录移到 `yaya/` 下，同步复制清单、`res://tools/` 与 `res://asset_workbench/` 引用、Python 工具的根目录推算以及全部文档、提示词与测试中的路径，用链接检查和仓库回归核对。不兼容已创建的项目。
- **待决定**：`reports/` 是否一并移入。
