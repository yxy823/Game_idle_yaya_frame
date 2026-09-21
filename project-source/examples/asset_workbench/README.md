# 美术与音频组合预览示例

这是可删除、可替换的开发示例，不是项目 Product、正式玩法或已验收资源。
复制框架后仍需按项目 README 完成环境准备；示例不会设置项目主场景或自动启动。

## 打开与操作

在 Godot 中打开 `example-workbench.tscn`，按 F6 运行当前场景。
也可在**生成项目根目录**使用配置中的引擎：

```powershell
$config = Get-Content -LiteralPath 'docs/methodology-config.json' -Raw | ConvertFrom-Json
& $config.environment_bootstrap.engine_executable --path . 'res://examples/asset_workbench/example-workbench.tscn' | Out-Host
```

先完成正常导入。窗口至少 1100 × 860；这不会把示例设为正式游戏入口。

1. 左侧筛选并查看图片尺寸、音频时长；`Audition` 和 `Repeat audition` 单独试听。
2. 普通浏览不改事件。点击 `Use selection in active A/B`，或使用右侧候选下拉框，才替换当前试调方案。
3. 调整显示尺度、脉冲动画时长、单次音量 dB、播放音高倍率、事件起点后的声音延迟秒数及总线；素材保持导入后的原色，不提供染色。
4. `Trigger` 从初态重播；`Repeat 0.6s`、`Rapid 0.1s` 允许事件重叠；`Stop all` 清除播放、动画、循环及尚未触发的延迟声音。
5. A、B 各自保留试调值，切换时停止旧效果再触发新方案。`Copy active to other` 复制方案；`Reset active trial` 放弃当前方案修改。
6. `Save active cue` 只保存当前 A/B 到下方显示的 `.tres`，不改原图或音频。`Reload from disk` 经界面确认后放弃两份试调并重读磁盘。
7. `Open example game` 启动独立进程，点击奖励按钮验证**已保存**配置；未保存的试调不会进入该场景。

默认使用白色背景和黑字；`Dark background` 切换为中性深灰背景和白字，适合检查白色素材。
`Transparency grid` 只给单项图片区与事件预览区增加灰色棋盘格，用于辨认透明边缘；默认关闭。
这些查看设置只在当前工作台会话生效，不影响素材颜色、A/B、保存的 Cue 或正式游戏环境。
黑色图标在深色背景下对比度降低属于素材与背景的真实关系，可切回浅色或启用棋盘格。

左右两种查看方式共享候选集合，但单项试听使用固定 -12 dB、1 倍速、Master 总线。
事件按右侧参数播放；没有自动响度匹配，主观比较时保持系统监听音量一致。
示例资源元数据来自导入后的 Texture2D / AudioStream，不是专业响度或风格分析。

## 数据和运行边界

| 位置 | 职责 |
| --- | --- |
| `example-workbench.tscn` | 工作台入口、两个视觉与两个音频候选、明确保存目标 |
| `example-feedback.tres` | 唯一示例事件配置；工作台保存，示例游戏直接读取 |
| `example-game.tscn`、`example_reward_game.gd` | 独立消费方；只有进程内奖励计数，没有真实存档或业务副作用 |
| `assets/example-*` | 仅示例素材及许可；禁止据此推定其适合当前游戏 |
| `components/feedback/` | 小型图标脉冲表现组件、数据类型和播放封装；两个场景复用同一表现逻辑 |
| `tools/asset_workbench/` | 候选浏览、试调和保存界面；不注册全局服务 |

首期是一项奖励按钮的 Activate 事件：一个图标、程序生成的确定性脉冲/放射线、一个声音。
它没有通用 Object/State/Event 引擎、完整时间轴、多音轨编辑、空间音频、音乐管理或专业 Analyzer。
已有游戏对象应接入其现有表现组件与配置；不要为了使用本示例复制一套正式关系模型。

试调复制 Cue 的标量字段，Texture/AudioStream 保持只读共享。保存前检查磁盘内容是否变化，
保存后绕过 Cue 缓存重新加载并核对；冲突或失败保留试调并显示原因。磁盘冲突检查不提供多进程事务锁。
保存仅供 Godot 编辑器二进制的开发运行使用，导出游戏不得依赖写回 `res://`。
所有引用这个目标 Cue 的对象都受保存影响；接真实项目前应明确这个范围。

音频封装直接复用 [SoundManager 固定提交](../../addons/sound_manager/UPSTREAM.md) 的局部池，
不启用其全局插件。最多重叠 16 个非空间声音；到达上限返回可见错误，不改全局总线音量。
切换、停止和退出使旧延迟请求失效；不把引擎帧调度当成采样级同步。

正式游戏导出时选择正式入口场景及依赖。使用全资源导出时，显式排除本示例与
`tools/asset_workbench/`；保留正式场景实际依赖的组件及音频实现。当前框架不预填生产导出配置。
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
