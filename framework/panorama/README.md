# 框架全景

[框架入口](../README.md)

框架全景是一个本地 HTML 页面，用来在框架仓库里查资料：把文档、Skill、工具、场景和问答做成卡片，关系从文档里的 Markdown 链接读出，不另外维护关系文件。它只在框架仓库使用，不进入生成项目。

目前只有界面外壳：布局、主题、悬浮提示、元素选取和首页的流程图是真的，其余模块是占位，详情面板用演示数据。

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

`install` 只在第一次和依赖版本变化后需要运行。生成约需 5 秒。npm 安装时会提示拦下了 esbuild 的安装脚本：这个脚本只检查 esbuild 的程序有没有装上，程序已经随 `@esbuild/win32-x64` 装好，所以不用处理。

## 元素选取

要让 Agent 改界面上的某个元素时，用元素选取把它的名称和源码位置复制下来：

1. 点顶栏右侧的设置按钮，打开“元素选取：点击即复制”开关，或按 `Alt+X`。
2. 鼠标移到元素上，粉色框标出元素，标签显示要复制的内容。
3. 点击元素，这一条就复制到剪贴板，页面底部提示“已复制”。
4. 把复制的内容和想怎么改一起发给 Agent。用完按 `Esc` 关闭。

复制出来的一条是这样：`topbar.search「搜索标题、用途、Skill、工具和术语」（framework/panorama/src/App.jsx:48）`。`「」` 里是元素现在的文字，超过 24 个字时截断；括号里是元素在源文件中的行号。

## 目录内容

| 路径 | 内容 |
| --- | --- |
| `src/` | 页面源码：React 组件和 `styles.css`；颜色、尺寸和层级都用 `styles.css` 开头的 CSS 变量 |
| `tools/babel-data-src.js` | 编译时给带 `data-ui` 的元素补 `data-src="文件:行号"`，元素选取靠它复制源码位置 |
| `tools/panorama-data.js` | 构建时读取仓库文档，以虚拟模块 `virtual:panorama-data` 交给页面；现在只读首页流程图和生成时间 |
| `vite.config.js` | 用 Vite 打包成一个内联全部脚本和样式的 HTML，因为 Edge 直接打开本地文件时会拦住外部的模块脚本 |
| `package.json`、`package-lock.json` | 依赖及固定版本：React、Vite、Pele（渲染 Mermaid 图）、Tabler Icons；升级时改这里的版本号，再运行 `install` |

给界面元素加 `data-ui="模块.元素"` 名称，元素选取才能选中它；名称只用英文小写、点和连字符。
