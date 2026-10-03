# 表现反馈组件

`components/feedback/` 是纯表现组件：Cue 资源、图像与 Shader 表面、图标脉冲、局部音频、GPU 粒子、运动层，以及可选的场景局部播放管理与有限编排。它不执行奖励、背包、存档或网络等业务逻辑，也不注册全局服务。[资源工作台示例](../../asset_workbench/examples/README.md)的四个入口共用这套组件。

正式项目优先复用自身已有的表现接口。需要使用这些组件时：

1. 把所需 Cue、预设及素材放到项目自己的正式目录，再调整场景引用。
2. 组合位置与层级仍在原生 Godot 场景中制作。
3. 只有需要多对象分组取消或窗口编排时，才挂局部 Manager/Timeline；普通单对象不需要这一层。
4. 新增素材在目标设备上核对成本。

组件没有通用的 Object/State/Event 引擎、完整时间轴、多音轨编辑、空间音频或音乐管理。已有游戏对象应接入其现有表现组件与配置，不要为了使用本组件复制一套正式关系模型。

## 文件与职责

| 文件 | 职责 |
| --- | --- |
| `feedback_cue.gd`（`FeedbackCue`） | 可选的图像、音频、Shader、粒子、动画与 Tween 绑定及数值；所引用素材保持只读 |
| `feedback_object.gd` | 可选中的表现对象，通过 `cue_resource` 绑定已保存的 Cue；不执行业务状态 |
| `feedback_presenter.gd` | 组合图像表面、音频、粒子与运动层的纯表现节点 |
| `feedback_visual.gd` | 图像表面及可选、独立计时的材质效果；只有 Shader 时在白色矩形上绘制 |
| `feedback_shader_preset.gd`（`FeedbackShaderPreset`） | 只读材质默认值，以及工作台可调的强度、颜色 uniform 契约 |
| `feedback_particles.gd`、`feedback_particle_preset.gd`（`FeedbackParticlePreset`） | 每对象一个 GPU 发射器，及其只读单发射器预设 |
| `feedback_motion.gd` | Tween 位移层与动画片段变换层 |
| `audio_playback.gd` | 局部音频池封装，唯一直接使用第三方音频 API 的文件 |
| `feedback_composition.gd` | 以场景相对节点路径登记一组对象，提供整体停止和可选的编排播放 |
| `feedback_playback_manager.gd` | 可选的场景局部播放管理与预算 |
| `feedback_timeline.gd`（`FeedbackTimeline`）、`feedback_timeline_clip.gd`（`FeedbackTimelineClip`）、`feedback_timeline_player.gd` | 有限编排的数据与播放时钟 |

## Cue 与消费绑定

消费对象通过 `cue_resource: FeedbackCue` 绑定已保存的 Cue，场景由此声明 Cue 及其媒体与预设依赖。工作台的保存路径从这个引用派生，不另存第二份目标。

- 消费实例进入场景时绕过 Cue 缓存重读，以取得最近一次保存。
- 没有绑定 Cue，与“已绑定但内容全空”的 Cue 不同；后者有效，播放时没有可见或可听内容。
- 试调只复制 Cue 的值字段。纹理、音频、Shader 预设、粒子预设与动画片段保持只读共享；运行材质、发射器和动画状态按对象持有。
- 所有引用同一个 Cue 的对象都受该 Cue 保存的影响；接入真实项目前要明确这个范围。

## Shader 预设

接入一个 **2D `canvas_item` Shader** 时，用 `FeedbackShaderPreset` 保存材质默认值与必要的 sampler：

- 按需填写一个 float 强度 uniform 及其峰值，以及一个 `source_color vec4` 颜色 uniform。uniform 名留空表示对应控件不适用。
- 启动与保存时检查 uniform 的名称和类型。
- 预设只定义 Shader，不绑定声音或目标图片。每个表现对象复制一份运行材质，普通 uniform 不会串到其他对象。

强度映射到预设峰值，触发后按 `sin(π × 进度)` 从零升到峰值再回零；Shader 的延迟、时长与音效时序分别控制。这一时序契约只适用于由上述参数控制的效果，依赖全局 `TIME` 的效果不能据此承诺暂停或重播一致。不支持 3D、全屏后处理、任意 uniform 编辑或多 Shader 堆叠。

## 粒子、动画与 Tween 的限制

- **粒子**：`FeedbackParticlePreset` 引用单根、无附加脚本或子节点的 `GPUParticles2D` 场景，模拟材质为 `ParticleProcessMaterial`；它不是图像用的 `FeedbackShaderPreset`。预设限制为 1–256 颗、寿命大于 0 且不超过 5 s、速度倍率为 1。Cue 保存缩放 0.25–2×、延迟 0–0.6 s 与持续发射时长 0.15–5 s。
- **粒子共享范围**：运行发射器与其模拟材质按对象隔离；纹理、曲线及预设只读共享。复杂粒子场景、子发射器、碰撞或自定义模拟 Shader 需要另行明确契约。
- **动画**：使用已保存的 `Animation` 资源。只接受长度大于 0 且不超过 5 s 的非循环片段，以及目标为 `.:position`、`.:scale`、`.:rotation` 的有限数值轨道；不执行方法、音频或跨对象轨道。
- **Tween**：往返时长 0.15–3 s，距离 0–80 px；片段速度 0.5–2×。
- **只读来源**：源文件、共享预设、AnimationLibrary 和运行中的 Tween 不会因保存 Cue 而被改写。

