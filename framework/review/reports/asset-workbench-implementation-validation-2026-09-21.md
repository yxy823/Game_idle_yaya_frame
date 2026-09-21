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

## 实际验证

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

后续测试方式见 [框架的复制与运行验证](../../docs/blank-project/maintenance/validating-framework.md)，当前待办见 [框架进度](../../progress.md)。
