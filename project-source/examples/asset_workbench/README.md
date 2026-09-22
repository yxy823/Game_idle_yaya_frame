# 美术、音频、Shader 与粒子动画组合预览示例

这是可删除、可替换的开发示例，不是项目 Product、正式玩法或已验收资源。
复制框架后仍需按项目 README 完成环境准备；示例不会设置项目主场景或自动启动。

## 打开与操作

四个独立入口放在不同目录，在 Godot 中选择对应场景按 F6：

- 单对象工作台：`single/example-workbench.tscn`。
- 组合场景工作台：`composition/example-workbench.tscn`。
- Shader 组合工作台：`shader_composition/example-workbench.tscn`。
- 粒子与动画组合工作台：`effects_composition/example-workbench.tscn`。

也可在**生成项目根目录**使用配置中的引擎：

```powershell
$config = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
& $config.environment_bootstrap.engine_executable --path . 'res://examples/asset_workbench/single/example-workbench.tscn' | Out-Host
```

先完成正常导入。框架的 `project.godot` 默认视口为 1600×900，新建项目继承此值；
工作台入口及分析、批量窗口默认都使用 1600×900，不再自动按屏幕比例缩小。
显式 `--resolution` 或后续项目设置可覆盖默认值；嵌入编辑器（`--wid`）时仍受宿主区域约束，查看完整独立窗口可分离运行。
宽窗口使用可拖动三栏：资源候选、真实预览、对象 Inspector。候选列表和属性独立滚动；
对象名称、对象 A/B、未保存状态、播放及保存入口不随长表单滚动。
窄窗口通过“资源候选 / 组合预览 / 对象属性”切换区域，底部持续显示当前对象、方案、保存目标、停止和保存；
真实组合场景尺寸不足时在预览内部滚动，不重排示例对象。低频操作在具名菜单中，无布局持久化。

1. 左侧筛选已有候选；图像显示等比例缩略图及**导入后**尺寸，音频显示类型与导入后时长。“试听 / 循环试听”固定使用 -12 dB、1×、Master；“停止试听”仅停止独立试听。
2. 浏览、元数据和源分析均不绑定。按需点击“分析候选源文件”，查看后点击“应用到对象 A/B”；应用只改变当前对象的当前方案。候选更多菜单可查看、选择复制完整路径。
3. Inspector“资源绑定”分别选择图像、音频、Shader、粒子与动画片段，均可留空；全空配置有效。下方按类型编辑，Tween 可独立启用；未启用 Shader 时素材保持原色。
4. “触发”从初态重播；“循环 0.6 s / 快速 0.1 s”仍允许事件重叠。“停止全部”清除全部对象的播放、动画、循环、待触发延迟及独立试听。
5. 打开或重载时 A 使用磁盘配置；原配置有声音且存在其他音频候选时，B 只换声音，静音配置保持静音。对象 A/B 按钮明确标出选中方案。对象更多菜单提供复制到另一方案、恢复当前方案、重载及打开消费场景。
6. “保存当前方案”只保存当前 A/B 到可见目标 `.tres`，影响所有引用该 Cue 的消费场景，不修改源素材或共享材质。“保存路径…”可查看并复制完整路径。重载仍确认丢弃**当前对象的两份**草稿。
7. “打开消费场景”启动独立实例验证**已保存**配置；未保存草稿不会进入该场景。最近操作与错误在底栏显示，长消息及部分失败路径可打开“操作详情…”完整查看并复制。

默认白底黑字；顶部“外观设置”可切换深色界面。
“图像透明棋盘格”给单项图片区与单对象预览增加灰色棋盘格，辨认透明边缘；默认关闭。组合场景保留真实背景。
这些查看设置只在当前工作台会话生效，不影响素材颜色、A/B、保存的 Cue 或正式游戏环境。
黑色图标在深色背景下对比度降低属于素材与背景的真实关系，可切回浅色或启用棋盘格。

