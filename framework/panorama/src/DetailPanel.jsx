import { useState } from "react";
import { IconChevronDown, IconChevronRight } from "@tabler/icons-react";
import { files, groupName, incoming, outgoing, paras, vscodeUrl } from "./docs.js";
import { qaOf, qaPageUrl } from "./QaModule.jsx";
import { docEdges, docKey, docNodes, docOf } from "./DocsModule.jsx";
import { store } from "./store.js";

function Row({ name, children }) {
  return <div className="row"><span className="name">{name}</span><span className="value">{children}</span></div>;
}

// 超过 20 条的小节默认收起，否则一节就占满整个面板
function Section({ title, ui, count, children }) {
  const [open, setOpen] = useState(count === undefined || count <= 20);
  return (
    <details className="section" open={open} data-ui={ui} onToggle={(e) => setOpen(e.currentTarget.open)}>
      <summary>
        <span className="twisty">{open ? <IconChevronDown aria-hidden="true" /> : <IconChevronRight aria-hidden="true" />}</span>
        {title}{count !== undefined && <span className="count">{count}</span>}
      </summary>
      {children}
    </details>
  );
}

function FileLink({ index, onSelect }) {
  return <button className="link-btn" onClick={() => onSelect(index)} data-tip={files[index].path}>{files[index].title}</button>;
}

// 每个目标只列一次，按第一次出现的顺序
const unique = (list, key) => list.filter((x, i) => list.findIndex((y) => key(y) === key(x)) === i);

// 引用它的那一段原文：指向当前文档的链接高亮，点它跳到来源卡片
function Quote({ link, current, onSelect }) {
  const p = paras[link.para];
  return (
    <div className="quote">
      <div className="quote-head">
        <FileLink index={p.file} onSelect={onSelect} />
        <a className="open" href={vscodeUrl(p.file, p.line)} data-tip="在 VSCode 里打开这一行">第 {p.line} 行</a>
      </div>
      <p className="quote-text">
        {p.parts.map((part, i) => (typeof part === "string" ? part
          : part.to === current ? <mark key={i}>{part.text}</mark> : <span key={i} className="quote-link">{part.text}</span>))}
      </p>
    </div>
  );
}

// 问答的详情：结论、为什么、依据；按钮在新标签页打开问答页里的这一条
function QaPanel({ q, onSelect }) {
  return (
    <aside className="panel" aria-label="详情" data-ui="panel">
      <div className="panel-head" data-ui="panel.head" data-tip={q.title}>{q.title}</div>
      <div className="panel-actions">
        <a className="btn-primary" href={qaPageUrl(q)} target="_blank" rel="noreferrer" data-ui="panel.open-qa">打开问答页</a>
      </div>
      <Section title="回答" ui="panel.answer">
        <Row name="结论">{q.conclusion}</Row>
        {q.why && <Row name="为什么">{q.why}</Row>}
      </Section>
      <Section title="关联" ui="panel.qa-links">
        <Row name="主题"><FileLink index={q.file} onSelect={onSelect} /></Row>
        {q.basis.length > 0 && <Row name="依据"><ul className="plain">{q.basis.map((i) => <li key={i}><FileLink index={i} onSelect={onSelect} /></li>)}</ul></Row>}
        <Row name="原文"><a className="open" href={vscodeUrl(q.file, q.line)} data-tip="在 VSCode 里打开这一行">{files[q.file].path}:{q.line}</a></Row>
      </Section>
    </aside>
  );
}

// 文档关系图里一个节点的详情：介绍、路径、模板文件，以及进出的关系和关系说明
function DocPanel({ k, onSelect }) {
  const n = docNodes[k];
  const out = docEdges.filter((e) => e.from === k), into = docEdges.filter((e) => e.to === k);
  const rel = (e, end) => (
    <li key={e.from + "-" + e.to + "-" + e.line}>
      {e.label && <span className="cond">{e.label}</span>}
      <button className="link-btn" onClick={() => onSelect(docKey(e[end]))}>{docNodes[e[end]].name}</button>
    </li>
  );
  return (
    <aside className="panel" aria-label="详情" data-ui="panel">
      <div className="panel-head" data-ui="panel.head" data-tip={n.name}>{n.name}</div>
      <Section title="摘要" ui="panel.summary">
        <Row name="介绍">{n.card !== null ? files[n.card].purpose || "模板文件的第一段没有用途说明" : n.note || "没有对应的模板文件，项目里按需要创建"}</Row>
        {n.paths.length > 0 && <Row name="位置"><ul className="plain">{n.paths.map((p) => <li key={p}><code>{p}</code></li>)}</ul></Row>}
        {n.card !== null && <Row name="模板"><FileLink index={n.card} onSelect={onSelect} /></Row>}
      </Section>
      {(out.length > 0 || into.length > 0) && (
        <Section title="关系" ui="panel.doc-links" count={out.length + into.length}>
          {out.length > 0 && <Row name="指向"><ul className="plain">{out.map((e) => rel(e, "to"))}</ul></Row>}
          {into.length > 0 && <Row name="来自"><ul className="plain">{into.map((e) => rel(e, "from"))}</ul></Row>}
        </Section>
      )}
      <Section title="出处" ui="panel.doc-sources">
        <ul className="plain">{n.from.map((f) => <li key={f}><FileLink index={f} onSelect={onSelect} /></li>)}</ul>
      </Section>
    </aside>
  );
}

