# Asset Workbench E3/E4：组合复用与规模验证

日期：2026-09-22。任务起点为 `7a4c582`，开始时工作区干净。E3 实现已本地提交为 `b1e2cf1`，E4 探针、测量与维护说明单独提交。用户明确授权执行 E3、E4；E2、Manager、Timeline 与后期整合没有因此开工。 源材料在框架维护仓库修改；真实 Godot 验证仅在此前已获准的 `D:/A_Games/Game_idle_yaya_frame_workbench_test` 执行。 定向同步前对照起点版本核对目标文件，没有覆盖冲突；不改其机器配置、既有 Cue、共享素材或其他游戏。

## E3 实现与设计取舍

第四个 F6 入口仍是 `examples/asset_workbench/effects_composition/example-workbench.tscn`。 它现在实例化两份原生 `example-effect-cluster.tscn`，每份含核心组合、局部粒子和场景坐标粒子三个对象。 独立 `example-consumer.tscn` 继承组合场景，以不同位置、旋转和缩放消费同一批保存的 Cue。没有复制预览业务或另建运行时编辑器。

| 发现或需求 | 最小实现与边界 |
| --- | --- |
| 原组合以 Cue 文件路径识别对象，两个实例引用同一文件时会共享草稿、一起高亮/更新 | 复用已有 `object_nodes` 的场景相对节点路径作为对象身份，Cue 路径只作保存目标；每实例有独立 Session、A/B 和运行组件，不增加 UUID、注册器或全局管理器 |
| 多个独立草稿可能同时写一个共享文件 | 全场景保存按唯一目标分组：当前内容一致且每个 Session 均未冲突时写一次，重读后同步保存基线，保留两份草稿；内容分歧或任一磁盘基线过期时跳过该文件，其他文件继续保存。仍无事务锁、多文件原子性或自动另存机制 |
| 单对象保存对其他引用的影响 | 只写选中对象当前方案，其他内存草稿不替换；后续保存会检测磁盘变化，重载仅丢弃选中对象 A/B。界面显示组名、共享目标数和实际保存文件 |
| 表现层附着、坐标及绘制归属 | 消费场景拥有组合根变换，Core 的原生 `z_index=1`、其余为 0；Presenter 内部 Tween 与片段层继续分开。新预设只改变粒子 `local_coords`；Inspector 明确局部跟随/场景坐标含义 |
| 停止和移除 | 单个 Presenter 停止本对象，组合停止登记的全部对象；退出时剔除对象，所属粒子/动画/待播音频取消，其他实例不受影响。场景坐标粒子仍随所属对象清理，并不变成独立世界服务 |
| 重复配置 | 基类提供实际预览调用点，组合工作台通过当前对象执行一次预览配置；取消原先单次编辑中基类与派生类的双重配置 |

运行时任意新增/重排节点、移除后重新加入同一节点、按草稿另存成新 Cue 不在本次契约内；需要重建时重新实例化完整场景。 原三个入口、图像/声音/Shader/粒子/运动独立留空、浏览不绑定、源分析只测原图/原音频的边界保持。

新资源均使用 `example-` 前缀。复用 E1 已检索的 Brackeys CC0 贴图和发射器，新增场景坐标变体为本地派生，不冒称新下载资源；许可文件和库原件未改。 现有目录复制映射已覆盖新场景/资源，维护用例与报告不进入生成项目。空白配置仍为 `incomplete`，没有创建 Feature 或推进项目开发 Stage。

## E4 范围与测量方法

用户未补充具体目标机型或并发需求，本轮采用已说明的当前 Windows / 8、32、128 对象分档。 设备为 i9-13980HX、RTX 4060 Laptop GPU，Godot `4.7.1.stable.official.a13da4feb`，Forward+ / Vulkan 1.4.329；1600×900、关闭垂直同步和帧率上限。 测试将三类 Cue 轮流应用到真实 ObjectView/Presenter，全部对象排列在视口内；不是离屏空节点压测，也不是工作台一次展示 128 个对象的人工可用性验收。

