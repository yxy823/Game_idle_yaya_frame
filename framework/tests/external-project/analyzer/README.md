# Analyzer 验证夹具

[测试与夹具](../../README.md#按需检查) · [验证范围](../../../maintenance/validation/validation-scope.md)

本目录保存 Analyzer Python 后端的维护夹具，适用于修改 `project-source/tools/analyzer/` 的后端、协议或内存限制。外部项目需要已有对应版本的 `yaya/tools/analyzer/`。

两项夹具都从框架根目录直接调用，通过 `YAYA_TEST_PROJECT` 选择已授权外部项目，不复制为业务测试。先按[资源 Analyzer](../../../../project-source/tools/analyzer/README.md)的说明准备 Python 3.13.16 的 `yaya-analyzer-2` 环境，把对应版本的 Analyzer（含 features/）同步到已授权外部项目。后端夹具另需 `pip install --only-binary=:all: jsonschema`，只供回归使用；保留夹具旁的 `analyzer_protocol_cases.json`。建立外部项目的 `reports/asset-analyzer/` 后运行，两个占位值替换为本次实际路径（解释器使用外部项目 `docs/methodology-config.json` 中的 `analyzer_python_executable`）：

```powershell
$env:YAYA_TEST_PROJECT = '<外部验证项目绝对路径>'
$validationPython = '<Analyzer 环境的解释器路径>'
```

| 夹具与命令（按需选择） | 检查及副作用 |
| --- | --- |
| `& $validationPython -B framework/tests/external-project/analyzer/asset_analyzer_backend_test.py` | 基础指标、文件/stdout 输出、C 盘请求与 D 盘缓存、模块选择与失败保留、模块缓存身份及 PNG 删除重算、同图双 worker 与 PNG/JSON 占用后发布、合成信号的新指标与共同协议；清理专属临时媒体、JSON 和 PNG 缓存，以 unittest 结果与退出码判断 |
| `& $validationPython -B framework/tests/external-project/analyzer/asset_analyzer_memory_check.py` | Windows 内存限制、8MP 四宫格、边界音频、双图像 worker；隔离副本的全部音频模块含 10 秒 pYIN 冷/热各一次；清理本次媒体和 JSON/PNG 缓存，固定写入外部项目 `reports/asset-analyzer/memory-check.json` |

内存测量会覆盖同名报告，先保留仍需使用的旧结果。检查真实进程退出码、内存记录和分配拒绝断言，不把一次测量推广为所有素材或设备的性能保证。结束后恢复原 `YAYA_TEST_PROJECT` 环境变量。

跨盘夹具要求外部项目在 D 盘，请求写入 C 盘 LOCALAPPDATA/Temp，并核对原子写临时文件与目标同目录。pYIN 冷运行使用报告区的专属 Analyzer 副本和空 Numba 目录；热运行 force 重算，避免测到结果缓存。生产副本的 numba-cache 保留，隔离副本随临时目录清理。

合成信号证明指标计算和状态契约；真实素材分析及 Godot 后台调用、界面回显分别验收。这两项夹具不启动 Godot 窗口。
