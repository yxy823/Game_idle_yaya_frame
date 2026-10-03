# 数据验证

```text
Source Discovery and Integrity
-> Syntax and Format
-> Schema and Structure
-> Field Type and Value
-> Identity and Reference
-> Graph and Domain Semantics
-> Normalization
-> Canonical Generation
-> Determinism and Staleness
-> Canonical Reload
-> Godot Runtime Integration
-> Target and Export Validation
```

上面的验证层依次为：源发现与完整性 → 语法与格式 → schema 与结构 → 字段类型与取值 → 身份与引用 → 图与领域语义 → 规范化 → 规范生成 → 确定性与过期检查 → 规范重新加载 → Godot 运行时集成 → 目标与导出验证。

- **[必须]** 低层的 PASS 永远不能证明高层通过。
- **[必须]** 所有必需的验证层都成功后，生产数据才能进入玩法。
- **[必须]** 未知的生产字段导致失败，除非明确的扩展 schema 允许。
- **[必须]** 校验 ID、别名、必填与可选引用、成环策略、跨记录不变量、单位、范围、枚举取值域和非有限数值。
- **[必须]** 通过生产解析器和 schema 重新加载规范输出；只在序列化前校验内存中的模型不够。
- **[必须]** 用目标 Godot 和一个有代表性的带类型使用方验证运行时集成。
- **[必须]** 对于运行时读取的原始文件，验证它们在实际导出的构建或 PCK 中可用，并验证生产加载和使用方的行为。
- **[必须]** 修改迁移时，让早期版本的真实夹具完整通过当前的整套验证。

生成器的确定性和严重级别的处理，分别在 `generation-and-derived-data.md` 和 `data-lifecycle-and-authority.md` 中规定。
