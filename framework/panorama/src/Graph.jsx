import { useEffect, useRef, useState } from "react";
import cytoscape from "cytoscape";
import fcose from "cytoscape-fcose";

cytoscape.use(fcose);

// 每张图第一次布局后记下位置（按 cacheKey 区分），切换视图再回来时位置不变
const positions = new Map();

const css = (name) => getComputedStyle(document.documentElement).getPropertyValue(name).trim();

// 按顺序挑要写名称的点，最多 limit 个；名称会和已挑的重叠就跳过
function pickLabels(cy, list, limit) {
  const z = cy.zoom(), boxes = [], picked = [];
  for (const n of list) {
    if (picked.length === limit) break;
    const { x, y } = n.position();
    const w = (n.data("label").length * 13 + 8) / z, h = 22 / z, top = y + n.data("size") / 2;
    const box = [x - w / 2, top, x + w / 2, top + h];
    if (boxes.some((b) => box[0] < b[2] && b[0] < box[2] && box[1] < b[3] && b[1] < box[3])) continue;
    boxes.push(box); picked.push(n);
  }
  return picked;
}

function style(legend, directed) {
  const colors = Object.fromEntries(legend.map((g) => [g.id, css(g.color)]));
  const edgeColor = (e) => colors[e.source().data("group")];
  return [
    { selector: "node", style: {
      "background-color": (n) => colors[n.data("group")], width: "data(size)", height: "data(size)", "border-width": 0,
      label: "", color: css("--fg"), "font-size": 13, "min-zoomed-font-size": 9, "font-family": "Segoe UI, Microsoft YaHei UI, sans-serif",
      "text-valign": "bottom", "text-margin-y": 3, "text-background-color": css("--bg"), "text-background-opacity": 1, "text-background-padding": 2,
    } },
    { selector: "edge", style: directed
      ? { width: 1, "line-color": edgeColor, opacity: 0.35, "curve-style": "bezier", "line-style": "dashed", "line-dash-pattern": [6, 4],
        "target-arrow-shape": "triangle", "target-arrow-color": edgeColor, "arrow-scale": 0.8 }
      : { width: 1, "line-color": edgeColor, opacity: 0.35, "curve-style": "haystack" } },
    // 主线画成强调色实线，比其他线粗
    { selector: "edge.main", style: { "line-style": "solid", "line-color": css("--brand"), "target-arrow-color": css("--brand"), width: 3, opacity: 0.9 } },
    { selector: ".faded", style: { opacity: 0.08 } },
    { selector: "edge.near", style: { opacity: 0.9, width: 2 } },
    { selector: "edge.main.near", style: { width: 4 } },
    // 写出名称的点按缩放反算字号，屏幕上始终是 13px，缩得再小也看得清
    { selector: "node.hub, node.labeled, node:selected", style: { label: "data(label)", "font-size": (n) => 13 / n.cy().zoom(), "min-zoomed-font-size": 0,
      "text-margin-y": (n) => 3 / n.cy().zoom(), "text-background-padding": (n) => 2 / n.cy().zoom() } },
    { selector: "node.quiet", style: { label: "" } },
    { selector: "node:selected", style: { "border-width": 2, "border-color": css("--ring") } },
  ];
}

