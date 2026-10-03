# 70 测试规则

测试层级按测试需要多少真实的 Godot 运行时语义来划分：

```text
L0 Static/File Validation
L1 Unit Test
L2 Godot Integration Test
L3 Runtime Scene Test
Manual Visual Acceptance
```

各层依次为：L0 静态与文件验证、L1 单元测试、L2 Godot 集成测试、L3 运行时场景测试，以及人工视觉验收。

[视觉验证边界](testing-strategy.md#视觉验证边界)和[覆盖率与性能策略](production-isolation.md#覆盖率与性能策略)规定了项目不使用哪些图像类和数值类的检查门槛。

阅读与本次修改匹配的文档；测试实际涉及多个领域时，合并阅读。

| 文档 | 何时阅读 |
| --- | --- |
| `testing-strategy.md` | 选择测试层级、复核层级分布，或应用视觉验证边界 |
| `gdunit4-profile.md` | 编写或运行 gdUnit4 测试，或修改运行器、结果处理、清理或运行器版本 |
| `unit-tests.md` | 编写或复核 L1 测试、测试替身，或重构前的特征测试 |
| `integration-tests.md` | 编写或复核使用真实 Godot 语义的 L2 测试 |
| `scene-runtime-tests.md` | 编写或复核 L3 运行时场景测试 |
| `fixtures-and-isolation.md` | 创建或修改测试夹具、共享或全局状态、测试用 Resource 或文件，或清理 |
| `time-randomness-and-async.md` | 测试时间、帧、Tween、随机性或异步行为 |
| `input-and-command-testing.md` | 测试输入、UI 交互或 Command 行为 |
| `errors-logs-and-diagnostics.md` | 运行测试并评估结果，或测试预期的错误、日志及其抑制 |
| `production-isolation.md` | 修改测试根目录、导出、Autoload、生产代码与测试代码之间的依赖，或生成的和第三方的测试资源 |
| `test-selection-and-gates.md` | 选择验证范围，或解读测试发现规则和完成检查的验证档位 |
| `feature-test-integration.md` | 创建或修改 Feature 的测试映射，或在 Feature 工作流程中执行测试 |

本模块没有单独的 `validation.md`：上面每份文档各自写明其规则要求的证据。
