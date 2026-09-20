# 空白项目动态验证报告 · 2026-09-14

## 结论与范围

本次从不存在的目录创建空白项目，完成实际环境配置、Product 编写、单 Feature 拆分、真实 TDD、自动验收、原生解析、lint、主场景启动、完成记录与本地提交。这条最小自动交付路径通过，未发现新的框架阻塞问题。

这是一次实际流程抽样，不是所有框架分支均已验证。没有执行 UI、音频、人工验收、Bug 专用阶段、多 Feature 依赖、用户指定的独立评审、导出或框架全套维护回归；这些范围没有被标记为通过。

## 基线与文件边界

| 项目 | 本次实际状态 |
| --- | --- |
| 框架仓库 | `D:/A_Games/Game_idle_yaya_frame`，创建基线 `fdc5aec`，含此前按需独立评审变更 `0fe69e6` |
| 根规则更新 | `fdc5aec`：根据 [OpenAI 原文](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra) 加入指令去重、精准触发、按需阅读、适度流程、授权续接和结果复用约束；保留原有核心原则 |
| 全新验证目录 | `D:/A_Games/Game_idle_yaya_frame_dynamic_20260914`；创建前不存在，父目录不属于另一个 Git 仓库 |
| 创建器 | 原有 `framework/commands/create_project.py --output <验证目录>`，实际输出 `Copied 21 entries`，退出 0 |
| 复制核对 | 753 个复制文件；初始化暂存内容除明确配置、进度、项目名称外与映射来源一致。首次扫描另生成 12 份正常资源 `.import`，未手工修改 |
| Python | `C:/Users/89523/anaconda3/envs/codex-python/python.exe`，实际版本 3.12.13 |
| Godot | `E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe`，实际版本 `4.7.1.stable.official.a13da4feb` |
| 工作区边界 | 样例源码、Product、Feature、配置和原始运行报告均保留在上述外部验证项目；框架本轮仅修改根 AGENTS.md、增加本报告 |

生成后配置和 Git 初始化由本次授权流程完成，创建器仍只负责复制。外部项目相对初始化提交的 `.agents/`、`agent-rules/`、`addons/`、`methodology/`、`tools/`、`AGENTS.md` 和 `gdlint.json` 均无差异，未靠修改框架工具或规则使样例通过。框架维护说明、提示词库和本报告均未进入复制清单。

## 实际流程结果

以下证据路径相对于外部验证目录。

| 环节 | 实际操作与结果 | 证据 |
| --- | --- | --- |
| 环境初始化 | 核对实际工具版本并配置 ready；首次扫描退出 0，仅新增正常 `.godot` 根目录；`--require-ready` 退出 0 | `reports/initialization.md`、`reports/initial-scan/godot.log` |
| Product | 按项目模板写中文总览与唯一模块，定义初值、递增、复位、继续操作，保留不适用的 UI/音频说明 | `docs/product.md`、`docs/product/01-counter.md` |
| Feature 拆分 | 原合并工具增加 counter 组件，`unit_test_paths: []`；严格检查通过，仅产生 F001，`--eligible` 返回 F001 | `docs/feature-list.json`、`docs/features/F001.json`、`docs/test-registry.json` |
| Stage 1–2 | 展示单 Feature 范围并复用已有授权，选择 automated，登记四项 AC 映射与 planned 测试，再初始化完成记录 | F001 方案与完成记录 |
| 递增 RED | 真实 gdUnit 运行：初值通过，递增实际仍为 0，断言失败后提前结束；包装器退出 1，Godot 退出 100 | `reports/gdunit-wrapper/run-cb1p3286/result.json` |
| 复位 RED | 实现递增后实际执行四用例，初值与递增通过，复位和复位后递增失败；包装器退出 1，Godot 退出 100 | `reports/gdunit-wrapper/run-nrxtlldj/result.json` |
| 最终 GREEN | `--feature F001 --scope auto` 选择 affected，Required/affected 四项映射去重为一个套件，四用例通过，无失败、跳过、flaky 或孤儿；包装器和引擎退出 0 | `reports/gdunit-wrapper/run-yzuzgeia/result.json`、同目录 discovery、JUnit、诊断原件 |
| 原生解析 | 三个新增脚本实际 `--check-only`，均退出 0；演示脚本变更后单独重验 | `reports/parse-counter.log`、`reports/parse-counter_demo-final.log`、`reports/parse-counter_acceptance_test.log` |
| 主场景启动 | 从新 Godot 进程运行真实主场景，内部核对 `0 → 1 → 2 → 0 → 1`，退出 0 | `reports/counter-startup-final.log` |
| Stage 7 | record-tests、validate、`--completion-feature F001`、最终台账检查均退出 0；F001 转为 done 并提交 | `docs/feature-completion-evidence.json`、`docs/progress/F001.md` |
| Stage 8 | 本次 Product 范围完成，无下一项已批准工作；归档一次并交接 | `docs/progress.md` |

