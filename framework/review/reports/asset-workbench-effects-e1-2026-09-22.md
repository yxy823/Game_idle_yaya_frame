# Asset Workbench E1：粒子与动画接入及验证

## 范围与基线

用户在完成 E0–E7 规划后授权开始实现，并要求通过指定 `game-asset-library-search` Skill 查找、复制合适资源，以 `example-` 标明示例。
本轮落实 E1：一次性与持续 GPU 粒子、Tween 跃动、一个 AnimationPlayer 片段，以及现有图像/音频/Shader 的组合、A/B、保存和消费回归。
E2–E7 尚未实施；没有新增 Manager、Timeline、通用属性编辑器、效果分析引擎或项目流程状态。

修改基于 `f76c29f8af8f2b2405f8df910c6ea64620fd71c9`，维护仓库开始时干净。原 UI 实现为 `4332ce1`，其画面已有用户验收；该验收不等于接受本轮新效果。
源材料在 `project-source/`，维护夹具与本报告在 `framework/`。沿用本会话授权，仅定向同步到既有 `D:/A_Games/Game_idle_yaya_frame_workbench_test`，不创建新游戏或 Feature。
同步前比较既有目标文件与基线，保护原 Cue、预设、项目主场景和机器配置；只回收本轮新脚本的 `.gd.uid` 与一份贴图 `.import`，不回灌缓存或测试结果。

## 实现、入口与设计取舍

