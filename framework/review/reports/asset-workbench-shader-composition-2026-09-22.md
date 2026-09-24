# 工作台 Shader 接入与独立资源组合验证

## 范围与基线

用户明确授权从指定本地 Shader 库复制合适样例、重命名、实现和实际测试，随后补充要求： 美术、声音、Shader 独立、可留空和自由组合。修改基于 `d5f6af9`，开始时维护仓库干净。 此前四项审核修复已完成，本报告记录后续新增能力，不将之前的“Shader 仅讨论”当作当前限制。

源材料在 `project-source/`；测试和报告只留在 `framework/`。 真实验证复用 `D:/A_Games/Game_idle_yaya_frame_workbench_test`，没有新建游戏、Feature 或项目流程状态。 同步前比对现有被测文件与 Git 基线，仅同步相关组件、工作台、新增示例及夹具，保留机器配置、主场景和原 Cue。

环境：Windows、Godot `4.7.1.stable.official.a13da4feb`、Vulkan Forward+ / RTX 4060 Laptop GPU， Python 为 `C:/Users/89523/anaconda3/envs/codex-python/python.exe`。

## 实现与取舍

| 范围 | 最终行为与理由 |
| --- | --- |
| 独立资源 | `FeedbackCue` 的图片、声音、Shader 预设都可为空；全空是有效的无表现配置。控件分别更换对应引用，不自动填入另一类资源；静音配置的初始 B 仍静音 |
| Shader 预设 | `FeedbackShaderPreset` 只保存材质默认值及可选的 float 强度、颜色 uniform 契约；不包含目标图片或声音。不扩建任意属性编辑器 |
| 运行状态隔离 | `feedback_visual.gd` 单独持有每个表面的运行材质和时间，复制材质但只读共享 Shader/遮罩。各对象和 A/B 不修改共同预设 |
| 时序与停止 | Shader 延迟、时长独立于声音；强度沿正弦包络变化，重触发重启该表面，停止/自然结束恢复原图，无图则恢复为空。不依赖全局 `TIME` |
| 场景联动 | 复用现有组合场景和会话，增加 `Scene A/B` 切全部对象各自的草稿；`Trigger all` 清理旧播放再统一触发，保留每个对象的独立延迟 |
| 保存与消费 | 沿用原 Cue 冲突检查、显式保存与重读验证，新增字段参与等值判断；示例游戏读取同一 Cue。没有预设文件回写或自动同步 |
| 无图片承载 | Shader 在普通白色矩形上绘制；噪声可独立显示。具体效果仍依赖 Shader 本身的采样方式，描边不保证在无透明边缘的矩形上明显 |
| 分析边界 | 仍只收集图片/声音源，跳过空项，不把材质或 Shader 的最终画面交给源文件 Analyzer |

新增入口：[Shader 组合工作台](../../../project-source/examples/asset_workbench/shader_composition/example_workbench.tscn)。 继承现有三对象 Scene，使用自己的 Cue；原单对象/组合示例配置未修改。 三个初始对象分别为图片＋描边＋声音、图片＋溶解且静音、噪声＋声音且无图片。 右侧颜色按钮在真实截图检查中补足了可点击高度。

