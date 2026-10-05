# 工程规则目录

本目录按领域保存引擎与语言的具体规则。工作流程、任务范围、Git、验证与完成汇报不在这里，见 [AGENTS.md](../../AGENTS.md) 和 `yaya/methodology/`。带编号的模块目录只用于组织规则，不规定项目自身的目录布局。

## 怎样阅读

做修改或与修改有关的工程决定时，先读 [00-core/README.md](00-core/README.md)，再读下表中每个受影响领域的 README：

- 按 README 的路由表只读匹配的文件和小节，不读整个目录。需要的验证写在模块 README 末尾的验证节。
- 模块可以叠加。例如测试用的 `.gd` 文件同时适用 GDScript 规则和测试规则。
- 续接时，已读且未变化的规则直接复用。只有任务或新证据需要时才多读。
- 规则冲突按[规则冲突的处理流程](00-core/rule-precedence-and-routing.md#规则冲突的处理流程)解决。

| 修改的对象或领域 | 规则入口 |
| --- | --- |
| GDScript | [10-gdscript/README.md](10-gdscript/README.md) |
| 场景 | [20-scenes/README.md](20-scenes/README.md) |
| 资源 | [21-resources/README.md](21-resources/README.md) |
| Shader | [30-shaders/README.md](30-shaders/README.md) |
| ProjectSettings | [40-project-config/README.md](40-project-config/README.md) |
| 导出配置或导出流水线 | [41-export-config/README.md](41-export-config/README.md) |
| 游戏数据、数据结构定义或数据流水线 | [50-data-files/README.md](50-data-files/README.md) |
| 素材或导入流水线 | [60-assets/README.md](60-assets/README.md) |
| 测试、测试夹具或测试运行器 | [70-tests/README.md](70-tests/README.md) |
| UID、路径、NodePath、业务 ID 或 RID 的身份 | [00-core/godot-resource-references.md](00-core/godot-resource-references.md) |

## 常见任务读哪些

| 任务 | 阅读 |
| --- | --- |
| 改 `.gd` 并加单元测试 | `00-core/README.md`；`10-gdscript/README.md` 与 `typing-and-api.md`；`70-tests/README.md` 与 `test-levels.md` |
| 重命名或移动节点、场景、资源 | `00-core/godot-resource-references.md`；`20-scenes/README.md`；移动资源文件时再读 `60-assets/README.md` |
| 导入或替换图片、音频、字体 | `60-assets/README.md`；涉及 `.import` 或生成文件时读 `00-core/third-party-generated-and-temporary-files.md` |
| 新增或修改游戏数据及其定义 | `21-resources/README.md`；`50-data-files/README.md` |
| 在 Codex 沙箱中运行任何 Godot 进程 | `00-core/windows-godot-sandbox.md` |

## 没有专门模块时

使用 `00-core` 规则和项目已有的约定，只在主题重叠处读相邻模块。修改依赖随版本变化的引擎行为时，按 [Godot 版本与依据](00-core/godot-version-and-authority.md) 核对 Godot 4.7 的行为；普通的 Markdown 编辑不需要。不在实现过程中顺带扩展规则体系。

要判断游戏逻辑和游戏表现的职责归属、它们的设计来源，或模块的位置和命名，读 [`docs/game-organization.md`](../../docs/game-organization.md) 中匹配的小节。它解释概念并给出示例；命名和引擎约束仍以上面的规则模块为准。
