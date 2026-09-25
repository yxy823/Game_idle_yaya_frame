# 职责重构与新项目实际验证（2026-09-25）

本报告记录职责审核后实施的实际验证，不把旧报告、静态可读性或配置存在当作运行通过。实施比较基线为 `6c6ec2e1011d05a2a4e38c1365fe3256baab8c52`；未完成状态由[框架待办](../../progress.md)维护。

## 验证位置与范围

本轮从当前复制清单创建独立目录 `D:/A_Games/Game_idle_yaya_frame_validation_20260925`，30 项映射生成 972 个初始受版本管理文件，初始提交为 `5f0a515992d103ac82e43edeeab002cada8ab0c1`。机器配置仅在该项目填写，源材料保持空白。测试夹具、Python 后端依赖与运行报告留在外部项目，不回灌为游戏业务或新项目默认内容。

实际环境为 Windows、Python `C:/Users/89523/anaconda3/envs/codex-python/python.exe`、Godot `4.7.1.stable.official.a13da4feb`。引擎路径为 `E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe`。

下文日志位置均相对此验证项目；本轮汇总日志目录为 `reports/maintenance/framework-validation-20260925/`。真实引擎在外部审批路径运行，未在维护源目录启动 Godot。

## 实施与独立审核

Skill、工具、提示词与场景分别由三个实施子智能体修改。独立审核者读取最终实现及旧审计项，协调者承担整合、运行验证和修正反馈。

- [Skill 与工具实现复核](skill-tool-implementation-review-2026-09-25.md)：29 个 Skill 的变更归属、所有本轮工具改动及调用链；两项 P2 已修复并复核。
- [提示词与场景实现复核](prompt-scenario-implementation-review-2026-09-25.md)：逐对检查提示词和页面，并对照旧用途，结果以该报告最终复核状态为准。
- [操作手册迁移复核](manual-migration-review-2026-09-25.md)：全文对照旧 19 篇与新 11 专题、维护导航，以及环境模板与源格式测试增量；两项 P2 已修复并复核。
- [实际验证证据复核](validation-evidence-review-2026-09-25.md)：独立核验十次 gdUnit 原件及附件哈希、Feature 提交与锚点、实际 researcher 委派、新路径运行日志和各项证据边界；未发现待修复 P1/P2。

最终提示词和场景各 123 项：框架维护 15、游戏开发 108，按 `Project/分类/提示词名称.md` 一一对应。独立初审的 R1–R11 已全部修正并复核，包括旧用途缺口、工具调用、暂停和只诊断边界。操作手册整理为 11 个概念与工具专题，原 19 篇迁移材料及其索引已删除；两册各自导航，不互相引用。长期职责准则仍由[设计基线](../baselines/skill-script-prompt-design.md)维护。

## 已取得的运行结果

| 检查 | 实际结果 | 证据与边界 |
| --- | --- | --- |
| 框架 unittest | 60 项通过 | `python -B -m unittest discover -s framework/tests -p test_*.py`；13.167 秒，退出 0；含复制器、原子写入、文档指纹、人工文件、提示词导出与路径校验 |
| 项目工具 unittest | 174 项通过 | `run_project_tool_tests.py --project <验证项目>`；40.196 秒，退出 0；含预期失败夹具，输出中的故意错误不等于测试失败 |
| 环境结构与实际就绪 | 两项退出 0 | `environment-structure.log`、`environment-ready.log`；后者实际探测 Godot 版本 |
| 全新导入与主入口 | 退出 0，无实际脚本错误 | `fresh-import.log`、`main-startup.log`；运行最小场景 5 帧，不表示游戏玩法或人工体验验收 |
| 工作台真实 gdUnit | 13 套、139 用例通过；0 错误、失败、跳过、flaky、孤儿 | `final-workbench-suites.log`；原件为 `reports/gdunit-wrapper/focused/run-fvnab7xb/` |
| 实际 Analyzer 后端 | 22 项通过 | `analyzer-backend.log`；按锁定文件安装到本项目 `reports/asset-analyzer/runtime/`，没有升级全局环境 |
| 配置 linter | 57 文件，0 Critical、0 Warning、376 Info，退出 0 | `final-lint.json`；作用于当时完整 `res://`，尊重现有配置。Info 是数值/引擎接口等提示，不当作零问题宣称 |

