# 项目目录与文件职责

[返回手册](../README.md) · 相关：[配置参考](configuration.md)、[项目知识与交接](../guides/project-knowledge.md)

本页按当前复制清单描述初始文件，再列出开发期间按需创建的内容。树中省略插件内部文件，目录存在不代表已编写业务内容或完成验证。

## 刚复制完成的目录

```text
MyGodotGame/
├── AGENTS.md
├── README.md
├── .agents/skills/                  11 项 Skill，含各自脚本或参考资料
├── .editorconfig
├── .gitattributes
├── .gitignore
├── project.godot
├── gdlint.json
├── addons/
│   ├── gdUnit4/
│   └── gdscript-linter/
├── agent-rules/                     按工程领域路由的规则
├── methodology/                     流程规范与 templates/
├── tools/
│   ├── checks/                     环境与 Feature 台账检查
│   ├── testing/                    gdUnit 运行器及 GDScript 扩展
│   └── lib/                        共享实现
├── docs/
│   ├── .gdignore
│   ├── methodology-config.json
│   ├── product.md                  空文件
│   ├── feature-list.json           features 为空
│   ├── feature-list-revisions.json revision_log 为空
│   ├── test-catalog.json            components 与 tests 为空
│   ├── progress.md                 当前状态模板
│   └── coding_rules.md             协作与通用架构约定
└── reports/
    └── .gdignore
```

`.git/`、`.godot/`、游戏场景和业务测试都不由复制器创建。配置中的 `tests/unit` 等值是后续目录约定，不表示这些目录已经存在。

## 源材料到项目的映射

以下以仓库根目录为源路径起点，以新项目根目录为目标起点。真正的复制范围始终以 [project-files.json](../../../project-files.json) 为准。

| 源材料 | 新项目位置 |
| --- | --- |
| `project-source/Project_AGENTS.md` | `AGENTS.md` |
| `project-source/Project_README.md` | `README.md` |
| `project-source/Project_Config.json` | `docs/methodology-config.json` |
| `project-source/skills/` | `.agents/skills/` |
| `project-source/methodology/` | `methodology/` |
| `project-source/agent-rules/` | `agent-rules/` |
| `project-source/tools/` | `tools/` |
| `project-source/addons/gdUnit4/` | `addons/gdUnit4/` |
| `project-source/addons/gdscript-linter/` | `addons/gdscript-linter/` |
| `project-source/defaults/.editorconfig` | `.editorconfig` |
| `project-source/defaults/.gitattributes` | `.gitattributes` |
| `project-source/defaults/.gitignore` | `.gitignore` |
| `project-source/defaults/docs/` | `docs/`，当前包含空 Product 和 `.gdignore` |
| `project-source/defaults/docs/.gdignore` | 另复制为 `reports/.gdignore` |
| `project-source/defaults/gdlint.json` | `gdlint.json` |
| `project-source/defaults/project.godot` | `project.godot` |
| `project-source/methodology/templates/feature-list.json.tmpl` | `docs/feature-list.json` |
| `project-source/methodology/templates/feature-list-revisions.json.tmpl` | `docs/feature-list-revisions.json` |
| `project-source/methodology/templates/test-catalog.json.tmpl` | `docs/test-catalog.json` |
| `project-source/methodology/templates/progress.md.tmpl` | `docs/progress.md` |
| `project-source/methodology/templates/coding_rules.md.tmpl` | `docs/coding_rules.md` |

部分模板既保留在项目 `methodology/templates/` 中，又复制为初始 `docs/` 文件。复制为初始文件时仅重命名，不执行变量渲染或语言转换。

## 开发中按需出现的内容

