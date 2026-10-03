# 场景验证

```text
format and dependency parse
-> UID and resource consistency
-> NodePath and reference resolution
-> attached script compilation and base-type compatibility
-> dynamic instantiate, _enter_tree and _ready where relevant
-> affected integration and runtime behavior
```

- **[必须]** 用目标 Godot 4.7 验证改动的场景。
- **[必须]** 修改实例化或继承时，验证有代表性的源场景，以及它们的派生场景或实例消费方。
- **[必须]** 使用了编辑器或自动化工具时，检查结果差异中有没有无关的场景污染或规范化。
- **[必须]** 能解析、但在实例化或 `_ready` 期间失败的场景，不算通过。
- **[优先]** 对足够独立的可复用场景，额外用 Play Current Scene（F6）或等价的单独运行作为验证路径。
- **[必须]** 单独运行失败时，归类为以下两者之一：隐藏的、未声明的依赖；或单独运行时没有提供的已声明公共依赖。合理的依赖注入契约，不会仅因为单纯按 F6 运行无法提供依赖就成为架构缺陷。
- **[优先]** 可复用场景有已声明的公共依赖时，用能提供该依赖的最小测试装置或夹具验证。不为了让单独运行通过，把场景伪装成自包含，或加入隐藏的 `/root/...` 路径。
- **[优先]** 修改涉及所有权、实例化、更换父节点或孤立节点行为时，在运行时验证中使用 Remote 场景树。
