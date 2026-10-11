# 测试与夹具

[框架入口](../README.md#维护命令)

`repository/` 保存从仓库根目录运行的维护回归；`external-project/` 保存需要指定外部项目的工具回归、调试台分析与插件夹具，均不进入复制清单。

## 按需检查

维护层回归使用系统临时目录，覆盖复制、路径映射、文档指纹与人工验收文件契约：

```powershell
python -B -m unittest discover -s framework/tests/repository -p test_*.py
```

文档指纹和人工文件测试只建立中立 Git 夹具，不创建业务项目或运行游戏；合成结果不证明真实人工体验。

项目工具回归需要明确指定、且已对应本次修改的外部项目：

```powershell
python -B framework/tests/external-project/run_project_tool_tests.py --project D:\Games\MyGodotGame
```

这个入口只运行已有 unittest，不创建或配置项目、不写示例 Feature 记录，也不执行 Godot、人工验收或发布；所测项目的机器配置与无关文件保留。仅静态任务不执行这些回归命令。

真实引擎、lint、gdUnit、调试台分析和插件夹具按实际变化选择，放置位置、依赖与结果边界见各夹具目录的说明：[工具回归夹具](external-project/tool-regression/README.md)、[调试台分析验证夹具](external-project/analyzer/README.md)、[编辑器插件验证夹具](external-project/plugins/README.md)、[按界面任务试用的引擎回归](external-project/ui-trial/README.md)、[文档语言冒烟场景](external-project/document-language/README.md)。Python 工具通过与真实引擎运行分别记录；夹具文件存在也不证明本轮已执行。
