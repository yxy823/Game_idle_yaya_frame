import { useState } from "react";
import { IconExternalLink } from "@tabler/icons-react";
import data from "virtual:panorama-data";
import { files } from "./docs.js";
import PageSearch, { PageHead, matches, words } from "./PageSearch.jsx";

// 问答的选中值写成 "qa:编号"，和文档的卡片编号（数字）区分开
export const qaKey = (n) => "qa:" + n;
export const qaOf = (selected) => (typeof selected === "string" && selected.startsWith("qa:") ? data.qa[Number(selected.slice(3))] : null);

// 问答页由 am.mjs 生成在 framework/qa/pages/，和主题文件同名；页面里的问题按出现顺序编号 panel-A、panel-B……
const pageOf = (file) => `../../qa/pages/${files[file].path.split("/").pop().replace(/\.md$/, ".html")}`;
export const qaPageUrl = (q) => `${pageOf(q.file)}#panel-${q.panel}`;

const topics = [...new Set(data.qa.map((q) => q.file))];

// 问答：按主题列出问题，点一条在详情面板显示结论、理由和依据。
// 每张卡片和主题标题上都有“打开问答页”，详情面板收起时也能直接跳到问答页
export default function QaModule({ selected, onSelect }) {
  const [query, setQuery] = useState("");
  const ws = words(query);
  const shown = data.qa.map((q) => matches(ws, q.title, q.conclusion, q.why));
  const count = shown.filter(Boolean).length;
  return (
    <>
      <PageHead search={<PageSearch ui="qa.search" value={query} onChange={setQuery} placeholder="搜索问题、结论和理由" />}>
      {ws.length > 0 && <p className="lead">{count ? `搜索“${query.trim()}”：${count} 条` : "没有匹配的问答，换一个词或减少关键词。"}</p>}
      </PageHead>
      {topics.filter((t) => data.qa.some((q, n) => q.file === t && shown[n])).map((t) => (
        <section className="qa-topic" key={t} data-ui="qa.topic">
          <h2>{files[t].title}<a className="open qa-open" href={pageOf(t)} target="_blank" rel="noreferrer" aria-label="打开问答页" data-tip="在新标签页打开这个主题的问答页"><IconExternalLink aria-hidden="true" /></a>
            <span className="count">{data.qa.filter((q, n) => q.file === t && shown[n]).length}</span></h2>
          <div className="cards">
            {data.qa.map((q, n) => q.file === t && shown[n] && (
              <div key={n} className="qa-card">
                <button className="card" aria-selected={selected === qaKey(n)} onClick={() => onSelect(selected === qaKey(n) ? null : qaKey(n))}>
                  <span className="card-title">{q.title}</span>
                  <span className="card-purpose">{q.conclusion}</span>
                </button>
                <a className="open qa-open" href={qaPageUrl(q)} target="_blank" rel="noreferrer" data-ui="qa.open" aria-label="打开问答页" data-tip="在新标签页打开这一条的问答页"><IconExternalLink aria-hidden="true" /></a>
              </div>
            ))}
          </div>
        </section>
      ))}
    </>
  );
}