每档预热 2 s，然后分别以 0.6 s 和 0.1 s 间隔触发 8 s；另以 128 对象快速触发持续 120 s，并对 32 对象做 10 轮创建、播放、停止和销毁。 仅探针草稿清空音频并将粒子延迟设为零，避免大规模叠音及延迟不断被重启导致粒子根本未发射；所有原始 Cue 不变，音频边界在 85 项回归中独立覆盖。 每批触发记录同步调用 CPU 时间；每帧用单调时钟记录应用帧间隔。引擎 `TIME_PROCESS` 仅保留为监视器快照，不把重复读取值的分位数当成逐帧 CPU/GPU 剖析。 节点、资源数、Godot 静态内存及渲染内存也是引擎计数，不是操作系统工作集或独占 GPU 使用量；具体语义参考 [Godot Performance](https://docs.godotengine.org/en/stable/classes/class_performance.html)。

最终样本如下，单位均为 ms；每档两个触发周期分别采样 8 s，不把单次结果推广为设备能力上限。首轮记录保留为 `scale-results-initial.json`，未与最终样本合并。

| 对象数 | 同步创建/配置总耗时 | 0.6 s 触发：帧间隔中位 / P95 / P99 | 0.1 s 触发：帧间隔中位 / P95 / P99 | 快速触发批次 CPU 中位 / P95 |
| --- | --- | --- | --- | --- |
| 8 | 29.14 | 0.48 / 0.82 / 1.27 | 0.78 / 1.04 / 1.53 | 0.29 / 0.46 |
| 32 | 45.37 | 0.82 / 1.08 / 1.47 | 1.84 / 2.53 / 4.31 | 0.77 / 0.95 |
| 128 | 140.31 | 2.56 / 3.54 / 4.72 | 7.36 / 16.45 / 17.61 | 2.76 / 3.05 |

128 对象连续快速触发实跑 120.013 s、1166 批、15588 帧，帧间隔中位 6.97、P95 15.77、P99 17.65、最大 28.55 ms；触发批次 CPU 中位 2.69、P95 3.11、最大 4.57 ms。 这些批次同步时间无法解释所有尾帧，尚无 GPU 逐阶段剖析；不能断言某个 Shader 或粒子算法是唯一瓶颈，也不能宣称稳定 60 fps。

生命周期与内存观察：

- 128 对象在采样期间保持 1794 场景节点、128 个实际发射器、38 个 Resource、零孤儿节点；活动效果抽样峰值 600（含重叠图标脉冲与各组件状态，不是粒子数量）。
- 各档释放后与 120 s 结束后均回到 1 个根节点、11 个 Resource、零发射器/活动效果/孤儿节点。10 轮装卸也保持这个基线，未出现节点或资源数随循环增加。
- 持续采样内 Godot 静态内存约 74.33 → 75.47 MB，包含不断增长的帧间隔、批次与快照数组；结束释放后为 56.06 MB，仍高于冷启动 49.53 MB。渲染内存从热身后的 30.29 MB 回到 24.06 MB，10 轮保持不变；冷启动为 13.18 MB。
- 十轮释放后静态内存 56.063 → 56.076 MB，其中输出快照也在逐轮保留。以上支持“本次未观察到实例/资源持续泄漏”，不证明所有缓存已归还、操作系统内存无增长或数小时运行无泄漏。MB 此处按 1,000,000 字节换算。

取舍：当前六对象工作台没有出现需要管理器接管的调度问题；保留现有局部组件。128 对象一次性创建约 140 ms 是明确的主线程尖峰，快速触发也出现超过 16.67 ms 的尾帧。 需要这种负载的真实消费方应先在加载期创建、减少同帧创建量及重复触发/绘制量，再按其目标设备做剖析；这不要求当前加入池化、异步加载或全局 Manager。 由于用户未规定目标机性能预算，本轮完成的是测量与边界识别，不把未选定优化写成阻塞缺陷，也不将所有对象数判为“性能达标”。

当前真实内容仍只有四个图像/音频候选、三个粒子预设和一个动画片段。候选筛选、绑定名称及只读引用入口已足够；新增坐标说明解决当前识别需求。 实例数增加并不要求复制预设或扩大源分析集合。本轮未伪造大规模素材库，也未据实例压测建设目录扫描、资源数据库或额外管理 UI。

## 验证证据

下表 `E` 表示外部项目 `reports/asset-workbench-e3-e4-20260922/`；渲染与测量进程顺序执行，没有同时运行两个 GPU 夹具。

| 层次 | 实际结果 | 证据 |
| --- | --- | --- |
| 导入与解析 | 正常导入；7 份改动项目脚本、3 份行为夹具、2 份新渲染/测量夹具共 12/12 单文件解析退出 0 | `E/import.log`、`parse-results.json` 及各 `parse-*.log` |
| lint | 最终 53 文件，0 Critical、0 Warning、389 Info，退出 0 | `E/lint-final.json` |
| Godot 行为 | 85/85，7 套，0 错误/失败/跳过/孤儿节点；其中 E3 新增 8 项 | `E/behavior-final.log`、`reports/gdunit-wrapper/run-1mzaous1/result.json` 与 JUnit 原件 |
| 新组合真实渲染 | Compatibility 与 Forward+ 均通过：父级移动 120 px，局部粒子质心移动 120 px，场景坐标粒子移动 0 px；停止后无可见粒子 | `E/reuse-render-*.log`、两渲染器 `reuse-render-results.json`、前后像素截图 |
| 既有粒子/运动及第四入口 | 两渲染器均通过粒子绘制、重触发、自然结束、停止清除与运动恢复；浅深色及 1600×900、1152×648、900×540、720×480 参数/固定操作可达 | `E/effect-render-*.log`、两渲染器 `render-results.json` 及截图 |
| 原三个入口 | 真实鼠标浏览/应用、键盘菜单、草稿保持、四种尺寸与固定停止/保存通过 | `E/existing-entries-render.log`、`existing-entries/layout-results.json` 与截图 |
| 规模与持续运行 | 三档两种频率、128 对象 120 s、10 轮装卸完成；停止和节点回收检查通过，性能分布与限制见上文 | `E/scale-forward-final.log`、最终 `forward_plus/scale-results.json`、`scale-8/32/128.png` |
| 维护工具与说明 | 38/38 unittest，14.430 s；阅读版构建通过，22 篇、33 图、487 源链接；17 份分发文件与被测副本核对一致 | 本轮命令实际输出；Markdown 与生成 HTML 差异。构建不代表浏览器排版或交互已验收 |

Agent 已查看宽窗浅色双组合、720×480 深色属性和实际旋转/缩放消费场景截图；可以辨认当前组/对象、共享保存范围、A/B 与固定操作。 这是本轮截图检查，不能代替用户的视觉协调、听感与操作舒适度验收；此前 UI 画面验收也不自动覆盖本轮新增组合。

代表图：[双组合工作台](D:/A_Games/Game_idle_yaya_frame_workbench_test/reports/asset-workbench-e3-e4-20260922/forward_plus/workbench-light.png)、[窄窗属性](D:/A_Games/Game_idle_yaya_frame_workbench_test/reports/asset-workbench-e3-e4-20260922/forward_plus/effect-controls-720x480.png)、[不同变换下的消费场景](D:/A_Games/Game_idle_yaya_frame_workbench_test/reports/asset-workbench-e3-e4-20260922/forward_plus/reused-consumer-playing.png)。

### 失败与修正记录

- 初次测试发现新夹具的 `Panel` 常量与原生类名冲突，另有局部变量遮蔽；修正命名，未改变断言。保留 `E/behavior-initial.log` / `run-mho_9jnz`。
- 第二次 85 项断言通过，但运行器在同一帧内多次重配后计出 13 个孤儿节点。源码追查与专项复核指向旧发射器的 `remove_child` / `queue_free` 帧末释放；在该同步交互用例末等待一次正常帧推进后，全套零遗留。未改引擎释放策略、忽略孤儿节点或放宽判定。保留 `behavior-rerun.log` / `run-npyrf070`、`behavior-orphan-details.log` / `run-bvvpwbog`。
- 首次 lint 有测量脚本两条调试输出与一条函数长度提示。去掉无必要输出，将环境记录独立为函数，未调整阈值。首轮测量后进一步分开实际帧间隔与引擎监视器，加入触发批次计时，最终重新执行完整测量。

## 文件与复跑入口

项目侧修改集中于 `feedback_object.gd` / `feedback_composition.gd` 的实例身份，`composition_panel.gd` / `composition_workbench.gd` / `workbench.gd` 的草稿与预览，`preview_session.gd` 的共享文件保存核对，以及 `effect_controls.gd` 的坐标说明。 `effects_composition/` 新增原生组合、独立消费、三份 Cue、世界坐标预设/发射器，更新现有第四入口及其组合场景；项目 README 同步当前契约。 维护侧保留新增复用用例、坐标捕获、规模探针，更新两份旧用例的对象身份调用，以及指南、验证说明、框架目录、同一份 progress 和阅读版。没有修改测试工具、插件或规则。

先核对并定向同步本轮源材料与夹具，然后在已授权外部项目根目录运行：

```powershell
$e34Godot = 'E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe'
& 'C:/Users/89523/anaconda3/envs/codex-python/python.exe' -B tools/testing/run-gdunit-tests.py --godot-binary $e34Godot --target tests/features --continue
& $e34Godot --path . --rendering-method forward_plus --script res://reports/asset-workbench-e3-e4-20260922/fixtures/asset_composition_reuse_capture.gd | Out-Host
& $e34Godot --path . --rendering-method forward_plus --script res://reports/asset-workbench-e3-e4-20260922/fixtures/asset_effect_scale_probe.gd | Out-Host
```

每条命令分别检查退出码；不要在框架源材料中启动 Godot。复跑时保存旧证据或更换副本输出目录。Compatibility 只复核渲染/坐标，没有做本轮性能测量。 本轮未复跑未改动的 Python 分析后端独立 22 项或完整项目开发 Stage。其他硬件、长期数小时负载、大型真实素材库与多消费方业务都没有被本样例测量替代。
