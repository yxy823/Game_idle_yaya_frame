# 验证与收尾：表达参考

> 自动生成的表达参考，不是流程规范或当前指令；勿手工修改。
> 框架维护来源：`framework/prompts.json`。生成项目使用自己的副本，不回查框架。
> 模板中的授权、停止条件与占位符仅属于原示例；依据当前用户指令、项目事实、规范及目标 Skill 改写，不据此执行、扩大授权或代作人工验收。

<a id="example-1"></a>

## 已有变更需要重新运行相关自动测试

来源：Godot 项目开发 → 验证与收尾 → 已有变更需要重新运行相关自动测试

```text
## 目标

请只对有明确 Feature 的当前变更运行必要自动测试；本入口不处理没有 Feature 的组件检查，组件测试使用其专用 --target 场景，不虚构任务 ID。

## 背景与入口条件

需要当前内容的实际测试结果，本次不顺手修复实现。

## 范围

只对具有明确 Feature 的当前变更运行必要自动测试，不处理无 Feature 的组件检查。

## 输入与事实来源

${1:当前 Feature ID、改动范围、测试授权}

读取当前 Feature、AC、测试登记、改动影响及实际测试路径。

## 决策边界与授权

执行已有测试授权；默认不修改实现、规则或完成状态，修复交回其已授权场景。

## 约束

遵循 methodology/08-testing-strategy.md；不虚构任务 ID，不把启动、零测试、跳过或旧成功写成当前通过。

## 工具与执行环境

在游戏项目根目录用 docs/methodology-config.json 配置的 Python 调用 tools/testing/run-gdunit-tests.py --feature <实际ID> --scope <实际范围>。

## 输出与交付

报告实际范围、完整原件、退出码、通过或失败及未执行部分。

## 验证要求

按登记、影响与 AC 选择测试，使用上述入口读取完整结果与原始报告，核对实际用例、退出码和覆盖。

## 完成条件

所选验证已按当前合法义务执行并如实报告；需要实际测试时保留完整原件，检查任务结束不代表 Feature 完成。

## 停止与异常处理

运行受阻或中断时报告实际覆盖及缺口，不称为测试完成。仅当实际运行器返回合法 not_required 时，按 methodology/08-testing-strategy.md 的窄条件处理：它不启动 Godot、不产生运行报告，不是运行通过，也不调用 record-tests。
```

<a id="example-2"></a>

## Feature 已能体验，需要准备人工验收清单

来源：Godot 项目开发 → 验证与收尾 → Feature 已能体验，需要准备人工验收清单

```text
## 目标

请为当前可体验的 manual Feature 准备人工清单。

## 背景与入口条件

实现已稳定且可体验，需要生成待用户填写的当前版本清单。

## 范围

为实现稳定、可体验的 manual Feature 准备当前版本清单，不替用户作接受决定。

## 输入与事实来源

${1:manual Feature、批准的 manual_checks 与必要 manual_regression、运行入口}

读取批准的 manual_checks、必要 manual_regression、运行入口和最终内容。

## 决策边界与授权

按 methodology/manual-acceptance-files.md 准备清单并绑定版本，用户实际体验与反馈由用户完成。

## 约束

全部用例初始为 pending，不另建验收台账，不将材料准备成功当接受或 Feature 完成。

## 工具与执行环境

在项目根目录使用配置 Python 调用 tools/features/record-feature-completion.py prepare-manual；准确参数与原清单绑定契约见 methodology/manual-acceptance-files.md。

## 输出与交付

提供清单链接、入口、条件、动作、可观察预期、重置方式及结果返回方式。

## 验证要求

核对全部批准用例及必要回归均在 pending 清单中，最终内容稳定后调用上述绑定入口，检查清单与当前版本一致。

## 完成条件

覆盖完整的 pending 清单已绑定当前版本并可供实际体验。
```

<a id="example-3"></a>

## 人工验收 JSON 已填好，需要导入结果

来源：Godot 项目开发 → 验证与收尾 → 人工验收 JSON 已填好，需要导入结果

```text
## 目标

请导入我实际填写的人工验收 JSON。

## 背景与入口条件

用户已实际体验并返回对应原清单的结果文件。

## 范围

只导入用户实际填写的对应人工验收 JSON，保留失败和 pending。

## 输入与事实来源

${1:Feature ID、未改动原清单、用户填写的结果 JSON}

核对未改动原清单、版本、用例定义、用户结果及注释。

## 决策边界与授权

有效全通过就是该实际范围的明确接受，无需重复口头确认；结果文字是反馈，不批准新需求或放宽预期。

## 约束

遵循 methodology/manual-acceptance-files.md；不伪造结果，不跳过其他完成检查。

## 工具与执行环境

在项目根目录用配置 Python 调用 tools/features/record-feature-completion.py record-acceptance --feature <实际ID> --result <实际结果JSON> --checklist <原清单JSON>；不与 --status 混用。

## 输出与交付

保存合法结果，说明实际接受、失败、pending 的范围及剩余完成义务。

## 验证要求

用上述文件入口导入，核对实际结果、原清单和当前版本一致，读取保存结果；失败和 pending 不得转为接受。

## 完成条件

合法结果已保存，实际接受或失败范围明确；尚需其他完成检查不跳过。
```
