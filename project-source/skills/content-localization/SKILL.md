---
name: content-localization
description: "在已授权的 Godot 任务中，按已批准的本地化规范实现翻译资源和语言支持。用于运行时翻译和语言区域相关的工作。不用于设计语言覆盖或翻译惯例（design-localization-spec），也不用于独立审核（review-localization）。"
---

# 本地化实现

按 `yaya/methodology/11-specialist-workflows.md` 执行。阅读已批准的 `docs/localization/localization-spec.md`，包括其中的 **术语译名** 章节（methodology 11 的 **本地化术语译名**）。同时阅读本次涉及的领域定义、外部提供的译文和当前实现。

目标语言、源语言和计划覆盖范围，以这些已确认的决定为准。`document_language` 只决定项目文档的语言，不决定这些内容。

语言要求缺失或发生变化时，先回到 `design-localization-spec` 处理，再做依赖它的实现。保留已批准的领域含义和游戏规则。未确认的译文仍是草稿；实现授权不能裁定有争议的用词或语言体验。

## 实现

在所属的已授权 Feature 或限定范围的实验中工作。没有这样的 Feature 或实验时，按 `yaya/methodology/00-overview.md` 的 **任务路由表** 说明需要的入口，不直接修改运行时文件。

- 默认使用 Godot 内置的 CSV 翻译：翻译表放在 `game/localization/`，第一列是键，之后每种语言一列（列名为语言区域代码，例如 `zh_CN`），按 Godot 的翻译导入器导入，生成的翻译文件登记到项目设置，见[本地化设置](../../../yaya/agent-rules/40-project-config/subsystem-settings.md#本地化)。项目已经采用其他机制时沿用它；改换格式或机制之前，先检查当前 Godot 版本的翻译 API。
- 键名格式为 `<区域>.<对象>.<用途>`：全部小写 ASCII，每段用下划线连接单词。区域是界面或调试对象的键，与 `game/<对象>/` 一致，多处共用的文字用 `common`；对象是界面上的元素或游戏实体；用途说明这段文字的作用，例如 `label`、`button`、`tooltip`、`title`、`desc`。例如 `main.producer_row.buy_button`、`offline_summary.dialog.title`、`common.confirm.button`。
- 键表示文字的用途，改措辞不改键；键被代码引用后保持不变。含数值或名称的句子用整句加命名占位符（例如 `{amount}`），在代码里填入，不拼接句子片段。场景和数据文件的显示字段只存键。
- 覆盖运行时生成的文本，以及本次范围内的错误状态和空状态。
- 完整的译文句子保存在运行时资源中，并使用已批准的术语译名。不要另建一份保存句子或对话的 Markdown 目录。
- 字符与字体覆盖、回退、长文本、数字和日期、输入提示标签以及从右到左排版（RTL），只针对需要的语言检查。

## 验证与返回

在实际显示条件下，验证文本提取或导入，以及有代表性的语言切换。写明覆盖了哪些语言和界面。机械上的完整不能证明用词自然或符合文化习惯。重大的歧义交给来源的负责方处理。

在最终验证之前，完成实现和译文的修改；需要修改规范时，由规范的负责方完成。返回修改过的来源、资源和缺口。用户要求独立审核时，由另一个 `review-localization` 实例进行；本 Skill 不提供语言或体验方面的人工验收。

返回调用方；Skill 返回不会结束它所在的已授权任务（methodology 03 的 **授权与续接**）。
