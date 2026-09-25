# Yaya Godot 项目起点

这里维护一套供 Windows / PowerShell 使用的 Godot 起始文件、开发方法与工具。使用者与 Agent 在单人项目中协作，让需求、任务、实际验证和交接有清楚的依据。

[文档总入口](framework/docs/README.md) 提供操作手册、场景速查手册的 Markdown 与 HTML 入口，以及框架维护说明。两本手册独立阅读，HTML 由同一构建脚本分别生成并自动检查。手册与完整提示词库不进入新项目，项目 README 保持自身的简短导航。

## 文件放在哪里

```text
Game_idle_yaya_frame/
├── AGENTS.md                  当前维护约定
├── framework/
│   ├── commands/              创建、导出、路径检查与按需回归入口
│   ├── project-files.json     唯一复制映射
│   ├── prompts.json           集中任务提示词
│   ├── docs/                  操作手册、场景速查与维护说明
│   ├── tests/                 维护和外部项目回归夹具
│   └── review/                长期准则、基线与按次报告
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

脚本按 [清单](framework/project-files.json) 预检、复制和重命名，然后建立独立 Git 仓库与本地初始提交。

- **目标目录**：位于框架之外，不存在或为空。
- **路径要求**：完整路径不含中文或空白。
- **失败处理**：保留现场，不自动清理或覆盖。

默认显示名为 New Godot Project，主场景为 main/main.tscn，代码与文档是最小起点。创建器不探测环境、不执行 Godot 或测试、不生成业务需求、不推送远程。默认工具位置不代表可用，配置中也没有“已就绪”状态字段。

工具契约和迁移边界见 [框架与项目](framework/docs/operation-manual/framework-and-project.md)。创建后的具体操作从文档总入口选择场景，正文取自 [prompts.json](framework/prompts.json)，在实际项目目录使用。

## 项目能力与边界

核心材料与专业方法按职责区分：

- **需求与任务**：Product 拥有玩家行为，Feature 拥有本项范围与验证责任，完成证据引用真实测试/人工原件。
- **专业要求与实现**：由对应 Skill 负责。
  - `project-terminology`：维护含义不变的定义。
  - `design-localization-spec`：确定语言要求。
  - `content-localization`：按要求实现。
- **其他专项工作**：共享设计、资源准备、接入、测量和独立审核按需使用。

素材目前覆盖准备要求、接收与检查；美术、音乐和音效制作保留待扩展边界。工作台提供实际资源查看、试听、分析与组合试调，不自动成为游戏设计或验收结论。

同一项目目录内可以暂停、切换和换对话续接，保留真实差异及已有授权。不为多人改动归属、worktree 隔离/续接建立机制。独立调研和审核使用真实可用的专用上下文；角色文件存在不证明加载或隔离成功。

- **项目独立性**：项目独立拥有代码、配置、文档与 Git 历史，不查询框架、不自动升级或同步。
- **advisor 参考**：只携带从集中库导出的精选表达参考，不让项目依赖维护源。
- **脚本边界**：保存和检查实际成果，不设置逐动作 Hook、重复状态或发布资格。

## 维护与验证

按修改范围选择静态、工具或真实引擎验证。仅静态任务不创建项目、不启动 Godot 或测试；实际项目验证在明确指定且材料对应本次修改的外部项目进行，机器配置与业务内容不回灌空白默认值。

修改源材料同时核对受影响说明、读写方、复制映射与夹具，具体见 [维护与同步](framework/docs/framework-maintenance/updating-the-blank-project.md)。维护命令见 [framework/README.md](framework/README.md)，职责准则与审核入口见 [review](framework/review/README.md)。所有结果按实际执行范围报告，旧版本成功、未运行或人工未验收不能写成当前通过。
