import { files, links } from "./docs.js";
import Graph from "./Graph.jsx";

// 只画 Godot 项目开发的场景：Yaya 框架维护的场景页没有下一步清单，画出来全是孤立的点
const ROOT = "framework/prompt-scenarios/scenarios/Godot 项目开发/";
const scenes = files.map((f, i) => i).filter((i) => files[i].path.startsWith(ROOT) && files[i].path.slice(ROOT.length).includes("/"));
const categoryOf = (i) => files[i].path.slice(ROOT.length).split("/")[0];
const categories = [...new Set(scenes.map(categoryOf))];
const inScenes = new Set(scenes);

// 连线来自场景页的下一步清单；同一对场景有主线时只画主线，链到自己的不画
const next = links.filter((l) => l.kind === "next" && l.from !== l.to && inScenes.has(l.from) && inScenes.has(l.to));
const byPair = new Map();
for (const l of next) {
  const key = l.from + "-" + l.to;
  byPair.set(key, { from: l.from, to: l.to, main: l.main || byPair.get(key)?.main || false });
}
const edges = [...byPair.values()];
const nextIn = Object.fromEntries(scenes.map((i) => [i, 0]));
for (const e of edges) nextIn[e.to] += 1;

const graph = {
  nodes: scenes.map((i) => ({ i, label: files[i].title, group: categoryOf(i), size: 12 + Math.sqrt(nextIn[i]) * 5 })),
  edges,
  legend: categories.map((c, k) => ({ id: c, name: c, color: "--p" + (k + 1), count: scenes.filter((i) => categoryOf(i) === c).length })),
  // 路标先挑主线上的场景，再按被指向的次数
  landmarks: [...scenes].sort((a, b) => {
    const onMain = (i) => edges.some((e) => e.main && (e.from === i || e.to === i));
    return onMain(b) - onMain(a) || nextIn[b] - nextIn[a];
  }),
};
const mainCount = edges.filter((e) => e.main).length;

// 开发场景：每个点是项目可能处在的一种情况，箭头指向做完之后可能进入的情况
export default function ScenesModule({ selected, onSelect, theme }) {
  return (
    <div className="files">
      <h1>开发场景</h1>
      <p className="lead">
        Godot 项目开发的 {scenes.length} 个场景，{edges.length} 条连线来自各场景页的下一步清单。蓝色实线是主线（{mainCount} 条），虚线是其他可能的下一步。默认按分类折叠，点分类展开；点一个场景，详情面板列出它的上一步和下一步，“只看邻居”只留它附近的场景。
      </p>
      <Graph cacheKey="scenes" {...graph} directed foldable focusable selected={selected} onSelect={onSelect} theme={theme} ui="scenes" />
    </div>
  );
}
