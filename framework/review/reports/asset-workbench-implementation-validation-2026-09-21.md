# 资源工作台首期实现与复制验证

日期：2026-09-21。范围为本次获准的首期工作台、示例资源与框架验证方式；不是完整专业分析平台或全部流程已验证的声明。

## 实现与取舍

- 在 Godot 开发场景中提供候选筛选、单项查看/试听、明确绑定、同一事件 A/B、参数试调、单次/连续/快速触发、停止和重置。
- 工作台与独立示例游戏复用 `FeedbackCue`、表现组件和音频封装。内存试调与保存分开，明确写入一个 `.tres`；检查外部编辑冲突、参数有效性及保存后重载，不修改原始图片或音频。
- 图片改用 Kenney 原包的 Black/2x 奖杯与星星；两段确认音效不变，均加 `example-` 前缀。CC0 许可与具体包内路径保留在示例 README；资源库原件、索引和标签未改动。
- 移除染色字段及控件。默认白底黑字，可切中性深灰底白字；棋盘格默认关闭，仅覆盖两个预览区。查看设置不改变素材、事件、A/B 或保存状态。程序生成的放射线使用独立中性灰。
- 使用固定提交 `1c041582db806a0d0edad77111d1fb7a009346ef` 的 `godot_sound_manager`，未修改上游代码。仅局部使用其播放器池，薄封装负责停止与最多 16 声部；不启用全局插件、不修改总线音量。
- 保持一个真实可操作切片：图标脉冲、放射线与短音效。Analyzer、完整音乐/空间音频、多音轨时间轴及批量分析留待真实需要，不引入额外专业依赖。