初值由整数零值声明直接满足，AC01 没有制造 RED；不能把初始化通过描述成四项 AC 都经历过独立 RED。其余行为缺失有上述真实失败证据。空白项目没有既有业务安全网，未运行零用例基线。此次实际是 affected 运行，没有为了覆盖 full 标签重复同一套件。

最终静态结果：

| 范围 / 文件数 | Critical | Warning | Info | 进程退出码 | 原始报告 |
| --- | --- | --- | --- | --- | --- |
| 按 gdlint.json 的全项目 res://，6 个脚本 | 0 | 0 | 1 | 0 | `reports/counter-lint-final.json` |

唯一 Info 来自既有 `gdunit_diagnostic_logger.gd`：Godot 的 `Logger._log_error` 固定需要八个参数，属于已实现的引擎接口契约说明；没有新增 Warning 或放宽参数阈值。

## 近期调整的实际表现

Product 写入、Feature 规划、Stage 执行和最终交接沿已有具体授权衔接，没有重复请求确认。Stage 8 在本次范围完成后结束。独立评审未被用户要求，因此未启动，也未创建评审开关、计数或待评审状态。

自动验收分支完成时，schema 8 记录中的 `human_acceptance` 保持未填写的 pending；它不代表待完成的人工工作，也没有被伪造为 accepted。当前工具据 automated 方案检查实际测试依据。

最终测试后增加 README 的演示说明，更新 Feature notes、完成时间和 Progress 归档。完成检查复用 `run-yzuzgeia` 仍然通过，没有因此重跑业务测试。这次只证明这些说明性变更的场景，不扩大为所有 Markdown 均可忽略。

## 发现与处理

| 类别 | 观察与处理 | 当前判断 |
| --- | --- | --- |
| 样例代码 | 第一轮四用例已通过，但 lint 拦住演示中的调试 print（0 Critical、1 Warning、1 Info）。改为核对结果并以退出码报告成败，重新解析、lint、启动和运行最终用例 | 样例已修正；检查有效，非框架缺陷。原 `counter-lint.json` 和 `run-50s6p5pt` 保留 |
| Agent 调用 | 误将互斥参数 `--target` 与 `--feature` 同时传入，argparse 退出 2；按既有契约改用单独 --target | 调用错误，不算 TDD RED |
| Agent 调用 | 一次 Windows GUI 直接重定向未取得有效退出码，未当作成功；随后采用已有文档中的管道等待方式，实际取得扫描与启动退出 0 | 原有规则足够，无需追加规则；有效扫描见 `counter-scan-waited.log` |
| 环境权限 | 沙箱内最后一次 validate 读取外部运行报告遇到 WinError 5、退出 2；同一报告沿既有沙箱外路径复核通过 | 读权限限制，未据此修改工具或判定内容过期 |
| 复制核对 | 初始逐文件比较将扫描生成的 12 份 .import 列为额外文件；核对原扫描和元数据后确认均为正常 Godot 产物 | 保留正式导入元数据，不把正常生成文件当作复制缺陷 |

未发现需要继续修改框架源码的新问题。无新增可复用经验条目；已存在的调用约束足以解释本次操作错误，没有为单次失误扩充 AGENTS.md 或 Skill。

## 提交与保留材料

| 仓库 | 提交 | 内容 |
| --- | --- | --- |
| 框架 | `fdc5aec` | 根 AGENTS.md 指令编写约束 |
| 外部验证项目 | `21888d6` | 空白复制、实际配置和正常导入元数据 |
| 外部验证项目 | `69a26eb` | 中文计数器 Product |
| 外部验证项目 | `a272239` | 单 Feature 规划和组件登记 |
| 外部验证项目 | `679f2e7` | 计数器实现、测试、完成依据、使用说明与交接归档 |

外部项目提交后工作区干净。原始 Godot 日志、JUnit、发现记录和诊断仍在其 `reports/`；该目录按项目原规则忽略，没有把报告引用误当作原件已进入 Git。框架本报告单独提交，未夹带样例代码或更改 project-source/。
