import { Button } from "@/components/ui/button";
import { useState } from "react";
import { ExternalLinkIcon } from "lucide-react";
import data from "virtual:panorama-data";
import { files } from "./docs.js";
import PageSearch, { PageHead, matches, words } from "./PageSearch.jsx";
import SideLayout from "./SideLayout.jsx";

// 问答的选中值写成 "qa:编号"，和文档的卡片编号（数字）区分开
export const qaKey = (n) => "qa:" + n;
export const qaOf = (selected) => (typeof selected === "string" && selected.startsWith("qa:") ? data.qa[Number(selected.slice(3))] : null);

// 问答页由 am.mjs 生成在 framework/qa/pages/，和主题文件同名；页面里的问题按出现顺序编号 panel-A、panel-B……
const pageOf = (file) => `../../qa/pages/${files[file].path.split("/").pop().replace(/\.md$/, ".html")}`;
export const qaPageUrl = (q) => `${pageOf(q.file)}#panel-${q.panel}`;

const topics = [...new Set(data.qa.map((q) => q.file))];

// 问答：按主题列出问题，点一条在详情面板显示结论、理由和依据。左侧目录列出主题，从问答数据里读，新增主题文件后自动出现。
// 每张卡片和主题标题上都有“打开问答页”，详情面板收起时也能直接跳到问答页
export default function QaModule({ selected, onSelect }) {
  const [query, setQuery] = useState("");
  const ws = words(query);
  const shown = data.qa.map((q) => matches(ws, q.title, q.conclusion, q.why));
  const count = shown.filter(Boolean).length;
  const countOf = (t) => data.qa.filter((q, n) => q.file === t && shown[n]).length;
  const listed = topics.filter((t) => countOf(t) > 0);
  return (
    <>
      <PageHead search={<PageSearch ui="qa.search" value={query} onChange={setQuery} placeholder="搜索问题、结论和理由" />}>
      {ws.length > 0 && <p className="lead">{count ? `搜索“${query.trim()}”：${count} 条` : "没有匹配的问答，换一个词或减少关键词。"}</p>}
      </PageHead>
      <SideLayout label="主题" ui="qa" toc={
        listed.map((t) => (
          <Button key={t} variant="row" size="none" className="tree-row" onClick={() => document.getElementById("qa-topic-" + t).scrollIntoView({ block: "start" })}>
            <span className="tree-name" data-tip-clip>{files[t].title}</span><span className="count">{countOf(t)}</span>
          </Button>
        ))}>
        <div>
          {listed.map((t) => (
            <section className="qa-topic" key={t} id={"qa-topic-" + t} data-ui="qa.topic">
              <h2 className="mt-4 mb-2 flex items-center text-sm [.qa-topic:first-child_&]:mt-0">{files[t].title}<Button asChild variant="link" size="none"><a className="open qa-open ml-3 text-primary" href={pageOf(t)} target="_blank" rel="noreferrer" aria-label="打开问答页" data-tip="在新标签页打开这个主题的问答页"><ExternalLinkIcon aria-hidden="true" /></a></Button>
                <span className="count">{countOf(t)}</span></h2>
              <div className="cards">
                {data.qa.map((q, n) => q.file === t && shown[n] && (
                  <div key={n} className="relative flex">
                    {/* 卡片右上角的链接压在卡片上，卡片右边留出位置 */}
                    <Button variant="card" size="none" className="card flex-1 pr-8" aria-selected={selected === qaKey(n)} onClick={() => onSelect(selected === qaKey(n) ? null : qaKey(n))}>
                      <span className="card-title">{q.title}</span>
                      <span className="card-purpose">{q.conclusion}</span>
                    </Button>
                    <Button asChild variant="link" size="none"><a className="open qa-open absolute top-2 right-2 text-primary" href={qaPageUrl(q)} target="_blank" rel="noreferrer" data-ui="qa.open" aria-label="打开问答页" data-tip="在新标签页打开这一条的问答页"><ExternalLinkIcon aria-hidden="true" /></a></Button>
                  </div>
                ))}
              </div>
            </section>
          ))}
        </div>
      </SideLayout>
    </>
  );
}
