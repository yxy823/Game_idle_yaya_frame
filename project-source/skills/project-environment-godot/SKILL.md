---
name: project-environment-godot
description: 配置、更新或恢复 Godot 项目的工具路径，或执行项目首次的 Godot 资源扫描。用于用户要求准备环境、某个工具移动了位置或换了版本、已配置的工具无法启动的情况。不用于创建项目、修复游戏行为、运行通用的验证套件，或升级 Godot 补丁版本与插件（engineering-change-plan）。
---

# 维护项目环境

准备或修复本项目运行所用的工具。配置和 Bootstrap 步骤由[项目环境](../../../yaya/methodology/06-project-environment.md)规定；本 Skill 执行这些步骤，不增加其他准备流程。环境工作不需要 GDD，也不创建 Feature 或 Stage。

## 按当前需要阅读对应章节

| 当前需要 | 阅读并执行 |
| --- | --- |
| 新项目首次准备 | **工具配置** 和 **项目环境准备**。默认文档语言已经设置好；只有用户要求使用其他语言时，才阅读[语言选择](../../../yaya/methodology/05-document-language.md#3-选择语言) |
| 某个工具移动了位置或换了版本 | 先读 **工具配置**，再运行下面「用真实输出检查」中的就绪检查。保留无关的设置和仍然有效的准备结果。Godot 换成新的补丁版本或升级插件时，按 `yaya/methodology/07-engineering-change.md` 的 **引擎与插件升级** 作为维护 Feature 进行；本 Skill 只承担其中修改路径和就绪检查这一步 |
| 已配置的工具无法启动 | **工具配置**：报告实际的失败；只在用户要求的范围内修改路径 |
| 需要首次导入和类扫描 | **项目环境准备** 的第 2 步，以及[首次 Godot 扫描](../../../yaya/tools/README.md#首次-godot-扫描) |

如果编辑器或导入过程会在 worktree 内写入文件，而你不清楚它写到哪里、怎样清理，先阅读 [Godot worktree 运行准备](../worktree-create-godot/references/godot-worktree-runtime.md)。阅读它不会创建 worktree。

## 用真实输出检查

- 用配置里的 Python 运行就绪检查：`python -B yaya/tools/checks/check-project-environment.py --require-ready`。不带 `--require-ready` 只检查配置结构，不能说明工具可用。根据检查器的实际输出判断是否就绪，不要根据填好的路径或已存在的文件判断。
- 检查失败时，不要自行重建项目、安装依赖或更换工具。报告这次失败。
- 已完成的首次扫描直接复用。不要增加定期导入的步骤，也不要用清除缓存来掩盖失败。

## 报告并返回

只做用户要求的配置或准备修改，并运行对应的检查。如果配置了路径，但首次扫描留到以后，要说明这一点。

按 **项目环境准备** 的说明，把结果记录到 `reports/initialization.md` 和 Progress。按 `AGENTS.md` 的 **Git 与提交** 提交，包括用户设定的提交条件。

返回修改了什么、实际检查了什么，以及剩余的阻塞。检查通过只说明工具可用，不说明测试通过或游戏能正常运行。如果本 Skill 是从另一个已授权的任务中调用的，继续那个任务；环境准备成功不代表那个任务已完成。
