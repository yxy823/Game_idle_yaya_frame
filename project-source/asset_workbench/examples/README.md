# 美术、音频、Shader 与粒子动画组合预览示例

这是可删除、可替换的开发示例，不是项目 Product、正式玩法或已验收资源。使用前按项目 README 完成环境准备；示例不会设置项目主场景，也不会自动启动。示例使用的表现组件契约见[表现反馈组件](../../../components/feedback/README.md)。

## 打开与操作

四个入口放在不同目录，在 Godot 中选择对应场景按 F6。按当前要验证的行为选择，不必逐个完成：

| 工作台入口 | 代表性检查 | 保存后的消费入口 |
| --- | --- | --- |
| `single/example_workbench.tscn` | 单对象浏览、试听、A/B、保存 | `single/example_game.tscn` |
| `composition/example_workbench.tscn` | 多对象选择、混合 A/B、逐文件保存 | `composition/example_composition.tscn` |
| `shader_composition/example_workbench.tscn` | 材质隔离、无图像承载面、独立绑定 | `shader_composition/example_composition.tscn` |
| `effects_composition/example_workbench.tscn` | 粒子与运动组合、共享 Cue 多实例、局部 Manager 与有限编排 | `effects_composition/example_consumer.tscn` |

也可在生成项目的根目录使用配置中的引擎打开：

```powershell
$config = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
& $config.engine_executable --path . 'res://yaya/asset_workbench/examples/single/example_workbench.tscn' | Out-Host
```

先完成正常导入。

### 窗口与布局

- **尺寸**：项目的 `project.godot` 默认视口为 1600×900，工作台入口及分析、批量窗口也都默认 1600×900。显式 `--resolution` 或项目设置可以覆盖。工作台运行时临时把窗口改为不拉伸，按实际像素布局，退出时恢复项目的拉伸设置。嵌入编辑器（`--wid`）时仍受宿主区域约束，要看完整窗口可分离运行。
- **宽窗口**：可拖动的三栏，依次是资源候选、真实预览和对象 Inspector。候选列表和属性各自滚动；对象名称、对象 A/B、未保存状态、播放及保存入口不随长表单滚动。
- **窄窗口**：用“资源候选 / 组合预览 / 对象属性”切换区域，底部持续显示当前对象、方案、保存目标、停止和保存。真实组合场景尺寸不足时在预览内部滚动，不重排示例对象。
- 低频操作放在具名菜单中；布局不持久保存。

### 单对象操作

1. 在左侧筛选候选。图像显示等比例缩略图及**导入后**尺寸，音频显示类型与导入后时长；这些元数据来自导入后的 Texture2D 与 AudioStream。
2. “试听 / 循环试听”固定使用 -12 dB、1 倍速、Master 总线；“停止试听”只停止独立试听。没有自动响度匹配，主观比较时保持系统监听音量一致。非音频候选不显示试听操作。
3. 浏览、元数据和源分析都不会绑定资源。按需点击“分析候选源文件”打开独立的“源资源分析”窗口，查看后点击“应用到对象 A/B”；应用只改变当前对象的当前方案。安装与操作见 [Analyzer 说明](../analyzer/README.md)；缺少可选分析依赖不影响预览与播放。
4. Inspector 的“资源绑定”分别选择图像、音频、Shader、粒子与动画片段，均可留空，全空配置也有效。它显示实际使用的文件；左侧候选名称不代表已经绑定。下方按类型编辑，Tween 可单独启用；未启用 Shader 时素材保持原色。
5. “触发”从初态重播；“循环 0.6 s / 快速 0.1 s”仍允许事件重叠。“停止全部”清除全部对象的播放、动画、循环、待触发延迟及独立试听。
6. 打开或重载时，A 使用磁盘上的配置。原配置有声音且存在其他音频候选时，B 只换声音；静音配置保持静音。对象 A/B 按钮标出当前选中的方案。“对象更多”菜单提供复制到另一方案、恢复当前方案、重载及打开消费场景。
7. “保存当前方案”只把当前 A 或 B 保存到可见的目标 `.tres`，影响所有引用该 Cue 的消费场景，不修改源素材或共享材质。“保存路径…”可查看并复制完整路径。重载会确认丢弃**当前对象的两份**草稿。
8. “打开消费场景”启动独立实例，验证**已保存**的配置；未保存的草稿不会进入该场景。最近的操作与错误显示在底栏，长消息和部分失败的路径可在“操作详情…”中完整查看并复制。

