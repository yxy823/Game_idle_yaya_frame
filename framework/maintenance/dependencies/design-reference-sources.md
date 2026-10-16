# 设计参考条目的来源

[框架维护](../README.md)

分发 Skill 的设计参考文件里，每条带编号的条目从哪里来。分发文件随项目复制，项目里没有 `references/` 目录，所以出处只记在这里。下文路径都相对仓库根目录的 `references/`，行号对应参考库清单 `references/README.md` 登记的提交；`references/` 不进 Git，只在本机。

新增、修改或删除条目时同步本页；条目编号在所属文件内唯一，删除后不复用。

## 取舍

引入时定下、以后引入同类经验沿用的取舍：

- 不引入手柄、触屏、掌机、电视、分屏、联网、内购相关内容，因为框架只做 Windows PC、鼠标和键盘。
- 不引入 AI 味反模式检查。
- 不引入来源之间说法冲突、需要看实际画面才能定的条目。
- 数值写成初始值；采纳的值保存在项目的调参资源中。
- 工程实现（状态枚举、超时、虚拟列表、对象池）不写进设计参考，归工程规则和性能诊断。

## 来源缩写

| 缩写 | 路径 |
| --- | --- |
| TS | `taste-skill/skills/taste-skill/SKILL.md` |
| TS-c、TS-y、TS-m、TS-t | `taste-skill/skills/taste-skill/references/` 下的 `colour.md`、`type.md`、`motion.md`、`tells.md` |
| RD | `taste-skill/skills/redesign-skill/SKILL.md` |
| MN | `taste-skill/skills/minimalist-skill/SKILL.md` |
| AF | `anthropic-skills/skills/frontend-design/SKILL.md` |
| FD | `frontend-design/SKILL.md` |
| IM/x | `impeccable/.claude/skills/impeccable/reference/x.md` |
| L01–L08 | `godot-ui-lesson/` 下以该编号开头的文件；`L02 §2.4` 表示第 02 篇第 2.4 节 |

## design-art-direction/references/ui-color-and-surface.md

| 条目 | 来源 |
| --- | --- |
| C1 | TS-c:34-50；IM/colorize:29-36, 49；L01 §1.2（21-33 行） |
| C2 | TS-c:52-65；RD:34-36；IM/quieter:54；L02 §2.2（22-31 行） |
| C3 | TS-c:67-79；IM/craft-floor:25；L02 §2.1（7-21 行） |
| C4 | L02 §2.4（50-63 行） |
| C5 | L02 §2.3（32-49 行） |
| C6 | L02 §2.2（22-31 行） |
| C7 | L02 §2.5（64-78 行） |
| C8 | IM/craft-floor:9；IM/quieter:57；IM/colorize:45 |
| C9 | IM/colorize:47, 55-63；TS-c:117-124；L02 §2.1（7-21 行） |
| C10 | IM/colorize:55-63；L02 §2.6（79-92 行） |
| C11 | IM/operate:22-23, 51；IM/mode-operate:17；MN:36-40 |
| C12 | IM/craft-floor:15 |

## design-art-direction/references/ui-type-and-numbers.md

| 条目 | 来源 |
| --- | --- |
| Y1 | TS-y:39-64, 168；TS-t:93；IM/operate:15 |
| Y2 | IM/typeset:42；TS-y:170；RD:25 |
| Y3 | TS:308；AF:19；IM/typeset:57；IM/operate:13, 49 |
| Y4 | TS:297, 303；TS-t:74, 79；AF:27；IM/craft-floor:38 |
| Y5 | RD:26；TS-y:153；FD:56；L03 §3.6（64-79 行） |
| Y6 | IM/harden:7-13, 27-29 |
| Y7 | L03 §3.5（54-63 行） |

## design-art-direction/references/ui-motion.md

| 条目 | 来源 |
| --- | --- |
| M1 | TS-m:40-53；L04 §4.2（26-40 行） |
| M2 | L04 §4.3（41-54 行）；IM/animate:52-61；TS-m:52-53；IM/operate:41 |
| M3 | L04 §4.2（26-40 行）、§4.7（95-104 行） |
| M4 | L04 §4.5（67-77 行）；TS-m:40-53 |
| M5 | L04 §4.5（67-77 行） |
| M6 | AF:32；TS-m:284-292；IM/animate:34, 48, 75；IM/craft-floor:13 |
| M7 | L04 §4.6（78-94 行） |
| M8 | L04 §4.5（67-77 行） |
| M9 | L07 §7.5（83-103 行） |

## design-ui-spec/references/ui-layout-and-sizing.md

| 条目 | 来源 |
| --- | --- |
| L1 | IM/layout:18, 63；TS-cr（`critique.md`）:23 |
| L2 | IM/layout:19, 47-48；IM/craft-floor:11；TS-y:158 |
| L3 | IM/layout:21, 49, 59；L03 §3.4（45-53 行） |
| L4 | L03 §3.1（7-21 行）、§3.2（22-34 行） |
| L5 | L03 §3.3（35-44 行） |
| L6 | IM/layout:22；IM/operate:60；RD:58 |
| L7 | RD:59-61 |
| L8 | RD:62；IM/layout:57 |
| L9 | L08 §8.1（7-26 行） |
| L10 | L08 §8.2（27-48 行）、§8.3（49-64 行） |
| L11 | L08 §8.2（27-48 行） |

## design-ui-spec/references/ui-feedback-and-input.md

| 条目 | 来源 |
| --- | --- |
| F1 | IM/operate:32, 36, 48；IM/polish:73；RD:66-69 |
| F2 | IM/onboard:168-187；IM/delight:41；AF:69 |
| F3 | L05 §5.2（24-40 行） |
| F4 | L05 §5.4（60-74 行） |
| F5 | L05 §5.3（41-59 行） |
| F6 | L05 §5.1（7-23 行） |
| F7 | L05 §5.5（75-92 行） |
| F8 | L05 §5.6（93-102 行） |
| F9 | AF:65-69；FD:38；IM/craft-floor:16 |
| F10 | FD:32-36；RD:82；TS:174-176 |
| F11 | L03 §3.7（80-92 行）；L06 §6.6（89-106 行） |
| F12 | L06 §6.2（27-48 行） |
| F13 | L06 §6.1（7-26 行） |
| F14 | L06 §6.4（59-73 行） |
| F15 | L05 §5.8（121-140 行） |
| F16 | L07 §7.6（104-117 行） |

## design-audio-direction/references/ui-audio-feedback.md

| 条目 | 来源 |
| --- | --- |
| A1 | L07 §7.2（27-46 行） |
| A2 | L07 §7.4（61-82 行） |
| A3 | L07 §7.3（47-60 行） |
| A4 | L07 §7.1（7-26 行）、§7.3（47-60 行） |
| A5 | L07 §7.1（7-26 行） |

## design-game-presentation/SKILL.md

| 内容 | 来源 |
| --- | --- |
| “反馈的强度与发生频率和后果成正比”一段 | IM/delight:39-43, 59 |
