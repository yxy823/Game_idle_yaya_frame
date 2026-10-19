import { useEffect, useRef, useState } from "react";
import cytoscape from "cytoscape";
import fcose from "cytoscape-fcose";
import { files, groups, incoming, links } from "./docs.js";

cytoscape.use(fcose);

// 两份文档之间有多条链接时只画一条线；链到自己的不画
const edges = [...new Set(links.filter((l) => l.from !== l.to).map((l) => l.from + "-" + l.to))]
  .map((key) => { const [from, to] = key.split("-"); return { data: { id: "e" + key, source: "n" + from, target: "n" + to } }; });
const counts = Object.fromEntries(groups.map((g) => [g.id, files.filter((f) => f.group === g.id).length]));

// 第一次布局后记下位置，切换视图再回来时位置不变
let positions = null;

const css = (name) => getComputedStyle(document.documentElement).getPropertyValue(name).trim();

function style() {
  const colors = Object.fromEntries(groups.map((g) => [g.id, css("--g-" + g.id)]));
  return [
    { selector: "node", style: {
      "background-color": (n) => colors[n.data("group")], width: "data(size)", height: "data(size)", "border-width": 0,
      label: "", color: css("--fg"), "font-size": 11, "font-family": "Segoe UI, Microsoft YaHei UI, sans-serif",
      "text-valign": "bottom", "text-margin-y": 3, "text-background-color": css("--bg"), "text-background-opacity": 0.8, "text-background-padding": 1,
    } },
    { selector: "edge", style: {
      width: 0.6, "line-color": (e) => colors[e.source().data("group")], opacity: 0.35, "curve-style": "haystack",
    } },
    { selector: ".faded", style: { opacity: 0.08 } },
    { selector: "edge.near", style: { opacity: 0.9, width: 1.2 } },
    { selector: "node.labeled", style: { label: "data(label)" } },
    { selector: "node:selected", style: { label: "data(label)", "border-width": 2, "border-color": css("--ring") } },
  ];
}

// 文件全景的图谱视图：全部文档按链接自动连线，颜色按分组；点一个点，只突出它和直接相连的文档。
export default function Graph({ selected, onSelect, theme }) {
  const box = useRef(null), cyRef = useRef(null);
  const [hidden, setHidden] = useState(() => new Set());

  useEffect(() => {
    const cy = cytoscape({
      container: box.current,
      elements: [
        ...files.map((f, i) => ({ data: { id: "n" + i, label: f.title, group: f.group, size: 6 + Math.sqrt(incoming[i].length) * 2.5 },
          position: positions?.[i] })),
        ...edges,
      ],
      style: style(),
      layout: positions ? { name: "preset" } : { name: "fcose", animate: false, quality: "default", nodeRepulsion: 6000, idealEdgeLength: 60 },
      minZoom: 0.1, maxZoom: 4, wheelSensitivity: 0.3, boxSelectionEnabled: false, autoungrabify: false,
    });
    positions = files.map((_, i) => ({ ...cy.getElementById("n" + i).position() }));
    cy.on("dragfree", "node", (e) => { positions[Number(e.target.id().slice(1))] = { ...e.target.position() }; });
    cy.on("tap", "node", (e) => onSelect(Number(e.target.id().slice(1))));
    cy.on("tap", (e) => { if (e.target === cy) onSelect(null); });
    cyRef.current = cy;
    return () => cy.destroy();
  }, [onSelect]);

  useEffect(() => { cyRef.current.style(style()); }, [theme]);

  // 选中的点突出它的直接邻居，其余变淡；只改样式，不移动视口
  useEffect(() => {
    const cy = cyRef.current;
    cy.batch(() => {
      cy.elements().removeClass("faded near labeled").unselect();
      if (selected === null) return;
      const node = cy.getElementById("n" + selected);
      const near = node.closedNeighborhood();
      cy.elements().not(near).addClass("faded");
      near.addClass("near");
      // 邻居太多时名称会叠成一片，只写选中点自己的名称
      if (near.nodes().length <= 30) near.nodes().addClass("labeled");
      node.select();
    });
  }, [selected]);

  useEffect(() => {
    const cy = cyRef.current;
    cy.batch(() => cy.nodes().forEach((n) => n.style("display", hidden.has(n.data("group")) ? "none" : "element")));
  }, [hidden]);

  const toggle = (id) => setHidden((s) => { const n = new Set(s); if (n.has(id)) n.delete(id); else n.add(id); return n; });
  const allOn = hidden.size === 0;
  return (
    <div className="graph-wrap">
      <div className="graph" ref={box} data-ui="files.graph" />
      <div className="legend" data-ui="files.legend">
        <label className="legend-row">
          <input type="checkbox" checked={allOn} onChange={() => setHidden(allOn ? new Set(groups.map((g) => g.id)) : new Set())} />
          <span className="legend-name">全部分组</span><span className="count">{files.length}</span>
        </label>
        {groups.filter((g) => counts[g.id]).map((g) => (
          <label className="legend-row" key={g.id}>
            <input type="checkbox" checked={!hidden.has(g.id)} onChange={() => toggle(g.id)} />
            <span className={"dot g-" + g.id} aria-hidden="true"></span>
            <span className="legend-name">{g.name}</span><span className="count">{counts[g.id]}</span>
          </label>
        ))}
      </div>
    </div>
  );
}
