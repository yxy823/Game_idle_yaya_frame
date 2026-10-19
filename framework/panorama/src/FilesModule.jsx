import { useMemo, useState } from "react";
import { IconArrowLeft, IconChevronDown, IconChevronRight } from "@tabler/icons-react";
import { dirOf, files, groupName, groups, incoming, links } from "./docs.js";
import DocView from "./DocView.jsx";
import Graph from "./Graph.jsx";
import PageSearch, { PageHead, matches, words } from "./PageSearch.jsx";
import { store } from "./store.js";

// 图谱数据：两份文档之间有多条链接时只画一条线，链到自己的不画；被引用最多的文档作为路标
const graph = {
  nodes: files.map((f, i) => ({ i, label: f.title, group: f.group, size: 12 + Math.sqrt(incoming[i].length) * 5 })),
  edges: [...new Set(links.filter((l) => l.from !== l.to).map((l) => l.from + "-" + l.to))]
    .map((key) => { const [from, to] = key.split("-").map(Number); return { from, to }; }),
  legend: groups.map((g) => ({ id: g.id, name: g.name, color: "--g-" + g.id, count: files.filter((f) => f.group === g.id).length })).filter((g) => g.count),
  landmarks: files.map((_, i) => i).sort((a, b) => incoming[b].length - incoming[a].length),
};

// 目录树：每个目录记下自己和子目录里的文档总数
function buildTree() {
  const root = { name: "仓库根目录", path: "", dirs: new Map(), count: 0 };
  for (const f of files) {
    let node = root;
    node.count += 1;
    for (const part of dirOf(f.path).split("/").filter(Boolean)) {
      const next = node.path ? node.path + "/" + part : part;
      if (!node.dirs.has(part)) node.dirs.set(part, { name: part, path: next, dirs: new Map(), count: 0 });
      node = node.dirs.get(part);
      node.count += 1;
    }
  }
  return root;
}

function TreeNode({ node, depth, dir, onDir, open, onToggle }) {
  const isOpen = open.has(node.path);
  const children = [...node.dirs.values()];
  return (
    <li>
      <button className="tree-row" style={{ paddingLeft: 4 + depth * 12 }} aria-selected={dir === node.path} aria-expanded={children.length ? isOpen : undefined}
        onClick={() => { onDir(node.path); if (children.length && !isOpen) onToggle(node.path); }}>
        <span className="twisty" onClick={(e) => { e.stopPropagation(); if (children.length) onToggle(node.path); }}>
          {children.length ? (isOpen ? <IconChevronDown aria-hidden="true" /> : <IconChevronRight aria-hidden="true" />) : null}
        </span>
        <span className="tree-name">{node.name}</span>
        <span className="count">{node.count}</span>
      </button>
      {isOpen && children.length > 0 && (
        <ul>{children.map((c) => <TreeNode key={c.path} node={c} depth={depth + 1} dir={dir} onDir={onDir} open={open} onToggle={onToggle} />)}</ul>
      )}
    </li>
  );
}

function Card({ index, selected, onSelect, onRead, showGroup }) {
  const f = files[index];
  return (
    <button className="card" aria-selected={selected} onClick={() => onSelect(index)} onDoubleClick={() => onRead(index)} data-tip={f.path + "（双击读全文）"}>
      <span className="card-title"><span className={"dot g-" + f.group} aria-hidden="true"></span>{f.title}</span>
      <span className="card-purpose">{f.purpose || "（第一段没有用途说明）"}</span>
      <span className="card-meta">{showGroup && <span>{groupName[f.group]}</span>}<span>{f.path.split("/").pop()}</span></span>
    </button>
  );
}

// 离开文件全景再回来时，仍停在正在读的文档
let lastReading = null;

