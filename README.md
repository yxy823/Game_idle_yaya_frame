# Yaya Godot 项目起点

这里维护一套供 Windows / PowerShell 使用的 Godot 起始文件、开发方法与工具。使用者与 Agent 在单人项目中协作，让需求、任务、实际验证和交接有清楚的依据。

[文档总入口](framework/docs/README.md) 提供操作手册、场景速查手册的 Markdown 与 HTML 入口，以及框架维护说明。两本手册独立阅读，HTML 由同一构建脚本分别生成并自动检查。手册与完整提示词库不进入新项目，项目 README 保持自身的简短导航。

## 文件放在哪里

```text
Game_idle_yaya_frame/
├── AGENTS.md                  当前维护约定
├── framework/
│   ├── commands/              创建器、唯一复制清单与全部命令索引
│   ├── prompt_scenarios/      prompts/ 提示词、scenarios/ 场景与 tools/ 检查
│   ├── docs/                  操作手册、构建器、关系图与框架维护说明
│   └── tests/                 repository/ 维护回归与 external-project/ 外部夹具
└── project-source/
    ├── Project_AGENTS.md      复制为项目 AGENTS.md
    ├── Project_README.md      复制为项目 README.md
    ├── Project_Workflow_Config.json  文档语言和工具路径
    ├── skills/                专项开发、规划、设计与审核方法
    ├── agents/                researcher 与 independent-reviewer 配置
    ├── methodology/           流程契约与模板
    ├── agent-rules/           Godot 工程语义
    ├── tools/                 项目检查、测试、记录、工作台与共享实现
    ├── addons/                随项目提供的插件及补丁
    └── defaults/              Godot、lint、文本与文档默认文件
```

源项目规则使用不同文件名，避免在维护仓库被误当作当前自动指令。维护遵循根 [AGENTS.md](AGENTS.md)，不会在 project-source/ 启动游戏开发流程。

## 创建器

在本目录使用已确认的 Python 3.12+ 和配置了身份的 Git：

```powershell
python -B framework/commands/create_project.py --output D:\Games\MyGodotGame
```

脚本按 [清单](framework/commands/project-files.json) 预检、复制和重命名，然后建立独立 Git 仓库与本地初始提交。

- **目标目录**：位于框架之外，不存在或为空。
- **路径要求**：完整路径不含中文或空白。
- **失败处理**：保留现场，不自动清理或覆盖。

默认显示名为 New Godot Project，主场景为 main/main.tscn，代码与文档是最小起点。创建器不探测环境、不执行 Godot 或测试、不生成业务需求、不推送远程。默认工具位置不代表可用，配置中也没有“已就绪”状态字段。

新项目预设 `docs/gdd/` 用途说明。创建后可以由 `design-gdd` 从想法形成设计，也可以导入并整理已有资料。新建 GDD 默认采用总览与主题文档，已有结构按需维护；开始依赖设计的规划或实现前，当前范围必须有足够明确的真实设计，目录说明和空模板不能代替它。

工具契约和迁移边界见 [框架与项目](framework/docs/operation-manual/框架基础/framework-and-project.md)。创建后的具体操作从文档总入口选择场景，正文取自 [Godot 开发提示词库](framework/prompt_scenarios/prompts/godot-development-prompts.json)，在实际项目目录使用；维护工作使用 [Yaya 框架维护提示词库](framework/prompt_scenarios/prompts/yaya-maintenance-prompts.json)。

## 项目能力与边界

核心材料与专业方法按职责区分：

- **设计与交付**：`design-gdd` 维护游戏设计，`design-balance` 推导并在授权内直接维护 GDD 数值主题；`product-author` 据此组织 Product 交付范围。当前 Product 轮到时才编写文档，并一次拆出完整必要 Feature，完成后再细化下一个 Product。设计采用、实际验证与人工接受分别判断。
- **专业要求与实现**：由对应 Skill 负责。
  - `project-terminology`：维护含义不变的定义。
  - `design-localization-spec`：确定语言要求。
  - `content-localization`：按要求实现。
- **其他专项工作**：共享设计、资源准备、接入、测量和独立审核按需使用。

素材目前覆盖准备要求、接收与检查；美术、音乐和音效制作保留待扩展边界。工作台提供实际资源查看、试听、分析与组合试调，不自动成为游戏设计或验收结论。

同一项目目录内可以暂停、切换和换对话续接，保留真实差异及已有授权；已有明确目标工作目录时，在该目录继续。worktree 按任务需要与授权使用，不是默认前置；不为多人改动归属建立机制。独立调研和审核使用真实可用的专用上下文；角色文件存在不证明加载或隔离成功。

- **项目独立性**：项目独立拥有代码、配置、文档与 Git 历史，不自动升级或同步。
- **advisor 入口**：根据项目现状，通过固定绝对路径读取本机 Godot 开发提示词库，选择适用场景、起草具体指令并判断覆盖缺口；执行仍依据项目自己的规则与有效授权。
- **脚本边界**：保存和检查实际成果，不设置逐动作 Hook、重复状态或发布资格。

## 维护与验证

按修改范围选择静态、工具或真实引擎验证。仅静态任务不创建项目、不启动 Godot 或测试；实际项目验证在明确指定且材料对应本次修改的外部项目进行，机器配置与业务内容不回灌空白默认值。

修改源材料同时核对受影响说明、读写方、复制映射与夹具，具体见 [维护与同步](framework/docs/framework-maintenance/updating-the-blank-project.md)。维护命令见 [命令清单](framework/commands/README.md)，职责准则与审核入口见 [复盘材料](framework/docs/framework-maintenance/review-materials.md)。所有结果按实际执行范围报告，旧版本成功、未运行或人工未验收不能写成当前通过。
