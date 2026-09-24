# 新项目骨架与统一命名：实施及验证

日期：2026-09-23。修改基线 `bb5fbe0bc86f0f5a293b02b439276c0e999018af`，开始时工作区干净。 用户确认共同目录骨架、按游戏类型展开的判断指南、`main/` 最小可运行入口与文件命名建议，并明确不保留旧命名兼容；外部验证目录由 Agent 自行新建。

## 实施结果

- 新项目包含 `main/`、`game/`、`components/`、`assets/`、`addons/`、`tests/`。入口为 `main/main.tscn`，使用普通 Node 根节点和居中就绪提示，没有空脚本或预置玩法。测试分层目录只有占位文件。
- [目录与命名指南](../../../project-source/defaults/docs/game-organization.md) 随项目复制，说明功能归属、专属与共享资源、探索/放置游戏的按需展开、职责词及 Autoload 的生命周期判断。
- 自有 Godot 文件与目录统一英文 `snake_case`，类/节点沿用 `PascalCase`；工具契约与第三方命名保留。旧名称违规按错误处理，不增加别名或回退。
- 迁移示例中的 57 个文件名及场景、资源、脚本、分析组、测试和说明引用，其中 4 份 `.uid` 保持身份、5 份 `.import` 由外部 Godot 重新生成并核对 UID 后回写。媒体字节未变。
- 复制清单、复制回归、规则路由、advisor 场景参考、项目 README、维护手册与当前进度同步。创建器仍只复制，初始环境为 `incomplete`，Product/测试登记为空。

没有新增命名监督脚本或兼容机制。静态复核核对了规则例外、引用、复制后链接与生成 HTML，没有剩余必须修复项；该复核不是完整开发流程或人工体验验收。

## 验证地点与结果

真实引擎只在新建的 `D:/A_Games/Yaya_Skeleton_Validation_20260923` 运行，使用 Godot 4.7.1 / Windows / RTX 4060 Laptop 和指定 `codex-python`。 创建器复制 30 项材料。仅在副本补充测试夹具、设置 Python 路径，并从已有验证项目复制锁定版本的 Analyzer 运行依赖；未安装新依赖，未把这些环境状态回灌源材料。 最终 700 份分发运行文件与被测副本逐字节一致。外部临时导出预设完成后已移除，机器配置及原始报告保留。

以下证据位于[本轮外部报告目录](D:/A_Games/Yaya_Skeleton_Validation_20260923/reports)。

| 层次 | 实际结果 | 原始证据 |
| --- | --- | --- |
| 维护回归 | 38/38，20.683 s；使用 unittest，未执行 pytest | 本轮终端原始输出 |
| 默认主入口 | 实际启动退出 0；1600×900 图像显示居中提示，已查看截图 | `starter_run.log`、`starter00000002.png` |
| Godot 行为 | 12/12 套件、134/134 用例，24.243 s；错误、失败、跳过、孤儿均为 0 | `starter_behavior.log`、`gdunit-wrapper/run-ux72pdak/result.json` |
| 解析 | 10 份受影响脚本/探针退出 0，无解析诊断 | `starter_parse_results.json`、`parse_*.log` |
| lint | 65 文件，0 Critical / 0 Warning、485 Info；阈值未改 | `starter_lint.json`、`starter_lint.log` |
| 独立消费包 | 最终导出退出 0，无错误诊断；从报告目录用 `--main-pack` 加载包，四入口声部分别 1/3/2/2，生命周期与工具排除断言通过 | `asset_consumers_verified.zip`、`starter_export_verified.log`、`starter_export_probe.json` / `.log` |
| 静态核对 | 命名/资源引用、UID、复制排除、源与被测内容、Skill 格式与文档链接通过；最终定向复核无必须修复项 | 本轮差异与终端输出 |
| 手册构建 | 22 篇、32 张 Mermaid SVG、530 个来源链接检查，构建退出 0 | [离线阅读版](../../docs/blank-project/blank-project-handbook.html) |

消费包验证使用 Compatibility 渲染器和引擎资源包，不是独立可执行发行包验证。没有重跑未受影响的后端全量回归、性能压测或所有历史画面场景。

## 失败与恢复

1. 首次导出虽然退出 0，却报告两次 `Cannot get keys from nonexistent section "preset.0.options"`；未计为通过。测试专用预设原来只有空段，现明确默认 `binary_format/embed_pck=false`，重新导出及包内消费均通过。保留 `starter_export.log` 和首次 `asset_consumers.zip` 供核对。
2. 手册首次构建遇到 npm 缓存访问限制；沿审批路径使用离线缓存后，浏览器仍立即退出。多个已安装 Chromium 入口复现。仅在成功构建进程内移除继承的 `__COMPAT_LAYER=DetectorsAppHealth` 后，同一 Edge 正常完成全部 SVG；未修改系统设置、生成器或依赖。

成功构建沿用原命令，进程内设置为：

```powershell
$env:npm_config_offline = 'true'
$env:__COMPAT_LAYER = $null
& 'C:/Users/89523/anaconda3/envs/codex-python/python.exe' -B framework/commands/build_blank_project_handbook.py --browser 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'
```

## 人工确认边界

实现与上述自动验证完成。主入口的实际使用体验、示例听感与交互、手册排版和浏览器阅读体验仍由用户确认；没有运行 Playwright 或以构建成功替代视觉验收。 阅读时重点查看“创建项目”“首次使用”的最小入口边界及“目录参考”；项目内指南用于后续具体游戏的目录判断，示例模块不会自动创建。