新增第四个 F6 入口：[粒子与动画工作台](../../../project-source/examples/asset_workbench/effects_composition/example_workbench.tscn)。原三个入口保留，四者共享同一工作台与表现组件。
新消费场景为同目录的 `example-composition.tscn`，读取三份独立示例 Cue。完整参数与扩展契约集中在 [示例说明](../../../project-source/examples/asset_workbench/README.md#粒子tween-与-animationplayer)。

| 变更 | 行为与取舍 |
| --- | --- |
| 独立绑定 | 图像、音频、Shader、粒子、动画片段分别选择并可留空，Tween 单独启用；不自动补图片或声音。仅运动、没有可见承载内容也有效，界面说明当前没有可见目标 |
| 粒子预设 | 单个无附加脚本/子节点的 `GPUParticles2D` 原生场景，通过 `FeedbackParticlePreset` 引用；开放缩放、延迟和持续发射时长。不做任意节点适配或自定义粒子模拟 Shader 编辑 |
| 粒子生命周期 | 每对象一个发射器，运行模拟材质独立、贴图和曲线只读共享；重触发重启。爆发自然结束，持续效果停止发射后等待存活粒子消散；立即停止隐藏并取消延迟，下次触发重置模拟 |
| 运动归属 | Tween 控制外层局部位移，AnimationPlayer 控制内层局部变换；共同作用于图像/Shader 表面和粒子发射器。名称、选择边框、对象布局及原有脉冲仍由各自原逻辑持有，避免同一属性竞争 |
| 动画片段 | 仅支持有限非循环的局部位置、缩放、旋转值轨道；重播、取消、自然结束恢复初态。工作台选择已制作的 Animation，不做轨道编辑或方法/音频轨道执行 |
| 草稿与保存 | 新字段加入 Cue 比较、校验、复制及保存后重读核对；编辑只改当前对象当前 A/B，绑定不在候选列表中时仍保留。保存只写 Cue，共享资源不写回；全场景继续逐文件保存与部分失败反馈 |
| 保留能力 | 声音和原图标脉冲仍可重叠；粒子、Tween、片段和当前 Shader 各自重启。源分析只收集 Cue 图片/音频，不把效果渲染或粒子内部纹理混入分析集合 |

关键代码：`feedback_cue.gd`、`feedback_presenter.gd` 接入现有生命周期；新增 `feedback_particle_preset.gd`、`feedback_particles.gd`、`feedback_motion.gd` 分别负责预设契约、粒子实例和运动层。
工作台新增 `effect_controls.gd`，由 `cue_controls.gd` 和 `workbench.gd` 提供候选及参数。没有另写一套预览/保存逻辑。
预设数量和时长限制用于本轮有限示例契约，详见示例说明；未把它们包装成全局资源管理能力。

## 素材选择与许可

使用 [用户指定 Skill](D:/A_Games/Game_Assets_Library/.agents/skills/game-asset-library-search/SKILL.md)，先通过资源库索引搜索 `particle`、`effect` 和 `art/vfx`。
候选为 Brackeys VFX in Godot 与 haowg Godot VFX Library；选用前者的 2D GPU 样例，未展开备用包。
本次“查找合适的复制过来”作为选择和复制授权，资源库原件、标签与元数据未改动。

来源：`brackeys-vfx-in-godot`，上游 [Brackeys/vfx-in-godot](https://github.com/Brackeys/vfx-in-godot)，本地存档版本 `23b58f272b828b0a894ed7ef72fbf9033ee9d177`。
从 ZIP 定向读取三个成员，未执行原包脚本、未安装插件：

| 原包成员 | 本轮用途 |
| --- | --- |
| `vfx/scenes/2d_example.tscn` | 复制重命名为 `example-particle-stream.tscn` 后适配单发射器、参数与本地资源引用；据此制作 `example-particle-burst.tscn` 变体 |
| `vfx/brackeys_particle_bundle/particles/alpha/spotlight_01_a.png` | `example-particle-spotlight.png`，图片字节保持不变 |
| `README.md` | `example-brackeys-license.md`，原文保留作者整项目 CC0 声明 |

Tween 行为、摇摆 Animation、Cue 与包装预设为本项目编写；已有图像/音频/Shader 继续复用原示例。不是把新写配置误称为下载的素材。

## 本轮实际验证

环境为 Windows、Godot `4.7.1.stable.official.a13da4feb`、RTX 4060 Laptop GPU（NVIDIA 596.21）。
使用 `C:/Users/89523/anaconda3/envs/codex-python/python.exe`；真实引擎只在上述外部项目运行。
下表证据路径相对该外部项目，`E` 代表 `reports/asset-workbench-effects-20260922/`。

| 层次 | 实际结果 | 原始证据 |
| --- | --- | --- |
| 导入与解析 | 正常导入；8 份项目脚本和 2 份新增夹具单独 `--check-only`，10/10 退出 0 | `E/import.log`、`E/parse-results.json`、各 `parse-*.log` |
| 项目 lint | 完整 `res://`（按现有排除配置）加显式新增渲染夹具，共 49 文件；0 Critical、0 Warning、312 Info，退出 0 | `E/lint-delivery.json` |
| E1 专项 | 12/12：8 种新机制有无组合、延迟取消、持续消散、材质隔离、30 次重触发、运动层恢复、切换/退出、新字段保存消费、草稿和候选保持、源分析范围、非法预设/片段 | 专项 `E/behavior-final.log`，以及下行最终全套结果 |
| 全套 Godot 回归 | 77/77，6 套：单对象 14、组合 10、Shader 9、Analyzer 18、分组 14、新效果 12；0 错误/失败/跳过/孤儿节点 | `E/behavior-all-final.log`、`reports/gdunit-wrapper/run-lxcb5r78/result.json` 与 `report_1/results.xml` |
| Compatibility 实际渲染 | OpenGL 3.3；真实粒子可见、重触发、立即停止及自然结束、运动恢复均通过；第四入口浅深色及四种尺寸通过 | `E/render-compatibility-final.log`、`E/gl_compatibility/render-results.json` 与截图 |
| Forward+ 实际渲染 | Vulkan 1.4.329；相同像素、生命周期和新入口尺寸检查通过 | `E/render-forward-plus.log`、`E/forward_plus/render-results.json` 与截图 |
| 原三个入口 | 真实鼠标浏览/应用、浏览不绑定、另一草稿保持、键盘菜单、固定动作和四种尺寸通过 | `E/render-existing-entries.log`、`E/existing-entries/layout-results.json` 与截图 |
| 维护工具回归 | 38/38 unittest，14.990 s；复制与文档契约检查 | 本次会话命令原始输出 |
| 文档与阅读版 | 使用说明和进度已同步；HTML 构建通过，22 篇、33 张 Mermaid、486 个源链接；另核对新文件 UTF-8/LF、复制映射及源/外部对应 | 本仓库手册与本轮构建输出 |

透明 256×256 探针中，Compatibility 爆发/持续可见像素为 3453/1656，Forward+ 为 3436/1656；停止和自然结束都回到 0。
数值仅是“该样例确实绘制并清除”的证据，不是质量评分、跨渲染器一致性承诺或性能指标。
图像＋Tween＋片段在运动期间实际像素改变，停止与自然结束后均与初态逐字节相同。
四种客户区尺寸为 1600×900、1152×648、900×540、720×480，新增选择器和参数可滚动访问，停止及保存持续可见。
Agent 已查看宽窗浅色组合、深色参数、1152/720 窄窗、独立消费及旧 Shader 窄窗等截图；真实观看/试听接受由用户决定。

本轮代表图：[浅色组合](D:/A_Games/Game_idle_yaya_frame_workbench_test/reports/asset-workbench-effects-20260922/forward_plus/workbench-light.png)、[深色参数](D:/A_Games/Game_idle_yaya_frame_workbench_test/reports/asset-workbench-effects-20260922/forward_plus/effect-controls-1600x900.png)、[720×480 参数](D:/A_Games/Game_idle_yaya_frame_workbench_test/reports/asset-workbench-effects-20260922/forward_plus/effect-controls-720x480.png)、[消费场景](D:/A_Games/Game_idle_yaya_frame_workbench_test/reports/asset-workbench-effects-20260922/forward_plus/saved-consumer-playing.png)。
截图留在外部项目，没有复制进框架源材料。

### 发现、修正与失败证据

- 首次专项运行取消片段绑定后，再次停止仍尝试定位已移除的 `effect` 动画，出现两条引擎错误。改为 `AnimationPlayer.stop(true)` 后显式恢复组件拥有的变换；专项与全套均复验。保留 `E/behavior-initial.log`、`run-4jpgtsr1`；专项修正结果为 `run-sbrehrwg`。
- 首次全套为 77 项、1 失败：SpinBox 步长归整让未编辑的默认 0.7 发生浮点变化，旧 Shader 控件的“不改值”检查失败。新控件只在实质变化时写回数值，未放宽 Cue 等值或保存核对。保留 `E/behavior-all.log`、`run-lnfk0co5`，最终为 `run-lxcb5r78`。
- 首次 lint 有 5 条复杂度提示；按音频/效果比较、粒子/动画校验与控件上下文拆分职责，未调宽阈值或忽略。扩充夹具后又发现两处未使用循环变量，改为下划线名称；该命名修正不改变已通过的 77 项行为，最终另做解析和 lint。保留 `E/lint-initial.json`、`E/lint-final.json`。
- 首次 GUI 引擎命令仅重定向输出，未得到可靠等待结果，空的 `E/render-initial.log` 不作成功证据；后续使用 PowerShell 管道等待并核对退出码。早期两尺寸 Compatibility 记录为 `render-compatibility.log`，最终四尺寸和重触发证据以上表为准。

### 复跑入口

先按本次范围同步源码和夹具，在已授权的外部验证项目根目录运行；不要在 `project-source/` 导入或启动引擎：

```powershell
$effectPython = 'C:/Users/89523/anaconda3/envs/codex-python/python.exe'
$effectGodot = 'E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe'
& $effectPython -B tools/testing/run-gdunit-tests.py --godot-binary $effectGodot --target tests/features --continue
& $effectGodot --path . --rendering-method forward_plus --script res://reports/asset-workbench-effects-20260922/fixtures/asset_effect_render_capture.gd | Out-Host
```

每次分别检查退出码。Compatibility 将渲染参数改为 `gl_compatibility`；旧 UI 夹具仅在外部副本替换了输出目录，未覆盖先前 UI 报告。
维护 unittest 与手册构建命令沿用 [维护说明](../../docs/blank-project/maintenance/updating-the-blank-project.md#按修改选择验证范围)。

## 交付和未验证边界

可分发变更为 8 份项目脚本、4 份新 UID、`effects_composition/` 示例/许可/导入描述和项目使用说明；两份新夹具只留在维护侧。
同步更新框架指南、目录说明、验证入口、阅读版及 [同一份 E0–E7 进度](../../progress.md#asset-workbench-视觉效果扩展规划)。27 份本轮分发文件已核对与外部副本相同，既有示例 Cue/场景/Shader/图像/音频无差异；外部两份使用说明同步前也与原基线一致。既有目录映射已覆盖新内容，没有增加复制规则或自动同步机制。

E1 实现和本轮自动检查已完成；新效果的视觉协调、快速触发时的听感、实际保存/消费操作体验仍待用户验收。
手册仅完成静态/构建核对，浏览器排版与交互仍由用户外部检查；本轮未复跑未改动的 Python 分析后端独立 22 项，也未执行完整项目开发 Stage 流程。
其他 GPU/平台、移动端、大规模长时间负载、CPU 粒子、复杂子发射器、动画轨道编辑、暂停/任意拖动定位均不在本轮验证范围。后续按 E2–E7 的真实需求和依赖选择，不因当前通过自动进入下一阶段。