// 文档的详情分三个标签：概要、关系、原文（被引用处的段落）；面板记住上次停在哪个标签
const TABS = [["summary", "概要"], ["links", "关系"], ["quotes", "原文"]];
let lastTab = TABS.some(([id]) => id === store.get("panel.tab")) ? store.get("panel.tab") : "summary";

// 右侧详情面板，照 draw.io 的属性面板：分节可以折叠，每行左边是名称、右边是值。
// file 是文档的卡片编号；问答的选中值是 "qa:编号"，交给 QaPanel；文档关系图的节点是 "doc:编号"，交给 DocPanel。
export default function DetailPanel({ file, onSelect }) {
  const [tab, setTab] = useState(lastTab);
  const pickTab = (t) => { lastTab = t; store.set("panel.tab", t); setTab(t); };
  const q = qaOf(file);
  if (q) return <QaPanel key={file} q={q} onSelect={onSelect} />;
  if (docOf(file) !== null) return <DocPanel key={file} k={docOf(file)} onSelect={onSelect} />;
  if (file === null) {
    return (
      <aside className="panel" aria-label="详情" data-ui="panel">
        <div className="panel-head" data-ui="panel.head">详情</div>
        <p className="empty" data-ui="panel.empty">在主区域选中一个文件</p>
      </aside>
    );
  }
  const f = files[file];
  const out = outgoing[file], into = incoming[file];
  const next = out.filter((l) => l.kind === "next"), prev = into.filter((l) => l.kind === "next");
  const basis = unique(out.filter((l) => l.kind === "basis"), (l) => l.to);
  const refs = unique(out.filter((l) => l.kind === "ref" && l.to !== file), (l) => l.to);
  const cited = unique(into.filter((l) => l.from !== file), (l) => l.para);
  const citing = unique(cited, (l) => l.from);
  const counts = { links: next.length + prev.length + basis.length + refs.length + citing.length, quotes: cited.length };
  const step = (l, end) => (
    <li key={l.from + "-" + l.to + "-" + l.para}>
      {l.main && <span className="tag">主线</span>}<span className="cond">{l.cond}</span><FileLink index={l[end]} onSelect={onSelect} />
    </li>
  );
  return (
    <aside className="panel" aria-label="详情" data-ui="panel" key={file}>
      <div className="panel-head" data-ui="panel.head" data-tip={f.title}>{f.title}</div>
      <div className="panel-tabs" role="tablist" data-ui="panel.tabs">
        {TABS.map(([id, name]) => (
          <button key={id} role="tab" aria-selected={tab === id} onClick={() => pickTab(id)}>
            {name}{counts[id] !== undefined && <span className="count">{counts[id]}</span>}
          </button>
        ))}
      </div>
      {tab === "summary" && (
        <>
          <Section title="摘要" ui="panel.summary">
            <Row name="用途">{f.purpose || "第一段没有用途说明"}</Row>
            <Row name="分组"><span className={"dot g-" + f.group} aria-hidden="true"></span>{groupName[f.group]}</Row>
            <Row name="路径"><a className="open" href={vscodeUrl(file)} data-tip="在 VSCode 里打开">{f.path}</a></Row>
          </Section>
          {f.outline.length > 0 && (
            <Section title="大纲" ui="panel.outline" count={f.outline.length}>
              <ul className="plain">{f.outline.map((h, i) => <li key={i}>{h}</li>)}</ul>
            </Section>
          )}
          <Section title="修改" ui="panel.history">
            <Row name="最近">{f.changed || "还没提交"}</Row>
            <Row name="次数">{f.changes}</Row>
          </Section>
        </>
      )}
      {tab === "links" && (
        <>
          {(next.length > 0 || prev.length > 0) && (
            <Section title="场景衔接" ui="panel.steps">
              {next.length > 0 && <Row name="下一步"><ul className="plain">{next.map((l) => step(l, "to"))}</ul></Row>}
              {prev.length > 0 && <Row name="上一步"><ul className="plain">{prev.map((l) => step(l, "from"))}</ul></Row>}
            </Section>
          )}
          {(basis.length > 0 || refs.length > 0) && (
            <Section title="引用" ui="panel.refs" count={basis.length + refs.length}>
              {basis.length > 0 && <Row name="依据"><ul className="plain">{basis.map((l) => <li key={l.to}><FileLink index={l.to} onSelect={onSelect} /></li>)}</ul></Row>}
              {refs.length > 0 && <Row name="引用"><ul className="plain">{refs.map((l) => <li key={l.to}><FileLink index={l.to} onSelect={onSelect} /></li>)}</ul></Row>}
            </Section>
          )}
          <Section title="被引用" ui="panel.cited" count={citing.length}>
            {citing.length ? <ul className="plain">{citing.map((l) => <li key={l.from}><FileLink index={l.from} onSelect={onSelect} /></li>)}</ul>
              : <p className="empty">没有其他文档链接到它</p>}
          </Section>
        </>
      )}
      {tab === "quotes" && (cited.length ? cited.map((l, i) => <Quote key={i} link={l} current={file} onSelect={onSelect} />)
        : <p className="empty">没有其他文档链接到它</p>)}
    </aside>
  );
}
