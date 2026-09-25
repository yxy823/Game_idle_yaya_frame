# 框架文档入口

本目录按用途分成操作手册、场景速查手册和框架维护说明。两本手册不互相引用，本页统一导航；只有现有内容需要时才创建目录。

| 需要什么 | 入口 |
| --- | --- |
| 理解框架、项目对象、配置、Skill 和工具用法 | [操作手册](operation-manual/README.md) |
| 根据当前情况找到具体处理步骤和同名提示词 | [场景速查索引](quick-reference/scenario-index.md) |
| 编写或修改单一场景 | [场景手册编写要求](quick-reference/README.md) |
| 修改框架、同步说明或选择验证 | [框架维护](framework-maintenance/README.md) |

## 目录与分工

```text
framework/docs/
├── README.md                       统一入口
├── operation-manual/               框架、概念、配置、职责与工具专题
│   └── README.md                   专题索引
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

操作手册按对象与契约组织，包括创建器、目录、需求与规划、阶段语义、配置、Skill/Agent、命令与证据、错误含义、专业来源、资源工作台和知识记录。速查手册按“要处理什么事情”分组，将当前状态写入场景名称；每篇只有一个目标和一条同名专用提示词，保留 11 类信息规则，只展示有内容的栏目。

速查路径的三个名称直接来自 [prompts.json](../prompts.json) 的 Project、分类和提示词名称，按文件名核对一对一对应，不通过读取各篇正文推测映射。长期职责判断以 [设计准则](../review/baselines/skill-script-prompt-design.md) 为准。框架维护的具体场景也进入其 Project，维护说明保留规范与工具契约。

## 使用范围

框架面向一位使用者与 Agent 配合开发，不包括多人协作、改动归属处理、worktree 隔离或续接。单目录的暂停、切换、新对话恢复仍支持；按需调研与独立审核不因此取消。素材覆盖准备要求、接收和检查；视觉美术、音乐与音效制作保持待扩展边界。

项目手册中的 docs/、tools/ 等相对生成后的游戏项目根目录；维护文档的框架路径相对本仓库。示例 ID、路径和输出必须换成实际对象，不能当作已经完成的验证或批准。

框架保存创建器、复制材料、手册与完整提示词库；生成项目独立维护自己的文件。本目录不进入 [复制清单](../project-files.json)，也不承担项目升级或自动同步。权威行为由项目自身规则、methodology、Skill 和实际工具定义，手册解释它们，不另建流程。

当前只交付 Markdown。HTML 生成工具保留但不调用，恢复时按两本独立手册适配；具体边界见 [阅读版说明](framework-maintenance/updating-the-blank-project.md#html-阅读版暂缓)。
