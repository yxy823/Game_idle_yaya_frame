# Yaya Godot 项目起点

这里维护一套供 Windows / PowerShell 使用的 Godot 起始文件、开发方法与工具。使用者与 Agent 在单人项目中协作，让需求、任务、实际验证和交接有清楚的依据。

[文档总入口](framework/docs/README.md) 提供操作手册、场景速查手册的 Markdown 入口，以及框架维护说明。两本手册独立阅读。手册与完整提示词库不进入新项目，项目 README 保持自身的简短导航。

## 文件放在哪里

```text
Game_idle_yaya_frame/
├── AGENTS.md                  当前维护约定
├── .agents/skills/            框架自用 Skill，不分发
├── framework/                 维护材料，目录说明见 framework/README.md
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
python -B framework/commands/project/create_project.py --output D:\Games\MyGodotGame
```

创建器按[复制清单](framework/commands/project/project-files.json)复制和重命名，再建立独立 Git 仓库与本地初始提交；它不探测环境、不执行 Godot 或测试、不生成业务需求、不推送远程。目标路径、失败处理等完整契约见[框架、创建器与项目边界](framework/docs/operation-manual/foundations/framework-and-project.md#创建器用法)。

新项目预设 `docs/gdd/` 用途说明。创建后可以由 `design-gdd` 从想法形成设计，也可以导入并整理已有资料。新建 GDD 默认采用总览与主题文档，已有结构按需维护；开始依赖设计的规划或实现前，当前范围必须有足够明确的真实设计，目录说明和空模板不能代替它。

创建后的具体操作从文档总入口选择场景，正文取自 [Godot 开发提示词库](framework/prompt-scenarios/prompts/godot-development-prompts.json)，在实际项目目录使用；维护工作使用 [Yaya 框架维护提示词库](framework/prompt-scenarios/prompts/yaya-maintenance-prompts.json)。

## 项目能力与边界

核心材料与专业方法按职责区分：

- **设计与交付**：`design-gdd` 维护游戏设计，`design-balance` 推导并在授权内直接维护 GDD 数值主题；`product-author` 据此组织 Product 交付范围。当前 Product 轮到时才编写文档，并一次拆出完整必要 Feature，完成后再细化下一个 Product。设计采用、实际验证与人工接受分别判断。
- **专业要求与实现**：由对应 Skill 负责。
  - `project-terminology`：维护含义不变的定义。
  - `design-localization-spec`：确定语言要求。
  - `content-localization`：按要求实现。
- **其他专项工作**：共享设计、资源准备、接入、测量和独立审核按需使用。

工作台提供实际资源查看、试听、分析与组合试调，不自动成为游戏设计或验收结论。

单人使用、任务续接、worktree 和素材制作的适用范围见[使用范围](framework/docs/README.md#使用范围)。独立调研和审核的角色与独立性要求见操作手册的 [Skill、Agent 与提示词](framework/docs/operation-manual/methods-and-tools/skills-and-agents.md)。

- **项目独立性**：项目独立拥有代码、配置、文档与 Git 历史，不自动升级或同步。
- **advisor 入口**：根据项目现状，通过固定绝对路径读取本机 Godot 开发提示词库，选择适用场景、起草具体指令并判断覆盖缺口；执行仍依据项目自己的规则与有效授权。
- **脚本边界**：保存和检查实际成果，不设置逐动作 Hook、重复状态或发布资格。

## 维护与验证

按修改范围选择静态、工具或真实引擎验证。仅静态任务不创建项目、不启动 Godot 或测试；实际项目验证在明确指定且材料对应本次修改的外部项目进行，机器配置与业务内容不回灌空白默认值。

修改源材料同时核对受影响说明、读写方、复制映射与夹具，具体见 [维护与同步](framework/docs/framework-maintenance/maintenance-and-sync.md)。维护目录见 [框架维护入口](framework/README.md)，命令见 [维护命令](framework/commands/README.md)，职责准则与审核入口见 [职责设计准则](framework/docs/framework-maintenance/responsibility-design-guidelines.md)。