| 路径 | 建立时机 | 主要内容 |
| --- | --- | --- |
| `docs/product/NN-name.md` | 产品模块需要详细规格时 | 流程、数据含义、状态、UI、音频、数值、AC |
| `docs/features/F001.json` 等 | 首次规划或新增工程任务时 | 任务行为、组件、AC、验证映射、长期 notes |
| `docs/gate-evidence.json` | Feature 执行初始化完成依据时 | 当前任务的测试原件引用、人工决定与复审结果 |
| `docs/progress/<key>.md` | 一项 Feature 或获批批次需要归档时 | 一份执行历史正文 |
| `docs/architecture.md` | 需要项目级职责和依赖地图时 | 当前架构导航 |
| `docs/architecture/<subsystem>.md` | 某个子系统需要展开说明时 | 状态归属、关键运行流程、生命周期与失败处理 |
| `docs/architecture/adr-NNNN-<slug>.md` | 存在值得长期保留的重要技术决定时 | 方案、理由、取舍与证据 |
| `tests/unit/` | 创建组件单元测试时 | 局部代码契约 |
| `tests/features/` | 创建 Feature 验收或 Bug 回归时 | 用户行为与历史缺陷覆盖 |
| `tests/invariants/` | 确实需要跨 Feature 不变量测试时 | 可执行的通用约束 |
| `reports/initialization.md` | 环境准备时 | 实际初始化过程与结果 |
| `reports/gdunit-wrapper/run-<id>/` | 每次显式测试运行时 | `result.json`、日志、发现集合及原始测试报告 |

游戏源码、场景、资源和素材源文件按游戏实际模块组织。项目规则目录中的 `10-gdscript`、`20-scenes` 等数字是规则导航，不要求业务目录也按文件类型分组。

## 模板怎么使用

| 模板组 | 用途 |
| --- | --- |
| `product.md.tmpl`、`product-module.md.tmpl` | Product 总览与模块规格 |
| `feature-detail.json.tmpl` | 产品 Feature，省略 `engineering_change` |
| `engineering-feature-detail.json.tmpl` | Bug、重构、维护 Feature |
| `feature-list.json.tmpl`、`feature-list-revisions.json.tmpl` | 任务索引与源需求演进记录 |
| `test-catalog.json.tmpl`、`gate-evidence.json.tmpl` | 测试索引与完成依据结构 |
| `progress.md.tmpl`、`stage8-learning.md.tmpl` | 当前交接与任务结束时的简短经验 |
| `coding_rules.md.tmpl` | 协作约定与通用设计原则 |
| `architecture-overview.md.tmpl`、`architecture-subsystem.md.tmpl` | 按需架构地图 |
| `architecture-decision-record.md.tmpl` | 按需 ADR |

模板提供结构。Skill 生成正文时遵循 `document_language`，保留机器字段、ID、状态和路径。不要一次性把所有模板实例化成空文档；例如没有真实架构决定就不创建占位 ADR。模板要求见 [模板说明](../../../../project-source/methodology/templates/README.md)。

## 工具为什么分成几处

`tools/checks/` 放跨任务检查，`tools/testing/` 放真实测试入口，`tools/lib/` 放共享实现。只服务于某个流程的脚本随其 Skill 保存：

- `.agents/skills/execute-next-feature/scripts/write-gate-evidence.py` 记录与检查完成依据。
- `.agents/skills/generate-feature-list/scripts/merge_test_catalog.py` 合并规划阶段的组件 Catalog。

这些是直接入口，没有根目录转发脚本，也没有自动工具事件。`project.godot` 中的 gdUnit session hook 是引擎测试诊断扩展，不是监督 Agent 编辑动作的 Hook。

## Git、Godot 忽略文件与报告

默认 `.gitignore` 排除 `.godot/`、Python 字节码和测试缓存，以及 `reports/` 下除 `.gdignore` 外的内容。`docs/` 下的需求、台账和完成依据没有被这个默认配置整体忽略。

`.gdignore` 是提供给 Godot 的扫描边界；它与 `.gitignore` 的作用不同。报告未被 Git 跟踪，也不代表可以删除。当前验证、人工验收或未解决失败仍引用的原件要保留，具体见 [历史与报告](../guides/project-knowledge.md)。

## 留在框架的材料

根维护 `AGENTS.md`、根 README、`framework/commands/`、`framework/tests/`、`framework/review/`、`framework/prompts.json` 和本手册都属于框架。它们不属于空白项目初始化输出，也不构成生成项目后续运行的依赖。
