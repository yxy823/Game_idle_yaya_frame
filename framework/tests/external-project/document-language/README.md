# 文档语言冒烟场景

[测试与夹具](../../README.md#按需检查) · [验证范围](../../../maintenance/validation/validation-scope.md)

修改生成项目的[文档语言约定](../../../../project-source/methodology/05-document-language.md)，或者想把 `en`、`zh-CN` 以外的语言列为已验证时，用下面三个场景在外部项目中实际走一遍。它们检查两件事：对话语言不会被当成项目设置保存；机器协议（键名、枚举、ID、路径）不会被翻译。

这些场景不随新项目分发，也不需要每次维护都运行。目前已验证的文档语言只有 `en` 和 `zh-CN`；其他 BCP 47 标签按尽力支持处理，不能因为这里的场景写成已验证。

## 运行方法

1. 用当前创建器生成一个可丢弃的外部项目，并获得在其中运行的授权。
2. 按场景的「准备」设置语言。
3. 在开始 Product 或 Feature 工作前，往 `docs/gdd/` 放一份实质性的 GDD。场景不会替你创建或翻译 GDD。
4. 记录 Agent 提出的问题、最终保存的语言、生成的文件和检查输出。

每条「预期结果」都满足、「禁止行为」都没有出现，场景才算通过。

## 协议对照夹具

下面两份 JSON 描述同一个 pending Feature，只列出受语言影响的字段，不是可运行的完整配置。环境检查使用项目的实际配置。自然语言的值随 `document_language` 变化；键名、枚举、ID、依赖、路径、时间戳和占位前缀不变。

<!-- fixture: en -->
```json
{
  "config": {
    "document_language": "en"
  },
  "feature": {
    "id": "F900",
    "title": "Add profile export",
    "status": "pending",
    "depends_on": ["F899"],
    "estimated_scope": "small",
    "completed_at": null
  },
  "detail": {
    "id": "F900",
    "description": "Let the user export a profile as JSON.",
    "affected_components": ["profile_export"],
    "acceptance_criteria": [{"id": "AC01", "text": "Selecting Export downloads one JSON file.", "verification": {"automated_tests": [], "manual_checks": []}}],
    "verification": {"acceptance_mode": null, "regression_tests": [], "manual_regression": null},
    "source": "product/01-profile.md#acceptance-criteria",
    "notes": "Keep the existing profile schema."
  },
  "protocol": {
    "detail_path": "docs/features/F900.json",
    "placeholder": "_placeholder_profile.json"
  }
}
```

<!-- fixture: zh-CN -->
```json
{
  "config": {
    "document_language": "zh-CN"
  },
  "feature": {
    "id": "F900",
    "title": "增加用户资料导出",
    "status": "pending",
    "depends_on": ["F899"],
    "estimated_scope": "small",
    "completed_at": null
  },
  "detail": {
    "id": "F900",
    "description": "允许用户把资料导出为 JSON。",
    "affected_components": ["profile_export"],
    "acceptance_criteria": [{"id": "AC01", "text": "点击导出后下载一个 JSON 文件。", "verification": {"automated_tests": [], "manual_checks": []}}],
    "verification": {"acceptance_mode": null, "regression_tests": [], "manual_regression": null},
    "source": "product/01-profile.md#acceptance-criteria",
    "notes": "保持现有用户资料 schema。"
  },
  "protocol": {
    "detail_path": "docs/features/F900.json",
    "placeholder": "_placeholder_profile.json"
  }
}
```

## DL-01 英文对话，英文文档

**准备**：项目只有创建时的初始说明。用英文和 Agent 交流，明确要求项目文档使用英文。Agent 保存 `en` 后，再放入准备好的英文 GDD。这一步不涉及迁移已有文档。

**预期结果**：

- Agent 用英文交流，不再追问一次确认。
- 生成 Product 或 Feature 之前，`document_language` 已保存为 `en`。
- Product 的标题和正文、Feature 的标题和详情、Progress 条目都是自然的英文。
- 生成的协议结构与上面的英文夹具一致。

**禁止行为**：根据国家、IP、时区或系统区域推断文档语言；翻译 JSON 键名、枚举、ID、路径、占位名或证据。

## DL-02 中文对话，简体中文文档

**准备**：保留创建时的 `zh-CN`，不另外确认语言，用简体中文和 Agent 交流。

**预期结果**：

- Agent 用简体中文交流，直接使用 `zh-CN`，不要求确认。
- Product、Feature 和 Progress 的内容是自然的简体中文。
- 生成的协议结构与中文夹具一致；和英文夹具相比，只有 `document_language` 和人读文字不同。

**禁止行为**：把对话语言另存为第二个语言设置；为方法论、Skill、提示词、模板、项目规则或工具建立本地化副本。

## DL-03 中文对话，英文文档

**准备**：项目配置为 `"document_language": "en"`。用简体中文和 Agent 交流，要求修改一项 Product。

**预期结果**：

- Agent 的提问、报告和人工验证说明使用简体中文。
- 新写入的 Product、Feature、修订记录、Progress 和交接内容使用自然的英文。
- `document_language` 仍为 `en`；协议字段与 DL-01 完全相同。

**禁止行为**：因为对话换成中文就把 `document_language` 改成 `zh-CN`；把中文对话内容写进项目文档。界面标签、专有名词、代码示例和外部引用的原文除外。

## 进度记录的补充检查

三个场景都要顺带确认：

- `docs/progress.md` 只保存当前状态、阻塞、待决定项、下一步和历史入口；归档只在和任务相关时读取。
- 完成的 Feature 或获准的批次把执行历史移到 `docs/progress/`，保留原文和证据链接。
- 语言迁移只改用户明确批准的当前内容，不翻译旧归档，也不把归档正文复制进 Feature notes。
- 单纯归档不会让业务测试的内容指纹失效；修改 AC 或验证映射仍会让对应证据失效。

## 记录结果

逐项写明实际执行了哪些检查。下面的清单本身不是执行证据：

1. 本页两份 JSON 夹具都能解析，机器字段完全相同。
2. 配置保持中文默认值且不追问确认；明确的语言要求会生效；已有内容不会被悄悄翻译。
3. `product-author`、`feature-plan` 等实际写入文档的 Skill，在两种语言下写出的协议字段相同，人读摘要是自然语言。
4. 测试登记表的协议字段在两种语言下保持不变。
5. 仓库回归、工具夹具和 `git diff --check` 通过，验证命令字符串没有改动。
