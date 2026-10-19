import { useEffect, useMemo, useRef, useState } from "react";
import { IconChevronDown, IconChevronRight } from "@tabler/icons-react";
import cytoscape from "cytoscape";
import fcose from "cytoscape-fcose";

cytoscape.use(fcose);

// 每张图第一次布局后记下位置和展开的分组（按 cacheKey 区分），切换视图再回来时保持不变
const positions = new Map();
const unfolded = new Map();

// 打开图之前先展开某个分组，例如首页点流程图的一步，跳到开发场景并展开对应的分类
export function unfoldGroup(cacheKey, id) {
  unfolded.set(cacheKey, new Set(unfolded.get(cacheKey)).add(id));
}

const css = (name) => getComputedStyle(document.documentElement).getPropertyValue(name).trim();

// 斥力大、理想边长长、引力小，点才散得开，名称不叠在一起
const FCOSE = { name: "fcose", animate: false, quality: "proof", nodeRepulsion: 45000, idealEdgeLength: 140,
  edgeElasticity: 0.3, gravity: 0.05, nodeSeparation: 120, numIter: 4000 };

// 按顺序挑要写名称的点，最多 limit 个；名称会和已挑的重叠就跳过
function pickLabels(cy, list, limit) {
  const z = cy.zoom(), boxes = [], picked = [];
  for (const n of list) {
    if (picked.length === limit) break;
    const { x, y } = n.position();
    const fs = parseFloat(css("--fs"));
    const w = (n.data("label").length * fs + 8) / z, h = (fs + 9) / z, top = y + n.data("size") / 2;
    const box = [x - w / 2, top, x + w / 2, top + h];
    if (boxes.some((b) => box[0] < b[2] && b[0] < box[2] && box[1] < b[3] && b[1] < box[3])) continue;
    boxes.push(box); picked.push(n);
  }
  return picked;
}

const foldTip = "只看邻居时不能折叠，先返回全图";

function style(legend, directed) {
  const colors = Object.fromEntries(legend.map((g) => [g.id, css(g.color)]));
  const edgeColor = (e) => colors[e.source().data("group")];
  // 写出的名称按缩放反算字号，屏幕上始终和正文一样大（设置里的字号），缩得再小也看得清
  const fs = parseFloat(css("--fs")), small = parseFloat(css("--fs-small"));
  const label = { label: "data(label)", "font-size": (n) => fs / n.cy().zoom(), "min-zoomed-font-size": 0,
    "text-margin-y": (n) => 3 / n.cy().zoom(), "text-background-padding": (n) => 2 / n.cy().zoom() };
  return [
    { selector: "node", style: {
      "background-color": (n) => colors[n.data("group")], width: "data(size)", height: "data(size)", "border-width": 0,
      label: "", color: css("--fg"), "font-size": fs, "min-zoomed-font-size": 9, "font-family": "Segoe UI, Microsoft YaHei UI, sans-serif",
      "text-valign": "bottom", "text-margin-y": 3, "text-background-color": css("--bg"), "text-background-opacity": 1, "text-background-padding": 2,
    } },
    { selector: "edge", style: directed
      ? { width: 1, "line-color": edgeColor, opacity: 0.35, "curve-style": "bezier", "line-style": "dashed", "line-dash-pattern": [6, 4],
        "target-arrow-shape": "triangle", "target-arrow-color": edgeColor, "arrow-scale": 0.8 }
      : { width: 1, "line-color": edgeColor, opacity: 0.35, "curve-style": "haystack" } },
    // 合并后的连线写条数
    { selector: "edge[?label]", style: { label: "data(label)", color: css("--muted-fg"), "font-size": (e) => small / e.cy().zoom(), "min-zoomed-font-size": 0,
      "text-background-color": css("--bg"), "text-background-opacity": 1, "text-background-padding": (e) => 1 / e.cy().zoom() } },
    // 主线画成强调色实线，比其他线粗
    { selector: "edge.main", style: { "line-style": "solid", "line-color": css("--brand"), "target-arrow-color": css("--brand"), width: 3, opacity: 0.9 } },
    // 折叠后的大点和连到它的线按缩放反算尺寸，缩小看全貌时也看得清；线越粗，合并的连线越多
    { selector: "node.group", style: { ...label, "font-weight": 600, opacity: 0.85,
      width: (n) => n.data("size") / n.cy().zoom(), height: (n) => n.data("size") / n.cy().zoom() } },
    { selector: "edge.merged", style: { width: (e) => (0.5 + Math.sqrt(e.data("count")) * 0.6) / e.cy().zoom(), opacity: 0.5,
      "line-dash-pattern": (e) => [6 / e.cy().zoom(), 4 / e.cy().zoom()], "arrow-scale": 1 } },
    { selector: ".faded", style: { opacity: 0.08 } },
    { selector: "edge.near", style: { opacity: 0.9, width: 2 } },
    { selector: "edge.main.near", style: { width: 4 } },
    { selector: "edge.merged.main", style: { width: (e) => (1.5 + Math.sqrt(e.data("count")) * 0.6) / e.cy().zoom(), opacity: 0.9 } },
    { selector: "node.hub, node.labeled, node:selected", style: label },
    // 关系说明只在选中点的连线上写，全写出来会盖住整张图
    { selector: "edge.near[?rel]", style: { label: "data(rel)", color: css("--muted-fg"), "font-size": (e) => small / e.cy().zoom(), "min-zoomed-font-size": 0,
      "text-background-color": css("--bg"), "text-background-opacity": 1, "text-background-padding": (e) => 1 / e.cy().zoom(), "text-rotation": "autorotate" } },
    { selector: "node.quiet", style: { label: "" } },
    { selector: "node:selected", style: { "border-width": 2, "border-color": css("--ring") } },
  ];
}

