# 框架全景

[框架入口](../README.md)

框架全景是一个本地 HTML 页面，用来在框架仓库里查资料：把文档、Skill、工具、场景和问答做成卡片，关系从文档里的 Markdown 链接读出，不另外维护关系文件。它只在框架仓库使用，不进入生成项目。

七个模块都已做好。首页从框架入口和 Godot 项目手册读出框架说明、开发主线图、Feature 主线图，以及 Stage 0–8 的流程图和每个 Stage 的执行条件与产出；开发主线图点一步，跳到开发场景并展开相关的分类，点“执行一个 Feature”跳到 Stage 一段。开发场景把 Godot 项目开发的场景画成图谱，箭头来自各场景页的下一步清单，主线画实线；默认按分类折叠，选中一个场景后可以只看它 1 跳或 2 跳以内的邻居。文件全景用目录树和卡片列出全部文档，双击卡片在页面里读全文，也能切换成按链接连线的图谱；选中一份文档，详情面板分「概要」「关系」「原文」三个标签，列出它的用途、大纲、场景衔接、引用和被引用的原文段落。每个模块各记自己选中的对象，详情面板能后退、前进到本模块选中过的对象。问答按主题列出 `framework/qa/` 里的问题，左侧目录列出各主题，选中一条，详情面板显示结论、为什么和依据，并能打开问答页里的这一条。文档关系把 Godot 项目手册里几张文档关系图合成一张图，节点用文件名标出，选中一个节点，详情面板显示它的介绍、模板文件和带说明的关系。学习按手册 README 的阅读顺序列出各章，点章节在页面里显示正文，Mermaid 图照常渲染，正文里的链接切换章节或在详情面板显示对应文档；搜索后可以在本章的匹配之间上一处、下一处地跳。顶栏页面名称右边的放大镜搜索本页的内容；全局搜索页查文档的标题、用途、大纲和路径，问答的问题、结论和理由，以及术语表、工具表的每一行；选中术语或工具，详情面板显示所在文档并滚到这一行。设置里可以换四档字号。

## 打开与生成

生成的页面是 `dist/index.html`，它被 Git 忽略。用 Edge 直接打开，不需要服务器和网络：

```powershell
Start-Process msedge "$PWD\framework\panorama\dist\index.html"
```

启用仓库钩子后，每次提交改了 Markdown 或本目录的源码，提交后钩子会自动重新生成，见[提交后生成框架全景](../maintenance/tools/README.md#提交后生成框架全景)。第一次使用、或想在提交前看效果时，在仓库根目录手动运行：

```powershell
npm --prefix framework/panorama install
npm --prefix framework/panorama run build
```

`install` 只在第一次和依赖版本变化后需要运行。生成约需 7 秒。npm 安装时会提示拦下了 esbuild 的安装脚本：这个脚本只检查 esbuild 的程序有没有装上，程序已经随 `@esbuild/win32-x64` 装好，所以不用处理。

## 元素选取

要让 Agent 改界面上的某个元素时，用元素选取把它的名称和源码位置复制下来：

1. 点顶栏右侧的设置按钮，打开“元素选取：点击即复制”开关，或按 `Alt+X`。
2. 鼠标移到元素上，粉色框标出元素，标签显示要复制的内容。
3. 点击元素，这一条就复制到剪贴板，页面底部提示“已复制”。
4. 把复制的内容和想怎么改一起发给 Agent。用完按 `Esc` 关闭。

复制出来的一条是这样：`home.what「框架是什么」（framework/panorama/src/modules.jsx:30）`。`「」` 里是元素现在的文字，超过 24 个字时截断；括号里是元素在源文件中的行号。

## 目录内容

| 路径 | 内容 |
| --- | --- |
| `src/` | 页面源码：React 组件、`tokens.css` 和 `styles.css`；颜色、尺寸、间距和层级的取值都在 `tokens.css` 的 CSS 变量里 |
| `tools/babel-data-src.js` | 编译时给带 `data-ui` 的元素补 `data-src="文件:行号"`，元素选取靠它复制源码位置 |
| `tools/panorama-data.js` | 构建时把首页的说明段落、两张主线图和 Stage 一节的图与表、生成时间和 `read-docs.js` 读出的数据，以虚拟模块 `virtual:panorama-data` 交给页面 |
| `tools/read-docs.js` | 读取纳入 Git 的 Markdown（不含 `.claude/` 副本和 `project-source/addons/`），得到卡片、含链接的段落、链接三张表，以及供搜索用的术语表和工具表的每一行；分组按路径前缀写在文件开头 |
| `tools/doc-graph.js` | 把 Godot 项目手册里的 Mermaid 文档关系图合成文档关系模块的图 |
| `tools/manual.js` | 按手册 README 的顺序读出学习模块的章节；把每份文档转成 HTML，并把指向仓库文档的链接改成卡片编号，学习模块和文件全景的阅读视图都用它 |
| `tools/check-ui.mjs` | 界面冒烟检查，用 `npm --prefix framework/panorama run check` 运行，先构建再跑；检查项见[框架全景的界面设计](interface-design.md)的「交付前跑冒烟检查」一条 |
| [interface-design.md](interface-design.md) | 界面设计约定：改界面时按它做 |
| `vite.config.js` | 用 Vite 打包成一个内联全部脚本和样式的 HTML，因为 Edge 直接打开本地文件时会拦住外部的模块脚本 |
| `package.json`、`package-lock.json` | 依赖及固定版本：React、Vite、Pele（渲染 Mermaid 图）、Tabler Icons、remark 与 rehype（构建时解析 Markdown、转成 HTML）、playwright-core（冒烟检查驱动本机 Edge，不下载浏览器）；升级时改这里的版本号，再运行 `install` |

修改界面前先读[框架全景的界面设计](interface-design.md)：风格、尺寸、布局、颜色用途和组件约定都写在那里。给界面元素加 `data-ui="区域.元素"` 名称，元素选取才能选中它，命名规则见其中的「元素名称」。
