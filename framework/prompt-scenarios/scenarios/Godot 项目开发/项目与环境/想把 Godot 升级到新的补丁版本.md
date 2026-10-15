# 想把 Godot 升级到新的补丁版本

[返回场景索引](../../scenario-index.md) · [执行步骤](#执行步骤) · [完成标准](#完成状态与验证标准)

## 触发场景与使用时机

Godot 发布了同一次版本内的修复版，例如项目在用 4.7.1，4.7.2 修掉了你遇到的导入或崩溃问题，想把项目换到新版本，并确认测试、启动和导出结果与升级前一致。

需要的材料：

- **目标版本号**：例如 `4.7.2`，必须提供；Agent 不自行挑选版本。
- **新版本的安装位置**（可空）：已经装好时给出可执行文件路径；还没装时，Agent 在 S3 停下等你安装。

由你完成的准备：下载并安装新版本的 Godot 和同版本的导出模板。新版本装在单独的目录，不覆盖旧版本，升级失败时才能改回去。

## 前置条件与适用范围

只处理 4.7.x 之内的补丁版本。次版本或主版本升级（例如 4.7 到 4.8）不在本场景：项目的规则、环境检查和测试运行器都按 4.7 编写，要等框架完成迁移后，用[已经选定新框架，检查适用后在当前项目替换](<已经选定新框架，检查适用后在当前项目替换.md>)同步，依据见[项目能自己升级的范围](<../../../../../project-source/methodology/07-engineering-change.md#项目能自己升级的范围>)。

只是 Godot 的安装位置变了、版本不变时，用[工具位置或版本变了，需要更新项目环境](<工具位置或版本变了，需要更新项目环境.md>)。

升级开始时工作区要干净；有未提交的改动，先提交或处理完。

## 执行步骤

使用[预设提示词库](<../../../prompts/godot-development-prompts.json>)中的“Godot 项目开发 → 项目与环境 → 想把 Godot 升级到新的补丁版本”。填入上述材料。本页先由当前 Agent 使用 [$engineering-change-plan](<../../../../../project-source/skills/engineering-change-plan/SKILL.md>) 建立维护 Feature，再用 [$feature-execute](<../../../../../project-source/skills/feature-execute/SKILL.md>) 实施；具体做法按 07 的[升级 Godot 补丁版本](<../../../../../project-source/methodology/07-engineering-change.md#升级-godot-补丁版本>)逐步执行，每步的检查通过后再继续。

**S1｜建立升级的维护 Feature**

当前 Agent 用 engineering-change-plan 的 maintenance 模式，按[维护 Feature 契约](<../../../../../project-source/methodology/07-engineering-change.md#维护-feature-契约>)写明旧版本和目标版本、要保持成立的行为（全量测试、主场景启动，项目会导出时还有本地导出），以及回滚方式：保留旧可执行文件，把配置改回旧路径并新建提交。展示方案，取得你的批准后写入；当前请求已明确批准具体方案时沿用。

**S2｜记录基线并核对版本说明**

对应 07 的第 1、2 步。当前 Agent 用旧版本运行全量测试并保留结果（在项目根目录，`$projectPython` 的取法见[调用](<../../../../../project-source/tools/README.md#调用>)，`F0XX` 换成 S1 建立的 Feature）：

```powershell
& $projectPython -B yaya/tools/testing/run-gdunit-tests.py --feature F0XX --scope full --phase baseline --continue
$LASTEXITCODE
```

已有的失败先报告，不算到升级头上。然后阅读从旧版本到目标版本之间每个补丁版本的官方更新说明，列出影响项目实际用到的 API、导入或编辑器行为的条目；没有相关条目也写明“已核对，无相关变化”。

**S3｜安装新版本并切换配置**

对应 07 的第 3 步。你安装新版本和导出模板后告诉 Agent 路径；当前 Agent 用 `project-environment` 把 `docs/methodology-config.json` 中的 `engine_executable` 改为新路径，并运行 `yaya/tools/checks/check-project-environment.py --require-ready`，确认观察到的版本就是目标版本。

**S4｜扫描导入并确认稳定**

对应 07 的第 4、5 步。当前 Agent 在项目根目录用新版本运行两次编辑器扫描（`$projectGodot` 的取法见[首次 Godot 扫描](<../../../../../project-source/tools/README.md#首次-godot-扫描>)）：

```powershell
& $projectGodot --headless --editor --path . --quit | Out-Host
$LASTEXITCODE
git status --short
```

第一次之后，只有 `.import`、新增 `.uid` 这类导入元数据时单独提交，提交说明写“Godot <新版本> 重新导入”；出现其他变化时先查原因。第二次与运行前相比没有新增或改写的文件；S3 的配置修改要到 S5 才提交，所以不要求整个工作区干净。扫描不会重新保存已有的 `.tscn`、`.tres`，不需要批量重存。

**S5｜完整验证并结束**

对应 07 的第 6、7 步。当前 Agent 对全部脚本做解析和 lint，运行全量测试（去掉 `--phase baseline`）并与 S2 的基线对比，对主场景做[启动场景冒烟检查](<../../../../../project-source/tools/README.md#启动场景冒烟检查>)；项目会导出时，再做[本地导出检查](<../../../../../project-source/tools/README.md#本地导出检查>)。全部通过后提交配置修改，在 Feature notes 写明新旧版本和保留的旧可执行文件位置，按 feature-execute 的完成条件交付。

## 步骤产出与状态变化

| 步骤 | 可继续的依据 |
| --- | --- |
| S1 | 维护 Feature（新旧版本、要保持的行为、回滚方式）已获批写入，`check-feature-list` PASS |
| S2 | 旧版本的全量测试结果和已有失败；版本说明的核对清单，或“已核对，无相关变化” |
| S3 | 配置中的 Godot 路径已改为新版本；`--require-ready` 的实际输出和观察到的版本 |
| S4 | 扫描生成的导入元数据已单独提交或已查明原因；第二次扫描没有新的文件变化 |
| S5 | 解析、lint、全量测试与基线的对比、冒烟检查（和本地导出检查）的实际结果；配置提交的哈希；Feature notes 中的版本记录 |

## 资源与文件影响

- `docs/methodology-config.json` 中的 `engine_executable`，以及 `reports/initialization.md` 的追加记录。
- 编辑器扫描生成的 `.uid`、`.import` 等导入元数据，单独成一个提交。
- 维护 Feature 记录和测试运行报告。
- 旧版本的可执行文件保留在原位置，不删除。

## 阻塞、异常与范围变化

- **新版本还没装**：S3 停下，说明需要安装的可执行文件和导出模板版本，等你装好后继续。
- **扫描出现导入元数据以外的变化，或验证结果比基线差**：先查原因，属于项目代码需要适配新版本的，在本 Feature 内修复；无法解决时把配置改回旧版本路径并新建一个提交，不改写历史，Feature 保持未完成。
- **目标版本实际是次版本或主版本**：不开始升级，改走框架迁移。

## 完成状态与验证标准

项目配置指向目标版本，第二次扫描没有新的文件变化，解析、lint、全量测试、主场景启动（和本地导出）的结果不差于升级前的基线，维护 Feature 按完成条件交付，旧可执行文件位置已记录。

## 流程关联与衔接关系

依据：[引擎与插件升级](<../../../../../project-source/methodology/07-engineering-change.md#引擎与插件升级>)、[维护 Feature 契约](<../../../../../project-source/methodology/07-engineering-change.md#维护-feature-契约>)、[工具配置](<../../../../../project-source/methodology/06-project-environment.md#工具配置>)。