Tween 位移层与动画片段变换层互相嵌套，作用于图像或 Shader 表面和粒子发射器，不移动名称、选中边框或 Inspector。已发射粒子是否跟随变换由预设的 `local_coords` 决定；场景坐标不表示独立生存，停止或移除所属对象仍会清除其粒子。

## 组合与登记

`feedback_composition.gd` 用场景相对节点路径（如 `GroupA/Core`）登记对象。路径标识当前实例，共享的 Cue 路径只表示保存目标。

- 组合位置、附着与绘制顺序在原生场景中制作；Presenter 的运动层只控制内部表现，组合根的变换由消费场景拥有。
- 调用单个 Presenter 的 `stop()` 只停止该对象；组合的 `stop()` 停止其登记的全部对象。移除整个组合实例会取消其子对象的延迟与播放，其他实例继续运行。
- 登记集合在对象退出时剔除该对象。动态新增、移除后重新加入同一节点，以及运行时编辑场景拓扑，都不在契约内；需要时重新实例化完整场景。

## 场景局部管理与有限编排

| 组件 | 契约与边界 |
| --- | --- |
| `feedback_playback_manager.gd` | 可选的场景内 Node。`request(presenter, group, priority)` 返回本 Manager 内有效的整数句柄，0 表示拒绝。句柄拥有整个对象的一次独占播放（包括延迟音频），不代表可以单独取消每个叠加声部 |
| 预算与回收 | 默认上限 8 个受管对象。满额时只接受严格更高优先级的请求，抢占最低优先级中最早的句柄；其他请求被拒绝并反馈，不排队。自然结束、取消或目标退出时释放句柄；不销毁现有对象，也不建立新对象池 |
| 取消与直接播放 | `cancel(handle)`、`cancel_group(group)`、`stop_all()` 只取消这个 Manager 仍拥有的播放。直接 `trigger()` 接管同一目标时先停止受管播放，之后手动快速触发仍允许声音重叠。旧句柄不能停止新播放；未受管对象仍可直接使用 Presenter |
| `FeedbackTimeline` / `FeedbackTimelineClip` | 原生 `.tres` 保存长度及片段数组；每个片段只有相对对象路径、起点、持续时间和优先级。长度最多 120 s，1–128 个片段。同一目标的窗口不可重叠，可首尾相接；不支持绝对路径、父级路径或 `%` 别名 |
| `feedback_timeline_player.gd` | 一个场景帧时钟负责窗口的开始、截止及循环。截止立即取消该句柄，可能截短声音或粒子余尾；效果提早结束不会补触发。Tween、AnimationPlayer、粒子及声音仍由各自组件推进 |

预算与并发：

- Manager 统计的是对象数，不是粒子数、显存或音频声部；直接触发不受这个预算约束，不能据此承诺性能上限。
- 多个 Manager 不共享限额。它们若争用同一 Presenter，后一次受管播放接管该目标，旧句柄失效。
- 处理 Manager 或 Timeline 的同步通知时可以取消或停止；需要重新申请或播放时用 `call_deferred`。同步重入会被拒绝，避免通知链递归修改正在处理的集合。

编排的调度规则：

- 编排到期时先取消旧窗口，再按**片段数组顺序**申请本帧的新窗口；同帧中排在后面的高优先级片段可以抢占先前已启动的低优先级对象。
- 被拒绝或被抢占的片段本轮不重试；同一窗口内被直接接管也不补播，下一轮才重新按定义申请。
- 卡顿后，已完整错过的窗口或循环会跳过；仍开放的窗口从效果开头触发，到定义终点截止，不补算粒子或音频的过去状态。
- 播放时复制编排定义，运行中修改共享定义只影响下次播放；目标的当前 Cue 在各窗口开始时读取。

编排 Resource 在 Godot Inspector 中编辑并保存，再赋给组合场景的 `timeline`。普通连续属性动画继续使用原生 AnimationPlayer；有限编排只补充跨对象触发、句柄取消和预算反馈，不开放任意方法或属性轨道。没有暂停、跳转、可视化轨道编辑、多轨混音、采样级同步或全局 Manager；全局 Shader `TIME` 不随编排重置。

## 局部音频

`audio_playback.gd` 直接复用 [SoundManager 固定提交](../../addons/sound_manager/UPSTREAM.md)的局部池，不启用其全局插件。

- 最多重叠 16 个非空间声音；达到上限时返回可见错误，不改全局总线音量。
- 切换、停止和退出会使旧的延迟请求失效。
- 引擎帧调度不是采样级同步。

导出包含这些组件的场景时，按[消费接入与导出](../../asset_workbench/examples/README.md#消费接入与导出)显式包含运行时加载的脚本与第三方许可。