完整使用与扩展契约集中在 [示例 README](../../../project-source/examples/asset_workbench/README.md#shader-与独立资源组合)。 现有目录复制映射已覆盖新增文件，无需修改创建器或清单。

## Shader 来源

按用户指定，从 `D:/A_Games/Matchbound-VFX-Library/references/shaders/godot-shaders/godot/Shaders` 复制：

- `outline2D_outer.gdshader` → `example-outline.gdshader`。
- `dissolve2D.gdshader` → `example-dissolve.gdshader`。
- `value_noise.gdshader` → `example-noise.gdshader`。

逐文件比较确认逻辑未变，只规范了空白和 LF。原件未改动；本地镜像未提供可识别的上游提交号，不补造版本。 本地镜像未附 LICENSE，已核对 [GDQuest 上游许可](https://github.com/gdquest-demos/godot-shaders/blob/main/LICENSE)： Shader 代码采用 MIT，保留于 [随示例复制的许可](../../../project-source/examples/asset_workbench/shader_composition/example_shaders_license.txt)。 没有复制采用另一许可的上游艺术资产；溶解遮罩是本例创建的 Godot 渐变资源。

## 实际验证

下列原始证据路径相对既有外部验证项目。Godot 包装器最终判定共 **60/60 通过**，不是只看引擎退出码。

| 检查 | 结果 | 原始证据 |
| --- | --- | --- |
| Shader 专项 | 9/9；8 种有无组合播放/停止及保存消费、运行材质隔离、延迟取消、重播/自然结束、候选替换、全场景 A/B、无效契约 | `reports/gdunit-wrapper/run-nu8jw_n8/result.json` |
| 原单对象工作台 | 12/12 | `reports/gdunit-wrapper/run-ffxv9gay/result.json` |
| 原组合工作台 | 8/8 | `reports/gdunit-wrapper/run-c4_nfhs_/result.json` |
| Godot Analyzer | 18/18 | `reports/gdunit-wrapper/run-tqet4hiq/result.json` |
| 分组/历史 | 13/13 | `reports/gdunit-wrapper/run-yuxhopvd/result.json` |
| 项目 lint | 41 文件，0 Critical、0 Warning、230 Info | `reports/asset-analyzer/shader-20260922-lint-final.json` |
| 渲染夹具 lint | 显式补查默认扫描忽略的两份捕获脚本：0 Critical、0 Warning、23 Info | `reports/asset-analyzer/shader-20260922-capture-lint-final.json` |
| 原单对象渲染 | 真实引擎退出 0；包括 1152×648、900×540、720×480 下控件滚动可达，更新末端控件定位以适配新增分组 | `reports/asset-shader-20260922/single/engine.log` 与同目录截图 |
| Shader 渲染 | 真实引擎退出 0，无错误诊断；1600×900 浅/深色、900×540 参数可达、独立场景消费；Agent 已查看相关截图 | `reports/asset-shader-20260922/engine-final.log`、`render-results.json` 及截图 |
| 框架维护回归 | 38/38 unittest；覆盖既有复制、文档及工具契约 | 本次会话命令输出 |
| 手册构建 | 22 篇、33 张 Mermaid、483 个源链接；正文链接与生成锚点检查通过 | `framework/docs/blank-project/blank-project-handbook.html` |

真实渲染探针使用 128×128 透明表面：描边的可见像素从 4764 增至 8401； 半强度溶解从 3731 减至 2471；无图片的噪声从 0 增至 16384，且颜色随 UV 变化。 三个效果停止后的像素均与各自静止初态逐字节一致。 原工作台截图保存在本轮新目录，没有覆盖先前任务的证据。

### 本轮遇到的失败

- 专项测试初次因夹具两处动态属性的局部变量类型推断失败，未发现可运行用例；补明确 `FeedbackCue` 类型后通过。保留 `shader-20260922-behavior-01.log`。
- 初次溶解像素探针在示例 0.9 峰值下完全消隐，和“必须部分残留”的测试前提冲突。保留示例参数，探针改为明确 0.5 强度再检查部分消隐；第一次引擎日志保留在 `asset-shader-20260922/engine-01.log`。
- 初次 lint 指出预设检查函数复杂度及渲染夹具函数过长；分别按材质/Uniform 契约、场景捕获/像素度量拆分职责，没有调宽规则或增加忽略。
- 手册首次构建因沙箱无法写 npm 缓存失败，沿审批路径在沙箱外重跑后成功；未修改机器权限或构建机制。

## 复跑与剩余边界

在已同步对应源文件和夹具的外部验证项目根目录，专项命令为：

```powershell
$python = 'C:/Users/89523/anaconda3/envs/codex-python/python.exe'
$godot = 'E:/GameTools/Godot/4.7.1/Godot_v4.7.1-stable_win64.exe'
& $python -B tools/testing/run-gdunit-tests.py --godot-binary $godot --target tests/features/asset_shader_composition/asset_shader_composition_test.gd --continue
& $godot --path . --script res://reports/asset-shader-20260922/asset_shader_render_capture.gd | Out-Host
```

回归四套既有测试沿用 [上次报告的命令入口](asset-workbench-code-quality-fixes-2026-09-22.md#复跑入口)。 本轮未改 Python 分析后端，未重跑其独立 22 项；不能将上次通过写成本次通过。

当前支持 2D `canvas_item` 与明确的参数契约；3D、全屏后处理、任意 uniform 编辑、多 Shader 堆叠、 依赖全局 TIME 的重播一致性与其他设备均未验证。声音听感、效果协调性和界面使用体验仍由用户实际体验判断。 手册 HTML 只完成静态/构建检查，外部阅读排版与交互未代替用户验收。