// 可以折叠的图分两层排布：先在每个分组内部排好，再按各组的范围大小把分组排开，最后把每组整体挪到分组的位置。
// 这样各组不重叠，折叠后的大点正好落在本组的中心
function layoutByGroup(cy, legend) {
  const boxes = legend.map((g) => {
    const members = cy.nodes().filter((n) => n.data("group") === g.id);
    members.union(members.edgesWith(members)).layout({ ...FCOSE, fit: false }).run();
    return { members, bb: members.boundingBox() };
  });
  const temp = cy.add([
    ...legend.map((g, k) => ({ data: { id: "t" + k, group: g.id, size: Math.max(boxes[k].bb.w, boxes[k].bb.h) + 80 } })),
    ...[...new Set(cy.edges().map((e) => legend.findIndex((g) => g.id === e.source().data("group")) + "-" + legend.findIndex((g) => g.id === e.target().data("group"))))]
      .map((key) => key.split("-")).filter(([a, b]) => a !== b).map(([a, b]) => ({ data: { id: "te" + a + "-" + b, source: "t" + a, target: "t" + b } })),
  ]);
  temp.layout({ ...FCOSE, fit: false, nodeRepulsion: 450000, idealEdgeLength: 200 }).run();
  boxes.forEach(({ members, bb }, k) => {
    const to = cy.getElementById("t" + k).position();
    members.shift({ x: to.x - (bb.x1 + bb.x2) / 2, y: to.y - (bb.y1 + bb.y2) / 2 });
  });
  cy.remove(temp);
}

