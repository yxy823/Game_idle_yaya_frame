import fs from "node:fs";
import path from "node:path";
import { readDocs } from "./read-docs.js";

// 构建时读取仓库文档，以虚拟模块 virtual:panorama-data 交给页面；卡片、段落和链接由 read-docs.js 读出。
const repo = path.resolve(import.meta.dirname, "..", "..", "..");
const id = "virtual:panorama-data";

// 一节的第一段文字、第一张 Mermaid 图、图后“图例：”开头的一段和第一张表，首页用它们说明框架、Feature 主线和各个 Stage，页面上不另写正文。
// sentences 只取第一段的前几句，用在第一段后半句指向本文档其他小节时。
// 第一张图之后、下一个三级标题之前的图是补充的小图（例如 Stage 1 内部的步骤），连同图前一段的说明放进 subs
const plain = (t) => t.replace(/\[([^\]]*)\]\([^)]*\)/g, "$1").replace(/`/g, "");
function section(file, heading, sentences) {
  const text = fs.readFileSync(path.join(repo, file), "utf-8").replace(/\r\n/g, "\n");
  let body = text.slice(text.indexOf("\n" + heading + "\n") + heading.length + 2);
  if (body.includes("\n## ")) body = body.slice(0, body.indexOf("\n## "));
  const paras = body.split("\n\n").map((p) => p.trim());
  let lead = plain(paras.find((p) => p && !p.startsWith("```")));
  if (sentences) lead = lead.split(/(?<=。)/).slice(0, sentences).join("");
  const start = body.indexOf("```mermaid\n") + "```mermaid\n".length;
  const legend = paras.find((p) => p.startsWith("图例："));
  const table = paras.find((p) => p.startsWith("|"));
  const top = body.includes("\n### ") ? body.slice(0, body.indexOf("\n### ")) : body;
  const subs = [...top.slice(body.indexOf("```", start) + 3).matchAll(/([^\n]+)\n\n```mermaid\n([\s\S]*?)```/g)]
    .map((m) => ({ caption: plain(m[1].trim()), flow: m[2].trimEnd() }));
  return {
    lead, flow: body.slice(start, body.indexOf("```", start)).trimEnd(), subs, legend: legend ? plain(legend) : null,
    // 表格每行去掉首尾的 |，按 | 分格；第二行是分隔行，不要
    table: table ? table.split("\n").filter((_, i) => i !== 1).map((l) => l.slice(1, -1).split("|").map((c) => plain(c.trim()))) : null,
  };
}
const home = () => ({
  framework: section("framework/README.md", "## 框架做什么"),
  feature: section("framework/godot-project-manual/README.md", "## 先建立的整体印象"),
  stages: section("framework/godot-project-manual/requirements-and-tasks/feature-lifecycle.md", "## Feature 的执行阶段", 1),
});

function generatedAt() {
  const d = new Date();
  const pad = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export default function panoramaData() {
  return {
    name: "panorama-data",
    resolveId: (source) => (source === id ? "\0" + id : null),
    load(resolved) {
      if (resolved !== "\0" + id) return null;
      const data = { home: home(), generatedAt: generatedAt(), repo: repo.split(path.sep).join("/"), ...readDocs(repo) };
      return `export default ${JSON.stringify(data)};`;
    },
  };
}