主题控件按目标版本核对了 [Godot 4.7 SpinBox](https://docs.godotengine.org/en/4.7/classes/class_spinbox.html) 和 [OptionButton](https://docs.godotengine.org/en/4.7/classes/class_optionbutton.html)，最终行为以下面的本机 4.7.1 实测为准。

## 测试载体与初始化

用户指定项目：`D:/A_Games/Game_idle_yaya_frame_workbench_test`。使用正式创建器复制 26 项映射，再仅在该副本填写 Python/Godot/test_cmd、将环境设为 ready，设置测试名称与示例主场景。未在 `project-source/` 启动引擎。

实际 Godot：`E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe`，输出 `4.7.1.stable.official.a13da4feb`。Python：`C:/Users/89523/anaconda3/envs/codex-python/python.exe`；调用带 `-B`。渲染测试使用 Vulkan / RTX 4060 Laptop GPU。

第二副本位于测试项目的 `reports/portability-project/`，由外层 `reports/.gdignore` 隔离。正式创建后先确认无 `.godot`、Git、tests、主场景，配置仍 incomplete；`--require-ready` 正确拒绝。正常导入后，仅填写本机工具配置即可通过 readiness，复制维护夹具后运行同一实际测试。它没有继承第一个项目的缓存、业务台账或测试结果。

逐文件比较两副本与复制映射的 831 个文件，分发内容一致；测试项目自己的 `project.godot`、机器配置及随后记录实际进度的 `docs/progress.md` 为明确允许的差异。初始化记录在两个副本各自的 `reports/initialization.md`。测试夹具、测试生成 Cue、日志与截图只保留在外部项目。可移植 UID/import 元数据随对应源文件保留，`.godot` 不回灌。源材料仍无正式主场景，环境 incomplete、版本/test_cmd 空，Product/Feature/Registry 保持初始状态。

## 首轮验证（提交 f77cc87）

下表的日志路径相对第一个测试项目；第二项目的结果另标。

| 检查 | 实际结果与证据 |
| --- | --- |
| 分发与配置静态检查 | 26 项映射；两角色 TOML 可解析，27 个 Skill 入口有 name/description，JSON 可解析。advisor 的 12 条精选提示词、6 个文件无过期；本次未改提示词正文或任务路由 |
| 维护 unittest | 本次实现期间 38 项通过；包括新增的实际分发隔离测试。之后只有工作台代码、资源和说明调整，复制器与这些契约未改，复用适用结果 |
| 项目工具 unittest | 指定外部项目 159 项通过，覆盖工具输入与证据契约；不冒充实际需求讨论或人工验收 |
| 正常 Godot 导入 | `reports/workbench/initial-import.log`、`theme-import.log`；首轮根目录前后只增加 `.godot`，无异常编辑器配置目录 |
| 原生解析 | 10 个项目自有 GDScript 逐个 `--check-only` 返回 0，最后的布局调整另补工作台解析；`reports/workbench/parse-final.log` |
| 全 res:// lint | 最终 15 个文件，0 Critical、0 Warning、59 Info，退出 0；`reports/workbench/lint-final.json`。Info 主要是布局/表现数值与引擎 Logger 固定参数，不通过禁用规则或排除工作台消除 |
| 实际行为测试 | 11/11，0 errors/failures/flaky/skipped/orphans；`reports/gdunit-wrapper/run-9krty4hr/result.json` |
| 新路径实际行为测试 | 同样 11/11；`reports/portability-project/reports/gdunit-wrapper/run-t1zxcwt0/result.json`。重建导入日志为该子项目 `reports/portability-import.log` |
| 实际渲染与观察 | 浅色、深色、棋盘格、1100×860 最小窗口、独立示例游戏均捕获并查看；`reports/workbench/capture-theme-final.log` 无错误/警告，截图在同目录。不等于用户接受 |
| 当前环境 | 两个实际项目的 `check-project-environment.py --require-ready` 都返回 READY；不将其等同于测试通过 |
| 手册生成 | 现有构建器离线生成 22 篇文档、33 张 Mermaid，核对 472 个源链接，退出 0；没有执行手册浏览器视觉验收 |

11 项行为覆盖：A/B 与原资源隔离、保存后实际消费者读取、外部磁盘冲突、无效参数拒绝、合法边界值、停止取消延迟声音、切换取消旧声音、声部上限及恢复、浏览与明确绑定、连续触发停止、主题与事件数据隔离。

## 发现并修复的真实问题

1. 首轮以 `Vector3` 储存参数界限时，浮点精度使合法的 0.15 秒被拒绝；边界回归真实失败后改用标量浮点数组。失败记录 `run-b_vun7a9` 保留，最终 11 项包含此回归。
2. 初始渲染夹具释放后立即退出，音频混音线程尚未处理释放，产生 Ogg 播放对象泄漏提示；停止时释放流引用，夹具等待真实输出延迟后退出。初始日志保留，最终无该警告。
3. 参数验证/主题构造复杂度及测试循环变量 lint 提示，通过拆分职责和明确未使用变量修正；未修改第三方或放宽规则。
4. 实际截图发现按钮/参数布局及最小窗口状态行挤出问题；已调整控件和预览最小高度，最终最小窗口截图显示状态文字完整。
5. 一次 Windows GUI 引擎命令只重定向输出，没有等待退出，读取到了旧报告且无法可靠取得退出码；不采用该次命令的表面退出码。后续用等待进程的 PowerShell 管道重做相关检查，以上最终结果来自可靠调用。

## 仍需明确保留的边界

- 本次完成复制、环境准备、实际资源导入、工作台/消费场景运行、脚本与工具回归及新路径验证；**没有从零执行一个新的 Product 需求讨论、Feature 规划到完成记录的全过程**。完整分支仍按既有动态审核入口选微型任务验证，不补写成已发生的 TDD/讨论历史。
- Skill 格式与提示词引用检查不证明所有 Agent 行为正确；reviewer/researcher 角色客户端加载与完整委派仍待实际项目验证，本次没有新建独立评审实例。
- 保存边界有磁盘内容冲突检查，不提供多进程事务锁；当前只支持一个已有 Cue。真正项目接入应复用其自己的数据与音频服务。
- 未执行生产导出、跨机器/其他平台测试、专业音频分析或用户听觉验收。响度主观感受、音画协调与真实项目玩法仍由用户体验判断。
- 手册的源码链接与 HTML/Mermaid 构建单独核对；不使用 Playwright 做手册视觉验收，浏览器排版与交互留给用户。

## 用户反馈后的修复与复验

用户在 1152×648 的实际窗口发现底部被截断。首轮只检查了高度 860 的窗口，不能证明较矮窗口可用；硬性扩大最小窗口也不能解决宿主可视区域的限制。 已移除工作台对宿主窗口最小尺寸的修改，三个内容栏分别纵向滚动，窄窗口允许内容区横向滚动，标题和状态保持在滚动区外。

两个源音频不是同一文件：本机只读解码得到约 0.289841 秒和 0.539002 秒，且属于同一确认音系列。 但旧版 A/B 同时从磁盘 Cue 克隆，初始确实播放同一个声音；左侧仅选择也不会改事件，试听和绑定按钮又被截在下方。 现将试听与绑定移到列表下方，顶部显示事件实际声音文件；打开或重载后 A 保留磁盘配置，B 存在其他声音候选时只换声音。 复制方案或将 B 重置到保存值仍可使两者相同，这是用户操作的正常结果。原始音频字节、默认 Cue 和资源库均未改动。

本次只同步指定测试项目中的两个工作台脚本、两份维护夹具和示例说明；保留其机器配置和已保存 Cue。 最终 Godot 4.7.1 验证如下，路径仍相对 `D:/A_Games/Game_idle_yaya_frame_workbench_test`：

| 检查 | 结果 |
| --- | --- |
| 改动脚本原生解析 | 两个工作台脚本和两个夹具分别 `--check-only`，均返回 0 |
| 全 res:// lint | 15 个文件，0 Critical、0 Warning、64 Info；`reports/workbench/lint-compact-final.json`。首轮两项警告通过拆分内容区构建和移除夹具调试打印解决，未放宽规则 |
| Godot 行为 | 12/12，通过；`reports/gdunit-wrapper/run-llwxq8g0/result.json`。新增检查实际播放中的 AudioStreamPlayer.stream，确认 A/B 分别使用不同文件，复制后使用相同文件；单项试听也检查实际流 |
| 小窗口布局与渲染 | 1152×648、900×540、720×480；检查实际窗口尺寸、内容区/状态边界和滚动后试听绑定、打开游戏、末项参数可达。`reports/workbench/capture-compact-final.log` 返回 0，无错误或警告；对应 `workbench-compact-*` 与 `workbench-actions-*` 截图已查看 |

本次未重跑不受影响的维护/项目工具 unittest，也未把第二路径旧版 11 项通过记录当成本次修复的复验。 声音听感、编辑器嵌入后的交互与最终人工接受仍需用户在自己的运行窗口体验。

## Analyzer 现状与后续技术选择

截至本次修复，**外部音频分析、外部美术分析、统一分析结果协议和分析图表均未实现**。 工作台只有 Godot 导入资源提供的图片尺寸、声音时长；本轮命令行解码诊断也不是工作台 Analyzer。 SoundManager 已接入局部播放池，其职责与上述分析能力无关。

以下是根据实际需求与外部资料形成的候选方向，不是已安装、已集成或已完成兼容性验收的声明：

| 范围 | 优先考虑的技术与理由 | 当前核对与剩余工作 |
| --- | --- | --- |
| 轻量信息 | Godot 原生；已有尺寸、时长等不重复引入外部依赖 | 继续区分导入后的资源与源文件，避免把源图统计当作最终 Shader/游戏画面 |
| 音频技术分析 | FFmpeg/ffprobe 9.0.2；元数据 JSON，以及现成 astats、silencedetect、ebur128 等能力，避免自研 DSP | 已核对 [9.0.2 发布信息](https://ffmpeg.org/download.html)、[该版本 ffprobe 文档](https://raw.githubusercontent.com/FFmpeg/FFmpeg/n9.0.2/doc/ffprobe.texi) 和 [滤镜文档](https://raw.githubusercontent.com/FFmpeg/FFmpeg/n9.0.2/doc/filters.texi)；当前 PATH 未发现 CLI，Windows 构建及其具体许可/参数仍需实际核对和烟测 |
| 源图统计 | Pillow 12.2.0 + NumPy 2.4.4；透明度、调色板、颜色分布和必要数组统计 | 本机 Python 3.12.13 可导入这两个确切版本；[Pillow 发布包](https://pypi.org/project/pillow/12.2.0/) 与 [12.2.0 图像 API 源码](https://raw.githubusercontent.com/python-pillow/Pillow/12.2.0/src/PIL/Image.py) 可核对。尚未形成项目依赖或适配器；只需 Godot 就能解决的指标仍留在 Godot |
| 音乐/有音高素材的进一步分析 | 需要节奏、起音、基频或频谱特征时再评估 librosa 0.11.0 | 已查阅 [0.11.0 文档](https://librosa.org/doc/0.11.0/index.html)，未安装到本项目；短确认音不据此强行展示 BPM、调性或“风格分数” |

拟采用本地后台进程和薄适配器，将输出归一为 JSON，再交给 Godot 展示；不增加服务、数据库或让 UI 解析第三方日志。 结果应带协议版本、资源与输入版本、Analyzer 名称/版本、指标值/单位/适用状态、警告和错误；分别表达测量、项目规则与辅助判断。 需处理取消、超时和切换资源后的过期结果，缓存只复用输入与分析版本相同的结果。以上接口、任务处理和缓存都仍是待实现内容。

不能把所有声音都送进同一评分公式。例如该版本 ebur128 的瞬时窗口为 400 ms、短期窗口为 3 s；本例 0.290 s 的声音不应展示貌似可靠的完整响度统计。 应优先给出适用的峰值、RMS 等信息，对时长不足或无明确音高的项目返回原因，不用补静音伪造适用性。图像统计同样需要明确透明像素与色彩空间处理，不能将背景颜色混入素材颜色。

后续测试方式见 [框架的复制与运行验证](../../docs/blank-project/maintenance/validating-framework.md)，当前待办见 [框架进度](../../progress.md)。