// 文件全景：照 VSCode 的资源管理器，左边目录树，右边是所选目录下的卡片；“图谱”看全部文档的链接关系。
// 单击卡片选中，双击在右边读全文；正文里的文档链接打开那份文档，“返回卡片”回到目录的卡片
export default function FilesModule({ selected, onSelect, theme, font }) {
  const [query, setQuery] = useState("");
  const [reading, setReading] = useState(lastReading);
  const [jump, setJump] = useState({ anchor: "" });
  const read = (i, anchor = "") => { lastReading = i; setReading(i); setJump({ anchor }); if (i !== null) onSelect(i); };
  const search = (q) => { setQuery(q); if (q.trim() && reading !== null) read(null); };
  const ws = words(query);
  const found = ws.length ? files.map((f, i) => i).filter((i) => matches(ws, files[i].title, files[i].purpose, files[i].path)) : null;
  const tree = useMemo(buildTree, []);
  const [view, setView] = useState(() => (store.get("files.view") === "graph" ? "graph" : "list"));
  const [dir, setDir] = useState(() => store.get("files.dir") ?? "framework");
  const [open, setOpen] = useState(() => new Set(["", ...dir.split("/").map((_, i, a) => a.slice(0, i + 1).join("/"))]));
  const toggle = (p) => setOpen((s) => { const n = new Set(s); if (n.has(p)) n.delete(p); else n.add(p); return n; });
  const choose = (v) => { setView(v); store.set("files.view", v); };
  const pickDir = (p) => { setDir(p); store.set("files.dir", p); };
  // 搜索时列出全部目录里命中的文档，不限于所选目录
  const cards = found ?? files.map((f, i) => i).filter((i) => dirOf(files[i].path) === dir);
  // 目录里只有一个分组时，每张卡片都写同一个分组名是重复信息
  const showGroup = new Set(cards.map((i) => files[i].group)).size > 1;

  return (
    <div className="files">
      <PageHead search={<PageSearch ui="files.search" value={query} onChange={search} placeholder="搜索标题、用途和路径"
        results={view === "graph" ? (found ?? []).map((i) => ({ key: i, label: files[i].title, meta: files[i].path.split("/").pop() })) : undefined} onPick={(r) => onSelect(r.key)} />}>
        <div className="segmented" role="tablist" data-ui="files.view-switch">
          <button role="tab" aria-selected={view === "list"} onClick={() => choose("list")}>列表</button>
          <button role="tab" aria-selected={view === "graph"} onClick={() => choose("graph")}>图谱</button>
        </div>
      </PageHead>
      {view === "list" ? (
        <div className="files-layout">
          <ul className="tree" data-ui="files.tree">
            <TreeNode node={tree} depth={0} dir={dir} onDir={(p) => { pickDir(p); read(null); }} open={open} onToggle={toggle} />
          </ul>
          {reading !== null ? (
            <article className="learn-body doc-scroll" data-ui="files.reader">
              <button className="graph-btn reader-back" onClick={() => read(null)} data-ui="files.reader-back"><IconArrowLeft aria-hidden="true" />返回卡片</button>
              <DocView card={reading} jump={jump} onLink={(i, anchor) => read(i, anchor)} font={font} />
            </article>
          ) : (
          <div data-ui="files.cards">
            <p className="lead">{found ? `搜索“${query.trim()}”：${cards.length} 份文档` : (dir || "仓库根目录") + "：" + cards.length + " 份文档"}</p>
            {cards.length ? (
              <div className="cards">{cards.map((i) => <Card key={i} index={i} selected={selected === i} onSelect={onSelect} onRead={read} showGroup={showGroup || found !== null} />)}</div>
            ) : <p className="empty-line">{found ? "没有匹配的文档，换一个词或减少关键词。" : "这个目录下没有直接放文档，在左边展开它的子目录。"}</p>}
          </div>
          )}
        </div>
      ) : <Graph cacheKey="files" {...graph} selected={selected} onSelect={onSelect} theme={theme} font={font} ui="files" />}
    </div>
  );
}
