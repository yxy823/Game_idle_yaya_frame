import { Button } from "@/components/ui/button";
import { useMemo, useState } from "react";
import data from "virtual:panorama-data";
import { files, groupName, vscodeUrl } from "./docs.js";
import PageSearch, { PageHead } from "./PageSearch.jsx";
import { qaKey } from "./QaModule.jsx";
import { Badge } from "@/components/ui/badge";

// 术语表、工具表的一行的选中值写成 "entry:编号"，详情面板显示所在文档并滚到这一行
const entryKey = (n) => "entry:" + n;
export const entryOf = (selected) => (typeof selected === "string" && selected.startsWith("entry:") ? data.entries[Number(selected.slice(6))] : null);

// 搜索对象：每份文档、每条问答，以及术语表、工具表的每一行。字段权重决定排序：标题命中排在用途命中前面。
// select 是点结果时选中的对象。
const items = [
  ...files.map((f, i) => ({
    kind: f.path.endsWith("/SKILL.md") ? "Skill" : "文档", file: i, select: i, line: 1, title: f.title,
    fields: [[f.title, 5], [f.purpose, 3], [f.outline.join("　"), 2], [f.path, 1]],
  })),
  ...data.qa.map((q, n) => ({
    kind: "问答", file: q.file, select: qaKey(n), line: q.line, title: q.title,
    fields: [[q.title, 5], [q.conclusion, 3], [q.why, 2]],
  })),
  ...data.entries.map((e, n) => ({
    kind: e.kind === "term" ? "术语" : "工具", file: e.file, select: entryKey(n), line: e.line, title: e.name,
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
  return text.split(pattern).map((part, i) => (i % 2 ? <mark key={i} className="rounded-[2px] bg-accent font-bold text-foreground">{part}</mark> : part));
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

// 离开全局搜索再回来时保留上次的关键词
let lastQuery = "";

export default function SearchModule({ selected, onSelect }) {
  const [query, setQuery] = useState(lastQuery);
  const change = (q) => { lastQuery = q; setQuery(q); };
  const hits = useMemo(() => search(query), [query]);
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  return (
    <>
      <PageHead search={<PageSearch ui="search.input" value={query} onChange={change} placeholder="搜索标题、用途、Skill、问答、工具和术语" open />}>
      {!words.length ? null : !hits.length ? (
        <p className="lead">没有找到包含“{query.trim()}”的内容。换一个词，或者减少关键词。</p>
      ) : (
          <p className="lead">{hits.length > LIMIT ? `共 ${hits.length} 条，显示前 ${LIMIT} 条` : `共 ${hits.length} 条`}</p>
      )}
      </PageHead>
      {hits.length > 0 && (
          <ul className="max-w-240 [&>li]:border-b [&>li]:border-border [&>li]:py-1.5" data-ui="search.results">
            {hits.slice(0, LIMIT).map((hit, i) => {
              const { item } = hit;
              const f = files[item.file];
              return (
                <li key={i}>
                  <Button variant="result" size="none" className="result" aria-selected={selected === item.select} onClick={() => onSelect(item.select)}>
                    <span className="flex items-center gap-1.5 font-semibold"><Badge variant="outline" className="kind">{item.kind}</Badge><Highlight text={item.title} words={words} /></span>
                    <span className="text-muted-foreground"><Highlight text={snippet(hit, words)} words={words} /></span>
                  </Button>
                  <span className="flex items-center gap-2 px-2 text-xs text-muted-foreground">
                    <span className="flex-none whitespace-nowrap"><span className={"dot g-" + f.group} aria-hidden="true"></span>{groupName[f.group]}</span>
                    <Button asChild variant="link" size="none"><a className="open min-w-0 text-primary" href={vscodeUrl(item.file, item.line)} data-tip="在 VSCode 里打开这一行">{f.path}:{item.line}</a></Button>
                  </span>
                </li>
              );
            })}
          </ul>
      )}
    </>
  );
}