完成记录的 `show` 现在只检查读取、结构和 Feature 身份，`validate` 保留真实完成判定；相关正反用例包含在上述 174 项中。基础模块抽取的静态 AST 等价检查由独立审核报告记录。

两组 unittest 输出保留在本次 Codex 任务的工具会话（分别为 57874、13622），未额外重定向成本地日志。后续独立审核不将这两组计作已读取本地运行原件；其他表列日志均保存在验证项目中。

### 首轮失败及修复

首次工作台执行完成 12 套、139 用例，其中一个用例产生两条错误：协调者复制夹具时漏带 `analyzer_protocol_cases.json`，JSON 读取失败继而产生类型错误。已复制原始共享数据夹具，保留失败原件 `reports/gdunit-wrapper/focused/run-tqa7b3ap/`，没有修改断言或放宽诊断。

首次 lint 报原集合测试文件的长度与公开方法数量两项 Warning。新增源格式校验覆盖有独立的配置变更、恢复和历史边界，已将这四个用例及其配置恢复夹具拆到 `asset_analysis_source_contract_test.gd`；原集合套件保留统计、批处理和界面行为。复验保持139个用例并通过，没有提高阈值或新增排除项。前后原始 lint 文件分别为 `lint.json`、`final-lint.json`。

独立审核另发现有效 JSON 可包含未验证的额外来源类型，分类函数会访问不存在的字段。初始化现限定已支持的 audio/image 两种来源，并保留失败后重试；新增用例实际覆盖添加、扫描、单项拒绝以及配置恢复。规则模板遗留的整树干净／改动归属措辞也已同步为保护现有差异与同目录续接。

## researcher 的真实客户端委派

在用户明确授权本机 Codex CLI 可能向 OpenAI 发送该验证项目所读取内容后，于外部项目运行 `codex exec`，沿用客户端配置，未指定或替换模型。首次调用因自动审批认为外发授权不充分而被拒；取得上述明确授权后沿原审批路径重试成功，未绕过审批。

客户端任务 `01a0d8e4-adb7-7cf2-88e2-6d4417467752` 的实际 `spawn_agent` 调用包含 `agent_type: researcher`、`task_name: logger_callback_research`、`fork_turns: none`。对应实例为 `/root/logger_callback_research`；本机任务记录中的调用 ID 为 `call_m6Q8cHN1iAvWQwnyf4zvpkX9`。协调者等待该实例完成，并核对报告后退出 0。这一检查使用项目的 `.codex/agents/researcher.toml` 注册角色，没有将角色正文粘给通用 Agent 冒充客户端加载。

委派问题限定为 Godot 4.7.1 的 `Logger._log_error` 参数与版本依据。研究者使用其已安装的 AnySearch Skill 检索，检查 `4.7.1-stable` 官方标签下的版本文件、接口文档和绑定源码，返回八参数结论及直接来源，写入 `docs/research/godot-4-7-1-logger-callback.md`。日志为 `researcher-events.jsonl`、`researcher-stderr.log` 和 `researcher-final.md`。

