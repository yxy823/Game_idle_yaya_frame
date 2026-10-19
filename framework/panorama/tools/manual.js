import fs from "node:fs";
import path from "node:path";
import { unified } from "unified";
import remarkParse from "remark-parse";
import remarkGfm from "remark-gfm";
import remarkFrontmatter from "remark-frontmatter";
import remarkRehype from "remark-rehype";
import rehypeStringify from "rehype-stringify";

// 学习模块：按 Godot 项目手册 README 的顺序列出各章，每章在构建时转成 HTML。
// 顺序：手册首页；「第一次阅读」的教程；「全部专题」各组下的链接。章节之间的链接在页面里切换章节，其他 Markdown 链接选中对应卡片。
const README = "framework/godot-project-manual/README.md";
const parser = unified().use(remarkParse).use(remarkGfm).use(remarkFrontmatter, ["yaml"]);
const toHtml = unified().use(remarkRehype).use(rehypeStringify);

const text = (n) => (n.type === "text" || n.type === "inlineCode" ? n.value : (n.children || []).map(text).join(""));
const linksIn = (n) => (n.type === "link" ? [n.url] : (n.children || []).flatMap(linksIn));

// 和 GitHub 的标题锚点一致：小写，去掉标点，空格换成“-”，重名加序号
function slugger() {
  const seen = new Map();
  return (s) => {
    const base = s.toLowerCase().replace(/[^\p{L}\p{M}\p{N}\p{Pc}\- ]/gu, "").replace(/ /g, "-");
    const n = seen.get(base) || 0;
    seen.set(base, n + 1);
    return n ? `${base}-${n}` : base;
  };
}

// 读出章节顺序：[{ group, file }]，file 是仓库内路径
function order(repo) {
  const tree = parser.parse(fs.readFileSync(path.join(repo, README), "utf-8"));
  const section = (title) => {
    const start = tree.children.findIndex((n) => n.type === "heading" && n.depth === 2 && text(n) === title);
    const end = tree.children.findIndex((n, i) => i > start && n.type === "heading" && n.depth === 2);
    return tree.children.slice(start + 1, end < 0 ? undefined : end);
  };
  const resolve = (url) => path.posix.normalize(path.posix.join(path.posix.dirname(README), decodeURI(url.split("#")[0])));
  const result = [{ group: "开始", file: README }];
  const tutorials = section("第一次阅读").find((n) => n.type === "list").children.flatMap(linksIn).map(resolve);
  for (const item of section("全部专题").find((n) => n.type === "list").children) {
    const group = text(item.children[0].children.find((c) => c.type === "strong"));
    const sub = item.children.find((c) => c.type === "list");
    const files = sub ? sub.children.map((li) => resolve(linksIn(li.children[0])[0])) : tutorials;
    for (const file of files) result.push({ group, file });
  }
  return result;
}

export function readManual(repo, paths, index, resolve) {
  const chapters = order(repo);
  const chapterOf = new Map(chapters.map((c, k) => [c.file, k]));
  return chapters.map(({ group, file }) => {
    const mdast = parser.parse(fs.readFileSync(path.join(repo, file), "utf-8"));
    const hast = toHtml.runSync(mdast);
    const slug = slugger();
    const walk = (node) => {
      if (node.type !== "element") return;
      if (/^h[1-6]$/.test(node.tagName)) node.properties.id = slug(hastText(node));
      if (node.tagName === "a" && typeof node.properties.href === "string") {
        const url = node.properties.href;
        const hit = resolve(file, url);
        if (/^https?:/.test(url)) Object.assign(node.properties, { target: "_blank", rel: "noreferrer" });
        else if (hit && chapterOf.has(paths[hit.to])) Object.assign(node.properties, { href: "#", dataChapter: chapterOf.get(paths[hit.to]), dataAnchor: hit.anchor });
        else if (hit) Object.assign(node.properties, { href: "#", dataCard: hit.to });
        else if (!url.startsWith("#")) node.properties.href = `vscode://file/${repo.split(path.sep).join("/")}/${path.posix.normalize(path.posix.join(path.posix.dirname(file), decodeURI(url.split("#")[0])))}`;
      }
      // Mermaid 代码块换成占位，页面里用 Pele 渲染
      if (node.tagName === "pre" && node.children[0]?.properties?.className?.includes("language-mermaid")) {
        node.tagName = "div";
        node.properties = { className: ["diagram", "manual-diagram"] };
      }
      node.children.forEach(walk);
    };
    hast.children.forEach(walk);
    return { group, card: index.get(file), html: toHtml.stringify(hast) };
  });
}

function hastText(n) {
  return n.type === "text" ? n.value : (n.children || []).map(hastText).join("");
}
