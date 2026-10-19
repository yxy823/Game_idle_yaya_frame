import fs from "node:fs";
import path from "node:path";
import { readDocs } from "./read-docs.js";

// 构建时读取仓库文档，以虚拟模块 virtual:panorama-data 交给页面；卡片、段落和链接由 read-docs.js 读出。
const repo = path.resolve(import.meta.dirname, "..", "..", "..");
const id = "virtual:panorama-data";

// 框架入口「框架做什么」一节的第一张 Mermaid 图
function homeFlow() {
  const text = fs.readFileSync(path.join(repo, "framework", "README.md"), "utf-8").replace(/\r\n/g, "\n");
  const section = text.slice(text.indexOf("## 框架做什么"));
  const start = section.indexOf("```mermaid\n") + "```mermaid\n".length;
  return section.slice(start, section.indexOf("```", start)).trimEnd();
}

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
      const data = { homeFlow: homeFlow(), generatedAt: generatedAt(), repo: repo.split(path.sep).join("/"), ...readDocs(repo) };
      return `export default ${JSON.stringify(data)};`;
    },
  };
}
