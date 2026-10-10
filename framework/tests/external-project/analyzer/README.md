# Analyzer 验证夹具

[测试与夹具](../../README.md#按需检查) · [验证范围](../../../maintenance/validation/validation-scope.md)

本目录保存图像 Analyzer 后端夹具，以及调试台调用 GAA 摘要的进程替身。夹具只在明确指定的外部验证项目使用，不进入复制清单。

## 图像后端与内存

外部项目需要已有对应版本的 `yaya/tools/analyzer/`。两个 Python 夹具从框架根目录调用，通过 YAYA_TEST_PROJECT 选择项目，不复制为业务测试。

按[准备与使用](../../../../project-source/tools/analyzer/README.md#准备与使用)准备 Python 3.13.16 的 yaya-analyzer 环境；后端夹具另需 jsonschema。保留夹具旁的 analyzer_protocol_cases.json，先建立外部项目的 `reports/asset-analyzer/`：

```powershell
$env:YAYA_TEST_PROJECT = '<外部验证项目绝对路径>'
$validationPython = '<该项目 analyzer_python_executable 的实际路径>'
& $validationPython -B framework/tests/external-project/analyzer/asset_analyzer_backend_test.py
& $validationPython -B framework/tests/external-project/analyzer/asset_analyzer_memory_check.py
```

- **后端夹具**：基础图像指标、源格式拒绝、模块选择和失败保留、结果 Schema、文件/stdout 输出、缓存身份、PNG 删除重算、同图双 worker、PNG/JSON 被占用后的发布、父进程退出和正常完成。以 unittest 计数及退出码判断。
- **内存夹具**：8MP 四宫格、两个并发图像 worker、Windows 内存分配拒绝。固定写入外部项目 `reports/asset-analyzer/memory-check.json`；运行前保留仍需使用的旧报告。以进程退出码、三条测量记录和分配拒绝断言判断。
- 两项夹具清理自己创建的媒体及缓存。跨盘用例要求项目位于 D 盘，请求写在 C 盘 LOCALAPPDATA/Temp，并检查临时文件与目标同目录。结束后恢复原 YAYA_TEST_PROJECT 环境变量。

这些检查不启动 Godot，不证明调试台界面或人工体验通过。

## GAA 进程替身

1. 把 `gaa_service_contracts.gd` 复制到外部项目 `dev/debug/_shared/tests/`，把 `gaa_summary_stub.py` 复制到其 `fixtures/`。
2. 在项目配置中填写普通 Python 的绝对路径。套件使用该解释器，通过服务已有的 launch 替换点，把 GAA 模块入口换成假脚本。
3. 在外部项目根目录运行项目包装脚本：

   ```powershell
   & '<项目 python_executable>' -B yaya/tools/testing/run-gdunit-tests.py --target dev/debug/_shared/tests/gaa_service_contracts.gd --continue
   ```

套件使用真实子进程，覆盖等待发布、成功结果、失败、中断和无结果文件。假脚本接受 GAA 的摘要参数，并额外接受测试用 `--case` 和 `--release-file`；它只输出固定指标，不进行音频测量。等待发布由释放文件控制，测试结束清理结果、释放文件和所属子进程。

界面字段、状态、音名和截图的替身测试保留在分发的 `dev/debug/_shared/tests/analysis_test.gd`。真实 GAA 集成另在外部项目运行：用服务分析 WAV，核对九项字段、运行身份和契约版本。真实集成通过与人工试听、观察分别记录。
