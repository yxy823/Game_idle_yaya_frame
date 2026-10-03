# Resource 复制与运行时状态

复制 Resource 资源图时，明确决定哪些共享引用、哪些复制，以及归谁所有。

## 复制

- **[必须]** 使用 `duplicate(false)`、`duplicate(true)` 或 `duplicate_deep(mode)` 时，明确决定顶层 Resource、容器、内部子资源和外部 Resource 中，哪些共享引用、哪些复制：
  - `duplicate(false)` 返回一个新的顶层 Resource，但嵌套的 Array、Dictionary、PackedArray 和 Resource 值仍是共享引用；
  - `duplicate(true)` 递归复制嵌套容器，但只复制本地（内部）Resource；
  - `duplicate_deep(mode)` 通过 `DEEP_DUPLICATE_NONE`、`DEEP_DUPLICATE_INTERNAL` 或 `DEEP_DUPLICATE_ALL` 选择子资源的复制方式。
- **[必须]** 深度复制会感知资源图。源资源图中同一个 Resource 被引用多次时，确认副本保留了预期的共享引用，而不是生成了多个独立副本。
- **[必须]** 不把某种通用的深度复制模式当作一劳永逸的“保证安全”操作。
- **[必须]** 身份重要时，测试复制结果中的共享与复制关系，而不只比较值。

## 持久化资源图

- **[优先]** 持久化的 Resource 资源图默认保持接近有向无环图（DAG）。避免子资源序列化地反向引用其所属父资源而形成循环。
- **[优先]** 对于循环或关联本身就是业务数据的图结构领域，使用稳定 ID 加解析器，而不是意外形成的序列化所有权循环。
- **[必须]** 所有权或生命周期与定义数据不同的运行时可变状态，要单独建模，不修改共享的定义。
- **[必须]** 承诺会发出 `changed` 通知的可变 Resource 契约，在可观察的状态变化时调用 `emit_changed()`。
