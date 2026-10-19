import data from "virtual:panorama-data";
import { files } from "./docs.js";

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
  return (
    <>
      <h1>问答</h1>
      <p className="lead">讨论中问过、以后还会用到的问题，共 {data.qa.length} 条。点一条，详情面板显示结论、为什么和依据；点“打开问答页”在新标签页看这一条的完整图解。</p>
      {topics.map((t) => (
        <section className="qa-topic" key={t} data-ui="qa.topic">
          <h2>{files[t].title}<a className="open qa-open" href={pageOf(t)} target="_blank" rel="noreferrer">打开问答页</a>
            <span className="count">{data.qa.filter((q) => q.file === t).length}</span></h2>
          <div className="cards">
            {data.qa.map((q, n) => q.file === t && (
              <div key={n} className="qa-card">
                <button className="card" aria-selected={selected === qaKey(n)} onClick={() => onSelect(qaKey(n))}>
                  <span className="card-title">{q.title}</span>
                  <span className="card-purpose">{q.conclusion}</span>
                </button>
                <a className="open qa-open" href={qaPageUrl(q)} target="_blank" rel="noreferrer" data-ui="qa.open">打开问答页</a>
              </div>
            ))}
          </div>
        </section>
      ))}
    </>
  );
}
