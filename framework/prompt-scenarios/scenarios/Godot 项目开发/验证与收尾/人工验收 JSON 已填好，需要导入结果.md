# 人工验收 JSON 已填好，需要导入结果

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

人工验收 JSON 已填好，需要导入结果。

需要的材料：

- 所属任务：Feature ID。
- 用户验收原件：未改动原清单、用户填写的结果 JSON。

## 前置条件与适用范围

用户已实际体验并返回对应原清单的结果文件。

## 执行步骤

使用[集中提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 验证与收尾 → 人工验收 JSON 已填好，需要导入结果”。填入上述材料。本页由当前 Agent 使用项目自己的 `manual-acceptance-godot` Skill；[源码入口](<../../../../../project-source/skills/manual-acceptance-godot/SKILL.md>)仅供核对。

**S1｜核对原件与结果**

当前 Agent 读取原清单、用例 ID、定义、版本、结果和注释，确认真由用户提供。

**S2｜导入实际结果**

用项目 Python 调用 tools/features/record-feature-completion.py record-acceptance --feature <ID> --result <结果路径> --checklist <原清单路径>。

**S3｜报告接受范围**

核对导入结果；有效全 passed 即为明确接受，不再重复确认；failed/pending 保留给对应处理。

项目工具命令的使用要求：

- 工作目录：实际游戏项目根目录。
- Python 与调用形式：使用 `docs/methodology-config.json` 中的 `python_executable`，按 `& $projectPython -B <脚本路径> <参数>` 调用，每次立即检查 `$LASTEXITCODE`。
- 参数：尖括号参数替换为实际值。
- 结果边界：命令成功只证明该操作完成。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 结果属于当前验收范围 |
| S2 | 工具接受合法原件与实际状态 |
| S3 | 接受与待处理范围准确 |

## 资源与文件影响

原清单和结果只读保留；当前完成证据的人工结果会更新。

## 阻塞、异常与范围变化

原件缺失、版本过期、预期被改或状态注释冲突时保留失败，只澄清具体缺口。

## 完成状态与验证标准

合法结果已保存，实际接受或失败范围明确；尚需其他完成检查不跳过。

## 流程关联与衔接关系

依据：[项目路由依据](<../../../../../project-source/methodology/00-overview.md>)、[测试与证据规范](<../../../../../project-source/methodology/08-testing-strategy.md>)、[人工验收文件契约](<../../../../../project-source/methodology/manual-acceptance-files.md>)。
