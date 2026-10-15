---
name: asset-library-search
description: "在用户的本地游戏资源库中查找、推荐或选择美术、音乐、音效、字体等素材时使用。按资源库自己的检索 Skill 执行：先查项目级索引列候选，查看内容逐项取得许可，查看后保存调研结果。不用于接入素材，改用 content-asset-integration；不用于制作素材。"
---

# 在本地资源库中查找素材

完整阅读并照做资源库的检索 Skill：`D:/A_Games/Game_Assets_Library/.agents/skills/game-asset-library-search/SKILL.md`。资源库根目录是 `D:/A_Games/Game_Assets_Library`，库根 `AGENTS.md` 的规则同样适用。读不到这两个文件时停下报告，不凭记忆检索，也不扫描磁盘找素材。

本项目只补充两点：

- 检索词来自当前任务已确定的规格，例如所属表现、界面或 Sound Bible 中的资源章节；规格还没定时先说明缺口，按[资源需求与交接](../../../yaya/methodology/11-specialist-workflows.md#资源需求与交接)补规格，不用候选表代替规格。
- 用户选定素材后，复制到资源库外的工作目录，再按需要接入：比较候选用 [debug-console-godot](../debug-console-godot/SKILL.md) 的候选，直接接入用 [content-asset-integration](../content-asset-integration/SKILL.md)。来源写资源库中的项目路径，许可写资源库 `research.md` 里已核验的结论，没有核验时按缺口处理。
