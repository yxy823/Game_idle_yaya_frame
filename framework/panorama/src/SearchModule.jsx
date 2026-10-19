import { useMemo } from "react";
import data from "virtual:panorama-data";
import { files, groupName, vscodeUrl } from "./docs.js";
import { qaKey } from "./QaModule.jsx";

// 搜索对象：每份文档、每条问答，以及术语表、工具表的每一行。字段权重决定排序：标题命中排在用途命中前面。
// select 是点结果时选中的卡片；术语和工具没有自己的卡片，选中它所在的文档。
const items = [
  ...files.map((f, i) => ({
    kind: f.path.endsWith("/SKILL.md") ? "Skill" : "文档", file: i, select: i, line: 1, title: f.title,
    fields: [[f.title, 5], [f.purpose, 3], [f.outline.join("　"), 2], [f.path, 1]],
  })),
  ...data.qa.map((q, n) => ({
    kind: "问答", file: q.file, select: qaKey(n), line: q.line, title: q.title,
    fields: [[q.title, 5], [q.conclusion, 3], [q.why, 2]],
  })),
  ...data.entries.map((e) => ({
    kind: e.kind === "term" ? "术语" : "工具", file: e.file, select: e.file, line: e.line, title: e.name,
    fields: [[e.name, 5], [e.aliases, 4], [e.desc, 3]],
  })),
].map((item) => ({ ...item, lower: item.fields.map(([t, w]) => [t.toLowerCase(), w]) }));

const LIMIT = 200;

// 多个词用空格分开，每个词都要在某个字段里出现；分数是每个词命中的最高权重之和
function search(query) {
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  if (!words.length) return [];
  const hits = [];
  for (const item of items) {
    let score = 0;
    for (const w of words) {
      const weights = item.lower.filter(([t]) => t.includes(w)).map(([, weight]) => weight);
      if (!weights.length) { score = 0; break; }
      score += Math.max(...weights);
    }
    if (score > 0) hits.push({ item, score });
  }
  return hits.sort((a, b) => b.score - a.score || a.item.title.length - b.item.title.length);
}

function Highlight({ text, words }) {
  if (!words.length) return text;
  const pattern = new RegExp("(" + words.map((w) => w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join("|") + ")", "gi");
  return text.split(pattern).map((part, i) => (i % 2 ? <mark key={i}>{part}</mark> : part));
}

// 摘要取第一个不是标题的命中字段，截取命中处前后各约 40 字
function snippet(hit, words) {
  const { item } = hit;
  const field = item.lower.findIndex(([t], i) => i > 0 && words.some((w) => t.includes(w)));
  const text = field > 0 ? item.fields[field][0] : item.fields[1]?.[0] || "";
  if (field <= 0) return text.slice(0, 90);
  const at = Math.min(...words.map((w) => item.lower[field][0].indexOf(w)).filter((i) => i >= 0));
  const start = Math.max(0, at - 40);
  return (start ? "…" : "") + text.slice(start, at + 50) + (at + 50 < text.length ? "…" : "");
}

export default function SearchModule({ query, selected, onSelect }) {
  const hits = useMemo(() => search(query), [query]);
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  return (
    <>
      <h1>搜索结果</h1>
      {!words.length ? (
        <p className="lead">在顶栏输入关键词，搜文档的标题、用途、大纲和路径，问答的问题、结论和理由，以及术语表、工具表的每一行。多个词用空格分开，全部包含才算命中。</p>
      ) : !hits.length ? (
        <p className="lead">没有找到包含“{query.trim()}”的内容。换一个词，或者减少关键词。</p>
      ) : (
        <>
          <p className="lead">{hits.length > LIMIT ? `共 ${hits.length} 条，显示前 ${LIMIT} 条` : `共 ${hits.length} 条`}</p>
          <ul className="results" data-ui="search.results">
            {hits.slice(0, LIMIT).map((hit, i) => {
              const { item } = hit;
              const f = files[item.file];
              return (
                <li key={i}>
                  <button className="result" aria-selected={selected === item.select && item.kind !== "术语" && item.kind !== "工具"} onClick={() => onSelect(item.select)}>
                    <span className="result-title"><span className="kind">{item.kind}</span><Highlight text={item.title} words={words} /></span>
                    <span className="result-text"><Highlight text={snippet(hit, words)} words={words} /></span>
                  </button>
                  <span className="result-meta">
                    <span className="result-group"><span className={"dot g-" + f.group} aria-hidden="true"></span>{groupName[f.group]}</span>
                    <a className="open" href={vscodeUrl(item.file, item.line)} data-tip="在 VSCode 里打开这一行">{f.path}:{item.line}</a>
                  </span>
                </li>
              );
            })}
          </ul>
        </>
      )}
    </>
  );
}
