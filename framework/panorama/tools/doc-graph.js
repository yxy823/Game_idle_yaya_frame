// 文档关系图谱：读 Godot 项目手册里的 Mermaid 关系图，合成一张图。
// 只取大部分节点写成“名称<br/>路径”的 flowchart，这类图画的是文档之间的关系；流程图的节点没有路径，不取。
// 同名节点合并成一个；箭头上的文字就是关系说明。
// 图上的节点名称取第一个路径的文件名（目录取目录名），名称本身作说明显示在详情面板；没写路径的节点仍用名称。

const MANUAL = "framework/godot-project-manual/";

// 生成项目里的路径对应到分发源里的文件，用来找节点的卡片；没有对应文件的节点（例如 reports/ 下的报告）不连卡片
const SOURCE = [
  ["AGENTS.md", "project-source/Project_AGENTS.md"],
  ["yaya/methodology/", "project-source/methodology/00-overview.md"],
  ["README.md", "project-source/Project_README.md"],
  ["docs/", "project-source/defaults/docs/"],
  ["yaya/", "project-source/"],
  [".agents/skills/", "project-source/skills/"],
];

// 节点分组按第一个路径的位置；没写路径的节点（例如“写在所属 UI、表现或共享规范中”）算项目文档
const KINDS = [
  { id: "rules", name: "入口、规则与方法", test: (p) => p && !p.startsWith("docs/") && !p.startsWith("reports/") },
  { id: "docs", name: "项目文档", test: (p) => !p || p.startsWith("docs/") },
  { id: "reports", name: "报告与证据", test: (p) => p.startsWith("reports/") },
];
const isPath = (p) => /[/.]/.test(p);

// README.md 带上所在目录，否则几个节点都叫 README.md；有多个路径或写了“等”时加“等”
function labelOf(node) {
  const p = node.paths[0];
  if (!p) return node.name;
  const parts = p.replace(/\/$/, "").split("/");
  let label = parts.pop() + (p.endsWith("/") ? "/" : "");
  if (label === "README.md" && parts.length) label = parts.pop() + "/" + label;
  return label + (node.paths.length > 1 || node.more ? " 等" : "");
}

const NODE = String.raw`(\w+)(?:\["([^"]*)"\]|\{"([^"]*)"\}|\(\["([^"]*)"\]\))?`;
const EDGE = new RegExp(String.raw`^\s*${NODE}\s*(?:-->|-\.->)\s*(?:\|([^|]*)\|\s*)?${NODE}\s*$`);
const ALONE = new RegExp(String.raw`^\s*${NODE}\s*$`);

function parse(code) {
  const labels = new Map(), edges = [];
  const keep = (id, ...ls) => { const l = ls.find((x) => x !== undefined); if (l !== undefined) labels.set(id, l); };
  for (const line of code.split("\n").slice(1)) {
    let m = EDGE.exec(line);
    if (m) {
      keep(m[1], m[2], m[3], m[4]);
      keep(m[6], m[7], m[8], m[9]);
      edges.push({ from: m[1], to: m[6], label: (m[5] || "").trim() });
      continue;
    }
    m = ALONE.exec(line);
    if (m) keep(m[1], m[2], m[3], m[4]);
  }
  return { labels, edges };
}

export function readDocGraph(diagrams, files, index) {
  const nodes = [], byName = new Map(), edges = [];
  const sources = [];
  for (const d of diagrams) {
    if (!files[d.file].path.startsWith(MANUAL) || !/^flowchart\b/.test(d.value)) continue;
    const { labels, edges: raw } = parse(d.value);
    const withPath = [...labels.values()].filter((l) => l.includes("<br/>")).length;
    if (!labels.size || withPath < labels.size * 0.8) continue;
    sources.push(d);
    const local = new Map();
    for (const [id, label] of labels) {
      const [name, where = ""] = label.split("<br/>");
      // “yaya/tools/README.md 等”去掉“等”；不是路径的说明文字不算路径
      const paths = where.split("、").map((p) => p.replace(/\s*等$/, "").trim()).filter(isPath);
      let node = byName.get(name);
      if (!node) {
        const card = paths.map((p) => {
          const rule = SOURCE.find(([from]) => p === from) || SOURCE.find(([from, to]) => to.endsWith("/") && p.startsWith(from));
          if (!rule) return undefined;
          const target = rule[1] + p.slice(rule[0].length);
          // 带编号的文件（例如 FXX-XXX.json）在分发源里没有实例，对应到所在目录的 README
          return index.get(target) ?? index.get(target.replace(/\/?$/, "/README.md")) ?? index.get(target.replace(/[^/]+$/, "README.md"));
        }).find((c) => c !== undefined);
        node = { name, paths, more: /等$/.test(where), note: paths.length ? "" : where, card: card ?? null, kind: KINDS.find((k) => k.test(paths[0] || "")).id, from: [] };
        byName.set(name, node);
        nodes.push(node);
      }
      // 同一个对象在不同图里写的路径可能不同，合并后列出全部路径
      for (const p of paths) if (!node.paths.includes(p)) node.paths.push(p);
      if (!node.from.includes(d.file)) node.from.push(d.file);
      local.set(id, nodes.indexOf(node));
    }
    for (const e of raw) edges.push({ from: local.get(e.from), to: local.get(e.to), label: e.label, file: d.file, line: d.line });
  }
  for (const node of nodes) node.label = labelOf(node);
  return { kinds: KINDS.map(({ id, name }) => ({ id, name })), nodes, edges, sources: sources.map((d) => ({ file: d.file, line: d.line })) };
}