示例中的两个原始音效属于同一确认音系列，解码时长分别约 0.290 秒和 0.539 秒。切换 A/B 不会自动改变音色、响度或音高。

### 外观设置

- 默认白底黑字，顶部“外观设置”可切换为深色界面。
- “图像透明棋盘格”给单项图片区与单对象预览增加灰色棋盘格，便于辨认透明边缘；默认关闭。组合场景保留真实背景。
- 这些设置只在当前工作台会话生效，不影响素材颜色、A/B、保存的 Cue 或正式游戏环境。
- 黑色图标在深色背景下对比度降低，是素材与背景的真实关系；可切回浅色或启用棋盘格。

## 可交互组合场景

运行 `composition/example_workbench.tscn`，中央加载真实的 `composition/example_composition.tscn`，其中有奖杯、星星和奖励三个对象。它们复用原始图片、声音与 FeedbackPresenter，每个对象使用独立的 `example_composition_*.tres`。工作台自身包含对象选择、属性及分析能力，背景可切换浅色或深色。

1. 点击对象会选中并触发它，右侧立即改为该对象的属性，底部显示真实保存目标。
2. 候选、参数、A/B、重置与保存的用法与单对象相同；试调同时更新组合场景中的对应对象。切换对象不会丢弃各自的 A/B；有另一个声音时，初始 B 只换声音。
3. 预览上方的“场景 A / B”切换所有对象，Inspector 的“对象方案 A / B”只切换当前对象。全场景状态根据各对象实际方案计算；混用时显示“混合方案”，场景 A/B 都不高亮。“触发全部”先清理旧播放再同时触发，“停止全部”负责整体停止。
4. “全场景更多…”中的“将增益应用到各对象的当前方案”只改变各对象当前 A 或 B 的草稿，另一方案与磁盘不变。
5. 同一菜单的“保存全场景当前方案（逐文件）”按 Cue 文件分别检查与保存，显示成功文件数与失败路径。同一文件的多个当前草稿一致时只写一次；不一致时跳过该文件，需要先统一草稿或只保存选中对象。这不是多文件事务：其他文件可以成功，冲突文件保留试调内容。
6. “对象更多…”中的“打开消费场景”读取已保存的 Cue；也可直接打开 `composition/example_composition.tscn` 按 F6。
7. “对象更多 → 分析当前对象源资源”与“全场景更多 → 分析场景源资源”收集相应当前方案中的图片和音频，跳过空项后去重加入同一批量集合；集合原有成员保留，并显示本次范围。它们不分析 Shader，也不测量最终混音或渲染画面。

加入集合后的反馈区分实际新增、已在集合中和跳过的项。AtlasTexture、音频 `.tres` 等间接资源不能作为源文件分析，会显示原因，不会自动改为分析其内部资源。

首次加载 Cue 失败的对象仍可选中，界面显示它的保存目标与加载错误，参数区暂时隐藏；浏览、独立试听与候选分析仍可使用。修正目标文件后，从“对象更多”重载即可恢复试调，其他对象的草稿不变。全场景方案切换、增益和源资源收集跳过未加载对象；全场景保存列出这些对象及其错误，同一目标文件有未加载对象时不写入该文件。

对象位置由原生场景布局维护，运行时只编辑明确支持的 Cue 参数。Agent 可以按画面描述组合或修改 `.tscn` 与表现组件；本例验证的是这种接入方式，运行时没有自然语言生成器、任意节点属性编辑器或通用场景制作功能。接入真实项目时，使用项目已有的对象与事件数据和明确的表现接口，不自动执行未知场景的业务副作用。

## Shader 与独立资源组合

运行 `shader_composition/example_workbench.tscn`。它复用组合工作台和三对象原生场景，使用独立的示例 Cue：

| 对象 | 初始组合 | Shader 来源 |
| --- | --- | --- |
| 奖杯 | 图片＋声音＋外描边 | `outline2D_outer.gdshader` → `example_outline.gdshader` |
| 星星 | 图片＋溶解，无声音 | `dissolve2D.gdshader` → `example_dissolve.gdshader` |
| 噪声 | Shader＋声音，无图片 | `value_noise.gdshader` → `example_noise.gdshader` |

