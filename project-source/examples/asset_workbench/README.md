# 美术、音频、Shader 与粒子动画组合预览示例

这是可删除、可替换的开发示例，不是项目 Product、正式玩法或已验收资源。 复制框架后仍需按项目 README 完成环境准备；示例不会设置项目主场景或自动启动。

## 打开与操作

四个独立入口放在不同目录，在 Godot 中选择对应场景按 F6。按当前要验证的行为选择，不必逐个完成：

| 工作台入口 | 代表性检查 | 保存后的消费入口 |
| --- | --- | --- |
| `single/example_workbench.tscn` | 单对象浏览、试听、A/B、保存 | `single/example_game.tscn` |
| `composition/example_workbench.tscn` | 多对象选择、混合 A/B、逐文件保存 | `composition/example_composition.tscn` |
| `shader_composition/example_workbench.tscn` | 材质隔离、无图像承载面、独立绑定 | `shader_composition/example_composition.tscn` |
| `effects_composition/example_workbench.tscn` | 粒子/运动组合、共享 Cue 多实例、局部 Manager 与有限编排 | `effects_composition/example_consumer.tscn` |

也可在**生成项目根目录**使用配置中的引擎：

```powershell
$config = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
& $config.environment_bootstrap.engine_executable --path . 'res://examples/asset_workbench/single/example_workbench.tscn' | Out-Host
```

先完成正常导入。框架的 `project.godot` 默认视口为 1600×900，新建项目继承此值； 工作台入口及分析、批量窗口默认都使用 1600×900，不再自动按屏幕比例缩小。 显式 `--resolution` 或后续项目设置可覆盖默认值；嵌入编辑器（`--wid`）时仍受宿主区域约束，查看完整独立窗口可分离运行。 宽窗口使用可拖动三栏：资源候选、真实预览、对象 Inspector。候选列表和属性独立滚动； 对象名称、对象 A/B、未保存状态、播放及保存入口不随长表单滚动。 窄窗口通过“资源候选 / 组合预览 / 对象属性”切换区域，底部持续显示当前对象、方案、保存目标、停止和保存； 真实组合场景尺寸不足时在预览内部滚动，不重排示例对象。低频操作在具名菜单中，无布局持久化。

1. 左侧筛选已有候选；图像显示等比例缩略图及**导入后**尺寸，音频显示类型与导入后时长。“试听 / 循环试听”固定使用 -12 dB、1×、Master；“停止试听”仅停止独立试听。
2. 浏览、元数据和源分析均不绑定。按需点击“分析候选源文件”，查看后点击“应用到对象 A/B”；应用只改变当前对象的当前方案。候选更多菜单可查看、选择复制完整路径。
3. Inspector“资源绑定”分别选择图像、音频、Shader、粒子与动画片段，均可留空；全空配置有效。下方按类型编辑，Tween 可独立启用；未启用 Shader 时素材保持原色。
4. “触发”从初态重播；“循环 0.6 s / 快速 0.1 s”仍允许事件重叠。“停止全部”清除全部对象的播放、动画、循环、待触发延迟及独立试听。
5. 打开或重载时 A 使用磁盘配置；原配置有声音且存在其他音频候选时，B 只换声音，静音配置保持静音。对象 A/B 按钮明确标出选中方案。对象更多菜单提供复制到另一方案、恢复当前方案、重载及打开消费场景。
6. “保存当前方案”只保存当前 A/B 到可见目标 `.tres`，影响所有引用该 Cue 的消费场景，不修改源素材或共享材质。“保存路径…”可查看并复制完整路径。重载仍确认丢弃**当前对象的两份**草稿。
7. “打开消费场景”启动独立实例验证**已保存**配置；未保存草稿不会进入该场景。最近操作与错误在底栏显示，长消息及部分失败路径可打开“操作详情…”完整查看并复制。

默认白底黑字；顶部“外观设置”可切换深色界面。 “图像透明棋盘格”给单项图片区与单对象预览增加灰色棋盘格，辨认透明边缘；默认关闭。组合场景保留真实背景。 这些查看设置只在当前工作台会话生效，不影响素材颜色、A/B、保存的 Cue 或正式游戏环境。 黑色图标在深色背景下对比度降低属于素材与背景的真实关系，可切回浅色或启用棋盘格。

