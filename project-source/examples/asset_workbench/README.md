# 美术与音频组合预览示例

这是可删除、可替换的开发示例，不是项目 Product、正式玩法或已验收资源。
复制框架后仍需按项目 README 完成环境准备；示例不会设置项目主场景或自动启动。

## 打开与操作

两个独立入口放在不同目录，在 Godot 中选择对应场景按 F6；二者不互相打开或切换：

- 单对象工作台：`single/example-workbench.tscn`。
- 组合场景工作台：`composition/example-workbench.tscn`。

也可在**生成项目根目录**使用配置中的引擎：

```powershell
$config = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
& $config.environment_bootstrap.engine_executable --path . 'res://examples/asset_workbench/single/example-workbench.tscn' | Out-Host
```

先完成正常导入。框架的 `project.godot` 默认视口为 1600×900，新建项目继承此值；
两个工作台入口及分析、批量窗口默认都使用 1600×900，不再自动按屏幕比例缩小。
显式 `--resolution` 或后续项目设置可覆盖默认值；嵌入编辑器（`--wid`）时仍受宿主区域约束，查看完整独立窗口可分离运行。
三个内容栏可分别上下滚动，窄窗口还可横向滚动内容区。
标题、当前事件声音和底部状态留在滚动区外；这不会把示例设为正式游戏入口。

1. 左侧筛选并查看图片尺寸、音频时长；`Audition` 和 `Repeat audition` 单独试听。
2. 普通浏览不改事件。点击 `Use selection in active A/B`，或使用右侧候选下拉框，才替换当前试调方案。
3. 调整显示尺度、脉冲动画时长、单次音量 dB、播放音高倍率、事件起点后的声音延迟秒数及总线；素材保持导入后的原色，不提供染色。
4. `Trigger` 从初态重播；`Repeat 0.6s`、`Rapid 0.1s` 允许事件重叠；`Stop all` 清除播放、动画、循环及尚未触发的延迟声音。
5. 打开或重载时，A 使用磁盘配置，B 在有其他音频候选时只换成另一声音，便于直接比较。两者各自保留试调值，切换时停止旧效果再触发新方案。`Copy active to other` 复制方案；`Reset active trial` 将当前方案恢复为磁盘配置，因此两者可能再次相同。
6. `Save active cue` 只保存当前 A/B 到下方显示的 `.tres`，不改原图或音频。`Reload from disk` 经界面确认后放弃两份试调并重读磁盘。
7. `Open example game` 启动独立进程，点击奖励按钮验证**已保存**配置；未保存的试调不会进入该场景。

默认使用白色背景和黑字；`Dark background` 切换为中性深灰背景和白字，适合检查白色素材。
`Transparency grid` 给单项图片区与单对象事件预览区增加灰色棋盘格，用于辨认透明边缘；默认关闭。组合场景保留真实场景背景。
这些查看设置只在当前工作台会话生效，不影响素材颜色、A/B、保存的 Cue 或正式游戏环境。
黑色图标在深色背景下对比度降低属于素材与背景的真实关系，可切回浅色或启用棋盘格。

左右两种查看方式共享候选集合，但单项试听使用固定 -12 dB、1 倍速、Master 总线。
事件按右侧参数播放；没有自动响度匹配，主观比较时保持系统监听音量一致。
顶部 `Event sound` 显示事件实际使用的文件；左侧选中后点 `Audition` 才单独播放所选文件，点 `Use selection in active A/B` 才绑定并触发事件。
两个原始音效属于同一确认音系列，解码时长分别约 0.290 秒和 0.539 秒；切换 A/B 不代表自动改变音色、响度或音高。
浏览器资源元数据来自导入后的 Texture2D / AudioStream；`Analyze selected source` 打开独立源文件分析窗口。
第二阶段已提供后台音频/图像分析、统一 JSON、图表与同类型分析 A/B；安装和操作见
[Analyzer 说明](../../tools/asset_analyzer/README.md)。缺少可选分析依赖不影响这里的预览与播放。

## 可交互组合场景

直接运行 `composition/example-workbench.tscn`，中央加载真实的 `composition/example-composition.tscn`：奖杯、星星和奖励三个对象。
它们复用原始图片、声音与 FeedbackPresenter，每个对象使用独立的 `example-composition-*.tres`。
组合工作台自身包含对象选择、属性及分析能力，背景可切换浅色/深色，素材不染色。