左右两种查看方式共享候选集合，但单项试听使用固定 -12 dB、1 倍速、Master 总线。
事件按右侧参数播放；没有自动响度匹配，主观比较时保持系统监听音量一致。
Inspector 的资源绑定显示实际使用的文件；左侧候选名称不代表已经绑定。无选择或类型不适用时操作禁用，非音频候选不显示试听操作。
两个原始音效属于同一确认音系列，解码时长分别约 0.290 秒和 0.539 秒；切换 A/B 不代表自动改变音色、响度或音高。
浏览器元数据来自导入后的 Texture2D / AudioStream；“分析候选源文件”打开独立“源资源分析”窗口。
第二阶段已提供后台音频/图像分析、统一 JSON、图表与同类型分析 A/B；安装和操作见
[Analyzer 说明](../../tools/asset_analyzer/README.md)。缺少可选分析依赖不影响这里的预览与播放。

## 可交互组合场景

直接运行 `composition/example-workbench.tscn`，中央加载真实的 `composition/example-composition.tscn`：奖杯、星星和奖励三个对象。
它们复用原始图片、声音与 FeedbackPresenter，每个对象使用独立的 `example-composition-*.tres`。
组合工作台自身包含对象选择、属性及分析能力，背景可切换浅色/深色。

1. 点击对象会选中并触发它。组合工作台右侧立即改为该对象的属性，底部显示真实保存目标。
2. 沿用现有候选、参数、A/B、重置与保存；试调也更新组合场景中的对应对象。切换对象不会丢弃各自 A/B；初始 B 在有另一个声音时仅换声音。
3. 预览上方“场景 A / B”切换所有对象；Inspector“对象方案 A / B”只切当前对象。全场景状态根据各对象实际方案计算，混用时显示“混合方案”且场景 A/B 均不高亮。“触发全部”清理旧播放后同时触发，单一“停止全部”负责整体停止。
4. “全场景更多…”中的“将增益应用到各对象的当前方案”只改变各对象当前 A 或 B 草稿；另一方案与磁盘不变。
5. 同一菜单的“保存全场景当前方案（逐文件）”对每个 Cue 分别执行原有冲突检查与保存，显示成功数与失败路径。它不是多文件事务：其他文件可以成功，冲突文件保留试调。
6. “对象更多…”中的“打开消费场景”读取已保存 Cue；也可打开 `composition/example-composition.tscn` 按 F6。
7. “对象更多 → 分析当前对象源资源”与“全场景更多 → 分析场景源资源”收集相应当前方案中的图片/音频，跳过空项后去重加入同一批量集合，保留既有集合成员并显示本次范围。不分析 Shader，也不测量最终混音或渲染画面。

对象位置由原生 Scene 布局维护；运行时只编辑明确支持的 Cue 参数。
Agent 可以根据画面描述组合或修改 `.tscn` 与表现组件。本例验证这种接入方式，没有在运行时实现自然语言生成器、任意节点属性编辑器或通用场景制作软件。
接真实项目时使用其已有对象/事件数据和明确的表现接口，不自动执行未知场景的业务副作用。

## Shader 与独立资源组合

运行 `shader_composition/example-workbench.tscn`。它复用组合工作台和三对象原生场景，使用独立的示例 Cue：

| 对象 | 初始组合 | Shader 来源 |
| --- | --- | --- |
| 奖杯 | 图片＋声音＋外描边 | `outline2D_outer.gdshader` → `example-outline.gdshader` |
| 星星 | 图片＋溶解，无声音 | `dissolve2D.gdshader` → `example-dissolve.gdshader` |
| 噪声 | Shader＋声音，无图片 | `value_noise.gdshader` → `example-noise.gdshader` |

右侧分别选择图片、声音和 Shader；更换某一类不会自动替换另两类。Shader 可复用于不同图片或对象，
每个对象及 A/B 草稿保存自己的强度、颜色、延迟和时长。没有图片时，Shader 在普通白色矩形上绘制；
这是明确的预览承载面，不会补选隐藏图片。具体视觉仍取决于 Shader 本身：噪声忽略图片，描边在无透明边缘的矩形上可能不明显。