- 右侧分别选择图片、声音和 Shader；更换其中一类不会自动替换另两类。同一 Shader 可用于不同图片或对象，每个对象及其 A/B 草稿各自保存强度、颜色、延迟和时长。
- 没有图片时，Shader 画在普通白色矩形上。这是明确的预览承载面，不会补选隐藏图片。具体效果仍取决于 Shader 本身：噪声忽略图片，描边在没有透明边缘的矩形上可能不明显。
- “强度 (0–1)”映射到预设峰值：描边最大 10 像素，溶解最大进度 1。溶解预设使用自行创建的渐变遮罩，较高强度可让整个图标消失。噪声没有强度和颜色 uniform，对应控件禁用，只能调显示时序。
- 再次触发会重启当前表面的 Shader，声音和图标脉冲仍可重叠。停止或自然结束时移除运行材质，恢复原图；没有图片时恢复为空。
- Shader 分组会显示控件禁用的原因。“预设引用（只读）”列出类型、Shader、材质及现有纹理引用，完整路径可查看复制。工作台不提供任意 uniform 编辑或依赖扫描。

保存仍只写当前对象的 Cue，重载和独立场景 `shader_composition/example_composition.tscn` 读取同一数据。共享的 Shader、纹理、音频及材质预设不会被试调修改。源文件分析只收集已选择的图片和声音，跳过空项，不分析 Shader 源码、材质或最终渲染画面。