角色加载方式依据 [Codex 官方自定义 Agent 配置](https://learn.chatgpt.com/docs/agent-configuration/subagents#custom-agents)核对；研究结论的证据包括 [4.7.1 Logger.xml](https://raw.githubusercontent.com/godotengine/godot/4.7.1-stable/doc/classes/Logger.xml) 和[该版本的 version.py](https://raw.githubusercontent.com/godotengine/godot/4.7.1-stable/version.py)。此项证明本机本次角色选择、完整调研返回与报告写入，不证明所有客户端、权限组合或调研问题均可成功。客户端启动中的非相关 MCP／用户配置告警保留在原日志，本轮没有改动全局配置。

## 真实 Feature、追加规划与来源同步

子智能体按验证项目内 `product-author`、`product-init-elicitor`、`feature-plan`、`feature-execute` 和 `feature-sync` 的规范执行一个独立整数计数器需求。实际过程与原件导航保存在该项目 `reports/maintenance/feature-lifecycle-20260925/result.md`，执行报告与独立审核分别记录。

| 阶段 | 实际结果 |
| --- | --- |
| 首次来源与 R000 | 来源提交 `d0ffe842da246d6c1adbe0dbbf60c1ad992d2703`；规划提交 `854818c`，R000 绑定真实已采用来源 |
| F001 实施 | 三轮真实 RED/GREEN；最终 3/3 测试通过；实现及测试原生解析退出 0；全项目 lint 59 文件、0 Critical、0 Warning、389 Info |
| F001 完成 | 完成工具及完成态结构检查当时均退出 0；本地提交 `376c9ad649588c1225109bd3f01b8498c09dee5c`。纯逻辑 AC 采用 automated，没有伪造人工接受 |
| 第二 Product 追加规划 | `c0036c1` 新增 F002，比较完整记录确认 R000 不变，保留三个既有测试 |
| 第二 Product 来源修订 | `ec1d9e3` 先提交上限 3→5；`0a93270` 随后修改 pending F002 并追加 R001，来源锚点正确，F001 详情字节与已完成索引条目不变 |
| 历史读取与当前判定 | `show` 退出 0；后续 Product/台账变化后 `validate` 退出 2，明确快照已经变化。旧通过不冒充新快照的完成依据，历史 done 也不自动重开 |
| 交接 | `2534903` 保存真实交接；F002 保持 pending，只用于验证追加与同步，实施不在本轮范围 |

首次 AC01 绿色尝试误将 `res://` 目录传给要求仓库相对路径的 `--target`：引擎执行 1/1，但包装工具无法匹配目录身份，整次返回失败。修正调用路径后通过，前次失败原件保留，未计作成功。

## 新路径无缓存重建

从最终分发源另建 `reports/scratch/clean-rebuild-20260925`，其父报告区已有 `.gdignore`，不被外层 Godot 扫描。初始提交 `e6ab3f7036f80345bc11d2469834e96505d64418`；首次导入前确认没有 `.godot`，未复制机器配置、测试数据或业务需求。

创建、Godot 导入、最小主入口和 single／composition／shader／effects 四类消费示例各退出 0；后五项均以 headless 运行 5 帧，未出现脚本或资源加载错误。结果为汇总日志目录中的 `clean-rebuild-results.json`，每项命令输出保存在同名前缀的 `.log`。这证明新路径下源资源可重建与加载，不证明画面、听感或交互已验收。

前一次 `clean-copy-20260925` 尝试通过 PowerShell 直接启动 Windows GUI 可执行文件，未取得可靠退出码且输出文件为空，未计作通过。随后改用 Python `subprocess.run` 等待实际退出，并在上述另一条全新路径重做；未用该尝试产生的缓存补足验证。

## 最终静态检查与收尾

机械检查通过：175 份维护 Markdown 的 1605 个本地链接/锚点、代码围栏、场景分类顺序与步骤对应关系，以及两册无相互引用；123 条提示词路径全部匹配，advisor 的 15 个入选提示词与 7 份生成参考一致。检查不读取页面正文来决定路径匹配，内容审核由上述独立子智能体完成。文档目录没有空文件夹。

外部项目 972 个复制文件无缺失。实际开发形成的 Product、台账、Progress 和机器配置保留；最终修正的 advisor 参考和规则模板仅定向同步。暂存检查另删除两个 Python 基础模块末尾的多余空行，语法与行为不变，不因此重复已通过的运行；同步外部副本时没有改写旧测试或完成证据。具体运行事实仍对应各节记录的版本和范围。

## 证据解释限制

上述结果不代表每条提示词都经过实际对话执行，不代表所有 Skill 的模型触发和人工语言体验已验证。工作台听感、节奏、截尾、分组抢占及保存后体验仍需真实用户接受；自动化没有替代这些判断。HTML 阅读版继续暂缓，本轮没有生成实际手册或运行 Playwright；保留生成器的临时夹具单测包含在框架60项回归内，不表示新目录已支持 HTML 构建。