Shader“强度 (0–1)”映射到预设的峰值；描边最大 10 像素，溶解最大进度 1。
触发后，映射值按 `sin(π × 进度)` 从零升到峰值再回零；Shader 的延迟、时长与音效时序分别控制。
溶解预设使用自行创建的渐变遮罩，较高强度可让整个图标消失；噪声没有强度/颜色 uniform，对应控件禁用，只调显示时序。
再次触发重启当前表面的 Shader，声音和图标脉冲仍可重叠。停止或自然结束移除运行材质，恢复原图；无图片时恢复为空。
Shader 分组显示禁用原因；“预设引用（只读）”列出类型、Shader/材质及现有纹理引用，完整路径可查看复制。不提供任意 uniform 编辑或依赖扫描。

保存仍只写当前对象的 Cue，重载和独立场景 `shader_composition/example-composition.tscn` 读取同一数据。
共享 Shader、纹理、音频及材质预设不被试调修改；每个表现对象创建独立运行材质，普通 uniform 不会串到其他对象。
源文件分析只收集已选择的图片/声音，跳过空项；不分析 Shader 源码、材质或最终渲染画面。

接入另一个 **2D `canvas_item` Shader** 时，用 `FeedbackShaderPreset` 保存材质默认值与必要 sampler，
按需填写一个 float 强度 uniform、峰值和一个 `source_color vec4` 颜色 uniform，并加入工作台场景的 `shader_candidates`。
留空 uniform 名表示该控件不适用；启动与保存会检查名字和类型。预设只定义 Shader，不绑定声音或目标图片。
当前时序契约适用于由上述参数控制的效果；依赖全局 `TIME` 的效果不能据此承诺暂停/重播一致。
本轮不提供 3D、全屏后处理、任意 uniform 编辑、多 Shader 堆叠或通用时间轴。

## 第三阶段：分组与批量检查

