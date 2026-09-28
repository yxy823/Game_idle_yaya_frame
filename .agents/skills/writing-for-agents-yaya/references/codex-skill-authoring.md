# Codex Skill 编写参考

编写或审核 Skill 的发现入口、元数据和资源组织时使用本页。格式行为以当前 Codex 官方文档和本机可用的 `skill-creator` 为依据；不要求每次改字都重新联网核对，字段或产品行为有疑问时再查证。

## 入口与调用策略

`SKILL.md` 的 YAML frontmatter 必须保留 `name` 和 `description`。description 说明核心职责和实际触发任务，必要时标明容易混淆的排除项；界面短描述不能代替它。

调用策略放在 `agents/openai.yaml` 的 `policy` 下：

```yaml
policy:
  allow_implicit_invocation: true
```

`true` 允许 Codex 根据任务匹配隐式选择，且是默认值；`false` 关闭隐式选择，仍可显式调用。新建时保持默认，只有用户明确要求手动调用时才改为 `false`；维护现有 Skill 时保留未获准调整的策略。调用策略控制选择方式，不授予写文件、运行工具或其他副作用的权限。

保留有效的 `name`、`description` 和正文，不从关闭隐式选择推导出“文件不能被引用”“其他 Skill 不能读取其参考”或“没有任何上下文成本”。资料引用、实际加载和隐式选择是不同机制。

`interface.display_name` 和 `interface.short_description` 用于界面展示。只添加实际需要的字段；如果已有工具依赖或其他有效配置，局部修改时保留无关值。检查支持范围时依据 Codex 文档，不套用其他产品的字段。

## 资源组织

入口写清共同目的、必要边界和条件路由；较长且仅供某些分支使用的内容放入 `references/`，入口注明读取条件。简单 Skill 可直接写在一个文件中，不为形式完整增加空目录、脚本或路由 Skill。

与另一份参考共享内容前，确认真实归属和部署范围：框架自用包可以指向本仓库权威规范；分发给 Godot 项目的包只能依赖目标项目拥有的材料。普通共享参考不必包装成可调用 Skill，也不需要靠手动调用策略决定能否共享文件。

新增脚本应解决重复、确定性的实际工作；仅为监督 Agent 是否依次执行步骤不成立。职责拆分沿用框架设计准则，不能把调用词、文件数量或引用层数单独当作拆分理由。

## 检查范围

- 修改格式或元数据后，运行当前可用的 `skill-creator` 格式检查，核对名称、目录与 YAML；格式通过不证明实际触发效果。
- 新增或实质调整职责时，比较应触发与不应触发的任务，按需独立试用代表性场景。手动向试用者提供 Skill 只验证已加载后的行为，不证明客户端能自动发现它。
- 检查包内引用及目标环境的外部引用；本机路径、缓存路径和测试环境事实不能变成分发材料的固定运行依赖。

## 产品依据

- [OpenAI：Build skills](https://learn.chatgpt.com/docs/build-skills)：文件结构、发现范围、显式与隐式调用、`agents/openai.yaml`。
- [OpenAI：Astra 指令设计建议](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra)：触发边界、按需阅读、流程粒度和持续完成；保留当前框架真实需要的权限、验证与验收约束。
