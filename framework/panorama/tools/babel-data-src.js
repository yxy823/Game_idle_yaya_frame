import path from "node:path";

// 给带 data-ui 的 JSX 元素补 data-src="文件:行号"，元素选取复制时带上源码位置；路径相对仓库根目录。
const repo = path.resolve(import.meta.dirname, "..", "..", "..");

export default function dataSrc({ types: t }) {
  return {
    visitor: {
      JSXOpeningElement(p, state) {
        const attrs = p.node.attributes;
        const has = (name) => attrs.some((a) => t.isJSXAttribute(a) && a.name.name === name);
        if (!has("data-ui") || has("data-src")) return;
        const file = path.relative(repo, state.filename).split(path.sep).join("/");
        attrs.push(t.jsxAttribute(t.jsxIdentifier("data-src"), t.stringLiteral(`${file}:${p.node.loc.start.line}`)));
      },
    },
  };
}
