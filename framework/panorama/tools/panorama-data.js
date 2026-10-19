import fs from "node:fs";
import path from "node:path";
import { readDocs } from "./read-docs.js";

// 构建时读取仓库文档，以虚拟模块 virtual:panorama-data 交给页面；卡片、段落和链接由 read-docs.js 读出。
const repo = path.resolve(import.meta.dirname, "..", "..", "..");
const id = "virtual:panorama-data";

// 一节的第一段文字和第一张 Mermaid 图，首页用它们说明框架和 Feature 主线，页面上不另写正文
function section(file, heading) {
  const text = fs.readFileSync(path.join(repo, file), "utf-8").replace(/\r\n/g, "\n");
  const body = text.slice(text.indexOf("\n" + heading + "\n") + heading.length + 2);
  const lead = body.split("\n\n").map((p) => p.trim()).find((p) => p && !p.startsWith("```"));
  const start = body.indexOf("```mermaid\n") + "```mermaid\n".length;
  return { lead: lead.replace(/\[([^\]]*)\]\([^)]*\)/g, "$1").replace(/`/g, ""), flow: body.slice(start, body.indexOf("```", start)).trimEnd() };
}
const home = () => ({
  framework: section("framework/README.md", "## 框架做什么"),
  feature: section("framework/godot-project-manual/README.md", "## 先建立的整体印象"),
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
