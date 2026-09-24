# Asset Workbench E5 / E6 实现与验证

日期：2026-09-22。基线为 `1aa4319`，开始时工作区干净。用户明确授权继续 E5、E6；沿用既有验证项目定向同步与真实验证授权。

## 结果与取舍

已完成场景局部播放管理器、有限片段编排、第四工作台与独立消费入口接入。E2 内容扩展与 E7 成熟整合未开展。 新内容复用已有图片、音频、Shader、粒子和动画，没有再次下载或复制外部素材；新增编排和示例代码使用 `example-` 前缀。

E4 没有证明需要全局池化，故本轮不把 Manager 包装成性能优化。它解决已选双组合案例中的对象播放归属、取消与并发取舍。 原生 AnimationPlayer 继续处理对象内部连续属性；新增播放器只调度受控 Cue 的跨对象窗口，并接入 Manager 的预算/取消句柄。 相比方法轨道任意调用，Resource 的目标、窗口和优先级可以启动前完整校验；没有再造通用属性动画系统或可视化编辑器。

| 范围 | 实际实现 |
| --- | --- |
| E5 | 场景内可选 Manager，整数句柄、分组取消、并发目标预算、严格高优先级抢占、自然完成/错误/退出释放。相同优先级满额拒绝，最低优先级相同则先抢占最早句柄；无等待队列 |
| 播放归属 | 一个句柄拥有整个 Presenter 的独占播放，待启动音频也计入活动状态。直接触发先接管受管对象，之后普通快速触发保留声音叠加；旧句柄不能误停新播放，其他 Manager 的新播放同样不会被旧句柄取消 |
| E6 | `FeedbackTimeline` / `FeedbackTimelineClip` 保存长度、相对对象路径、起点、持续时间与优先级。最多 120 s / 128 片段；同目标窗口不可重叠，可首尾相接。拒绝父级、绝对、属性路径和 `%` 别名 |
| 时间语义 | 单一场景帧时钟负责窗口开始、截止和循环；同帧先结束旧窗口，再按数组顺序申请新窗口。晚帧跳过已过窗口/循环；仍开放窗口从效果开头触发，到定义终点停止，不补算媒体历史状态 |
| 示例 | 4.8 s，A 组 → B 组 → 双核心并行，共 8 片段。工作台用对象当前 A/B，消费场景用已保存 Cue；示例预算 3 个受管对象，组件默认 8 |
| UI | 第四入口增加播放/循环编排与真实状态；固定停止仍唯一。消费场景增加受管 A 组、高优先级 B 组和取消 A 组，可直接体验抢占与作用范围 |
| 生命周期修复 | Presenter 和运动组件在 `_init()` 建立内部节点归属，避免构造后未入树即释放时遗留节点；不新增节点或池 |

窗口截止立即停止仍属其所有的效果，可能截短声音或粒子余尾。提前结束不补播；被拒绝、抢占或直接接管的窗口本轮不重试。 播放时复制定义，编辑共享定义只影响下次播放；窗口开始时读取该对象当前 Cue。Manager/Timeline 同步通知中可取消/停止，新申请或重新播放须延后调用，避免重入改变正在处理的集合。 预算只统计本 Manager 的受管对象，不统计全场景声音、粒子或显存；直接触发不受此限额约束。没有新增全局单例、池化、预加载、暂停/跳转、多轨混音或采样级同步；Shader 全局 `TIME` 不随编排重置。

## 修改范围与原有能力

| 文件/目录 | 变化 |
| --- | --- |
| `project-source/components/feedback/feedback_playback_manager.gd` | 新增局部管理器 |
| 同目录 `feedback_timeline.gd`、`feedback_timeline_clip.gd`、`feedback_timeline_player.gd` | 编排 Resource、窗口校验和运行播放器 |
| 同目录 `feedback_presenter.gd`、`feedback_motion.gd` | 待播音频计数、播放版本/受管接管、冷构造归属 |
| 同目录 `feedback_composition.gd` | 有编排时实例化管理器与播放器，接入组合停止和错误反馈；其他入口不创建两者 |
| `project-source/tools/asset_workbench/composition_panel.gd` | 编排按钮、循环选择、状态与原有停止路由 |
| `project-source/examples/asset_workbench/effects_composition/` | 新增 `example-dual-group-timeline.tres`、`example-managed-consumer.gd`，两个原场景接入；已有 Cue 和素材不改 |
| `framework/tests/project/` | 新增 Manager 15 项、Timeline 15 项、入口集成 2 项及真实渲染捕获夹具，不随项目分发 |
| README、指南、验证说明、HTML、progress | 同步使用契约、阶段状态与实际证据；正常导入生成的 5 份新脚本 `.uid` 随源文件保存 |

现有四个工作台入口保留，浏览不绑定，图像/声音/Shader/粒子独立留空，Tween 与动画变换分层不变。 对象/场景/分析 A/B 仍分开；共享 Cue 的草稿隔离、保存冲突、逐文件部分失败与重载仍由原实现负责。 保存按钮只写 Cue；编排在 Godot Inspector 中编辑/保存，工作台没有另增时间轴写回。源分析仍只测原始图像/音频。

## 本轮证据

