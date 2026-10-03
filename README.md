# Yaya Godot 项目起点

这里维护一套供 Windows / PowerShell 使用的 Godot 起始文件、开发方法与工具。使用者与 Agent 在单人项目中协作，让需求、任务、实际验证和交接有清楚的依据。

[框架入口](framework/README.md) 导航 Godot 项目手册、场景速查手册、关系图和框架维护说明。两本手册独立阅读；手册与完整提示词库不进入新项目，项目 README 保持自身的简短导航。

## 文件放在哪里

```text
Game_idle_yaya_frame/
├── AGENTS.md                  当前维护约定
├── .agents/skills/            框架自用 Skill，不分发
├── framework/                 手册、提示词与场景、关系图、维护文档、创建器与测试，目录说明见 framework/README.md
├── tmp/                       临时文档与当次报告，不纳入 Git
└── project-source/
    ├── Project_AGENTS.md      复制为项目 AGENTS.md
    ├── Project_README.md      复制为项目 README.md
    ├── Project_Workflow_Config.json  文档语言和工具路径
    ├── skills/                专项开发、规划、设计与审核方法
    ├── agents/                researcher 与 independent-reviewer 配置
    ├── methodology/           流程契约与模板
    ├── agent-rules/           Godot 工程语义
    ├── tools/                 项目检查、测试、记录与共享实现
    ├── asset_workbench/       ui/ 工作台、analyzer/ 分析后端与 examples/ 示例
    ├── addons/                随项目提供的插件及补丁
    └── defaults/              Godot、lint、文本与文档默认文件
```

源项目规则使用不同文件名，避免在维护仓库被误当作当前自动指令。维护遵循根 [AGENTS.md](AGENTS.md)，不会在 project-source/ 启动游戏开发流程。

## 创建器

在本目录使用已确认的 Python 3.12+ 和配置了身份的 Git：

```powershell
python -B framework/project-creation/tools/create_project.py --output D:\Games\MyGodotGame
```

创建器按[复制清单](framework/project-creation/project-files.json)复制和重命名，再建立独立 Git 仓库与本地初始提交；它不探测环境、不执行 Godot 或测试、不生成业务需求、不推送远程。目标路径、失败处理等完整契约见[框架、创建器与项目边界](framework/godot-project-manual/foundations/framework-and-project.md#创建器用法)。

新项目只带 `docs/gdd/` 的用途说明，不带任何游戏设计。创建后可以用 `design-gdd` 从想法形成设计，或导入整理已有资料；依赖设计的规划和实现开始前，当前范围必须有真实设计。

具体操作从[场景速查索引](framework/prompt-scenarios/scenarios/scenario-index.md)选择场景；提示词正文分别在 [Godot 开发提示词库](framework/prompt-scenarios/prompts/godot-development-prompts.json)（在游戏项目目录使用）和 [Yaya 框架维护提示词库](framework/prompt-scenarios/prompts/yaya-maintenance-prompts.json)（在本仓库使用）。

## 项目能力与边界

- **开发方法**：生成项目自带一组 Skill，覆盖游戏设计、交付规划、实现、专项资源与本地化、诊断、验证和独立审核；每个 Skill 的职责见 Godot 项目手册的 [Skill 职责速查](framework/godot-project-manual/methods-and-tools/skills-and-agents.md#skill-职责速查)。
- **工作台**：提供实际资源的查看、试听、分析与组合试调，结果不自动成为设计或验收结论。
- **项目独立性**：项目独立拥有代码、配置、文档与 Git 历史，不自动升级或同步。
- **advisor**：根据项目现状，从本机 Godot 开发提示词库选择适用场景并起草具体指令；执行仍依据项目自己的规则与有效授权。
- **适用范围**：单人使用、任务续接、worktree 和素材制作的边界见[使用范围](framework/README.md#使用范围)。

## 维护

维护约定见 [AGENTS.md](AGENTS.md)，`framework/` 的目录与命令索引见 [框架入口](framework/README.md)，修改后要同步什么、选择哪种验证见 [框架维护](framework/maintenance/README.md)。
