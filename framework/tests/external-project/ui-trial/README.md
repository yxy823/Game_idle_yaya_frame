# 按界面任务试用的引擎回归

[测试与夹具](../../README.md#按需检查) · [工具说明](../../../../project-source/tools/ui-trial/README.md)

本目录用真实 Godot 验证 `yaya/tools/ui-trial/` 的驱动基类、运行脚本和静态扫描。副本改名与拒绝运行的检查不需要 Godot，放在[工具回归](../tool-regression/README.md)的 `test_ui_trial_copy.py`，随统一入口运行。

## 运行

指定一个已带有本次 `yaya/tools/ui-trial/` 的外部项目，它只提供工具文件和 `docs/methodology-config.json` 中的 `engine_executable`：

```powershell
python -B framework/tests/external-project/ui-trial/test_ui_trial_engine.py --project D:\Games\MyGodotGame
```

测试在系统临时目录建立名为 `UI trial fixture trial` 的最小项目，复制工具的 `.gd` 和本目录的夹具后无头运行，结束时删除。所测项目的文件不被修改；Godot 会在 `%APPDATA%/Godot/app_userdata/` 下留下两个夹具项目的目录（`UI trial fixture trial`、`UI trial fixture`），只含日志。

退出码：`0` 全部通过；`1` 有用例失败；`2` 参数错误或项目没有 `yaya/tools/ui-trial/`。

## 用例

| 用例 | 夹具 | 检查什么 |
| --- | --- | --- |
| 看门狗 | `hang_driver.gd` | 驱动在等待中卡住，看门狗到时以退出码 2 结束 |
| 外层超时 | `busy_driver.gd` | 主线程死循环，看门狗无法触发，运行脚本到时结束进程树并返回 3 |
| 出错即退出 | `error_driver.gd` | 脚本运行错误立即以退出码 1 结束，后续步骤不被记成完成 |
| 操作 | `actions_driver.gd` | 点按钮、注入按键、读文字生效；点禁用按钮让试用失败 |
| 项目名检查 | `hang_driver.gd` | 直接用 Godot 在不以 ` trial` 结尾的项目中运行，驱动基类以退出码 3 拒绝 |
| 扫描规则 | `scan_cases.tscn` | S01–S05、S10 各有应报出的控件和不应报出的控件（有提示的图标按钮、文字清楚的按钮、间距足够的危险按钮、有提示的禁用按钮、隐藏按钮、对话框自带的按钮），结果必须与预期集合完全相同 |

一次运行约 15 秒，会启动 6 次 Godot，每次都有超时。
