# 框架维护进度

更新日期：2026-09-21。

本文件记录框架自身的当前成果、验证缺口、未决事项与下一步，只留在维护仓库。
执行与更新边界见 [根 AGENTS.md](../AGENTS.md#维护边界与查阅)；条目用于续接，不授予实施权限。
详细变更保留在 Git，验证详情链接已有报告；实际游戏任务使用各自项目的 Progress。

## 当前工作与后续完善

| 事项 | 当前情况 | 下一步或完成条件 | 依据 |
| --- | --- | --- | --- |
| 美术与音频资源预览、分析与调试工作台 | 正在审核用户提供的 40 节设计方案；本次仅审核，尚未实现 | 核对现有流程、音频插件和 Godot 约束，给出保留、修改、延后内容；实施前确定目标项目、代表性事件与写回位置 | [原型规范](../project-source/methodology/01-product-doc-structure.md#visual-prototype-before-dependent-implementation)、[专业职责](../project-source/methodology/11-specialist-workflows.md) |
| researcher 实际使用验证 | 角色、复制映射、报告约定及回归已完成；anysearch 曾由子 Agent 实际搜索与抽取成功，新角色的客户端加载与完整委派尚未实测 | 在实际项目核实角色是否加载、按任务委派、返回来源并按需写报告；分别记录配置验证与实际委派结果 | [researcher](../project-source/agents/researcher.toml)、[调研使用说明](docs/blank-project/guides/project-knowledge.md#按需搜索与保存调研) |
| 手册阅读体验 | 已有离线阅读版和构建检查；尚缺本会话对应内容的外部排版与交互验收 | 用户在外部检查当前阅读版的导航、正文定位、图表与调研章节；按实际问题修正，不用构建成功替代视觉接受 | [阅读版](docs/blank-project/blank-project-handbook.html)、[维护说明](docs/blank-project/maintenance/updating-the-blank-project.md#阅读版交互维护原则) |
| wayfinder 借鉴 | 用户已要求暂缓；尚未采纳整体方案 | 用户重新选择讨论范围后，针对真实问题评估；不因列入本文自动实施 | 本会话已确认的暂缓决定 |

## 最近完成

| 日期 | 成果 | 验证范围与记录 |
| --- | --- | --- |
| 2026-09-21 | 已有提交 `7f86f60` 明确失败结果与异步操作有效期；`2c27cb7` 补充调用方复杂度的设计与评审判断 | 已从当前 Git 历史和相关规则核对；本次未重新执行其验证，原范围以对应提交为准 |
| 2026-09-21 | `8dbc9fb` 新增按需 researcher、搜索回退、明确版本与调研报告约定；anysearch 保持用户级安装 | 该轮 24 项 unittest 通过，advisor 导出检查通过；手册构建覆盖 20 篇文档、32 张图和 459 个源链接。记录见 [场景基线](review/baselines/scenario-coverage.md)，不作为此后所有修改的验证结果 |
| 2026-09-21 | 建立本进度文档及根规则中的更新入口 | 内容、本地链接、锚点与 UTF-8/LF 静态核对通过；复制清单未包含本文件，不增加自动 Hook 或任务状态机 |

## 持续观察

规则阅读成本、验证工具的维护成本及说明同步成本沿用
[设计复盘](review/baselines/design-quality.md#可重复使用的判断依据)；出现实际问题后再形成具体改进项。
美术、音乐和音效制作仍是 [预留能力](../project-source/methodology/11-specialist-workflows.md#design-production-integration-and-review)，
工作台方案的讨论不表示这些制作能力已经实现。
