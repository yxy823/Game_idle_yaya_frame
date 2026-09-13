# 框架维护约定

本机环境与审批遵循当前生效的个人规则；文本格式以 [.editorconfig](.editorconfig)、[.gitattributes](.gitattributes) 为准。

## 查阅与适用范围

| 当前工作 | 执行依据 |
| --- | --- |
| 文件放置与项目创建 | 遵循 [根 README](README.md) 的目录职责、复制边界与项目独立性约定。 |
| 修改空白项目 | 先读 [使用手册](framework/docs/blank-project/README.md)，再按 [维护与同步说明](framework/docs/blank-project/maintenance/updating-the-blank-project.md) 查阅受影响专题、核对源材料并同步说明。 |
| 维护任务提示词 | 遵循 [提示词管理](framework/README.md#提示词) 的存放、分类与使用范围。 |
| 审核及后续讨论 | 按 [外部结果复核](framework/docs/blank-project/maintenance/updating-the-blank-project.md#复核外部审核结果与讨论取舍)、[会话延续](framework/docs/blank-project/maintenance/updating-the-blank-project.md#后续用口语继续) 区分报告意见、事实证据与实施授权。 |
| 机制取舍 | 对照 [README 的维护目标](README.md)、[设计判断依据](framework/review/design-quality.md#可重复使用的判断依据) 评估。 |
| 选择验证 | 检查范围按 [验证范围说明](framework/docs/blank-project/maintenance/updating-the-blank-project.md#按修改选择验证范围)，确切命令见 [按需检查](framework/README.md#按需检查)。 |

## 修改约定

流程与测试规则以权威规范为唯一正文，其他入口仅保留引用、必要步骤和使用示例；整理文档或文件名不得顺带改变 Skill 行为。

改名应体现领域与职责；调整路径或字段时，追到全部读写方及其调用链、复制映射与回归夹具，核对生成后的路径和语义一致，不留下仅部分工具支持的选项。

在已指定的外部项目运行回归前，核对被测文件是否对应本次修复；需要同步时仅更新授权范围内的具体文件，保留目标项目的机器配置与无关内容。

## 本地提交

任务修改开始前与提交后执行 `git status --short`，核对已有差异和最终状态；只暂存本次明确路径或已检查的差异块，保留无关改动。

获准的文件修改完成后，除非用户明确要求不提交，否则自动创建本地提交；独立逻辑变更分别提交，同一根因且必须一起完成的改动可以合并。

提交前完成与改动相称的验证，检查 `git diff --cached --check`、`git diff --cached --stat` 和完整的 `git diff --cached`；已完成且仍适用于最终内容的验证可以沿用。

提交主题采用 `<type>(<scope>): <中文摘要>`，说明实际行为变化；非简单修改在正文说明原因、关键取舍与真实验证结果。

不使用 `--no-verify`，不自动执行 push、tag、amend、rebase、reset 或修改远程配置。