接入另一个 Shader 的预设要求和时序契约，见[表现反馈组件的 Shader 预设](../../../components/feedback/README.md#shader-预设)。

## 分组与批量检查

“候选更多 → 将筛选结果加入批量分析”把当前筛选后的候选加入分组，并打开批量窗口。可加载 `example_analysis_group.json` 体验包含四个示例资源的分组；其中的阈值只是示例，不是项目规范。操作、同类统计、规则、历史快照及缓存边界见[批量分析说明](../analyzer/README.md#分组批量分析与一致性检查)。

## 粒子、Tween 与 AnimationPlayer

运行 `effects_composition/example_workbench.tscn`。GroupA、GroupB 各实例化一次 `example_effect_cluster.tscn`，每个组合包含以下三个对象：

| 对象 | 初始内容 | 可独立替换或关闭的部分 |
| --- | --- | --- |
| 核心组合 | 奖杯、音效、描边、一次性 GPU 粒子、Tween 跃动及 AnimationPlayer 摇摆 | 所有绑定可独立替换或清空，Tween 单独启用 |
| 局部粒子 | 无图像和声音的持续 GPU 粒子与 Tween | 已发射粒子跟随表现层位移；粒子使用自己的贴图 |
| 场景粒子 | 同类持续 GPU 粒子与 Tween，预设 `local_coords=false` | 已发射粒子留在场景坐标，发射源继续随表现层移动 |

- 资源绑定中的粒子与动画片段是只读预设选择，候选来自场景的 `particle_candidates`、`animation_candidates`，不扫描整个项目。已保存的绑定即使不在候选数组里，也会保留并显示。
- 参数只改变当前对象的当前 A/B，保存只写当前 Cue；对象、全场景与源分析的 A/B、冲突和逐文件部分失败的处理与上文相同。
- 源分析仍只收集 Cue 的图片和音频，不把粒子内部贴图、动画片段或最终效果加入源文件分析集合。

| 机制 | 可编辑参数 | 播放与停止 |
| --- | --- | --- |
| GPU 粒子 | 独立预设、缩放、延迟；持续预设的发射时长 | 每对象一个发射器。重触发重新开始；爆发按粒子生命周期结束，持续发射停止后等待存活粒子消散。发射时长不是单颗粒子的寿命；爆发预设下该参数禁用 |
| Tween | 启用、跃动距离、往返时长 | 动态计算内部表现层的向上位移并返回；重触发取消前一次，再从初态开始 |
| AnimationPlayer | 独立片段、播放速度 | 播放已制作的有限动画片段；重触发从头开始，停止或自然结束时恢复内部变换 |

停止与重叠：

- “停止全部”、切换方案或对象、重载和退出，会取消粒子延迟与动画。粒子立即隐藏并停止发射，下次触发重置 GPU 模拟，不显示旧粒子。
- 声音和图标脉冲仍可重叠；粒子、Tween、片段与当前表面的 Shader 各自重启，快速触发不会无限创建节点。图标脉冲由原有绘制逻辑负责，不与 Tween 写同一属性。
- Inspector 显示预设 `local_coords` 的含义；本例同时提供局部跟随与场景坐标两种粒子。
- 只启用运动而没有图像、Shader 或粒子时，画面上没有可见目标；该配置仍然有效，不会补入隐藏素材。

本例的动画片段为 `example_wobble_animation.tres`，可在 Godot 编辑器中制作片段，工作台只负责选择和调整速度。新增粒子、动画预设的取值范围与制作限制见[表现反馈组件](../../../components/feedback/README.md#粒子动画与-tween-的限制)。

### 组合复用、保存和消费

`example_composition.tscn` 用场景相对节点路径（如 `GroupA/Core`）登记六个对象。工作台显示对象所属的组名及共享保存目标的提示。两个组合中对应的对象共用三份 `example_cluster_*_cue.tres`，但各对象仍独立拥有 A/B 草稿、运行材质、发射器和动画状态。

- 只保存一个对象也会更新共享的 Cue。其他对象的未保存草稿不会被自动替换，之后保存时会因磁盘内容变化提示重载。
- 重载只丢弃选中对象的两份草稿。
- 全场景保存按[可交互组合场景](#可交互组合场景)中的规则处理同一文件的一致或分歧草稿，不按遍历顺序覆盖。

“打开消费场景”运行 `example_consumer.tscn`。它继承组合场景，改变两个组合根的摆放、旋转和缩放，读取同一批已保存的 Cue，不依赖工作台或框架路径。`Core` 的 `z_index=1`，另两个为 0。组合的停止与登记规则见[表现反馈组件的组合与登记](../../../components/feedback/README.md#组合与登记)。

粒子候选是三个明确的预设，片段候选为一个，没有按并发实例数复制候选。`example_burst_cue.tres`、`example_animation_cue.tres`、`example_stream_cue.tres` 作为单一机制的独立示例保留。示例不附带性能测量结果，不能作为任何设备或任意素材的性能保证；没有全项目扫描或预设数据库。

### 场景局部管理与有限编排

第四个工作台的预览上方提供“播放编排”和“循环编排”（循环设置下次播放时生效），旁边显示实际播放状态。

- 示例 `example_dual_group_timeline.tres` 长 4.8 s：A 组核心先触发，局部和场景粒子随后并行，再轮到 B 组，最后两组核心同时触发。
- 工作台播放读取各对象**当前的 A/B 草稿**，不绑定候选，也不修改 Cue。停止全部、编辑、切换对象或方案、保存及重载都会停止播放，并取消后续片段和循环。
- 消费场景读取同一编排和**已保存的 Cue**，提供播放与循环、受管触发 A 组、高优先级 B 组、取消受管 A 组及停止全部，便于单独检查调度。示例最多同时管理 3 个对象。
- 工作台只播放编排定义，没有时间轴编辑或保存按钮；“保存当前方案/全场景”仍只写 Cue。

Manager 的句柄、预算、取消规则与编排的调度规则见[表现反馈组件的场景局部管理与有限编排](../../../components/feedback/README.md#场景局部管理与有限编排)。

## 示例文件

| 位置 | 职责 |
| --- | --- |
| `single/example_workbench.tscn` | 单对象工作台入口、候选与明确的保存目标 |
| `single/example_feedback.tres` | 单对象事件配置；工作台保存，奖励示例游戏直接读取 |
| `single/example_game.tscn`、`single/example_reward_game.gd` | 独立消费方；只有进程内的奖励计数，没有真实存档或业务副作用 |
| `composition/example_workbench.tscn` | 组合工作台；直接选择场景内对象并编辑属性 |
| `composition/example_composition.tscn`、该目录的 `example_composition_*.tres` | 三对象真实场景及分别保存的表现配置；不改单对象配置 |
| `shader_composition/` | 继承三对象示例的 Shader 工作台、独立 Cue、材质预设、复制并重命名的 Shader 与许可 |
| `effects_composition/` | 第四个工作台入口、可复用的三对象组合、双实例预览与独立消费场景、Cue、发射器预设、动画片段及示例贴图与许可 |
| `example_analysis_group.json` | 可携带的资源分组与示例规则，不包含缓存或通过记录 |
| `assets/example_*` | 仅为示例素材及许可；不能据此推定它们适合当前游戏 |

单对象示例是一个奖励按钮的 Activate 事件：一个图标、程序生成的确定性脉冲与放射线、一个声音。

### 保存的边界

- 保存前检查磁盘内容是否变化；保存后绕过 Cue 缓存重新加载并核对。冲突或失败时保留试调内容并显示原因。
- 磁盘冲突检查不提供多进程事务锁。
- 保存只供 Godot 编辑器二进制的开发运行使用，导出的游戏不得依赖写回 `res://`。

## 消费接入与导出

四个消费入口只使用自身场景、表现组件和局部音频实现，不依赖工作台、Analyzer、框架路径或就绪流程。Cue 的绑定方式见[表现反馈组件的 Cue 与消费绑定](../../../components/feedback/README.md#cue-与消费绑定)。

选择“场景及依赖”导出时：

1. 除正式入口外，显式包含运行时加载的脚本。对本示例，在非资源包含过滤中加入 `components/feedback/*.gd`、`addons/sound_manager/abstract_audio_player_pool.gd`；只选择 `.tscn` 不能保证 GDScript 的 `preload` 链都进入包。
2. 保留实际使用的第三方许可，例如 SoundManager 的 `LICENSE` 和 Shader 的 `example_shaders_license.txt`，可随包包含或放在发行说明中。
3. 用导出包独立启动消费场景，核对图像、声音、材质、粒子、动画、编排与停止。编辑器里 F6 成功不能代替导出验证。项目不预填生产导出配置。

使用全资源导出时，排除仅用于开发的 `yaya/asset_workbench/ui/`、`yaya/asset_workbench/analyzer/`、测试与 `reports/`。只有正式场景已不引用示例时，才能排除整个 `yaya/asset_workbench/examples/`；不能只因文件有 `example_` 前缀就忽略真实引用。保留正式场景实际依赖的组件、音频实现、素材和许可。

## 素材来源与许可

图片与音效复制自以下两个资源包，只复制了下表文件与原包许可，只重命名，没有改变图片和音频字节。`a` / `b` 表示候选编号，不是音质排名。

| 示例文件 | 原始包内路径 | 资源项目 / 作者 / 来源 |
| --- | --- | --- |
| `example_trophy.png` | `PNG/Black/2x/trophy.png` | `kenney-game-icons` / Kenney / [Game icons](https://opengameart.org/content/game-icons) |
| `example_star.png` | `PNG/Black/2x/star.png` | 同上 |
| `example_confirmation_a.ogg` | `Audio/confirmation_001.ogg` | `kenney-interface-sounds` / Kenney / [Interface Sounds](https://opengameart.org/content/interface-sounds) |
| `example_confirmation_b.ogg` | `Audio/confirmation_002.ogg` | 同上 |

两包原始许可均为 CC0，分别保留在[图标许可](assets/example_icons_license.txt)和[声音许可](assets/example_sounds_license.txt)。本文件记录来源，不需要逐素材的哈希清单。

Shader 复制自 GDQuest `godot-shaders` 仓库的 `godot/Shaders` 目录，保留逻辑，只重命名并规范空白与换行。完整对应关系与 MIT 许可见 [Shader 许可](shader_composition/example_shaders_license.txt)。上游的艺术资产采用不同许可，本例没有复制；溶解遮罩用 Godot 渐变资源生成。

粒子资源来自 `brackeys-vfx-in-godot` 仓库，提交 `23b58f272b828b0a894ed7ef72fbf9033ee9d177`。只复制了所需场景、一张贴图和原始 README，没有执行原包脚本或安装插件。作者的整项目 CC0 声明原文保留在 [example_brackeys_license.md](effects_composition/example_brackeys_license.md)。

| 原包路径（仓库根下） | 本例文件 | 处理 |
| --- | --- | --- |
| `vfx/scenes/2d_example.tscn` | `effects_composition/example_particle_stream.tscn`、`example_particle_burst.tscn`、`example_world_stream.tscn` | 复制后改为单发射器，调整数量、寿命、速度、曲线与颜色及本地引用；爆发与场景坐标版本均为基于该样例的变体 |
| `vfx/brackeys_particle_bundle/particles/alpha/spotlight_01_a.png` | `effects_composition/example_particle_spotlight.png` | 仅重命名，图片字节不变 |
| `README.md` | `effects_composition/example_brackeys_license.md` | 保留原文与许可声明 |

`example_wobble_animation.tres`、`example_dual_group_timeline.tres` 以及各 Cue 和预设为本项目编写；它们复用上文的图片、音频、Shader 与粒子，没有其他外部素材。

## 验证和人工体验

源码中的 `.uid` 与素材的 `.import` 来自目标 Godot 版本的正常导入；`.godot` 缓存不随项目复制。项目不自带这些示例的测试任务、Feature 或通过记录。每个实际项目按自己的修改选择导入、解析、lint、行为测试和必要的人工体验。自动化能验证绑定、隔离、保存与停止行为；声音是否悦耳、视觉是否协调，仍需实际观看和试听。
