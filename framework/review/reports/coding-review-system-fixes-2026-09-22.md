# 编码规范与审核体系局部修复

基线：`79c760ac2085dcde0bf25a3a2adb973464ca19ad`。本轮按用户确认的审核复核建议实施，保留规则树、审核角色与测试证据体系。2026-09-23 按用户要求新建外部目录并完成真实引擎验证。

## 实施范围

| 原发现 | 本轮处理 |
| --- | --- |
| F1 | CLI 要求默认或显式配置成功加载；未知检查 ID 在改变开关前拒绝并返回 3；帮助入口不再继续分析 |
| F2 | 可选面板的分析配置取项目 JSON，机器设置仅保存个人偏好；初始回填不触发保存，主题重建保持配置引用一致；保存保留未知字段，拒绝覆盖无效目标 |
| F3 | 补版本权威的条件阅读路由；维护入口明确按领域核对工程语义，仍遵循维护仓库授权、验证地点和交付边界 |
| F4 | `review-code` 区分变更与现状输入，需求证据缺失时限定对应结论并继续有依据的质量审查；同步 advisor 场景 |
| F5 | Signal API 的约束强度和动态例外只由类型/API 规则定义，结构规则改为引用 |
| F6 | 视觉边界集中在测试策略：不默认建设通用视觉门禁；已明确客观渲染契约的专项证据与主观人工验收分开 |
| F7 | 测试桥接引用方法层的追踪/生命周期契约，保留引擎层级与最低集合增量；BUG learning 四字段集中到工程变更规范，保留原触发时点、授权与晚期验证要求 |
| F8 | CLI 文档同步文件输入、JSON 输出、配置来源、退出码与显示筛选；本地补丁说明记录新增维护范围 |
| F9 | 仅修维护根 `.gitattributes` 中 vendor 文件的实际路径；生成项目配置保持正确的相对路径 |

没有调整 `.editorconfig`、业务阈值或插件默认启用状态。面板仍保存已加载配置的整体值，不增加与外部手工并发编辑的自动合并机制。没有新增审核门禁、状态机或默认项目测试入口。

## 当前验证

| 层次 | 结果 |
| --- | --- |
| 维护回归 | 指定 Python 在沙箱外执行现有 `unittest discover -s framework/tests -p test_*.py`，38 项通过 |
| Skill 格式 | `skill-creator/scripts/quick_validate.py project-source/skills/review-code` 通过；不代表自然语言流程已动态验收 |
| 静态差异 | 33 个改动/新增文件 UTF-8/LF、295 个本地链接与锚点及 `git diff --check` 通过；交叉源码检查未发现新的实现阻断问题 |
| 属性匹配 | `git check-attr whitespace` 确认实际 vendor 路径得到 `-blank-at-eof` |
| 手册 | 离线构建 22 篇、32 张 Mermaid、529 个源链接通过；未做浏览器视觉或交互验收 |
| 真实引擎 | Godot 4.7.1 `a13da4feb`：108 条分析器、34 条 CLI、79 条真实面板契约断言通过；另验证已有配置文件被独占锁定时退出 3 |
| 解析与 lint | 5 个改动实现脚本和 2 个新增夹具的原生解析通过；最终面板夹具在真实编辑器中编译执行。两份最终夹具 lint 为 0 Critical、0 Warning、22 Info，Info 为测试边界值等数值线索 |
| 文件与恢复 | 测试前后被测 linter 与本轮源码逐字节一致；最终夹具一致，项目配置恢复到原始字节。测试插件未进入分发清单，编辑器设置隔离在新目录中 |

## 真实引擎环境与证据

用户要求换新目录，实际使用 `D:/A_Games/Game_idle_yaya_frame_lint_test_20260923`，未写入之前的 workbench 测试项目。本目录仅含专项最小 Godot 项目、当前 linter、三个测试夹具、引擎副本及报告，没有复制游戏台账或运行业务流程。

引擎副本来自 `E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe`。新目录 `runtime/_sc_` 启用 [Godot self-contained 模式](https://docs.godotengine.org/en/4.4/tutorials/io/data_paths.html#self-contained-mode)，实际生成 `runtime/editor_data/editor_settings-4.7.tres`；面板测试对机器偏好的读写只作用于这份隔离配置。所有引擎执行均走沙箱外审批路径。

原件位于 [本次证据目录](D:/A_Games/Game_idle_yaya_frame_lint_test_20260923/reports)：

| 文件 | 覆盖 |
| --- | --- |
| `import-01.log` | 新目录真实编辑器导入、类注册与图标资源导入，退出 0 |
| `analyzer-01.json` / `.log` | 原有 108 条声明、度量、指令、Logger 接口和数字字面量契约 |
| `entry-01.json` / `.log` | 34 条断言；包含每次 CLI 子进程的参数、退出码和输出。覆盖缺省/显式缺失配置、配置路径为目录、非法 JSON、未知与混合检查 ID、有效筛选 JSON 和无配置帮助 |
| `locked-config-01.log` | 用 Windows 临时独占只读句柄锁定已有配置，CLI 返回 3 并解释无法加载；句柄在 finally 关闭，未改文件内容 |
| `editor-01.json` / `.log` | 首轮 77 条断言通过，保留扫描尚未结束时关闭编辑器的警告 |
| `editor-02.json` / `.log` | 夹具增加有界文件扫描等待后 79 条断言通过，扫描中止警告消失；真实 Dock、SpinBox/CheckBox 信号、保存、重载与主题重建链 |
| `parse-1.log` 至 `parse-7.log` | 5 份改动实现和两份新夹具的直接 `--check-only` 结果 |
| `fixture-lint-01.json`、`fixture-lint-02.json` 与对应 `.log` | 初版及最终两份夹具的实际检查；最终 2 文件、0 Critical/Warning、22 Info |

编辑器负向案例故意写入损坏 JSON；日志中的解析失败和拒绝覆盖诊断属于该案例预期，原文件保留检查通过。源码自带 `dock.tscn` 的图标 UID 与首次导入生成的 UID 不同，Godot 给出警告并成功按文本路径加载 `settings.svg`；此上游资源引用未为测试通过而改写，不将日志表述为零警告。未发现其他运行或脚本错误。

复现三个契约入口时，从外部目录使用 `runtime/Godot.exe --headless --path project --script res://gdscript_lint_contracts.gd -- <报告路径>`、同样的 `gdscript_lint_entry_contracts.gd` 入口，以及 `runtime/Godot.exe --headless --editor --path project -- --lint-editor-contracts <报告路径>`。CLI 夹具只允许一次性项目；面板夹具由该项目的 `addons/lint-contracts/plugin.cfg` 启用，运行后恢复它修改的具体配置值。

这些结果只证明所列 linter 契约；没有运行完整游戏回归、全部框架交付流程或 gdUnit 测试。面板视觉可用性与手册阅读体验仍待用户外部检查，38 项维护测试沿用本轮此前通过且未失效的结果。
