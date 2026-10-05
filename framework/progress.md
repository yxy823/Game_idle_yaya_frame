# 框架待办

## 补齐开发环节的覆盖

不考虑资源制作和发布，按下面的顺序补齐。每项开工前先给用户看 Skill 或章节草案，确认后再实施。

1. **调优 Skill 实际试用**：`feel-tuning-godot` 已提交，只做过静态检查。下一步在 Demo（`D:/A_Games/Game_Match_Three`）同步分发改动后，挑一个消除特效和用户实际调一轮，核对 `dev/` 中的工作台入口、A/B 对比和写回是否可行，按结果修正 Skill。
2. **引擎与插件升级**：规则只有一句“版本升级按迁移处理”，没有步骤。计划在 `project-source/methodology/07-engineering-change.md` 加“引擎与插件升级”一节（走 maintenance，串起更新工具路径、`resave_godot_files.gd`、开关编辑器后 git 不变的检查、全量测试和启动冒烟），并新增两个场景：升级 Godot、升级插件。
3. **本地测试导出**：导出核对步骤只写在资源工作台 README。计划在 `project-source/tools/README.md` 加“本地导出检查”一节，`project-verification-godot` 增加导出检查，新增场景“想导出一个包在本机试玩”。不涉及发布配置。
4. **游戏文本**：没有负责原创源语言文本的地方。计划先在 `project-source/methodology/11-specialist-workflows.md` 加“玩家可见文本”一节并配一个场景，反复使用后再考虑升级为 Skill。
5. **关卡与内容数据**：没有负责批量制作具体关卡、波次、物品表和可通关检查的地方。候选是新建 `design-level-content`；开工前要先请用户确认游戏类型和需要覆盖的内容种类。
