# 提示词与场景工具

[框架入口](../../README.md#维护命令)

本目录的脚本核对两份提示词库、同名场景页与开发场景图之间的名称和路径对应，并维护场景图节点的场景链接。命令在仓库根目录、使用已确认的 Python 3.12+ 运行；`-B` 禁止生成字节码缓存，参数细节以 `--help` 为准。

## 提示词与场景路径检查

```powershell
python -B framework/prompt-scenarios/tools/check_scenario_prompt_paths.py
```

默认合并两份提示词库的名称，检查 `framework/prompt-scenarios/scenarios/<Project>/<分类>/<提示词名称>.md` 是否一一对应。名称与路径规则见[提示词与场景准则](../../maintenance/design-guidelines/04-prompts-and-scenarios.md)。

- **可选参数**：`--prompts <JSON> [<JSON> ...]`、`--scenarios <目录>`；每份只允许一个 Project，跨文件重复 Project 也会报错。
- **检查范围**：只读检查缺少、多余、重复与非法路径；场景目录根级的 `README.md`、`scenario-index.md` 是导航排除项。
- **退出码**：`0` 集合一致；`1` 缺少或多余；`2` 输入或结构错误。
- **不检查**：正文 H1、具体步骤、授权与语义由作者自查；也不验证实际运行结果。

## 检查场景图名称与链接

```powershell
python -B framework/prompt-scenarios/tools/check_workflow_graph_names.py --summary
python -B framework/prompt-scenarios/tools/link_workflow_graph_scenarios.py --check
```

两个命令默认读取 `framework/prompt-scenarios/prompts/godot-development-prompts.json` 和开发场景图，`--prompts`、`--graph` 可分别指定其他文件。

- **名称检查**：只忽略 CR/LF，报告缺少、多余、重名及节点 ID 重复；去掉 `--summary` 可查看字段位置和候选名称。
- **链接写入**：去掉 `--check` 时只修改节点的 `link`，会替换已有链接；名称不匹配或目标文件缺失时不写入。链接是当前仓库的绝对本地路径，仓库移动后重新运行即可。只读审核不运行写入命令。

两项检查都不覆盖完整格式、连线含义或显示效果；图的维护规则见[文档关系图与开发场景图](../../relationship-maps/README.md)。