左右两种查看方式共享候选集合，但单项试听使用固定 -12 dB、1 倍速、Master 总线。 事件按右侧参数播放；没有自动响度匹配，主观比较时保持系统监听音量一致。 Inspector 的资源绑定显示实际使用的文件；左侧候选名称不代表已经绑定。无选择或类型不适用时操作禁用，非音频候选不显示试听操作。 两个原始音效属于同一确认音系列，解码时长分别约 0.290 秒和 0.539 秒；切换 A/B 不代表自动改变音色、响度或音高。 浏览器元数据来自导入后的 Texture2D / AudioStream；“分析候选源文件”打开独立“源资源分析”窗口。 第二阶段已提供后台音频/图像分析、统一 JSON、图表与同类型分析 A/B；安装和操作见 [Analyzer 说明](../../tools/asset_analyzer/README.md)。缺少可选分析依赖不影响这里的预览与播放。

## 可交互组合场景

直接运行 `composition/example_workbench.tscn`，中央加载真实的 `composition/example_composition.tscn`：奖杯、星星和奖励三个对象。 它们复用原始图片、声音与 FeedbackPresenter，每个对象使用独立的 `example_composition_*.tres`。 组合工作台自身包含对象选择、属性及分析能力，背景可切换浅色/深色。

1. 点击对象会选中并触发它。组合工作台右侧立即改为该对象的属性，底部显示真实保存目标。
2. 沿用现有候选、参数、A/B、重置与保存；试调也更新组合场景中的对应对象。切换对象不会丢弃各自 A/B；初始 B 在有另一个声音时仅换声音。
3. 预览上方“场景 A / B”切换所有对象；Inspector“对象方案 A / B”只切当前对象。全场景状态根据各对象实际方案计算，混用时显示“混合方案”且场景 A/B 均不高亮。“触发全部”清理旧播放后同时触发，单一“停止全部”负责整体停止。
4. “全场景更多…”中的“将增益应用到各对象的当前方案”只改变各对象当前 A 或 B 草稿；另一方案与磁盘不变。
5. 同一菜单的“保存全场景当前方案（逐文件）”按不同 Cue 文件检查与保存，显示成功文件数与失败路径。同文件的多个当前草稿一致时只写一次；不一致时跳过该文件，需统一草稿或只保存选中对象。它不是多文件事务：其他文件可以成功，冲突文件保留试调。
6. “对象更多…”中的“打开消费场景”读取已保存 Cue；也可打开 `composition/example_composition.tscn` 按 F6。
7. “对象更多 → 分析当前对象源资源”与“全场景更多 → 分析场景源资源”收集相应当前方案中的图片/音频，跳过空项后去重加入同一批量集合，保留既有集合成员并显示本次范围。不分析 Shader，也不测量最终混音或渲染画面。

集合反馈区分实际新增、已在集合和跳过项；AtlasTexture、音频 `.tres` 等间接资源不能作为源文件分析，会显示对应原因，不自动改为分析其内部资源。 首次 Cue 加载失败时，对象操作会提示尚未加载；浏览、独立试听与候选分析仍可使用。修正目标文件后从“对象更多”重载，再继续试调。

对象位置由原生 Scene 布局维护；运行时只编辑明确支持的 Cue 参数。 Agent 可以根据画面描述组合或修改 `.tscn` 与表现组件。本例验证这种接入方式，没有在运行时实现自然语言生成器、任意节点属性编辑器或通用场景制作软件。 接真实项目时使用其已有对象/事件数据和明确的表现接口，不自动执行未知场景的业务副作用。

## Shader 与独立资源组合

运行 `shader_composition/example_workbench.tscn`。它复用组合工作台和三对象原生场景，使用独立的示例 Cue：

| 对象 | 初始组合 | Shader 来源 |
| --- | --- | --- |
| 奖杯 | 图片＋声音＋外描边 | `outline2D_outer.gdshader` → `example_outline.gdshader` |
| 星星 | 图片＋溶解，无声音 | `dissolve2D.gdshader` → `example_dissolve.gdshader` |
| 噪声 | Shader＋声音，无图片 | `value_noise.gdshader` → `example_noise.gdshader` |

