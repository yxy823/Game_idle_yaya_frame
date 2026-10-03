# Feature 已能体验，需要准备人工验收清单

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

Feature 已能体验，需要准备人工验收清单。

需要的材料：

- 任务与人工义务：manual Feature、批准的 manual_checks 与必要 manual_regression。
- 体验入口：运行入口。

## 前置条件与适用范围

实现已稳定且可体验，需要生成待用户填写的当前版本清单。

## 执行步骤

使用[集中提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 验证与收尾 → Feature 已能体验，需要准备人工验收清单”。填入上述材料。本页由当前 Agent 使用项目自己的 `manual-acceptance-godot` Skill；[源码入口](<../../../../../project-source/skills/manual-acceptance-godot/SKILL.md>)仅供核对。

**S1｜核对人工义务**

当前 Agent 按 manual-acceptance-files.md 检查全部人工 AC 和回归，不给 automated 任务生成空清单。

**S2｜编写待验清单**

在 reports/manual-acceptance/ 写 pending JSON，说明入口、初始条件、实际动作、预期和重置。

**S3｜绑定版本并交付**

用配置 Python 调用 tools/features/record-feature-completion.py prepare-manual --feature <ID> --checklist <清单路径>，给出可点击路径及返回方式。

项目工具命令的使用要求：

- 工作目录：实际游戏项目根目录。
- Python 与调用形式：使用 `docs/methodology-config.json` 中的 `python_executable`，按 `& $projectPython -B <脚本路径> <参数>` 调用，每次立即检查 `$LASTEXITCODE`。
- 参数：尖括号参数替换为实际值。
- 结果边界：命令成功只证明该操作完成。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 清单范围对应真实人工义务 |
| S2 | 用户可按步骤实际体验 |
| S3 | 清单绑定当前稳定内容 |

## 资源与文件影响

当前 pending 清单和完成记录中的必要版本绑定会写入；不记录接受。

## 阻塞、异常与范围变化

内容仍在变化时先稳定实现；生成样本不能预填 passed。

## 完成状态与验证标准

覆盖完整的 pending 清单已绑定当前版本并可供实际体验。

## 流程关联与衔接关系

依据：[项目路由依据](<../../../../../project-source/methodology/00-overview.md>)、[测试与证据规范](<../../../../../project-source/methodology/08-test-traceability-and-evidence.md>)、[人工验收文件契约](<../../../../../project-source/methodology/contracts/manual-acceptance-files.md>)。
