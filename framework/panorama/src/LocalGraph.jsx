import { useLayoutEffect, useRef, useState } from "react";
import { hoverNode } from "./Graph.jsx";

// 详情面板里的关系图：当前对象在中间，左边是指向它的（开发场景里是上一步），右边是它指向的（下一步）。
// 每侧最多 8 行，点多时向外再排一列；名称只写在最外一列点的外侧，放不下就截断，其余的点悬停看名称。
// 主线画粗线；连线带条件或关系说明时，悬停连线显示。点一个点就选中它，悬停时主图谱上对应的点也高亮。
// left、right 的每项：{ key, label, color, main, note, both }；both 为真表示两个方向都有连线，画两头箭头
const ROWS = 8, ROW = 18, PAD = 10, INNER = 72;
const css = (name) => parseFloat(getComputedStyle(document.documentElement).getPropertyValue(name));
// 估算文字宽度：汉字和全角符号按一个字号，其余按 0.6 个
const textWidth = (s, fs) => [...s].reduce((w, c) => w + (c.charCodeAt(0) > 0x2e80 ? fs : fs * 0.6), 0);
const clip = (s, fs, max) => {
  if (textWidth(s, fs) <= max) return s;
  let out = "";
  for (const c of s) { if (textWidth(out + c + "…", fs) > max) break; out += c; }
  return out ? out + "…" : "";
};

function place(list, dir, width, height) {
  const cols = Math.max(1, Math.ceil(list.length / ROWS));
  const room = width / 2 - INNER - PAD - 40;
  const step = cols > 1 ? Math.min(26, room / (cols - 1)) : 0;
  // 先排最外一列，重要的点（主线在前）有名称
  return list.map((n, i) => {
    const c = cols - 1 - Math.floor(i / ROWS), inCol = Math.min(ROWS, list.length - (cols - 1 - c) * ROWS), row = i % ROWS;
    return { ...n, x: width / 2 + dir * (INNER + c * step), y: height / 2 + (row - (inCol - 1) / 2) * ROW, outer: c === cols - 1 };
  });
}

export default function LocalGraph({ center, left, right, onSelect, font }) {
  const box = useRef(null);
  const [width, setWidth] = useState(0);
  useLayoutEffect(() => {
    const ro = new ResizeObserver(([e]) => setWidth(Math.round(e.contentRect.width)));
    ro.observe(box.current);
    return () => ro.disconnect();
  }, []);
  // font 变了会重新渲染，名称字号跟着设置走
  const fs = width && font ? css("--fs-small") : 12;
  const rows = Math.min(ROWS, Math.max(left.length, right.length, 1));
  const height = Math.max(96, rows * ROW + 2 * PAD + 20);
  const nodes = width ? [...place(left, -1, width, height).map((n) => ({ ...n, dir: -1 })), ...place(right, 1, width, height).map((n) => ({ ...n, dir: 1 }))] : [];
  const cx = width / 2, cy = height / 2;
  const r = 5, rc = 7;
  // 连线从点的边缘画到中心点的边缘，箭头朝被指向的一端
  const line = (n) => {
    const dx = cx - n.x, dy = cy - n.y, d = Math.hypot(dx, dy), ux = dx / d, uy = dy / d;
    const a = { x: n.x + ux * r, y: n.y + uy * r }, b = { x: cx - ux * rc, y: cy - uy * rc };
    return n.dir < 0 ? [a, b] : [b, a];
  };
  return (
    <div ref={box} className="local-graph" data-ui="panel.graph">
      {width > 0 && (
        <svg width={width} height={height} role="img" aria-label={"关系图：" + center.label}>
          <defs>
            {["edge", "main"].map((k) => (
              <marker key={k} id={"lg-" + k} viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
                <path d="M0 0L10 5L0 10z" className={"lg-arrow lg-" + k} />
              </marker>
            ))}
          </defs>
          {nodes.map((n) => {
            const [a, b] = line(n), m = n.main ? "url(#lg-main)" : "url(#lg-edge)";
            return (
              <g key={"e" + n.key}>
                <line x1={a.x} y1={a.y} x2={b.x} y2={b.y} className={n.main ? "lg-line lg-main" : "lg-line"} markerEnd={m} markerStart={n.both ? m : undefined} />
                {n.note && <line x1={a.x} y1={a.y} x2={b.x} y2={b.y} className="lg-hit" data-tip={n.note} />}
              </g>
            );
          })}
          {nodes.map((n) => {
            const room = n.dir < 0 ? n.x - r - 4 - PAD : width - n.x - r - 4 - PAD;
            const text = n.outer ? clip(n.label, fs, room) : "";
            return (
              <g key={"n" + n.key} className="lg-node" data-tip={n.label} onClick={() => onSelect(n.key)}
                onMouseEnter={() => hoverNode(n.key)} onMouseLeave={() => hoverNode(null)}>
                <circle cx={n.x} cy={n.y} r={r} style={{ fill: n.color }} />
                {text && <text x={n.x + n.dir * (r + 4)} y={n.y} dy="0.35em" textAnchor={n.dir < 0 ? "end" : "start"} style={{ fontSize: fs }}>{text}</text>}
              </g>
            );
          })}
          <g className="lg-center" data-tip={center.label}>
            <circle cx={cx} cy={cy} r={rc} style={{ fill: center.color }} />
            <text x={cx} y={cy + rc + 4} dy="0.8em" textAnchor="middle" style={{ fontSize: fs }}>{clip(center.label, fs, 2 * INNER - 40)}</text>
          </g>
        </svg>
      )}
    </div>
  );
}
