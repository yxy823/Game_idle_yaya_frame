---
name: feature-execute
description: >-
  执行一个已规划的 Feature（执行批准在 Stage 1 取得）：测试影响评估、TDD/验证、适用的人工验收、用户要求时的独立审核和完成。还有其他已获授权的工作时，返回调用它的流程。英文触发：execute next feature, implement <Feature ID>, continue feature。中文触发：执行下一个 Feature、实现 <Feature ID>、继续当前 Feature。
---

# 执行下一个 Feature

## 步骤

先检查相关来源的变化并处理它们的影响，再执行依赖这些来源的工作。`yaya/methodology/03-execute-loop.md` 是 Stage 0–8 唯一的执行步骤，包括其中的通用约定、批准材料、证据命令、异常处理和已授权的续接。先阅读通用约定和当前 Stage，然后按顺序执行每个适用的 Stage。恢复工作时，根据 Feature/Progress 的实际状态和当前证据找到下一个必须的动作；不要重做已完成的工作，也不要重复读取没有变化的上下文。

| 决定或动作 | 依据 |
| --- | --- |
| 选择当前的 Product/Feature | `yaya/methodology/03-execute-loop.md` 的 **Stage 0 · 选择 Feature 并加载上下文**，Product 顺序见 methodology 02 的 **逐个 Product 规划** |
| 阅读适用的实现规则和知识 | 项目 `AGENTS.md` 及其按任务划分的入口 |
| 为已有 Feature 准备需要的实施指导 | [implementation-guidance](../implementation-guidance/SKILL.md)；是否委派顾问由它的“明确要求”约定决定，设计稿的生命周期由 methodology 03 的 Stage 1C、2 和 3 负责 |
| Feature 涉及有命名状态、并按事件或时间转换的行为 | [behavior-model-check](../behavior-model-check/SKILL.md)；适用条件和调用时机见 methodology 03 的 Stage 1C |
| 确定文档语言或准备环境 | `yaya/methodology/05-document-language.md` 或 `yaya/methodology/06-project-environment.md`，以及当前的 `docs/methodology-config.json` |
| 规划测试、清理过时测试或选择运行范围 | `yaya/methodology/08-test-traceability-and-evidence.md` 中的相关小节 |
| 写入 Feature、测试登记表或完成字段 | `yaya/methodology/02-feature-list-schema.md` 中对应产物的约定 |
| 直接执行解析/lint | `yaya/methodology/contracts/gdscript-lint.md` |
| 记录 Bug 诊断和经验 | `yaya/methodology/07-engineering-change.md` 和 `yaya/methodology/03-execute-loop.md` 的 Stage 5.5 |
| 归档执行记录或记录架构决定 | `yaya/methodology/09-records-reports-and-handoff.md`，适用时还有 `yaya/methodology/10-architecture-overview.md` |
| 使用专业来源、辅助性的专业工作或补充证据 | `yaya/methodology/11-specialist-workflows.md` |
| 执行用户要求的独立审核 | Stage 6 和 `yaya/methodology/12-independent-review.md`；审核方法在单独的 Skill 中 |

可选的 Stage 6 审核和全部完成条件都由 `yaya/methodology/03-execute-loop.md` 负责。本 Skill 不提供另一套检查顺序或证据格式。项目命令 `yaya/tools/features/record-feature-completion.py` 记录并校验那里描述的证据；它不负责实现、测试或审核。

到 Stage 8 时，报告已完成的 Feature 和下一个动作。完成后返回调用方；Skill 返回不会结束它所服务的已授权任务（methodology 03 **授权与续接**）。
