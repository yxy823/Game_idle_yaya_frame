# Feature 已能体验，需要准备人工验收清单

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

F01-012 的背包界面已经实现完、代码不再改动，它的验收模式是 manual，需要一份清单让你按步骤实际体验。

需要的材料：

- Feature ID（可空）：不提供时用当前对话中正在执行的 Feature。
- 体验入口（可空）：从哪个场景或菜单进入、需要的初始存档或参数；不知道时由 Agent 从实现查找。Feature 涉及调试台（视觉决策或调参）时，入口是调试入口与固定局面，启动命令直接引用项目 `dev/debug/README.md` 中那一条。

人工检查项（`manual_checks`、`manual_regression`）由 Agent 从 Feature 直接读取。

## 前置条件与适用范围

实现已稳定且可体验，需要生成待用户填写的当前版本清单。

## 执行步骤

使用[预设提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 审核与人工验收 → Feature 已能体验，需要准备人工验收清单”。填入上述材料。本页由当前 Agent 使用项目自己的 [$manual-acceptance](<../../../../../project-source/skills/manual-acceptance/SKILL.md>)，链接指向框架中的源文件，仅供核对。

**S1｜核对人工义务**

当前 Agent 按人工验收文件契约的[定义与准备](<../../../../../project-source/methodology/contracts/manual-acceptance-files.md#定义与准备>)核对 Feature 的 `verification.acceptance_mode` 和全部 `manual_checks`、`manual_regression`，不给 automated 任务生成空清单。

**S2｜编写待验清单**

按[定义与准备](../../../../../project-source/methodology/contracts/manual-acceptance-files.md#定义与准备)选择清单路径与轮次命名。用 `yaya/methodology/templates/manual-acceptance-checklist.json.tmpl` 写清单，全部 status 为 `pending`，写明入口、初始条件、实际动作、预期和重置；涉及调试台时，检查项针对采纳后的游戏原值，不针对插槽预设或组合；Feature notes 链接清单，不复制步骤。

**S3｜绑定版本并交付**

用配置 Python 调用 yaya/tools/features/record-feature-completion.py prepare-manual --feature <ID> --checklist <清单路径>，给出可点击路径及返回方式。

项目工具命令的使用要求：

- 工作目录：实际游戏项目根目录。
- Python 与调用形式：使用 `docs/methodology-config.json` 中的 `python_executable`，按 `& $projectPython -B <脚本路径> <参数>` 调用，每次立即检查 `$LASTEXITCODE`。
- 参数：尖括号参数替换为实际值。
- 结果边界：命令成功只证明该操作完成。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 要覆盖的人工检查项清单已列出 |
| S2 | 清单文件已写好，每项都有 `source_ref` 且为 `pending`；Feature notes 已链接清单 |
| S3 | `prepare-manual` 退出码为 0，清单的 `snapshot` 已填入 |

## 资源与文件影响

写入清单，`prepare-manual` 在清单的 `snapshot` 中绑定当前版本；Feature notes 增加清单链接。不写完成证据，不记录接受。

## 阻塞、异常与范围变化

内容仍在变化时先稳定实现；生成样本不能预填 passed。

## 完成状态与验证标准

覆盖完整的 pending 清单已绑定当前版本并可供实际体验。

## 流程关联与衔接关系

依据：人工验收文件的[定义与准备](<../../../../../project-source/methodology/contracts/manual-acceptance-files.md#定义与准备>)、[Stage 4 · 自动验证与人工验收清单](<../../../../../project-source/methodology/03-execute-loop.md#stage-4--自动验证与人工验收清单>)。