1. 点击对象会选中并触发它。组合工作台右侧立即改为该对象的属性，底部显示真实保存目标。
2. 沿用现有候选、参数、A/B、重置与保存；试调也更新组合场景中的对应对象。切换对象不会丢弃各自 A/B；初始 B 在有另一个声音时仅换声音。
3. `Trigger all` 同时触发三个对象，检查重叠；`Stop all` 清理动画、音频及延迟。
4. `Apply gain to all trials` 只改变三个对象各自当前 A/B 的音量；另一方案与磁盘保持不变。
5. `Save all scene cues` 对每个明确 Cue 分别执行原有冲突检查与保存，显示成功数量及失败路径。它不是多文件事务：其他文件可以成功，冲突文件保留试调。
6. `Open example game using saved cue` 启动组合场景的独立实例，读取已保存 Cue；也可打开 `composition/example-composition.tscn` 按 F6。未保存试调不会进入独立实例。
7. `Analyze selected object's sources` / `Analyze all scene sources` 将当前试调引用的原始资源去重后加入同一个批量分组。分析源文件，不测量最终混音、播放增益或渲染后画面。

对象位置由原生 Scene 布局维护；运行时只编辑明确支持的 Cue 参数。
Agent 可以根据画面描述组合或修改 `.tscn` 与表现组件。本例验证这种接入方式，没有在运行时实现自然语言生成器、任意节点属性编辑器或通用场景制作软件。
接真实项目时使用其已有对象/事件数据和明确的表现接口，不自动执行未知场景的业务副作用。

## 第三阶段：分组与批量检查

原浏览器中的 `Add filtered candidates to group` 把当前筛选后的候选加入分组并打开批量窗口。
可加载 `example-analysis-group.json` 体验包含四个示例资源的分组；其中阈值仅为示例，不是项目硬性规范。
操作、同类统计、规则、历史快照及缓存边界见 [批量分析说明](../../tools/asset_analyzer/README.md#分组批量分析与一致性检查)。

## 数据和运行边界

| 位置 | 职责 |
| --- | --- |
| `single/example-workbench.tscn` | 单对象工作台入口、候选与明确保存目标 |
| `single/example-feedback.tres` | 单对象事件配置；工作台保存，奖励示例游戏直接读取 |
| `single/example-game.tscn`、`single/example_reward_game.gd` | 独立消费方；只有进程内奖励计数，没有真实存档或业务副作用 |
| `composition/example-workbench.tscn` | 独立组合工作台；直接选择场景内对象并编辑属性 |
| `composition/example-composition.tscn`、该目录的 `example-composition-*.tres` | 三对象真实场景及分别保存的表现配置；不改单对象配置 |
| `example-analysis-group.json` | 可携带的资源分组与示例规则，不包含缓存或通过记录 |
| `assets/example-*` | 仅示例素材及许可；禁止据此推定其适合当前游戏 |
| `components/feedback/` | 小型图标脉冲表现组件、数据类型和播放封装；两个场景复用同一表现逻辑 |
| `tools/asset_workbench/` | 候选浏览、试调和保存界面；不注册全局服务 |
| `tools/asset_analyzer/` | 源文件专业分析与适配器；独立于音频播放，不写回 Cue |

首期是一项奖励按钮的 Activate 事件：一个图标、程序生成的确定性脉冲/放射线、一个声音。
它没有通用 Object/State/Event 引擎、完整时间轴、多音轨编辑、空间音频或音乐管理。
已有游戏对象应接入其现有表现组件与配置；不要为了使用本示例复制一套正式关系模型。

试调复制 Cue 的标量字段，Texture/AudioStream 保持只读共享。保存前检查磁盘内容是否变化，
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

## 验证和人工体验

源码中的 `.uid` 与素材 `.import` 来自目标 Godot 的正常导入；`.godot` 缓存不随框架复制。
框架维护回归源码留在维护仓库，生成项目不自带已完成的测试任务、Feature 或通过记录。
每个实际项目按其修改选择导入、解析、lint、行为测试和必要人工体验。
自动化能验证绑定、隔离、保存与停止行为；声音是否悦耳、视觉是否协调仍需实际观看、试听。
