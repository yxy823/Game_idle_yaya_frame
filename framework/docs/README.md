# 框架文档入口

本目录按用途分成操作手册、场景速查手册和框架维护说明。两本手册不互相引用，本页统一导航；只有现有内容需要时才创建目录。

| 需要什么 | Markdown 入口 | HTML 阅读版 |
| --- | --- | --- |
| 理解框架、项目对象、配置、Skill 和工具用法 | [操作手册](operation-manual/README.md) | [打开操作手册](operation-manual/operation-handbook.html) |
| 根据当前情况找到具体处理步骤和同名提示词 | [场景速查索引](quick-reference/scenario-index.md) | [打开场景速查手册](quick-reference/quick-reference-handbook.html) |
| 查看游戏项目开发场景之间的衔接关系 | [场景图与 JSON 格式](workflow-maps/README.md) | [打开场景图](workflow-maps/game-development-workflow.readable.json) |
| 编写或修改单一场景 | [场景手册编写要求](quick-reference/README.md) | 收录在场景速查手册末尾 |
| 修改框架、同步说明或选择验证 | [框架维护](framework-maintenance/README.md) | — |
| 确认框架与项目公共术语的含义和统一写法 | [术语](terminology.md) | 两本阅读版共用同一正文 |

## 目录与分工

```text
framework/docs/
├── README.md                       统一入口
├── terminology.md                  两册共用的框架与工程术语
├── workflow-maps/                  复用提示场景名称的关系图与格式说明
├── operation-manual/               框架、概念、配置、职责与工具专题
│   ├── README.md                   专题索引
│   ├── 框架基础/                   创建器、目录与配置
│   ├── 需求与任务/                 需求、规划与阶段
│   ├── 方法与工具/                 Skill、命令与证据
│   └── 专业工作与记录/             专业来源、工作台与知识
├── quick-reference/
│   ├── README.md                   编写要求
│   ├── scenario-index.md           场景索引
│   ├── Yaya 框架维护/<分类>/<提示词名称>.md
│   └── Godot 项目开发/<分类>/<提示词名称>.md
└── framework-maintenance/
    ├── README.md                   维护说明索引
    ├── updating-the-blank-project.md
    └── validating-framework.md
```

两本手册各自的组织方式如下：

- **操作手册**：按对象与契约组织。
  - 框架基础：创建器、目录与配置。
  - 需求与任务：需求与规划、阶段语义。
  - 方法与工具：Skill/Agent、命令与证据、错误含义。
  - 专业工作与记录：专业来源、资源工作台、知识记录。
- **场景速查手册**：按“要处理什么事情”分组。
  - 场景名称：写清当前状态，方便从目录选择。
  - 单篇范围：一个目标，对应一条同名专用提示词。
  - 信息栏目：保留 11 类分类规则，只展示有内容的栏目。

速查路径直接使用 [prompts.json](../prompts.json) 中的三个名称：

- Project：所属项目文件夹。
- 分类：该项目下的子文件夹。
- 提示词名称：具体场景的文件名。

按文件名核对一对一对应，不通过读取各篇正文推测映射。长期职责判断以 [设计准则](../review/baselines/skill-script-prompt-design.md) 为准。框架维护的具体场景也进入其 Project，维护说明保留规范与工具契约。

## 使用范围

框架的适用范围按以下几类区分：

- **使用方式**：一位使用者与 Agent 配合开发，不包括多人协作或改动归属处理；worktree 使用按具体任务需要与授权判断，不作为通用前置。
- **任务续接**：支持同一目录中的暂停、切换与新对话恢复；按需调研与独立审核仍可使用。
- **素材工作**：覆盖准备要求、接收和检查；视觉美术、音乐与音效制作保持待扩展边界。

项目手册中的 docs/、tools/ 等相对生成后的游戏项目根目录；维护文档的框架路径相对本仓库。示例 ID、路径和输出必须换成实际对象，不能当作已经完成的验证或批准。

框架保存创建器、复制材料、手册与完整提示词库；生成项目独立维护自己的文件。本目录不进入 [复制清单](../project-files.json)，也不承担项目升级或自动同步。权威行为由项目自身规则、methodology、Skill 和实际工具定义，手册解释它们，不另建流程。

Markdown 是正文来源，HTML 由一条[构建命令](../README.md#构建-html-阅读版)分别生成，并自动检查链接、锚点和产物结构；日常重建不要求手动复审未改正文。具体边界见 [阅读版说明](framework-maintenance/updating-the-blank-project.md#html-阅读版构建)。