“候选更多 → 将筛选结果加入批量分析”把当前筛选后的候选加入分组并打开批量窗口。
可加载 `example-analysis-group.json` 体验包含四个示例资源的分组；其中阈值仅为示例，不是项目硬性规范。
操作、同类统计、规则、历史快照及缓存边界见 [批量分析说明](../../tools/asset_analyzer/README.md#分组批量分析与一致性检查)。

## 粒子、Tween 与 AnimationPlayer

运行 `effects_composition/example-workbench.tscn`；原来的三个入口保持可用。新增入口复用同一组合工作台、保存流程和消费组件：

| 对象 | 初始内容 | 可独立替换或关闭的部分 |
| --- | --- | --- |
| 爆发 / Tween | 奖杯、音效、描边、一次性 GPU 粒子及 Tween 跃动 | 图像、声音、Shader、粒子、Tween 分别控制 |
| 片段 / Shader | 星星、溶解及 AnimationPlayer 摇摆片段 | 可关闭图像、Shader 或片段，也可另外启用 Tween/粒子 |
| 持续 / 纯粒子 | 无图像、无声音的持续 GPU 粒子 | 粒子使用自己的贴图；不会自动绑定 Cue 图像或音频 |

资源绑定中的粒子与动画片段是只读预设选择，候选来自场景的 `particle_candidates`、`animation_candidates`，不扫描整个项目。
已保存的绑定即使不在候选数组里，也会保留并显示。参数只改变当前对象的当前 A/B，保存只写当前 Cue；对象/全场景/源分析 A/B、冲突和逐文件部分失败语义不变。
源分析仍只收集 Cue 的图片和音频，不把粒子内部贴图、动画片段或最终效果加入原始文件分析集合。

| 机制 | 本轮可编辑参数 | 播放与停止语义 |
| --- | --- | --- |
| GPU 粒子 | 独立预设、缩放、延迟；持续预设的发射时长 | 每对象持有一个发射器。重触发重新开始；爆发按粒子生命周期结束，持续发射停止后等待存活粒子消散。发射时长不是单颗粒子的寿命；爆发时此参数禁用 |
| Tween | 启用、跃动距离、往返时长 | 动态计算内部表现层的向上位移并返回；重触发取消前一次，再从初态开始 |
| AnimationPlayer | 独立片段、播放速度 | 播放已制作的有限动画片段；重触发从头开始，停止或自然结束恢复内部变换 |

“停止全部”、切换方案/对象、重载和退出会取消粒子延迟与动画；粒子立即隐藏并停止发射，下次触发重置 GPU 模拟，不显示旧粒子。
声音和原有图标脉冲仍可重叠；粒子、Tween、片段与当前表面的 Shader 分别重启，不为快速触发无限创建节点。
Tween 位移层与动画片段变换层互相嵌套，作用于图像/Shader 表面和粒子发射器，不移动名称、选中边框或 Inspector。
已发射粒子是否跟随变换由预设 `local_coords` 决定，本例为局部跟随。旧图标脉冲仍由原绘制逻辑拥有，不与 Tween 写同一属性。
只启用运动而没有图像、Shader 或粒子时没有可见目标；该配置仍有效，不补入隐藏素材。

新增预设的制作边界：

- 粒子使用 `FeedbackParticlePreset` 引用单根、无附加脚本/子节点的 `GPUParticles2D` 场景，模拟材质为 `ParticleProcessMaterial`；不是图像用的 `FeedbackShaderPreset`。本契约限制 1–256 颗、寿命大于 0 且不超过 5 s、速度倍率为 1。缩放 0.25–2×、延迟 0–0.6 s、持续发射时长 0.15–5 s 保存在 Cue。
- 运行发射器与其模拟材质按对象隔离；纹理、曲线及预设保持只读共享。制作复杂粒子场景、子发射器、碰撞或自定义模拟 Shader 需要另行明确契约。
- 动画使用已保存的 `Animation` 资源，本例为 `example-wobble-animation.tres`。仅接受长度大于 0 且不超过 5 s 的非循环片段，以及目标为 `.:position`、`.:scale`、`.:rotation` 的有限数值轨道；不执行方法、音频或跨对象轨道。可在 Godot 编辑器制作片段，工作台只选择和调整速度。
- Tween 往返时长 0.15–3 s、距离 0–80 px；片段速度 0.5–2×。源文件、共享预设、AnimationLibrary 和运行中的 Tween 不通过 Cue 保存改写。

独立运行 `effects_composition/example-composition.tscn` 即可消费已保存的三份 Cue。这里没有新增 Manager、统一时间轴或通用动画编辑器。

## 数据和运行边界

| 位置 | 职责 |
| --- | --- |
| `single/example-workbench.tscn` | 单对象工作台入口、候选与明确保存目标 |
| `single/example-feedback.tres` | 单对象事件配置；工作台保存，奖励示例游戏直接读取 |
| `single/example-game.tscn`、`single/example_reward_game.gd` | 独立消费方；只有进程内奖励计数，没有真实存档或业务副作用 |
| `composition/example-workbench.tscn` | 独立组合工作台；直接选择场景内对象并编辑属性 |
| `composition/example-composition.tscn`、该目录的 `example-composition-*.tres` | 三对象真实场景及分别保存的表现配置；不改单对象配置 |
| `shader_composition/` | 继承三对象示例的 Shader 工作台、独立 Cue、材质预设、复制重命名的 Shader 与许可 |
| `effects_composition/` | 粒子/Tween/AnimationPlayer 组合入口与消费场景、独立 Cue、发射器预设、动画片段及示例贴图/许可 |
| `example-analysis-group.json` | 可携带的资源分组与示例规则，不包含缓存或通过记录 |
| `assets/example-*` | 仅示例素材及许可；禁止据此推定其适合当前游戏 |
| `components/feedback/` | Cue、图像/Shader 表面、图标脉冲、局部音频、独立粒子与运动层；各入口共用同一表现逻辑 |
| `tools/asset_workbench/` | 候选浏览、试调和保存界面；不注册全局服务 |
| `tools/asset_analyzer/` | 源文件专业分析与适配器；独立于音频播放，不写回 Cue |

首期是一项奖励按钮的 Activate 事件：一个图标、程序生成的确定性脉冲/放射线、一个声音。
它没有通用 Object/State/Event 引擎、完整时间轴、多音轨编辑、空间音频或音乐管理。
已有游戏对象应接入其现有表现组件与配置；不要为了使用本示例复制一套正式关系模型。

试调复制 Cue 的值字段，纹理/音频/Shader/粒子预设与动画片段保持只读共享；运行材质、发射器和动画状态按对象持有。保存前检查磁盘内容是否变化，
保存后绕过 Cue 缓存重新加载并核对；冲突或失败保留试调并显示原因。磁盘冲突检查不提供多进程事务锁。
保存仅供 Godot 编辑器二进制的开发运行使用，导出游戏不得依赖写回 `res://`。
所有引用这个目标 Cue 的对象都受保存影响；接真实项目前应明确这个范围。

音频封装直接复用 [SoundManager 固定提交](../../addons/sound_manager/UPSTREAM.md) 的局部池，
不启用其全局插件。最多重叠 16 个非空间声音；到达上限返回可见错误，不改全局总线音量。
切换、停止和退出使旧延迟请求失效；不把引擎帧调度当成采样级同步。

正式游戏导出时选择正式入口场景及依赖。使用全资源导出时，显式排除本示例与
`tools/asset_workbench/`、`tools/asset_analyzer/` 和 `reports/`；保留正式场景实际依赖的组件及音频实现。当前框架不预填生产导出配置。
删除示例前核对正式场景没有引用其中资产；不能只因文件有 `example-` 前缀就忽略真实引用。

## 素材来源与许可

素材来自用户本地资源库的两个项目，按本次授权仅复制下表文件与原包许可，原件未改动。
只重命名，没有改变图片、音频字节；`a` / `b` 表示候选编号，不是音质排名。

| 示例文件 | 原始包内路径 | 资源项目 / 作者 / 来源 |
| --- | --- | --- |
| `example-trophy.png` | `PNG/Black/2x/trophy.png` | `kenney-game-icons` / Kenney / [Game icons](https://opengameart.org/content/game-icons) |
| `example-star.png` | `PNG/Black/2x/star.png` | 同上 |
| `example-confirmation-a.ogg` | `Audio/confirmation_001.ogg` | `kenney-interface-sounds` / Kenney / [Interface Sounds](https://opengameart.org/content/interface-sounds) |
| `example-confirmation-b.ogg` | `Audio/confirmation_002.ogg` | 同上 |

两包原始许可均为 CC0，分别保留在 [图标许可](assets/example-icons-license.txt) 和
[声音许可](assets/example-sounds-license.txt)。本文件记录来源，不需要生成逐素材哈希清单。

Shader 从用户指定的本地 GDQuest `godot-shaders/godot/Shaders` 复制，保留逻辑，只重命名并规范空白与换行。
完整对应与 MIT 许可见 [Shader 许可](shader_composition/example-shaders-license.txt)。
上游艺术资产采用不同许可，本例没有复制这些艺术资产；溶解遮罩在本例中用 Godot 渐变资源生成。

粒子资源通过用户指定的本地 `game-asset-library-search` Skill 检索，选用 `brackeys-vfx-in-godot`，存档版本 `23b58f272b828b0a894ed7ef72fbf9033ee9d177`。
只读取并复制所需场景、其一张贴图和原始 README，资源库原件未改动，未执行原包脚本或安装插件。作者的整项目 CC0 声明原文保留在 [example-brackeys-license.md](effects_composition/example-brackeys-license.md)。

| 原包路径（仓库根下） | 本例文件 | 处理 |
| --- | --- | --- |
| `vfx/scenes/2d_example.tscn` | `effects_composition/example-particle-stream.tscn`、`example-particle-burst.tscn` | 复制后适配为单发射器，调整数量、寿命、速度、曲线/颜色与本地引用；爆发为基于该样例的变体 |
| `vfx/brackeys_particle_bundle/particles/alpha/spotlight_01_a.png` | `effects_composition/example-particle-spotlight.png` | 仅重命名，图片字节不变 |
| `README.md` | `effects_composition/example-brackeys-license.md` | 保留原文与许可声明 |

`example-wobble-animation.tres` 和本轮 Cue/预设为本项目编写；图片、音频与 Shader 继续复用上文已有示例，不把程序制作的动画误记成下载素材。

## 验证和人工体验

源码中的 `.uid` 与素材 `.import` 来自目标 Godot 的正常导入；`.godot` 缓存不随框架复制。
框架维护回归源码留在维护仓库，生成项目不自带已完成的测试任务、Feature 或通过记录。
每个实际项目按其修改选择导入、解析、lint、行为测试和必要人工体验。
自动化能验证绑定、隔离、保存与停止行为；声音是否悦耳、视觉是否协调仍需实际观看、试听。