真实引擎只在 `D:/A_Games/Game_idle_yaya_frame_workbench_test` 运行。首次同步前核对外部对应文件等于基线；只更新本轮具体文件与夹具，未改机器配置、原 Cue 或无关内容。 最终 18 份分发源文件与验证项目对应文件按换行规范化逐一相等；测试文件按职责分别复制，捕获的旧夹具仅在外部副本改输出目录。 环境为 Godot 4.7.1、Windows、RTX 4060 Laptop；Python 使用本机指定 `codex-python` 解释器。

以下相对证据路径以外部项目 `reports/asset-workbench-e5-e6-20260922/` 为根：

| 层次 | 实际结果 | 证据 |
| --- | --- | --- |
| 静态核对 | 归属/异步延迟/重入/路径边界、复制映射、使用说明、完整差异与 whitespace 检查；两名协作 Agent 参与独立风险检查，发现项由本轮修正 | 本次差异；不是另一次正式独立验收 |
| 引擎解析 | 13 份生产/测试脚本 `--check-only` 全部退出 0；后续纯 UI 行修正又经真实加载及渲染 | `parse-results.json` 与各 `parse-*.log` |
| Godot 行为 | 117/117，10 套件、22.832 s；0 errors/failures/skips/orphans。原 85 项及新增 32 项均通过；最后状态行两处换行属性由下列渲染复验覆盖 | `behavior-final.log`；项目根下 `reports/gdunit-wrapper/run-kp9_etvb/` 的 `result.json` 与 `report_1/results.xml` |
| 最终 lint | 60 文件，0 Critical、0 Warning，417 Info；未调整阈值 | `lint-layout-final.json` / `.log` |
| 维护测试 | 38/38，14.752 s | 本轮维护 unittest 终端原始输出；未运行 pytest |
| 编排真实渲染 | Forward+ / Compatibility 均通过，四尺寸 × 浅深色真实按钮输入、运行态状态文本/停止/保存可达；真实 A、B、并行阶段像素和活动对象符合预期 | `timeline-render-<renderer>-layout-fixed.log`、`<renderer>/timeline-render-results.json` |
| 生命周期 | 两渲染器各 10 轮真实创建/播放/停止/释放，节点回到 1、孤儿 0；音频、延迟、运动、粒子及句柄清除 | 上述 JSON 的 lifecycle / failures |
| 既有能力 | 两渲染器粒子显现/重启/自然结束/停止、运动恢复与第四入口参数可访问；原三个入口最终四尺寸及输入检查通过 | `effects-*.log`、`<renderer>/render-results.json`；`existing-entries-layout-final.log`、`existing-entries/layout-results.json` |
| 手册 | 构建 22 文档、33 Mermaid、488 源链接；未用 Playwright 或其他浏览器视觉验收 | `framework/docs/blank-project/blank-project-handbook.html` |

查看了本轮真实宽/窄、浅/深色截图及消费画面。尺寸为 1600×900、1152×648、900×540、720×480；窄窗继续用区域切换和场景内部滚动，不重排真实对象。 截图中的像素变化只证明效果实际绘制，不是审美或最终画面质量测量。此次不重跑 E4 的 128 对象长期性能测量，也不宣称改善其帧间隔。

## 失败、发现与复验

1. `behavior-initial.log` / `run-y1ulne45`：111 项断言通过但 95 个孤儿记录导致进程失败。Timeline 离树夹具遗留 85 个节点；Manager 冷目标测试暴露组件在 `_ready` 才建立归属的真实泄漏，另有夹具释放时点问题。保留离树断言后明确释放夹具，并将生产节点归属提前；新增冷构造回到基线的测试，没有减小检查范围或放宽阈值。
2. `behavior-rerun.log` / `run-29lf_1d1`：117 项、0 孤儿通过。随后只按职责拆出 2 项入口测试，原测试正文未变；最终 10 套件再次全部通过。
3. `lint-initial.json`：校验函数复杂度与单份测试长度共 1 Critical / 3 Warning。拆分路径/窗口/运行前置校验及测试职责后最终为零；没有修改 lint 配置。
4. 静态检查修正 Timeline 同步 stop/play 的代际与 Manager 快照，禁止 `%UniqueName` 别名绕开目标边界；新增相关重入和路径断言。
5. 初轮真实画面发现消费按钮文字对比度不足；紧凑状态行随后又因自动换行在窄窗竖排。前者定向设置按钮文字颜色，后者关闭短状态文字自动换行；捕获夹具新增播放后再次检查按钮及状态行，双渲染器复验通过。`initial-*`、`wrapped-status-720x480.png` 与 `before-running-layout-check.json` 保留旧观察，不能用它们替代当前视觉结果。

## 使用与待人工体验

在既有验证项目打开 `examples/asset_workbench/effects_composition/example-workbench.tscn` 按 F6，选择各对象方案后点击“播放编排”；循环选择下次播放生效。 独立检查管理器可打开同目录 `example-consumer.tscn`，先“受管触发 A 组”，随即“高优先级 B 组”，观察 B 接管三个预算名额，取消 A 不会停止 B；停止全部清理整个组合。

最终截图包括 `<renderer>/timeline-workbench-light-1600x900.png`、`timeline-workbench-dark-720x480.png`、`timeline-consumer-group-a.png`、`timeline-consumer-group-b.png`、`timeline-consumer-parallel-cores.png`。 用户仍需确认节奏、片段截止造成的音频/粒子截尾是否符合预期、主观听感、组合协调及操作顺手程度；手册阅读版的排版与交互也未由用户验收。 E5/E6 本轮实现与自动验证完成，不把授权推进视为这些新体验已通过人工验收。
