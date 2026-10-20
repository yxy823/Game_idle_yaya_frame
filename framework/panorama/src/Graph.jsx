import { useEffect, useMemo, useRef, useState } from "react";
import { IconChevronsDown, IconFolder, IconFolderOpen, IconChevronsUp, IconLayoutSidebarRightCollapse, IconLayoutSidebarRightExpand } from "@tabler/icons-react";
import cytoscape from "cytoscape";
import fcose from "cytoscape-fcose";
import { store } from "./store.js";

cytoscape.use(fcose);

// 每张图第一次布局后记下位置和展开的分组（按 cacheKey 区分），切换视图再回来时保持不变
const positions = new Map();
const unfolded = new Map();

// 打开图之前先展开某个分组，例如首页点流程图的一步，跳到开发场景并展开对应的分类
export function unfoldGroup(cacheKey, id) {
  unfolded.set(cacheKey, new Set(unfolded.get(cacheKey)).add(id));
}

// 打开图时直接进入一个分组的邻居视图：只留组内的点和与它们直接相连的点。首页点流程图的一步用它，跳过去就能看出这一步在图里的范围
const pendingFocus = new Map();
export function focusGroup(cacheKey, id) {
  pendingFocus.set(cacheKey, id);
}

const css = (name) => getComputedStyle(document.documentElement).getPropertyValue(name).trim();

// 斥力大、理想边长长、引力小，点才散得开，名称不叠在一起
const FCOSE = { name: "fcose", animate: false, quality: "proof", nodeRepulsion: 45000, idealEdgeLength: 140,
  edgeElasticity: 0.3, gravity: 0.05, nodeSeparation: 120, numIter: 4000 };
const MIN_SCALE = 0.5;
// 分类的大点一直写名称；和已写的名称重叠、或超出画布会被裁掉时只写条数，条数也放不下时不写，悬停都能看全名。按场景数从多到少挑，大的分类先写全名。
// 名称按屏幕像素写，重叠与否随缩放变，所以缩放后重挑；名称的范围用 cytoscape 实际排出的文字量
function shortenGroupLabels(cy) {
  const ext = cy.extent(), boxes = [];
  const groups = cy.nodes(".group").filter((n) => n.style("display") === "element").sort((a, b) => b.data("count") - a.data("count"));
  const box = (n) => { const b = n.boundingBox({ includeNodes: false, includeEdges: false, includeLabels: true }); return [b.x1, b.y1, b.x2, b.y2]; };
  const hit = (b) => boxes.some((o) => b[0] < o[2] && o[0] < b[2] && b[1] < o[3] && o[1] < b[3]) || b[0] < ext.x1 || b[2] > ext.x2 || b[3] > ext.y2;
  groups.removeClass("short bare");
  groups.forEach((n) => {
    if (hit(box(n))) n.addClass("short");
    if (n.hasClass("short") && hit(box(n))) n.addClass("bare");
    else boxes.push(box(n));
  });
}

// 一组点的中心，分组的大点放在这里
const centre = (ps) => ({ x: ps.reduce((a, p) => a + p.x, 0) / ps.length, y: ps.reduce((a, p) => a + p.y, 0) / ps.length });

// 按顺序挑要写名称的点，最多 limit 个；名称会和已挑的重叠、或超出画布被裁掉就跳过。
// keepFirst 为真时第一个点（选中的点）一定写名称
function pickLabels(cy, list, limit, keepFirst = false) {
  const z = cy.zoom(), ext = cy.extent(), boxes = [], picked = [];
  for (const n of list) {
    if (picked.length === limit) break;
    const { x, y } = n.position();
    const fs = parseFloat(css("--fs"));
    const w = (n.data("label").length * fs + 8) / z, h = (fs + 9) / z, top = y + n.height() / 2;
    const box = [x - w / 2, top, x + w / 2, top + h];
    if (boxes.some((b) => box[0] < b[2] && b[0] < box[2] && box[1] < b[3] && b[1] < box[3])) continue;
    if (!(keepFirst && !picked.length) && (box[0] < ext.x1 || box[2] > ext.x2 || box[3] > ext.y2)) continue;
    boxes.push(box); picked.push(n);
  }
  return picked;
}


