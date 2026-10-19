# 提示词与场景工具

[框架入口](../../README.md#维护命令)

本目录的脚本核对两份提示词库与同名场景页之间的名称和路径对应。命令在仓库根目录、使用已确认的 Python 3.12+ 运行；`-B` 禁止生成字节码缓存，参数细节以 `--help` 为准。

## 提示词与场景路径检查

```powershell
python -B framework/prompt-scenarios/tools/check_scenario_prompt_paths.py
```

默认合并两份提示词库的名称，检查 `framework/prompt-scenarios/scenarios/<Project>/<分类>/<提示词名称>.md` 是否一一对应。名称与路径规则见[提示词与场景准则](../../maintenance/design-guidelines/04-prompts-and-scenarios.md)。

- **可选参数**：`--prompts <JSON> [<JSON> ...]`、`--scenarios <目录>`；每份只允许一个 Project，跨文件重复 Project 也会报错。
- **检查范围**：只读检查缺少、多余、重复与非法路径；场景目录根级的 `README.md`、`scenario-index.md` 是导航排除项。
- **退出码**：`0` 集合一致；`1` 缺少或多余；`2` 输入或结构错误。
- **不检查**：正文 H1、具体步骤、授权与语义由作者自查；也不验证实际运行结果。