右侧分别选择图片、声音和 Shader；更换某一类不会自动替换另两类。Shader 可复用于不同图片或对象， 每个对象及 A/B 草稿保存自己的强度、颜色、延迟和时长。没有图片时，Shader 在普通白色矩形上绘制； 这是明确的预览承载面，不会补选隐藏图片。具体视觉仍取决于 Shader 本身：噪声忽略图片，描边在无透明边缘的矩形上可能不明显。

Shader“强度 (0–1)”映射到预设的峰值；描边最大 10 像素，溶解最大进度 1。 触发后，映射值按 `sin(π × 进度)` 从零升到峰值再回零；Shader 的延迟、时长与音效时序分别控制。 溶解预设使用自行创建的渐变遮罩，较高强度可让整个图标消失；噪声没有强度/颜色 uniform，对应控件禁用，只调显示时序。 再次触发重启当前表面的 Shader，声音和图标脉冲仍可重叠。停止或自然结束移除运行材质，恢复原图；无图片时恢复为空。 Shader 分组显示禁用原因；“预设引用（只读）”列出类型、Shader/材质及现有纹理引用，完整路径可查看复制。不提供任意 uniform 编辑或依赖扫描。

保存仍只写当前对象的 Cue，重载和独立场景 `shader_composition/example_composition.tscn` 读取同一数据。 共享 Shader、纹理、音频及材质预设不被试调修改；每个表现对象创建独立运行材质，普通 uniform 不会串到其他对象。 源文件分析只收集已选择的图片/声音，跳过空项；不分析 Shader 源码、材质或最终渲染画面。

接入另一个 **2D `canvas_item` Shader** 时，用 `FeedbackShaderPreset` 保存材质默认值与必要 sampler， 按需填写一个 float 强度 uniform、峰值和一个 `source_color vec4` 颜色 uniform，并加入工作台场景的 `shader_candidates`。 留空 uniform 名表示该控件不适用；启动与保存会检查名字和类型。预设只定义 Shader，不绑定声音或目标图片。 当前时序契约适用于由上述参数控制的效果；依赖全局 `TIME` 的效果不能据此承诺暂停/重播一致。 本轮不提供 3D、全屏后处理、任意 uniform 编辑、多 Shader 堆叠或通用时间轴。

## 第三阶段：分组与批量检查