// 关系图谱：点按链接自动连线，颜色按分组；点一个点，只突出它和直接相连的点。
// 点空白处不取消选中，因为误点大多落在空白处；按 Esc、再点一次选中的点或点“取消选中”才退出。
// nodes 的 i 是选中值（卡片编号或 "doc:编号" 这类字符串），选中时交给 onSelect；edges 里 main 为真的画成主线，label 是关系说明。nodes、edges、legend、landmarks 要在模块里算好，不随渲染变化。
// foldable：分组可以折叠成一个大点，默认全部折叠。focusable：可以只看选中点几跳以内的邻居。
export default function Graph({ cacheKey, nodes, edges, legend, landmarks, landmarkLimit = 15, directed = false, foldable = false, focusable = false,
  selected, onSelect, theme, font, ui }) {
  const tipRef = useRef(null);
  const box = useRef(null), cyRef = useRef(null), selectedRef = useRef(selected), focusRef = useRef(null), viewRef = useRef(null);
  selectedRef.current = selected;
  const [hidden, setHidden] = useState(() => new Set());
  const [expanded, setExpanded] = useState(() => unfolded.get(cacheKey) ?? new Set(foldable ? [] : legend.map((g) => g.id)));
  const [focus, setFocus] = useState(null);
  const [hops, setHops] = useState(2);
  const groupOf = useMemo(() => Object.fromEntries(nodes.map((n) => [n.i, n.group])), [nodes]);
  const neighbours = useMemo(() => {
    const m = new Map(nodes.map((n) => [n.i, new Set()]));
    for (const e of edges) { m.get(e.from).add(e.to); m.get(e.to).add(e.from); }
    return m;
  }, [nodes, edges]);

  useEffect(() => {
    const saved = positions.get(cacheKey);
    const cy = cytoscape({
      container: box.current,
      elements: nodes.map((n) => ({ data: { id: "n" + n.i, key: n.i, label: n.label, group: n.group, size: n.size }, position: saved?.[n.i] })),
      style: style(legend, directed),
      layout: { name: "preset" },
      minZoom: 0.1, maxZoom: 4, boxSelectionEnabled: false,
    });
    // 第一次布局：先带上全部连线排布，之后连线按折叠状态重画
    if (!saved) {
      cy.add(edges.map((e) => ({ data: { id: "e" + e.from + "-" + e.to, source: "n" + e.from, target: "n" + e.to } })));
      if (foldable) layoutByGroup(cy, legend); else cy.layout(FCOSE).run();
      cy.edges().remove();
      cy.fit(undefined, 30);
    }
    const record = Object.fromEntries(nodes.map((n) => [n.i, { ...cy.getElementById("n" + n.i).position() }]));
    positions.set(cacheKey, record);
    // 分组的大点放在组内场景的中心，不能拖动，因为位置跟着组内场景算
    if (foldable) {
      cy.add(legend.map((g, k) => ({ data: { id: "g" + k, label: `${g.name}（${g.count}）`, group: g.id, size: 16 + Math.sqrt(g.count) * 5 },
        classes: "group", grabbable: false })));
    }
    // 邻居视图里排布是临时的，拖动不记下
    cy.on("dragfree", "node", (e) => { if (!focusRef.current) record[e.target.data("key")] = { ...e.target.position() }; });
    cy.on("tap", "node", (e) => {
      if (e.target.hasClass("group")) { const id = e.target.data("group"); setExpanded((s) => new Set(s).add(id)); return; }
      const key = e.target.data("key");
      onSelect(key === selectedRef.current ? null : key);
    });
    cy.on("zoom", () => cy.elements(".hub, .labeled, :selected, .group, .merged, edge[?label], edge.near").updateStyle());
    // 悬停一个点 400ms 后在它下方显示名称，没写名称的点也能认出来；移动视口或点击时收起
    // 提示元素先记下来：卸载时 React 已经清空 tipRef，清理函数里还要用它
    let tipTimer = 0;
    const tip = tipRef.current;
    const hideTip = () => { clearTimeout(tipTimer); tip.hidden = true; };
    cy.on("mouseover", "node", (e) => {
      if (e.target.hasClass("group")) return;
      hideTip();
      tipTimer = setTimeout(() => {
        const bb = e.target.renderedBoundingBox({ includeLabels: false }), r = box.current.getBoundingClientRect();
        tip.textContent = e.target.data("label"); tip.hidden = false;
        tip.style.left = Math.max(8, Math.min(r.left + (bb.x1 + bb.x2) / 2 - tip.offsetWidth / 2, innerWidth - tip.offsetWidth - 8)) + "px";
        tip.style.top = (r.top + bb.y2 + 6) + "px";
      }, 400);
    });
    cy.on("mouseout", "node", hideTip);
    cy.on("viewport tapstart", hideTip);
    cyRef.current = cy;
    // 拖动详情面板改宽度、开合面板时画布尺寸会变，cytoscape 只监听窗口尺寸，要手动通知
    const resize = new ResizeObserver(() => cy.resize());
    resize.observe(box.current);
    return () => { hideTip(); resize.disconnect(); cy.destroy(); };
  }, [cacheKey, nodes, edges, legend, directed, foldable, onSelect]);

  useEffect(() => { cyRef.current.style(style(legend, directed)); }, [theme, font, legend, directed]);
  useEffect(() => { unfolded.set(cacheKey, expanded); }, [cacheKey, expanded]);

  const inGraph = selected !== null && Object.hasOwn(groupOf, selected);
  // 邻居视图里留下的点：中心点几跳以内
  const within = useMemo(() => {
    if (!focus) return null;
    const seen = new Set([focus.center]);
    let ring = [focus.center];
    for (let k = 0; k < focus.hops; k++) ring = ring.flatMap((i) => [...neighbours.get(i)].filter((j) => !seen.has(j) && seen.add(j)));
    return seen;
  }, [focus, neighbours]);
  // 选中的场景在折叠的分组里时（例如从搜索选中），展开它所在的分组；取消选中时退出邻居视图；
  // 邻居视图里选中了范围外的点（例如从详情面板的链接），以它为中心重排
  useEffect(() => {
    if (inGraph && !expanded.has(groupOf[selected])) setExpanded((s) => new Set(s).add(groupOf[selected]));
    if (!inGraph && focus) setFocus(null);
    if (inGraph && within && !within.has(selected)) setFocus({ ...focus, center: selected });
  }, [selected]);

  // 按折叠状态、隐藏的分组和邻居视图决定显示哪些点，再重画连线：
  // 每条连线的两端换成实际显示的点（场景本身或它折叠后的大点），同一对点之间的连线合并成一条
  useEffect(() => {
    const cy = cyRef.current, record = positions.get(cacheKey);
    const shown = (i) => !hidden.has(groupOf[i]) && (within ? within.has(i) : expanded.has(groupOf[i]));
    const groupIndex = Object.fromEntries(legend.map((g, k) => [g.id, k]));
    const folded = (g) => foldable && !within && !hidden.has(g) && !expanded.has(g);
    const end = (i) => (shown(i) ? "n" + i : folded(groupOf[i]) ? "g" + groupIndex[groupOf[i]] : null);
    const merged = new Map();
    for (const e of edges) {
      const s = end(e.from), t = end(e.to);
      if (!s || !t || s === t) continue;
      const m = merged.get(s + "|" + t) || { s, t, count: 0, main: false, rel: [] };
      m.count += 1; m.main ||= Boolean(e.main);
      if (e.label && !m.rel.includes(e.label)) m.rel.push(e.label);
      merged.set(s + "|" + t, m);
    }
    const entering = within && !focusRef.current, leaving = !within && focusRef.current;
    if (entering) viewRef.current = { zoom: cy.zoom(), pan: { ...cy.pan() } };
    focusRef.current = focus;
    cy.batch(() => {
      cy.edges().remove();
      for (const n of nodes) {
        const node = cy.getElementById("n" + n.i);
        node.style("display", shown(n.i) ? "element" : "none");
        if (leaving) node.position(record[n.i]);
      }
      legend.forEach((g, k) => {
        const node = cy.getElementById("g" + k);
        if (node.empty()) return;
        node.style("display", folded(g.id) ? "element" : "none");
        const members = nodes.filter((n) => n.group === g.id).map((n) => record[n.i]);
        node.position({ x: members.reduce((a, p) => a + p.x, 0) / members.length, y: members.reduce((a, p) => a + p.y, 0) / members.length });
      });
      cy.add([...merged.values()].map((m) => ({ data: { id: "e" + m.s + "-" + m.t, source: m.s, target: m.t, count: m.count, label: m.count > 1 ? String(m.count) : "", rel: m.rel.join("；") },
        classes: [m.main && "main", (m.s[0] === "g" || m.t[0] === "g") && "merged"].filter(Boolean).join(" ") })));
    });
    // 邻居视图只排布留下的场景；回到全图时恢复原来的位置和视口
    // 边距按最长的名称算，名称按屏幕像素写，边缘的点名称才不被画布裁掉
    if (within) {
      const kept = cy.nodes().filter((n) => n.style("display") === "element");
      const longest = Math.max(...kept.map((n) => n.data("label").length));
      kept.union(kept.edgesWith(kept)).layout({ ...FCOSE, fit: true, padding: Math.max(40, longest * parseFloat(css("--fs")) / 2 + 8) }).run();
    } else if (leaving && viewRef.current) cy.viewport(viewRef.current);
    // 路标在显示出来的点里挑，所以展开一个分组后，组里的点也写出名称
    if (!within) {
      cy.nodes(".hub").removeClass("hub");
      pickLabels(cy, landmarks.map((i) => cy.getElementById("n" + i)).filter((n) => n.nonempty() && n.style("display") === "element"), landmarkLimit).forEach((n) => n.addClass("hub"));
    }
  }, [cacheKey, nodes, edges, legend, landmarks, landmarkLimit, foldable, groupOf, expanded, hidden, within]);

  // 选中的点突出它的直接邻居，其余变淡；只改样式，不移动视口。选中的不是图里的点时，图保持原样
  useEffect(() => {
    const cy = cyRef.current;
    cy.batch(() => {
      cy.elements().removeClass("faded near labeled quiet").unselect();
      const node = inGraph ? cy.getElementById("n" + selected) : cy.collection();
      if (node.empty()) return;
      const near = node.closedNeighborhood();
      near.addClass("near");
      // 邻居视图里留下的都是要看的点，不变淡；不超过 20 个点时全部写名称，多了在全部留下的点里挑
      const kept = focus ? cy.nodes(":visible").not(".group") : cy.collection();
      if (!focus) cy.elements().not(near).addClass("faded");
      // 变淡的路标不写名称；邻居先写选中点自己的，其余名称会重叠就不写，详情面板里有完整的关系列表
      cy.nodes(".hub").not(near).addClass("quiet");
      if (focus && kept.length <= 20) kept.addClass("labeled");
      else pickLabels(cy, [node, ...near.nodes().not(node).not(".group"), ...kept.not(near)], Infinity).forEach((n) => n.addClass("labeled"));
      node.select();
    });
  }, [selected, cacheKey, inGraph, expanded, hidden, focus]);

  const toggleHidden = (id) => setHidden((s) => { const n = new Set(s); if (n.has(id)) n.delete(id); else n.add(id); return n; });
  const toggleFold = (id) => setExpanded((s) => { const n = new Set(s); if (n.has(id)) n.delete(id); else n.add(id); return n; });
  const allOn = hidden.size === 0;
  return (
    <div className="graph-wrap">
      <div className="graph-area">
        <div className="graph" ref={box} data-ui={ui + ".graph"} />
        <div className="tip" role="tooltip" hidden ref={tipRef} data-pick-ignore />
        <div className="graph-tools">
          {/* 不可用时用 aria-disabled 置灰，不用 disabled：禁用的按钮收不到点击和悬停，元素选取复制不了，也显示不了提示 */}
          <button className="graph-btn" aria-disabled={!inGraph} data-tip={inGraph ? undefined : "先在图里选中一个点"}
            onClick={() => { if (inGraph) onSelect(null); }} data-ui={ui + ".graph-clear"}>取消选中（Esc）</button>
          {focusable && (
            <>
              <button className="graph-btn graph-focus" aria-disabled={!inGraph} aria-pressed={Boolean(focus)} data-ui={ui + ".graph-focus"}
                data-tip={inGraph ? undefined : "先在图里选中一个点"} onClick={() => { if (inGraph) setFocus(focus ? null : { center: selected, hops }); }}>{focus ? "返回全图" : "只看邻居"}</button>
              <div className="segmented" role="tablist" aria-label="邻居范围" data-ui={ui + ".graph-hops"}>
                {[1, 2].map((h) => (
                  <button key={h} role="tab" aria-selected={hops === h}
                    onClick={() => { setHops(h); if (focus) setFocus({ ...focus, hops: h }); }}>{h} 跳</button>
                ))}
              </div>
            </>
          )}
        </div>
      </div>
      <div className="legend" data-ui={ui + ".legend"}>
        <label className="legend-row">
          <input type="checkbox" checked={allOn} onChange={() => setHidden(allOn ? new Set(legend.map((g) => g.id)) : new Set())} />
          <span className="legend-name">全部分组</span><span className="count">{nodes.length}</span>
        </label>
        {foldable && (
          <div className="legend-actions">
            <button className="graph-btn" aria-disabled={Boolean(focus)} data-tip={focus ? foldTip : undefined} onClick={() => { if (!focus) setExpanded(new Set(legend.map((g) => g.id))); }}>全部展开</button>
            <button className="graph-btn" aria-disabled={Boolean(focus)} data-tip={focus ? foldTip : undefined} onClick={() => { if (!focus) setExpanded(new Set()); }}>全部折叠</button>
          </div>
        )}
        {legend.map((g) => (
          <div className="legend-row" key={g.id}>
            {foldable && (
              <button className="twisty" aria-disabled={Boolean(focus)} aria-label={(expanded.has(g.id) ? "折叠" : "展开") + g.name} aria-expanded={expanded.has(g.id)}
                data-tip={focus ? foldTip : undefined} onClick={() => { if (!focus) toggleFold(g.id); }}>
                {expanded.has(g.id) ? <IconChevronDown aria-hidden="true" /> : <IconChevronRight aria-hidden="true" />}
              </button>
            )}
            <label className="legend-label">
              <input type="checkbox" checked={!hidden.has(g.id)} onChange={() => toggleHidden(g.id)} />
              <span className="dot" style={{ background: `var(${g.color})` }} aria-hidden="true"></span>
              <span className="legend-name">{g.name}</span><span className="count">{g.count}</span>
            </label>
          </div>
        ))}
      </div>
    </div>
  );
}