function style(legend, directed, foldable) {
  const colors = Object.fromEntries(legend.map((g) => [g.id, css(g.color)]));
  // 普通连线用中性色，选中点的连线换成来源分组的颜色；取值在 tokens.css。
  // 连线的透明度用 line-opacity，只淡化线，线上的条数和关系说明保持不透明，才读得清
  const edgeColor = css("--graph-edge"), edgeOpacity = parseFloat(css("--graph-edge-opacity")), mainColor = css("--graph-edge-main");
  const groupColor = (e) => colors[e.source().data("group")];
  // 写出的名称按缩放反算字号，屏幕上始终和正文一样大（设置里的字号），缩得再小也看得清
  const fs = parseFloat(css("--fs")), small = parseFloat(css("--fs-small"));
  const label = { label: "data(label)", "font-size": (n) => fs / n.cy().zoom(), "min-zoomed-font-size": 0,
    "text-margin-y": (n) => 3 / n.cy().zoom(), "text-background-padding": (n) => 2 / n.cy().zoom() };
  return [
    { selector: "node", style: {
      "background-color": (n) => colors[n.data("group")], width: "data(size)", height: "data(size)",
      // 浅色的分类色和背景对比不足，加一圈屏幕上 1px 的轮廓；颜色取 tokens.css
      "border-width": (n) => 1 / n.cy().zoom(), "border-color": css("--graph-node-border"),
      label: "", color: css("--fg"), "font-size": fs, "min-zoomed-font-size": 9, "font-family": "Segoe UI, Microsoft YaHei UI, sans-serif",
      "text-valign": "bottom", "text-margin-y": 3, "text-background-color": css("--bg"), "text-background-opacity": 1, "text-background-padding": 2,
    } },
    // 可折叠的图缩得很小时，展开后的场景按屏幕像素保底，不小于本身尺寸的一半，和折叠后的大点差得不太悬殊
    ...(foldable ? [{ selector: "node", style: {
      width: (n) => Math.max(n.data("size"), n.data("size") * MIN_SCALE / n.cy().zoom()),
      height: (n) => Math.max(n.data("size"), n.data("size") * MIN_SCALE / n.cy().zoom()) } }] : []),
    { selector: "edge", style: directed
      ? { width: 1, "line-color": edgeColor, "line-opacity": edgeOpacity, "curve-style": "bezier", "line-style": "dashed", "line-dash-pattern": [6, 4],
        "target-arrow-shape": "triangle", "target-arrow-color": edgeColor, "arrow-scale": 0.8 }
      : { width: 1, "line-color": edgeColor, "line-opacity": edgeOpacity, "curve-style": "haystack" } },
    // 合并后的连线写条数
    { selector: "edge[?label]", style: { label: "data(label)", color: css("--muted-fg"), "font-size": (e) => small / e.cy().zoom(), "min-zoomed-font-size": 0,
      "text-background-color": css("--bg"), "text-background-opacity": 1, "text-background-padding": (e) => 1 / e.cy().zoom() } },
    // 主线画成强调色实线，比其他线粗
    { selector: "edge.main", style: { "line-style": "solid", "line-color": mainColor, "target-arrow-color": mainColor, width: 3, "line-opacity": 0.9 } },
    // 折叠后的大点和连到它的线按缩放反算尺寸，缩小看全貌时也看得清；线越粗，合并的连线越多
    { selector: "node.group", style: { ...label, "font-weight": 600, opacity: 0.85,
      width: (n) => n.data("size") / n.cy().zoom(), height: (n) => n.data("size") / n.cy().zoom() } },
    { selector: "node.group.short", style: { label: "data(short)" } },
    { selector: "node.group.bare", style: { label: "" } },
    { selector: "edge.merged", style: { width: (e) => (0.5 + Math.sqrt(e.data("count")) * 0.6) / e.cy().zoom(), "line-opacity": 0.5,
      "line-dash-pattern": (e) => [6 / e.cy().zoom(), 4 / e.cy().zoom()], "arrow-scale": 1 } },
    { selector: ".faded", style: { opacity: 0.08 } },
    { selector: "edge.near", style: { "line-opacity": 0.9, width: 2, "line-color": groupColor, "target-arrow-color": groupColor } },
    { selector: "edge.main.near", style: { width: 4, "line-color": mainColor, "target-arrow-color": mainColor } },
    { selector: "edge.merged.main", style: { width: (e) => (1.5 + Math.sqrt(e.data("count")) * 0.6) / e.cy().zoom(), "line-opacity": 0.9 } },
    { selector: "node.hub, node.labeled, node.chosen", style: label },
    // 关系说明只在选中点的连线上写，全写出来会盖住整张图
    { selector: "edge.near[?rel]", style: { label: "data(rel)", color: css("--muted-fg"), "font-size": (e) => small / e.cy().zoom(), "min-zoomed-font-size": 0,
      "text-background-color": css("--bg"), "text-background-opacity": 1, "text-background-padding": (e) => 1 / e.cy().zoom(), "text-rotation": "autorotate" } },
    { selector: "node.quiet", style: { label: "" } },
    { selector: "node.chosen", style: { "border-width": (n) => 2 / n.cy().zoom(), "border-color": css("--ring") } },
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
  // 图例收起后只留开关，各图谱共用这一个设置
  const [legendOpen, setLegendOpen] = useState(() => store.get("legend") !== "closed");
  const [expanded, setExpanded] = useState(() => unfolded.get(cacheKey) ?? new Set(foldable ? [] : legend.map((g) => g.id)));
  // 邻居视图：center 是选中的点；group 是整个分组（从首页进入），这时以组内全部的点为中心
  const [focus, setFocus] = useState(() => {
    const group = pendingFocus.get(cacheKey);
    pendingFocus.delete(cacheKey);
    return group ? { group, hops: 1 } : null;
  });
  const [hops, setHops] = useState(() => focus?.hops ?? 2);
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
      style: style(legend, directed, foldable),
      layout: { name: "preset" },
      minZoom: 0.1, maxZoom: 4, boxSelectionEnabled: false,
      // 选中描边用 chosen 类，跟页面的选中值走；cytoscape 自带的选中在点空白处时会自己取消，和详情面板对不上，所以关掉
      autounselectify: true,
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
      cy.add(legend.map((g, k) => ({ data: { id: "g" + k, label: `${g.name}（${g.count}）`, short: `（${g.count}）`, count: g.count, group: g.id, size: 16 + Math.sqrt(g.count) * 5 },
        classes: "group", grabbable: false })));
    }
    // 邻居视图里排布是临时的，拖动不记下
    cy.on("dragfree", "node", (e) => { if (!focusRef.current) record[e.target.data("key")] = { ...e.target.position() }; });
    cy.on("tap", "node", (e) => {
      if (e.target.hasClass("group")) { const id = e.target.data("group"); setExpanded((s) => new Set(s).add(id)); return; }
      const key = e.target.data("key");
      onSelect(key === selectedRef.current ? null : key);
    });
    cy.on("zoom", () => { cy.elements("node, .merged, edge[?label], edge.near").updateStyle(); if (foldable) shortenGroupLabels(cy); });
    // 悬停一个点 400ms 后在它下方显示名称，没写名称的点也能认出来；移动视口或点击时收起
    // 提示元素先记下来：卸载时 React 已经清空 tipRef，清理函数里还要用它
    let tipTimer = 0;
    const tip = tipRef.current;
    const hideTip = () => { clearTimeout(tipTimer); tip.hidden = true; };
    cy.on("mouseover", "node", (e) => {
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

  useEffect(() => { cyRef.current.style(style(legend, directed, foldable)); }, [theme, font, legend, directed, foldable]);
  useEffect(() => { unfolded.set(cacheKey, expanded); }, [cacheKey, expanded]);

  const inGraph = selected !== null && Object.hasOwn(groupOf, selected);
  // 邻居视图里留下的点：中心点几跳以内
  const within = useMemo(() => {
    if (!focus) return null;
    let ring = focus.group ? nodes.filter((n) => n.group === focus.group).map((n) => n.i) : [focus.center];
    const seen = new Set(ring);
    for (let k = 0; k < focus.hops; k++) ring = ring.flatMap((i) => [...neighbours.get(i)].filter((j) => !seen.has(j) && seen.add(j)));
    return seen;
  }, [focus, neighbours, nodes]);
  // 选中的场景在折叠的分组里时（例如从搜索选中），展开它所在的分组；取消选中时退出邻居视图；
  // 邻居视图里选中了范围外的点（例如从详情面板的链接），以它为中心重排
  useEffect(() => {
    if (inGraph && !expanded.has(groupOf[selected])) setExpanded((s) => new Set(s).add(groupOf[selected]));
    if (!inGraph && focus && !focus.group) setFocus(null);
    if (inGraph && within && !within.has(selected)) setFocus({ center: selected, hops: focus.hops });
  }, [selected]);
  // 分组的邻居视图不靠选中进入，没有选中时按 Esc 直接回到全图
  useEffect(() => {
    if (!focus?.group) return undefined;
    const key = (e) => { if (e.key === "Escape" && selectedRef.current === null) setFocus(null); };
    document.addEventListener("keydown", key);
    return () => document.removeEventListener("keydown", key);
  }, [focus]);

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
        node.position(centre(nodes.filter((n) => n.group === g.id).map((n) => record[n.i])));
      });
      cy.add([...merged.values()].map((m) => ({ data: { id: "e" + m.s + "-" + m.t, source: m.s, target: m.t, count: m.count, label: m.count > 1 ? String(m.count) : "", rel: m.rel.join("；") },
        classes: [m.main && "main", (m.s[0] === "g" || m.t[0] === "g") && "merged"].filter(Boolean).join(" ") })));
    });
    // 邻居视图只排布留下的场景；回到全图时恢复原来的位置和视口
    // 不超过 20 个点时全部写名称，边距按最长的名称算，边缘的点名称才不被画布裁掉，但最多占画布短边的四分之一，否则点会挤成一团；
    // 点多时名称是挑着写的，超出画布的不写，边距只留 40px
    if (within) {
      const kept = cy.nodes().filter((n) => n.style("display") === "element");
      const longest = Math.max(...kept.map((n) => n.data("label").length));
      const padding = kept.length > 20 ? 40 : Math.min(Math.max(40, longest * parseFloat(css("--fs")) / 2 + 8), Math.min(cy.width(), cy.height()) / 4);
      kept.union(kept.edgesWith(kept)).layout({ ...FCOSE, fit: true, padding }).run();
    } else if (leaving && viewRef.current) cy.viewport(viewRef.current);
    // 路标在显示出来的点里挑，所以展开一个分组后，组里的点也写出名称
    if (!within) {
      cy.nodes(".hub").removeClass("hub");
      pickLabels(cy, landmarks.map((i) => cy.getElementById("n" + i)).filter((n) => n.nonempty() && n.style("display") === "element"), landmarkLimit).forEach((n) => n.addClass("hub"));
    }
    if (foldable) shortenGroupLabels(cy);
  }, [cacheKey, nodes, edges, legend, landmarks, landmarkLimit, foldable, groupOf, expanded, hidden, within]);

  // 选中的点突出它的直接邻居，其余变淡；只改样式，不移动视口。选中的不是图里的点，或它所在的分组被隐藏、折叠时，图保持原样，
  // 因为看不见的点做中心，其余的点会全部变淡
  useEffect(() => {
    const cy = cyRef.current;
    cy.batch(() => {
      cy.elements().removeClass("faded near labeled quiet chosen");
      const node = inGraph ? cy.getElementById("n" + selected) : cy.collection();
      if (node.empty() || node.style("display") === "none") return;
      const near = node.closedNeighborhood();
      near.addClass("near");
      // 邻居视图里留下的都是要看的点，不变淡；不超过 20 个点时全部写名称，多了在全部留下的点里挑
      const kept = focus ? cy.nodes(":visible").not(".group") : cy.collection();
      if (!focus) cy.elements().not(near).addClass("faded");
      // 先写选中点自己的，再写邻居，名称会重叠就不写，详情面板里有完整的关系列表；没挑上的路标不写名称，免得盖住挑上的
      const picked = focus && kept.length <= 20 ? kept
        : cy.collection(pickLabels(cy, [node, ...near.nodes().not(node).not(".group"), ...kept.not(near)], Infinity, true));
      picked.addClass("labeled");
      cy.nodes(".hub").not(picked).addClass("quiet");
      node.addClass("chosen");
    });
  }, [selected, cacheKey, inGraph, expanded, hidden, focus]);

  return (
    <div className={"graph-wrap" + (legendOpen ? "" : " legend-closed")}>
      <div className="graph-area">
        <div className="graph" ref={box} data-ui={ui + ".graph"} />
        <div className="tip" role="tooltip" hidden ref={tipRef} data-pick-ignore />
        <div className="graph-tools">
          {/* 不可用时用 aria-disabled 置灰，不用 disabled：禁用的按钮收不到点击和悬停，元素选取复制不了，也显示不了提示 */}
          <button className="graph-btn" aria-disabled={!inGraph} data-tip={inGraph ? undefined : "先在图里选中一个点"}
            onClick={() => { if (inGraph) onSelect(null); }} data-ui={ui + ".graph-clear"}>取消选中（Esc）</button>
          {/* 拖动或缩放后找不到点时，把显示着的点都放回画布里；只在点击时移动视口 */}
          <button className="graph-btn" data-tip="把显示着的点都放进画布" data-ui={ui + ".graph-fit"}
            onClick={() => { const cy = cyRef.current; cy.fit(cy.nodes(":visible"), 30); }}>适配画布</button>
          {focusable && (
            <>
              <button className="graph-btn graph-focus" aria-disabled={!inGraph && !focus} aria-pressed={Boolean(focus)} data-ui={ui + ".graph-focus"}
                data-tip={inGraph || focus ? undefined : "先在图里选中一个点"}
                onClick={() => { if (focus) setFocus(null); else if (inGraph) setFocus({ center: selected, hops }); }}>{focus ? "返回全图" : "只看邻居"}</button>
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
      <Legend ui={ui} legend={legend} total={nodes.length} foldable={foldable} focused={Boolean(focus)} leaveFocus={() => setFocus(null)}
        hidden={hidden} setHidden={setHidden} expanded={expanded} setExpanded={setExpanded} open={legendOpen} setOpen={setLegendOpen} />
    </div>
  );
}

// 图例：各图谱共用。顶行是标题、全部展开、全部折叠和收起开关，开关贴着图谱右边缘，收起后只留开关那一窄条。
// 下面每行是一个分组：折叠开关（展开时用 --primary，和折叠一眼分开）、显示开关、颜色和条数。
// 折叠是全图的操作：只看邻居时点折叠按钮，先返回全图再折叠或展开，不把按钮置灰，因为一排按钮突然全灰，看不出原因
function Legend({ ui, legend, total, foldable, focused, leaveFocus, hidden, setHidden, expanded, setExpanded, open, setOpen }) {
  const toggle = (set, id) => set((s) => { const n = new Set(s); if (n.has(id)) n.delete(id); else n.add(id); return n; });
  const allOn = hidden.size === 0;
  const tip = (label) => (focused ? "返回全图并" + label : label);
  const fold = (next) => { if (focused) leaveFocus(); setExpanded(next); };
  return (
    <div className="legend" data-ui={ui + ".legend"}>
      <div className="legend-head">
        <span className="legend-title">图例</span>
        {foldable && open && (
          <>
            <button className="icon-btn" aria-label="全部展开" data-tip={tip("全部展开")} data-ui={ui + ".legend-unfold"}
              onClick={() => fold(new Set(legend.map((g) => g.id)))}><IconChevronsDown aria-hidden="true" /></button>
            <button className="icon-btn" aria-label="全部折叠" data-tip={tip("全部折叠")} data-ui={ui + ".legend-fold"}
              onClick={() => fold(new Set())}><IconChevronsUp aria-hidden="true" /></button>
          </>
        )}
        <button className="icon-btn" aria-label={open ? "收起图例" : "展开图例"} data-tip={open ? "收起图例" : "展开图例"} data-ui={ui + ".legend-toggle"}
          onClick={() => { store.set("legend", open ? "closed" : "open"); setOpen(!open); }}>
          {open ? <IconLayoutSidebarRightCollapse aria-hidden="true" /> : <IconLayoutSidebarRightExpand aria-hidden="true" />}
        </button>
      </div>
      {open && <>
        <label className="legend-row">
          {/* 只隐藏了部分分组时显示半选 */}
          <input type="checkbox" checked={allOn} ref={(el) => { if (el) el.indeterminate = hidden.size > 0 && hidden.size < legend.length; }} onChange={() => setHidden(allOn ? new Set(legend.map((g) => g.id)) : new Set())} />
          <span className="legend-name">全部分组</span><span className="count">{total}</span>
        </label>
        {legend.map((g) => (
          <div className="legend-row" key={g.id}>
            {foldable && (
              <button className="twisty" aria-label={(expanded.has(g.id) ? "折叠" : "展开") + g.name} aria-expanded={expanded.has(g.id)}
                data-tip={tip(expanded.has(g.id) ? "折叠这个分类" : "展开这个分类")}
                onClick={() => { const n = new Set(expanded); if (n.has(g.id)) n.delete(g.id); else n.add(g.id); fold(n); }}>
                {expanded.has(g.id) ? <IconFolderOpen aria-hidden="true" /> : <IconFolder aria-hidden="true" />}
              </button>
            )}
            <label className="legend-label">
              <input type="checkbox" checked={!hidden.has(g.id)} onChange={() => toggle(setHidden, g.id)} />
              <span className="dot" style={{ background: `var(${g.color})` }} aria-hidden="true"></span>
              <span className="legend-name">{g.name}</span><span className="count">{g.count}</span>
            </label>
          </div>
        ))}
      </>}
    </div>
  );
}
