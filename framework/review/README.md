# 框架复盘材料

本目录区分持续维护的基线与一次检查的历史记录，均不进入生成项目。

| 位置 | 用途 |
| --- | --- |
| [baselines/design-quality.md](baselines/design-quality.md) | 设计判断依据、当前结构与需要继续观察的成本 |
| [baselines/skill-script-prompt-design.md](baselines/skill-script-prompt-design.md) | Skill、脚本与提示词的长期职责准则、场景同名目录契约和全量审核要求 |
| [baselines/scenario-coverage.md](baselines/scenario-coverage.md) | 场景职责、静态覆盖依据及集中提示词用途清单 |
| `reports/` | 按次保留的审核、导入或运行验证报告，文件名说明主题与日期；旧结果不证明当前版本通过 |

已有报告：

- 2026-09-27 提示词字段与全库静态审核：[框架维护、创建、需求与规划 58 条](reports/prompt-fields-review-a-2026-09-27.md)、[修复、工程、验证与恢复 66 条](reports/prompt-fields-review-b-2026-09-27.md)。逐条核对正文、同名场景与必要来源，不代表逐条实际执行。
- [2026-09-25 职责重构与新项目实际验证](reports/framework-implementation-validation-2026-09-25.md)：实施与外部项目运行结果；独立审核包括 [Skill 与工具](reports/skill-tool-implementation-review-2026-09-25.md)、[提示词与场景](reports/prompt-scenario-implementation-review-2026-09-25.md)、[手册迁移](reports/manual-migration-review-2026-09-25.md)和[实际验证证据](reports/validation-evidence-review-2026-09-25.md)。
- [2026-09-25 职责准则与子智能体全量审核汇总](reports/responsibility-audit-summary-2026-09-25.md)：[27 个 Skill](reports/skill-responsibility-audit-2026-09-25.md)、[55 个工具脚本及模块](reports/script-responsibility-audit-2026-09-25.md)、[50 条提示词与 8 篇样稿](reports/prompt-scenario-responsibility-audit-2026-09-25.md)。
- [2026-09-22 编码规范与审核体系局部修复](reports/coding-review-system-fixes-2026-09-22.md)
- [2026-09-22 Shader 接入与独立资源组合验证](reports/asset-workbench-shader-composition-2026-09-22.md)
- [2026-09-22 工作台编码规范修复与实际验证](reports/asset-workbench-code-quality-fixes-2026-09-22.md)
- [2026-09-21 工作台第三阶段与交互组合场景](reports/asset-workbench-phase3-2026-09-21.md)
- [2026-09-21 外部 Analyzer 第二阶段](reports/asset-analyzer-phase2-2026-09-21.md)
- [2026-09-21 美术与音频工作台首期实现与复制验证](reports/asset-workbench-implementation-validation-2026-09-21.md)
- [2026-09-21 美术与音频工作台设计适配审核](reports/asset-workbench-design-review-2026-09-21.md)
- [2026-09-20 外部审核修复验证](reports/workflow-audit-validation-2026-09-20.md)
- [2026-09-20 实际导入验证](reports/import-validation-2026-09-20.md)
- [2026-09-14 空白项目动态验证](reports/blank-project-dynamic-validation-2026-09-14.md)

报告的范围、原始证据和未验证项以各次记录为准；正式使用流程仍以源规范及[使用手册](../docs/README.md)为准。