// 关系图谱：点按链接自动连线，颜色按分组；点一个点，只突出它和直接相连的点。
// 点空白处不取消选中，因为误点大多落在空白处；按 Esc、再点一次选中的点或点“取消选中”才退出。
// nodes 的 i 是卡片编号，选中时交给 onSelect；edges 里 main 为真的画成主线。nodes、edges、legend、landmarks 要在模块里算好，不随渲染变化。
export default function Graph({ cacheKey, nodes, edges, legend, landmarks, directed = false, selected, onSelect, theme, ui }) {
  const box = useRef(null), cyRef = useRef(null), selectedRef = useRef(selected);
  selectedRef.current = selected;
  const [hidden, setHidden] = useState(() => new Set());

  useEffect(() => {
    const saved = positions.get(cacheKey);
    const cy = cytoscape({
      container: box.current,
      elements: [
        ...nodes.map((n) => ({ data: { id: "n" + n.i, label: n.label, group: n.group, size: n.size }, position: saved?.[n.i] })),
        ...edges.map((e) => ({ data: { id: "e" + e.from + "-" + e.to, source: "n" + e.from, target: "n" + e.to }, classes: e.main ? "main" : "" })),
      ],
      style: style(legend, directed),
      // 斥力大、理想边长长、引力小，点才散得开，名称不叠在一起
      layout: saved ? { name: "preset" } : { name: "fcose", animate: false, quality: "proof", nodeRepulsion: 45000, idealEdgeLength: 140,
        edgeElasticity: 0.3, gravity: 0.05, nodeSeparation: 120, numIter: 4000 },
      minZoom: 0.1, maxZoom: 4, wheelSensitivity: 0.3, boxSelectionEnabled: false,
    });
    const record = Object.fromEntries(nodes.map((n) => [n.i, { ...cy.getElementById("n" + n.i).position() }]));
    positions.set(cacheKey, record);
    // 路标：按 landmarks 的顺序挑，最多 15 个
    pickLabels(cy, landmarks.map((i) => cy.getElementById("n" + i)).filter((n) => n.nonempty()), 15).forEach((n) => n.addClass("hub"));
    cy.on("dragfree", "node", (e) => { record[Number(e.target.id().slice(1))] = { ...e.target.position() }; });
    cy.on("tap", "node", (e) => {
      const index = Number(e.target.id().slice(1));
      onSelect(index === selectedRef.current ? null : index);
    });
    cy.on("zoom", () => cy.nodes(".hub, .labeled, :selected").updateStyle());
    cyRef.current = cy;
    return () => cy.destroy();
  }, [cacheKey, nodes, edges, legend, landmarks, directed, onSelect]);

  useEffect(() => { cyRef.current.style(style(legend, directed)); }, [theme, legend, directed]);

  // 选中的点突出它的直接邻居，其余变淡；只改样式，不移动视口。选中的不是图里的点时，图保持原样
  useEffect(() => {
    const cy = cyRef.current;
    cy.batch(() => {
      cy.elements().removeClass("faded near labeled quiet").unselect();
      const node = typeof selected === "number" ? cy.getElementById("n" + selected) : cy.collection();
      if (node.empty()) return;
      const near = node.closedNeighborhood();
      cy.elements().not(near).addClass("faded");
      near.addClass("near");
      // 变淡的路标不写名称；邻居先写选中点自己的，其余名称会重叠就不写，详情面板里有完整的关系列表
      cy.nodes(".hub").not(near).addClass("quiet");
      pickLabels(cy, [node, ...near.nodes().not(node)], Infinity).forEach((n) => n.addClass("labeled"));
      node.select();
    });
  }, [selected, cacheKey]);

  useEffect(() => {
    const cy = cyRef.current;
    cy.batch(() => cy.nodes().forEach((n) => n.style("display", hidden.has(n.data("group")) ? "none" : "element")));
  }, [hidden, cacheKey]);

  const toggle = (id) => setHidden((s) => { const n = new Set(s); if (n.has(id)) n.delete(id); else n.add(id); return n; });
  const allOn = hidden.size === 0;
  const inGraph = typeof selected === "number" && nodes.some((n) => n.i === selected);
  return (
    <div className="graph-wrap">
      <div className="graph-area">
        <div className="graph" ref={box} data-ui={ui + ".graph"} />
        <button className="graph-clear" disabled={!inGraph} onClick={() => onSelect(null)} data-ui={ui + ".graph-clear"}>取消选中（Esc）</button>
      </div>
      <div className="legend" data-ui={ui + ".legend"}>
        <label className="legend-row">
          <input type="checkbox" checked={allOn} onChange={() => setHidden(allOn ? new Set(legend.map((g) => g.id)) : new Set())} />
          <span className="legend-name">全部分组</span><span className="count">{nodes.length}</span>
        </label>
        {legend.map((g) => (
          <label className="legend-row" key={g.id}>
            <input type="checkbox" checked={!hidden.has(g.id)} onChange={() => toggle(g.id)} />
            <span className="dot" style={{ background: `var(${g.color})` }} aria-hidden="true"></span>
            <span className="legend-name">{g.name}</span><span className="count">{g.count}</span>
          </label>
        ))}
      </div>
    </div>
  );
}