“候选更多 → 将筛选结果加入批量分析”把当前筛选后的候选加入分组并打开批量窗口。 可加载 `example_analysis_group.json` 体验包含四个示例资源的分组；其中阈值仅为示例，不是项目硬性规范。 操作、同类统计、规则、历史快照及缓存边界见 [批量分析说明](../../tools/asset_analyzer/README.md#分组批量分析与一致性检查)。

## 粒子、Tween 与 AnimationPlayer

运行 `effects_composition/example_workbench.tscn`；原来的三个入口保持可用。第四入口中 GroupA、GroupB 各实例化一次 `example_effect_cluster.tscn`，每个组合包含以下三个对象：

| 对象 | 初始内容 | 可独立替换或关闭的部分 |
| --- | --- | --- |
| 核心组合 | 奖杯、音效、描边、一次性 GPU 粒子、Tween 跃动及 AnimationPlayer 摇摆 | 所有绑定可独立替换或清空，Tween 单独启用 |
| 局部粒子 | 无图像/声音的持续 GPU 粒子与 Tween | 已发射粒子跟随表现层位移；粒子使用自己的贴图 |
| 场景粒子 | 同类持续 GPU 粒子与 Tween，预设 `local_coords=false` | 已发射粒子留在场景坐标，发射源继续随表现层移动 |

资源绑定中的粒子与动画片段是只读预设选择，候选来自场景的 `particle_candidates`、`animation_candidates`，不扫描整个项目。 已保存的绑定即使不在候选数组里，也会保留并显示。参数只改变当前对象的当前 A/B，保存只写当前 Cue；对象/全场景/源分析 A/B、冲突和逐文件部分失败语义不变。 源分析仍只收集 Cue 的图片和音频，不把粒子内部贴图、动画片段或最终效果加入原始文件分析集合。

| 机制 | 本轮可编辑参数 | 播放与停止语义 |
| --- | --- | --- |
| GPU 粒子 | 独立预设、缩放、延迟；持续预设的发射时长 | 每对象持有一个发射器。重触发重新开始；爆发按粒子生命周期结束，持续发射停止后等待存活粒子消散。发射时长不是单颗粒子的寿命；爆发时此参数禁用 |
| Tween | 启用、跃动距离、往返时长 | 动态计算内部表现层的向上位移并返回；重触发取消前一次，再从初态开始 |
| AnimationPlayer | 独立片段、播放速度 | 播放已制作的有限动画片段；重触发从头开始，停止或自然结束恢复内部变换 |

“停止全部”、切换方案/对象、重载和退出会取消粒子延迟与动画；粒子立即隐藏并停止发射，下次触发重置 GPU 模拟，不显示旧粒子。 声音和原有图标脉冲仍可重叠；粒子、Tween、片段与当前表面的 Shader 分别重启，不为快速触发无限创建节点。 Tween 位移层与动画片段变换层互相嵌套，作用于图像/Shader 表面和粒子发射器，不移动名称、选中边框或 Inspector。 已发射粒子是否跟随变换由预设 `local_coords` 决定，Inspector 显示其含义；本例同时提供局部跟随与场景坐标。场景坐标不表示独立生存：停止或移除所属对象仍清除其粒子。旧图标脉冲仍由原绘制逻辑拥有，不与 Tween 写同一属性。 只启用运动而没有图像、Shader 或粒子时没有可见目标；该配置仍有效，不补入隐藏素材。

新增预设的制作边界：

- 粒子使用 `FeedbackParticlePreset` 引用单根、无附加脚本/子节点的 `GPUParticles2D` 场景，模拟材质为 `ParticleProcessMaterial`；不是图像用的 `FeedbackShaderPreset`。本契约限制 1–256 颗、寿命大于 0 且不超过 5 s、速度倍率为 1。缩放 0.25–2×、延迟 0–0.6 s、持续发射时长 0.15–5 s 保存在 Cue。
- 运行发射器与其模拟材质按对象隔离；纹理、曲线及预设保持只读共享。制作复杂粒子场景、子发射器、碰撞或自定义模拟 Shader 需要另行明确契约。
- 动画使用已保存的 `Animation` 资源，本例为 `example_wobble_animation.tres`。仅接受长度大于 0 且不超过 5 s 的非循环片段，以及目标为 `.:position`、`.:scale`、`.:rotation` 的有限数值轨道；不执行方法、音频或跨对象轨道。可在 Godot 编辑器制作片段，工作台只选择和调整速度。
- Tween 往返时长 0.15–3 s、距离 0–80 px；片段速度 0.5–2×。源文件、共享预设、AnimationLibrary 和运行中的 Tween 不通过 Cue 保存改写。

### 组合复用、保存和消费

`example_composition.tscn` 用场景相对节点路径（如 `GroupA/Core`）登记六个对象，路径标识当前实例，Cue 路径只表示保存目标。 工作台显示所属组名及共享目标提示；两个组合对应的对象共用三份 `example_cluster_*_cue.tres`，各对象仍独立拥有 A/B 草稿、运行材质、发射器和动画状态。 只保存一个对象会更新共享 Cue；其他对象的未保存草稿不自动替换，其后保存会按磁盘变化提示重载。重载只丢弃选中对象的两份草稿。 全场景保存按上文规则处理同文件的一致或分歧草稿，不按遍历顺序覆盖。

“打开消费场景”运行 `example_consumer.tscn`：它继承组合场景，改变两个组合根的摆放、旋转和缩放，读取同一批已保存 Cue；不依赖工作台或框架路径。 组合位置、附着与绘制顺序在原生场景制作：`Core` 的 `z_index=1`，另两个为 0；Presenter 的运动层只控制内部表现，组合根变换由消费场景拥有。 调用单个 Presenter 的 `stop()` 只停止该对象，组合的 `stop()` 停止其登记的全部对象；移除整个组合实例会取消其子对象的延迟与播放，其他实例继续运行。 登记集合在退出时剔除对象；动态新增、移除后重新加入同一节点和运行时编辑场景拓扑不属于工作台契约，应重新实例化完整场景。

粒子候选仍是三个明确预设，片段候选为一个；没有按并发实例数复制候选。早期 `example_burst_cue.tres`、`example_animation_cue.tres`、`example_stream_cue.tres` 保留作为独立机制示例。 规模测量夹具与机器结果只留在框架维护侧，不能作为其他设备或任意素材的性能保证；没有全项目扫描或预设数据库。

### 场景局部管理与有限编排

第四工作台预览上方提供“播放编排”和“循环编排”（下次播放生效），旁边显示实际播放状态。 示例 `example_dual_group_timeline.tres` 为 4.8 s：A 组核心先触发、局部/场景粒子随后并行，再轮到 B 组，最后两组核心同时触发。 它读取各对象**当前 A/B 草稿**；播放不绑定候选、不改 Cue。停止全部、编辑、切对象/方案、保存及重载沿用已有停止范围，并取消后续片段和循环。 消费场景读取同一编排和**已保存 Cue**，提供播放/循环、受管触发 A 组、高优先级 B 组、取消受管 A 组及停止全部，便于单独检查调度。

| 组件 | 契约与边界 |
| --- | --- |
| `feedback_playback_manager.gd` | 可选场景内 Node；`request(presenter, group, priority)` 返回本 Manager 内有效的整数句柄，0 表示拒绝。句柄拥有整个对象的一次独占播放，包括延迟音频，不代表可单独取消每个叠加声部 |
| 预算与回收 | 示例最多 3 个受管对象，组件默认 8；满额只接受严格更高优先级，抢占最低优先级中最早的句柄。其他请求拒绝并反馈，不排队。自然结束、取消或目标退出释放句柄；不销毁现有对象，也不建立新对象池 |
| 取消与直接播放 | `cancel(handle)`、`cancel_group(group)`、`stop_all()` 只取消这个 Manager 仍拥有的播放。直接 `trigger()` 接管同一目标时先停止受管播放；之后手动快速触发照旧允许声音重叠。旧句柄不能停止新播放，未受管对象仍可直接使用 Presenter |
| `FeedbackTimeline` / `FeedbackTimelineClip` | 原生 `.tres` 保存长度及片段数组，每片段只有相对对象路径、起点、持续时间和优先级；长度最多 120 s、1–128 片段。同目标窗口不可重叠，可首尾相接；不支持绝对路径、父级路径或 `%` 别名 |
| `feedback_timeline_player.gd` | 一个场景帧时钟负责窗口开始、截止及循环；截止立即取消该句柄，可能截短声音或粒子余尾。效果提早结束不会补触发。Tween、AnimationPlayer、粒子及声音仍由既有组件各自推进 |

Manager 的数额统计对象而非粒子数、显存或音频声部；直接触发不受这个预算约束，不能据此承诺性能上限。 多个 Manager 不共享限额；它们若争用同一 Presenter，后一次受管播放接管该目标，旧句柄失效。 处理 Manager/Timeline 同步通知时可取消或停止；需要重新申请/播放时用 `call_deferred`，同步重入会拒绝，避免通知链递归改变正在处理的集合。

编排到期先取消旧窗口，再按**片段数组顺序**申请本帧新窗口；同帧高优先级后列时可以抢占先前已启动的低优先级对象。 被拒绝或抢占的片段本轮不重试。同一窗口内直接接管也不触发补播；下一轮才重新按定义申请。 卡顿后，已完整错过的窗口/循环跳过；仍开放的窗口从效果开头触发，到定义终点截止，不补算粒子或音频的过去状态。 播放时复制编排定义，运行中改共享定义只影响下次播放；目标当前 Cue 在各窗口开始时读取。

在 Godot Inspector 编辑并保存编排 Resource，再将其赋给组合场景的 `timeline`。工作台只播放该定义，没有时间轴编辑或保存按钮；“保存当前方案/全场景”仍只写 Cue。 普通连续属性动画继续用原生 AnimationPlayer；有限编排补充跨对象触发、句柄取消和预算反馈，不开放任意方法或属性轨道。 没有暂停/跳转、可视化轨道编辑、多轨混音、采样级同步或全局 Manager；全局 Shader `TIME` 不随编排重置。

## 数据和运行边界

| 位置 | 职责 |
| --- | --- |
| `single/example_workbench.tscn` | 单对象工作台入口、候选与明确保存目标 |
| `single/example_feedback.tres` | 单对象事件配置；工作台保存，奖励示例游戏直接读取 |
| `single/example_game.tscn`、`single/example_reward_game.gd` | 独立消费方；只有进程内奖励计数，没有真实存档或业务副作用 |
| `composition/example_workbench.tscn` | 独立组合工作台；直接选择场景内对象并编辑属性 |
| `composition/example_composition.tscn`、该目录的 `example_composition_*.tres` | 三对象真实场景及分别保存的表现配置；不改单对象配置 |
| `shader_composition/` | 继承三对象示例的 Shader 工作台、独立 Cue、材质预设、复制重命名的 Shader 与许可 |
| `effects_composition/` | 第四工作台入口、可复用三对象组合、双实例预览与独立消费场景、Cue、发射器预设、动画片段及示例贴图/许可 |
| `example_analysis_group.json` | 可携带的资源分组与示例规则，不包含缓存或通过记录 |
| `assets/example_*` | 仅示例素材及许可；禁止据此推定其适合当前游戏 |
| `components/feedback/` | Cue、图像/Shader 表面、图标脉冲、局部音频、独立粒子与运动层，可选局部 Manager/有限编排；各入口共用同一表现逻辑 |
| `tools/asset_workbench/` | 候选浏览、试调和保存界面；不注册全局服务 |
| `tools/asset_analyzer/` | 源文件专业分析与适配器；独立于音频播放，不写回 Cue |

首期是一项奖励按钮的 Activate 事件：一个图标、程序生成的确定性脉冲/放射线、一个声音。 它没有通用 Object/State/Event 引擎、完整时间轴、多音轨编辑、空间音频或音乐管理。 已有游戏对象应接入其现有表现组件与配置；不要为了使用本示例复制一套正式关系模型。

试调复制 Cue 的值字段，纹理/音频/Shader/粒子预设与动画片段保持只读共享；运行材质、发射器和动画状态按对象持有。保存前检查磁盘内容是否变化， 保存后绕过 Cue 缓存重新加载并核对；冲突或失败保留试调并显示原因。磁盘冲突检查不提供多进程事务锁。 保存仅供 Godot 编辑器二进制的开发运行使用，导出游戏不得依赖写回 `res://`。 所有引用这个目标 Cue 的对象都受保存影响；接真实项目前应明确这个范围。

音频封装直接复用 [SoundManager 固定提交](../../addons/sound_manager/UPSTREAM.md) 的局部池， 不启用其全局插件。最多重叠 16 个非空间声音；到达上限返回可见错误，不改全局总线音量。 切换、停止和退出使旧延迟请求失效；不把引擎帧调度当成采样级同步。

### 消费接入与导出

消费对象通过 `cue_resource: FeedbackCue` 绑定已保存的资源，场景由此声明 Cue 及其媒体/预设依赖；工作台保存路径从该引用派生，不另存第二份目标。 消费实例进入场景时绕过 Cue 缓存重读，以取得最近一次保存；工作台内存中的 A/B 仍独立。没有绑定与“已绑定但内容全空”的 Cue 不同，后者有效且可以播放为空。 四个消费入口只使用自身场景、表现组件和局部音频实现，不依赖工作台、Analyzer、框架路径或就绪流程。

正式项目优先复用自身表现接口。使用这些组件时，将所需 Cue、预设及素材放到项目自己的正式目录，再调整场景引用；组合位置/层级仍由原生 Scene 负责。 需要多对象分组取消或窗口编排时再挂局部 Manager/Timeline；普通单对象无需该层。新增素材应在目标设备核对成本，示例的三个受管对象预算不代表性能上限。

选择“场景及依赖”导出时，除正式入口外，还要显式包含运行时加载的脚本。对本示例，在非资源包含过滤中加入 `components/feedback/*.gd`、`addons/sound_manager/abstract_audio_player_pool.gd`；仅选择 `.tscn` 不能保证 GDScript 的 `preload` 链都进入包。 另保留实际使用的第三方许可，例如 SoundManager 的 `LICENSE` 和 Shader 的 `example_shaders_license.txt`，可随包包含或放在发行说明中。 用导出包独立启动消费场景，核对图像、声音、材质、粒子、动画、编排与停止；编辑器里的 F6 成功不能替代导出验证。当前框架不预填生产导出配置。

使用全资源导出时，排除仅用于开发的 `tools/asset_workbench/`、`tools/asset_analyzer/`、测试与 `reports/`。 只有正式场景已不引用示例时，才能排除整个 `examples/asset_workbench/`；不能只因文件有 `example_` 前缀就忽略真实引用。保留正式场景实际依赖的组件、音频实现、素材和许可。

## 素材来源与许可

素材来自用户本地资源库的两个项目，按本次授权仅复制下表文件与原包许可，原件未改动。 只重命名，没有改变图片、音频字节；`a` / `b` 表示候选编号，不是音质排名。

| 示例文件 | 原始包内路径 | 资源项目 / 作者 / 来源 |
| --- | --- | --- |
| `example_trophy.png` | `PNG/Black/2x/trophy.png` | `kenney-game-icons` / Kenney / [Game icons](https://opengameart.org/content/game-icons) |
| `example_star.png` | `PNG/Black/2x/star.png` | 同上 |
| `example_confirmation_a.ogg` | `Audio/confirmation_001.ogg` | `kenney-interface-sounds` / Kenney / [Interface Sounds](https://opengameart.org/content/interface-sounds) |
| `example_confirmation_b.ogg` | `Audio/confirmation_002.ogg` | 同上 |

两包原始许可均为 CC0，分别保留在 [图标许可](assets/example_icons_license.txt) 和 [声音许可](assets/example_sounds_license.txt)。本文件记录来源，不需要生成逐素材哈希清单。

Shader 从用户指定的本地 GDQuest `godot-shaders/godot/Shaders` 复制，保留逻辑，只重命名并规范空白与换行。 完整对应与 MIT 许可见 [Shader 许可](shader_composition/example_shaders_license.txt)。 上游艺术资产采用不同许可，本例没有复制这些艺术资产；溶解遮罩在本例中用 Godot 渐变资源生成。

粒子资源通过用户指定的本地 `game-asset-library-search` Skill 检索，选用 `brackeys-vfx-in-godot`，存档版本 `23b58f272b828b0a894ed7ef72fbf9033ee9d177`。 只读取并复制所需场景、其一张贴图和原始 README，资源库原件未改动，未执行原包脚本或安装插件。作者的整项目 CC0 声明原文保留在 [example_brackeys_license.md](effects_composition/example_brackeys_license.md)。

| 原包路径（仓库根下） | 本例文件 | 处理 |
| --- | --- | --- |
| `vfx/scenes/2d_example.tscn` | `effects_composition/example_particle_stream.tscn`、`example_particle_burst.tscn`、`example_world_stream.tscn` | 复制后适配为单发射器，调整数量、寿命、速度、曲线/颜色与本地引用；爆发与场景坐标版本均为基于该样例的变体 |
| `vfx/brackeys_particle_bundle/particles/alpha/spotlight_01_a.png` | `effects_composition/example_particle_spotlight.png` | 仅重命名，图片字节不变 |
| `README.md` | `effects_composition/example_brackeys_license.md` | 保留原文与许可声明 |

`example_wobble_animation.tres`、`example_dual_group_timeline.tres` 和 Cue/预设为本项目编写；图片、音频、Shader 与粒子继续复用上文已有示例，编排阶段没有再下载或复制外部素材。

## 验证和人工体验

源码中的 `.uid` 与素材 `.import` 来自目标 Godot 的正常导入；`.godot` 缓存不随框架复制。 框架维护回归源码留在维护仓库，生成项目不自带已完成的测试任务、Feature 或通过记录。 每个实际项目按其修改选择导入、解析、lint、行为测试和必要人工体验。 自动化能验证绑定、隔离、保存与停止行为；声音是否悦耳、视觉是否协调仍需实际观看、试听。
