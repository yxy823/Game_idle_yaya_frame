import { useState } from "react";
import data from "virtual:panorama-data";
import { files } from "./docs.js";
import Graph from "./Graph.jsx";
import PageSearch, { PageHead, matches, words } from "./PageSearch.jsx";

// 文档关系：Godot 项目手册里几张关系图合成的一张图，节点是生成项目里的文档和记录，连线写着关系。
// 选中值写成 "doc:编号"，和文档的卡片编号（数字）区分开
const { kinds, nodes, edges, sources } = data.docGraph;
export const docKey = (k) => "doc:" + k;
export const docOf = (selected) => (typeof selected === "string" && selected.startsWith("doc:") ? Number(selected.slice(4)) : null);
export const docNodes = nodes;
export const docEdges = edges;

const degree = nodes.map((_, k) => edges.filter((e) => e.from === k || e.to === k).length);
const graph = {
  nodes: nodes.map((n, k) => ({ i: docKey(k), label: n.name, group: n.kind, size: 12 + Math.sqrt(degree[k]) * 5 })),
  edges: edges.map((e) => ({ from: docKey(e.from), to: docKey(e.to), label: e.label })),
  legend: kinds.map((g, k) => ({ id: g.id, name: g.name, color: "--p" + (k + 1), count: nodes.filter((n) => n.kind === g.id).length })),
  // 点只有几十个，路标不限数量，名称不重叠就都写出来（见下方 landmarkLimit）
  landmarks: nodes.map((_, k) => k).sort((a, b) => degree[b] - degree[a]).map(docKey),
};
const pages = [...new Set(sources.map((s) => s.file))];

export default function DocsModule({ selected, onSelect, theme, font }) {
  const [query, setQuery] = useState("");
  const ws = words(query);
  const results = nodes.map((n, k) => ({ n, k })).filter(({ n }) => matches(ws, n.name, n.paths.join(" "), n.note))
    .map(({ n, k }) => ({ key: docKey(k), label: n.name, meta: kinds.find((g) => g.id === n.kind).name }));
  return (
    <div className="files">
      <PageHead search={<PageSearch ui="docs.search" value={query} onChange={setQuery} placeholder="搜索文档名称和路径" results={results} onPick={(r) => onSelect(r.key)} />}>
      <p className="lead">
        生成项目里的 {nodes.length} 类文档和记录，{edges.length} 条关系，从 Godot 项目手册的 {sources.length} 张关系图自动合成：
        {pages.map((f, n) => <span key={f}>{n ? "、" : ""}{files[f].title}</span>)}。点一个点，详情面板列出它的介绍和进出的关系，连线上写关系说明。
      </p>
      </PageHead>
      <Graph cacheKey="docs" {...graph} landmarkLimit={Infinity} directed focusable selected={selected} onSelect={onSelect} theme={theme} font={font} ui="docs" />
    </div>
  );
}
