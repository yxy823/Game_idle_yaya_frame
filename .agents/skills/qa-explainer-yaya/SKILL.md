---
name: qa-explainer-yaya
description: 框架讨论中用户的追问暴露出理解缺口、问到以后还会用到的框架做法或游戏开发专业知识时使用，用户要求“用图解释”“生成 HTML 解释”时也使用：在回复结尾提议记入 Q&A，用户同意后把问答写进 `framework/qa/` 的主题文件，生成带图的 HTML 页面，回复结论和页面链接。不用于只关于当次对话的问题，不用于需要用户做决定的讨论，也不修改被解释的规则或实现。
---

# Yaya 图解问答

把框架讨论中问过、以后还会用到的问题保存为 `framework/qa/` 下的问答，并生成一页 HTML 方便阅读。本 Skill 只供框架仓库使用，不随游戏项目分发。

## 两份规则分别管什么

- **什么时候添加、按问题类型写多少**：以 [Q&A](../../../framework/qa/README.md) 的说明为准，它是框架问答的唯一正文。
- **主题文件格式、组件选择、生成命令和页面意见的处理**：沿用随项目分发的 [qa-explainer-godot](../../../project-source/skills/qa-explainer-godot/SKILL.md)，渲染脚本也只保存在那里一份。读它时把 `docs/qa/` 换成 `framework/qa/`，把项目的 `document_language` 换成中文，脚本路径换成 `project-source/skills/qa-explainer-godot/scripts/`；其中“何时添加”和“文件与位置”两节以 Q&A 说明为准。

## 步骤

1. 按 Q&A 说明判断是否提议、放进哪个主题；用户同意后再往下做。
2. 按 qa-explainer-godot 的格式和 [technical-documentation-writing-yaya](../technical-documentation-writing-yaya/SKILL.md) 的写作要求写或改主题文件。再对改过的文件运行措辞检查和术语检查，按输出改写：

   ```powershell
   python -B project-source/tools/checks/check-wording.py framework/qa/<主题>.md
   python -B project-source/tools/checks/check-terminology.py --terms framework/terminology.md framework/qa/<主题>.md
   ```

3. 在仓库根目录生成全部主题页和首页 `framework/qa/index.html`；用户自己修改了主题文件后，也运行同一条命令：

   ```powershell
   node project-source/skills/qa-explainer-godot/scripts/qa-build.mjs framework/qa
   ```

4. 按根 `AGENTS.md` 的本地提交规则提交 `.md`；`.html` 已被根 `.gitignore` 忽略，不提交。
5. 回复核心结论、新增或修改了哪几条问答，以及 `file:///` 页面链接。
