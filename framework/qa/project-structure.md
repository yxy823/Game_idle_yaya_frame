---
template: doc
title: 生成项目的结构
---
## 生成的 Godot 项目里有哪几类文件，各管什么？

**结论**：按“给谁用、谁来写”分成五块：游戏本体、测试、开发辅助、项目文档与记录，以及框架带来的规则和工具。前四块是项目自己的内容；第五块由创建器复制进来，复制后也属于项目，可以按需修改。

**为什么**：同一类东西放在一起，找文件时先想“它是给谁用的”就能定位。例如商店的购买规则和商店面板都是游戏本体，放在 `game/` 的同一个模块里；调试商店价格用的调试台是开发辅助，放在 `dev/`，导出时整体排除。

```nested
生成的 Godot 项目 | 一个 Git 仓库
  游戏本体 | 玩家最终运行的部分
    main/ | 启动场景与顶层组装
    *game/ | 游戏独有的模块、场景与资源
    components/ | 确实要复用的能力
    assets/ | 共享资源
  测试 | 由 gdUnit 运行
    tests/ | 单元、Feature 验收、跨任务不变量
  开发辅助 | 帮助开发，不是游戏内容
    dev/ | 调试台与常用命令脚本，导出时排除
    addons/ | 第三方插件
  项目文档与记录 | 开发过程中逐步写出
    *docs/ | GDD、Product、Feature 记录、架构、问答
    reports/ | 运行原件与人工验收，不进 Git
  框架带来的规则与工具 | 复制后属于项目
    *AGENTS.md | Agent 的入口规则与任务路由
    yaya/ | 流程契约、工程规则、检查工具
    .agents/、.claude/、.codex/ | Skill 与角色配置
    .githooks/ | 提交时的自动检查
```

Agent 每次工作都从 `AGENTS.md` 开始，再按任务去读 `yaya/` 里的规则和对应的 Skill。所以项目的 Agent 规则集中在 `AGENTS.md` 和 `yaya/`，游戏的代码、场景、文档和测试都不放进 `yaya/`。

创建项目时，`docs/`、`tests/` 等目录只有用途说明和空的初始文件。目录存在只说明位置已经准备好，不说明对应的工作已经完成。

**依据**：[项目对象与目录](../godot-project-manual/foundations/project-layout.md)，其中有每个文件的说明和完整目录树；复制映射只维护在 [project-files.json](../project-creation/project-files.json)。

## 开发一个 Feature 时，会依次读写哪些文件？

**结论**：从 GDD 开始，经过 Product 和 Feature 记录，再到代码、测试和运行原件，最后由完成证据把 Feature 标为 done。每一步写出的文件，就是下一步读取的来源。

**为什么**：以“给放置游戏加一个离线收益”为例，文件按下图依次产生。连线上写的是负责这一步的 Skill 或 Stage。

```flow LR
(你的想法) -> GDD: design-gdd
GDD -> Product: product-author
Product -> *Feature 记录: feature-plan
Feature 记录 -> 设计稿 & 测试登记: Stage 2
设计稿 -> 游戏代码: Stage 3
测试登记 -> 测试: Stage 3
游戏代码 & 测试 -> 运行原件: Stage 4
运行原件 -> 完成证据: Stage 7
完成证据 -> Feature 记录: 标记 done
游戏代码 --> GDD: 3D 文档检查
```

图中每个名称对应的位置：

| 图中名称 | 位置 | 保存什么 |
| --- | --- | --- |
| GDD | `docs/gdd/` | 游戏定位、核心循环、系统规则与数值 |
| Product | `docs/product.md`、`docs/product/` | 交付单元的范围、依赖和顺序 |
| Feature 记录 | `docs/feature-list.json`、`docs/features/F0XX.json` | Feature 的范围、AC、状态和验证义务 |
| 设计稿 | `docs/features/F0XX-design.md` | 这个 Feature 的实施设计 |
| 测试登记 | `docs/test-registry.json` | 组件与测试 ID，测试运行器按它选测试 |
| 游戏代码 | `game/`、`main/`、`components/` | 实际实现 |
| 测试 | `tests/` | 自动测试 |
| 运行原件 | `reports/` | gdUnit 运行结果、人工验收清单 |
| 完成证据 | `docs/features/F0XX-evidence.json` | 把运行原件和当前内容绑定起来 |

几处容易误解的地方：

- 虚线表示回写：Stage 3D 让本次涉及的 GDD、Product、规格和架构文档与实际决定一致，所以文件关系不是单向的。
- 运行原件在 `reports/`，默认不进 Git；完成证据在 `docs/`，会提交。Feature 是否完成以完成证据和 Feature 记录里的状态为准，测试通过或代码提交都不能单独证明。
- 每次停下或换对话前，Agent 会更新 `docs/progress.md`，写明当前停点和下一步。它不在主线上，所以图里没有画。

**依据**：[任务类型、开发阶段与完成语义](../godot-project-manual/requirements-and-tasks/feature-lifecycle.md)、[交付规划与 Feature 记录](../godot-project-manual/foundations/project-layout.md#交付规划与-feature-记录)；从空白项目开始的完整操作见[教程一：从空白项目到第一份 Feature 计划](../godot-project-manual/tutorial/01-blank-project-to-feature-plan.md)。

## 游戏代码的几个目录之间，谁可以引用谁？

**结论**：`main/` 组装 `game/`，`game/` 使用 `components/`；`dev/` 和 `tests/` 可以引用游戏代码，反过来不行。游戏本体一旦引用 `dev/`，导出时排除 `dev/` 就会让游戏缺文件。

**为什么**：

```flow LR
main/ -> game/: 组装
game/ -> components/: 使用
dev/ --> game/: 调试台挂接
tests/ --> game/ & components/: 测试
```

- `main/` 只负责启动和连接顶层模块，具体行为仍写在所属模块里。
- 只有不依赖当前游戏规则、确实要在别处复用的能力才放进 `components/`；否则先留在 `game/` 的模块里。
- `main/`、`game/`、`components/` 和 `project.godot` 不能引用 `dev/`。`tests/invariants/` 里的依赖方向测试每次全量测试都会检查这一点，所以这条规则不靠人记。

**依据**：[游戏职责与项目组织指南](../../project-source/defaults/docs/game-organization.md)、[依赖方向测试](../../project-source/defaults/tests/invariants/debug_dependency_test.gd)
