# 实际导入验证 · 2026-09-20

## 结论与范围

从不存在的目录创建独立项目，实际完成复制、环境设置、Godot 首次导入、Codex Skill 发现、项目工具回归和真实引擎契约测试。本次未发现框架导入缺陷，没有修改框架实现或第三方插件来使验证通过。

这次验证没有运行游戏业务 Feature、人工验收、专业审核或发布。自定义审核角色只核对了复制和 TOML 解析，没有实际调用该角色；其运行时权限和上下文独立性仍未验证。

## 基线与结果

| 检查 | 实际结果 |
| --- | --- |
| 框架基线 | `ed3a71b19595af590b1ca16aecba566e7c8af06e`，验证前工作区干净 |
| 新项目 | `D:/A_Games/Yaya_Import_Validation_20260920`，创建前不存在且不在其他 Git 仓库内 |
| 创建器 | `framework/commands/create_project.py --output <新项目>`，22 个映射项；初始化前展开核对 775 个文件，路径和字节均一致 |
| 工具版本 | Python 3.12.13；Godot `4.7.1.stable.official.a13da4feb`；Codex CLI `0.155.0-alpha.9.2` |
| 环境与台账 | 配置本机路径后，`check-project-environment.py --require-ready` 和空白台账检查均退出 0 |
| Godot 首次导入 | 沙箱外 `--headless --editor --path <新项目> --quit` 退出 0；日志无错误或警告，根目录仅新增正常 `.godot` |
| Codex 发现 | 实际调用 app-server `skills/list`，指定新项目 cwd 并强制刷新：27 项项目 Skill 全部启用、零加载错误；未创建模型执行轮次 |
| 项目工具回归 | `framework/commands/run_project_tool_tests.py --project <新项目>`：159 项通过，35.656 秒 |
| 真实引擎 lint 契约 | 现有 `gdscript_lint_contracts.gd`：108 项检查，零失败 |
| 正式 gdUnit 包装器 | 现有 `gdunit_runner_contracts.gd`：4 项通过，零错误、失败、跳过、flaky 或孤儿；包装器退出 0，结果 passed |

项目环境采用 `C:/Users/89523/anaconda3/envs/codex-python/python.exe` 和 `E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe`。这些机器配置只保存在验证项目，不回写框架默认值。复制内容仅配置和 Progress 经初始化修改；首次导入另产生 12 个正常 `.import` 文件。

## 过程问题与处理

首次探索第三方 gdUnit 直接入口时，在参数前误加 `--`，命令仅输出帮助并返回 0。该次没有执行用例，不计为通过。随后改用项目已有正式包装器，得到真实四用例通过结果。包装器原有参数就是正确的，因此这属于验证命令纠正，不是框架修复。

读取沙箱外引擎产生的报告时遇到受限沙箱访问错误，沿原审批路径只读复核成功；未修改 ACL。Git 暂存按已有属性规范化第三方 `.cmd` 的 CRLF，提交核对按换行规则比较，未更改第三方逻辑。

## 原始记录与保留范围

以下路径相对于新项目：

- 初始化与边界：`reports/initialization.md`，当前交接入口 `docs/progress.md`。
- 首次导入：`reports/import-validation/godot-first-import.log`。
- Skill 实际发现：`reports/import-validation/codex-skill-discovery.json`。
- lint：`reports/import-validation/lint-contracts.json` 和同名 `.log`。
- 未执行测试的探索尝试：`reports/import-validation/gdunit-contracts.log`。
- 正式测试：`reports/gdunit-wrapper/run-w1h7g5q8/result.json`、`engine.log`、`report_1/results.xml` 及发现与诊断原件。
- 中性测试夹具：`reports/scratch/import-contracts/`，从框架现有夹具原样复制。

159 项工具回归的原始输出保留在本次会话，没有另存日志。运行报告、协议探测文件、临时夹具和 `.godot` 缓存沿项目忽略规则留在本机；正常资源旁文件保留。框架本次仅提交本报告；验证项目初始化提交为 `f7d2b99`，包含 787 个文件，提交后工作区干净。未推送。
