# 框架维护进度

更新日期：2026-09-22。

本文件记录框架自身的当前成果、验证缺口、未决事项与下一步，只留在维护仓库。
执行与更新边界见 [根 AGENTS.md](../AGENTS.md#维护边界与查阅)；条目用于续接，不授予实施权限。
详细变更保留在 Git，验证详情链接已有报告；实际游戏任务使用各自项目的 Progress。

## 当前工作与后续完善

| 事项 | 当前情况 | 下一步或完成条件 | 依据 |
| --- | --- | --- | --- |
| 模式选型与地图导航 | 已完成 A＋B 的设计建议收敛与地图导航维护；本轮已补充地图中的关键理由与已有设计来源链接 | 继续已批准的 agent-rules 纠错说明与 review-code 设计判断提醒；C 的动态效果验证仍待单独决定 | [项目规则模板](../project-source/methodology/templates/project-rules.md.tmpl)、[架构规范](../project-source/methodology/10-architecture-overview.md) |
| 审核修复与入口整理 | 已实现 1600×900 项目默认值、single/composition 独立目录入口；修复内存/并发预算、A/B 条件与 STALE、共同 Schema/缓存恢复和源能力预检；边界压力、变异、引擎回归及渲染已验证 | 用户实际体验两个入口、分析/批量窗口及按钮布局；设计讨论沿用现有 UI 规格与 Godot 原型入口 | [本轮修复与验证](review/reports/asset-workbench-audit-fixes-2026-09-21.md) |
| 美术与音频资源工作台 | 首期已实现，用户在第二阶段实施请求中明确确认已通过验收；保留预览、播放、试调与保存边界 | 后续修改继续回归第一阶段；真实项目接入自身对象/事件时仍需按实际场景验证 | [首期实现与反馈复验](review/reports/asset-workbench-implementation-validation-2026-09-21.md) |
| 外部专业 Analyzer | 第二阶段基础链路及本轮审核修复已实现；Analyzer v2 采用流式/分块统计、Windows worker 限额、兼容性检查、共用 Schema 和语义缓存恢复，后端依赖版本保持不变 | 用户接受分析窗口；预算外响度/大图精确色数明确不支持，高级音频与最终混音/画面测量按需求另行评估 | [初次实施](review/reports/asset-analyzer-phase2-2026-09-21.md)、[当前验证](review/reports/asset-workbench-audit-fixes-2026-09-21.md) |
| 第三阶段与组合场景 | 分组、有界发现、批量分析、可比统计、规则与历史已实现；三对象组合现为独立目录和入口，自身复用属性、A/B、保存与源分析；与单对象入口不互相切换 | 用户实际体验组合交互与批量操作；后续按场景决定属性适配、聚类或历史趋势，不把示例称为通用场景编辑器 | [第三阶段实施](review/reports/asset-workbench-phase3-2026-09-21.md)、[当前入口与回归](review/reports/asset-workbench-audit-fixes-2026-09-21.md) |
| 框架可复制与流程验证 | 已完成源材料隔离检查、独立项目初始化、工具回归、实际 Godot 运行与第二路径无缓存重建；空白源状态保持不变 | 按既有动态审核入口在明确项目执行一个新的微型需求到 Feature 完成记录全过程；不将本次工作台维护回归当作全部流程已验证 | [分层验证方式](docs/blank-project/maintenance/validating-framework.md)、[当前证据与限制](review/reports/asset-workbench-implementation-validation-2026-09-21.md) |
| researcher 实际使用验证 | 角色、复制映射、报告约定及回归已完成；anysearch 曾由子 Agent 实际搜索与抽取成功，新角色的客户端加载与完整委派尚未实测 | 在实际项目核实角色是否加载、按任务委派、返回来源并按需写报告；分别记录配置验证与实际委派结果 | [researcher](../project-source/agents/researcher.toml)、[调研使用说明](docs/blank-project/guides/project-knowledge.md#按需搜索与保存调研) |
| 手册阅读体验 | 当前构建覆盖 22 篇文档、33 张 Mermaid、480 个源链接；尚缺对应内容的外部排版与交互验收 | 用户在外部检查导航、正文定位、图表、设计取舍、架构地图及工作台入口/布局讨论章节；按实际问题修正，不用构建成功替代视觉接受 | [阅读版](docs/blank-project/blank-project-handbook.html)、[维护说明](docs/blank-project/maintenance/updating-the-blank-project.md#阅读版交互维护原则) |
| wayfinder 借鉴 | 用户已要求暂缓；尚未采纳整体方案 | 用户重新选择讨论范围后，针对真实问题评估；不因列入本文自动实施 | 本会话已确认的暂缓决定 |

## 最近完成

| 日期 | 成果 | 验证范围与记录 |
| --- | --- | --- |
| 2026-09-22 | 地图模板补充关键设计理由与 Feature 设计/notes/ADR 来源链接，保留当前结构与历史设计的分工 | 对照既有设计归属静态核对；手册构建为 22 篇文档、33 张图、480 个源链接。未执行项目测试、Godot 或动态效果验证 |
| 2026-09-21 | 完成外部意见复核后获准的模式选型收敛与地图导航修订；地图维护复用 Stage 3D，补充路径和入口变动，不新增流程机制 | 两个 Skill 静态校验、源材料与 advisor/复制映射衔接、链接/锚点和 Git 差异核对通过；手册构建为 22 篇文档、33 张图、478 个源链接。未执行项目测试、Godot 或动态效果验证；阅读体验仍待用户外部检查 |
| 2026-09-21 | 修复第二阶段审核问题；统一 1600×900 默认值，拆分单对象/组合入口，补充布局讨论导航 | 后端 22、Godot 分析 18、单对象 12、组合 7、分组 12、维护 38 项通过；边界资源内存与 Windows 限额实测通过；37 文件 lint 0 Critical/Warning；真实渲染已查看，人工体验仍待用户。见 [报告](review/reports/asset-workbench-audit-fixes-2026-09-21.md) |
| 2026-09-21 | 分组批量分析、解释性规则/历史与三对象交互组合示例；工作台独立窗口按屏幕优先 1600×900 | 分组 12、组合 6、分析回归 12、首期回归 12、维护 38 项通过；lint 34 文件 0 Critical/Warning。浅/深色与小窗滚动渲染检查通过，人工体验待用户；见 [报告](review/reports/asset-workbench-phase3-2026-09-21.md) |
| 2026-09-21 | 外部 Analyzer 第二阶段、明确版本/许可、可替换适配器与工作台指标/图表 | 后端 17、引擎分析 12、首期回归 12、维护 38 项通过；Godot lint 22 文件 0 Critical/Warning；真实 A/B 与浅/深色、小窗滚动渲染已检查。新界面人工接受待用户；见 [实施报告](review/reports/asset-analyzer-phase2-2026-09-21.md) |
| 2026-09-21 | 修复工作台小窗口访问与示例 A/B 比较，明确 Analyzer 尚未接入 | 指定项目 Godot 4.7.1：12 项通过，四个改动脚本解析通过，lint 0 Critical/0 Warning；1152×648、900×540、720×480 渲染与滚动可达检查通过。未将命令行音频诊断或旧版第二路径结果当作 Analyzer/本次迁移通过 |
| 2026-09-21 | 首期工作台、可移除示例与分层验证说明 | 维护 38 项、项目工具 159 项；两个路径的 Godot 行为各 11 项通过，10 个自有脚本解析成功，lint 0 Critical/0 Warning。渲染截图已检查，主观验收待用户；见 [报告](review/reports/asset-workbench-implementation-validation-2026-09-21.md) |
| 2026-09-21 | 已有提交 `7f86f60` 明确失败结果与异步操作有效期；`2c27cb7` 补充调用方复杂度的设计与评审判断 | 已从当前 Git 历史和相关规则核对；本次未重新执行其验证，原范围以对应提交为准 |
| 2026-09-21 | `8dbc9fb` 新增按需 researcher、搜索回退、明确版本与调研报告约定；anysearch 保持用户级安装 | 该轮 24 项 unittest 通过，advisor 导出检查通过；手册构建覆盖 20 篇文档、32 张图和 459 个源链接。记录见 [场景基线](review/baselines/scenario-coverage.md)，不作为此后所有修改的验证结果 |
| 2026-09-21 | `84a5136` 建立本进度文档及根规则中的更新入口 | 内容、本地链接、锚点与 UTF-8/LF 静态核对通过；复制清单未包含本文件，不增加自动 Hook 或任务状态机 |

## 持续观察

规则阅读成本、验证工具的维护成本及说明同步成本沿用
[设计复盘](review/baselines/design-quality.md#可重复使用的判断依据)；出现实际问题后再形成具体改进项。
美术、音乐和音效制作仍是 [预留能力](../project-source/methodology/11-specialist-workflows.md#design-production-integration-and-review)，
工作台提供预览与试调，不表示这些制作能力已经实现。
