# 调试台分析验证夹具

[测试与夹具](../../README.md#按需检查) · [验证范围](../../../maintenance/validation/validation-scope.md)

本目录保存调试台调用 GAA 后台模式的进程替身。夹具只在明确指定的外部验证项目使用，不进入复制清单。

## GAA 进程替身

1. 把 `gaa_service_contracts.gd` 复制到外部项目 `dev/debug/_shared/tests/`，把 `gaa_summary_stub.py` 复制到其 `fixtures/`。
2. 在项目配置中填写普通 Python 的绝对路径。套件使用该解释器，通过服务已有的 launch 替换点，把 GAA 模块入口换成假脚本。
3. 在外部项目根目录运行项目包装脚本：

   ```powershell
   & '<项目 python_executable>' -B yaya/tools/testing/run-gdunit-tests.py --target dev/debug/_shared/tests/gaa_service_contracts.gd --continue
   ```

套件使用真实子进程，覆盖等待发布、成功结果、失败和无结果文件。假脚本接受 GAA 后台模式的参数 `analyze <源文件> --result-file <结果文件>`，并额外接受测试用 `--case` 和 `--release-file`；它按 GAA 的结果文件格式写固定指标，失败时 `metrics` 为 `null`、`error` 为 `{code, message}`，不进行音频测量。等待发布由释放文件控制，测试结束清理结果、释放文件和所属子进程。

## 替身测试与真实集成

界面字段、状态和音名的替身测试保留在分发的 `dev/debug/_shared/tests/analysis_test.gd`。真实集成另在外部项目运行：用服务分析 WAV，核对九项指标和结果文件的五个顶层字段。

真实集成通过与人工试听分别记录。
