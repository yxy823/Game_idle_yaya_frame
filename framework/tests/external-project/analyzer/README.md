# Analyzer 验证夹具

[测试与夹具](../../README.md#按需检查) · [验证范围](../../../maintenance/validation/validation-scope.md)

本目录保存 Analyzer Python 后端的维护夹具，适用于修改 `project-source/tools/analyzer/` 的后端、协议或内存限制。外部项目需要已有对应版本的 `yaya/tools/analyzer/`。

两项夹具都从框架根目录直接调用，通过 `YAYA_TEST_PROJECT` 选择已授权外部项目，不复制为业务测试。先按 [Analyzer 安装说明](../../../../project-source/tools/analyzer/README.md)准备 Analyzer 环境并配置外部项目；后端测试还需要在这个环境中另装 `jsonschema`（只供回归使用），并保留夹具旁的 `analyzer_protocol_cases.json`。建立外部项目的 `reports/asset-analyzer/` 后运行，两个占位值替换为本次实际路径（解释器使用外部项目 `docs/methodology-config.json` 中的 `analyzer_python_executable`）：

```powershell
$env:YAYA_TEST_PROJECT = '<外部验证项目绝对路径>'
$validationPython = '<Analyzer 环境的解释器路径>'
```

| 夹具与命令（按需选择） | 检查及副作用 |
| --- | --- |
| `& $validationPython -B framework/tests/external-project/analyzer/asset_analyzer_backend_test.py` | 实际音频/图像后端、错误输入、缓存与协议；写入专属临时媒体及缓存，正常清理；以 unittest 结果与退出码判断 |
| `& $validationPython -B framework/tests/external-project/analyzer/asset_analyzer_memory_check.py` | Windows 子进程内存限制、边界素材及双 worker 测量；生成并清理临时媒体和本次缓存，固定写入外部项目 `reports/asset-analyzer/memory-check.json` |

内存测量会覆盖同名报告，先保留仍需使用的旧结果。检查真实进程退出码、内存记录和分配拒绝断言，不把一次测量推广为所有素材或设备的性能保证。结束后恢复原 `YAYA_TEST_PROJECT` 环境变量。

