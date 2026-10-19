import { useMemo, useState } from "react";
import { IconArrowLeft, IconArrowRight, IconCaretDownFilled, IconCaretRightFilled } from "@tabler/icons-react";
import DocView from "./DocView.jsx";
import { files, groupName, incoming, outgoing, paras, vscodeUrl } from "./docs.js";
import { qaOf, qaPageUrl } from "./QaModule.jsx";
import { docEdges, docKey, docNodes, docOf } from "./DocsModule.jsx";
import { entryOf } from "./SearchModule.jsx";
import { store } from "./store.js";

// 照 draw.io 的格式面板：成对的短属性用“名称 + 取值”两栏的 Row；列表和长文字用 Group，名称写在上方一行，内容占满整行。
// 小节里只有一组、组名和小节标题相同时，不写组名
function Row({ name, children }) {
  return <div className="row"><span className="name">{name}</span><span className="value">{children}</span></div>;
}
function Group({ name, children }) {
  return <div className="group">{name && <div className="group-name">{name}</div>}{children}</div>;
}

// 超过 20 条的小节默认收起，否则一节就占满整个面板
function Section({ title, ui, count, children }) {
  const [open, setOpen] = useState(count === undefined || count <= 20);
  return (
    <details className="section" open={open} data-ui={ui} onToggle={(e) => setOpen(e.currentTarget.open)}>
      <summary>
        <span className="twisty">{open ? <IconCaretDownFilled aria-hidden="true" /> : <IconCaretRightFilled aria-hidden="true" />}</span>
        {title}{count !== undefined && <span className="count">{count}</span>}
      </summary>
      {children}
    </details>
  );
}

// 面板标题行：名称和后退、前进；后退、前进在本模块选中过的对象之间移动
function Head({ title, nav }) {
  return (
    <div className="panel-head" data-ui="panel.head">
      <span className="panel-title" data-tip={title}>{title}</span>
      <button className="icon-btn" aria-label="后退" data-tip={nav.onBack ? "后退" : "没有更早选中的对象"} aria-disabled={!nav.onBack}
        onClick={() => nav.onBack?.()} data-ui="panel.back"><IconArrowLeft aria-hidden="true" /></button>
      <button className="icon-btn" aria-label="前进" data-tip={nav.onForward ? "前进" : "没有后退过"} aria-disabled={!nav.onForward}
        onClick={() => nav.onForward?.()} data-ui="panel.forward"><IconArrowRight aria-hidden="true" /></button>
    </div>
  );
}

function FileLink({ index, onSelect }) {
  return <button className="link-btn" onClick={() => onSelect(index)} data-tip={files[index].title + "（" + files[index].path + "）"}>{files[index].title}</button>;
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
function QaPanel({ q, onSelect, nav }) {
  return (
    <aside className="panel" aria-label="详情" data-ui="panel">
      <Head title={q.title} nav={nav} />
      <div className="panel-actions">
        <a className="btn-primary" href={qaPageUrl(q)} target="_blank" rel="noreferrer" data-ui="panel.open-qa">打开问答页</a>
      </div>
      <Section title="回答" ui="panel.answer">
        <Group name="结论"><p className="text">{q.conclusion}</p></Group>
        {q.whyParts.length > 0 && (
          <Group name="为什么">
            {q.whyParts.map((part, i) => (part.items ? <ul key={i} className="text">{part.items.map((t, j) => <li key={j}>{t}</li>)}</ul> : <p key={i} className="text">{part.text}</p>))}
          </Group>
        )}
      </Section>
      <Section title="关联" ui="panel.qa-links">
        <Row name="主题"><FileLink index={q.file} onSelect={onSelect} /></Row>
        {q.basis.length > 0 && <Group name="依据"><ul className="plain">{q.basis.map((i) => <li key={i}><FileLink index={i} onSelect={onSelect} /></li>)}</ul></Group>}
        <Row name="原文"><a className="open" href={vscodeUrl(q.file, q.line)} data-tip="在 VSCode 里打开这一行">{files[q.file].path}:{q.line}</a></Row>
      </Section>
    </aside>
  );
}

// 文档关系图里一个节点的详情：介绍、路径、模板文件，以及进出的关系和关系说明
function DocPanel({ k, onSelect, nav }) {
  const n = docNodes[k];
  const out = docEdges.filter((e) => e.from === k), into = docEdges.filter((e) => e.to === k);
  const rel = (e, end) => (
    <li key={e.from + "-" + e.to + "-" + e.line}>
      {e.label && <div className="cond">{e.label}</div>}
      <button className="link-btn" onClick={() => onSelect(docKey(e[end]))}>{docNodes[e[end]].name}</button>
    </li>
  );
  return (
    <aside className="panel" aria-label="详情" data-ui="panel">
      <Head title={n.name} nav={nav} />
      <Section title="摘要" ui="panel.summary">
        <Group name="介绍"><p className="text">{n.card !== null ? files[n.card].purpose || "模板文件的第一段没有用途说明" : n.note || "没有对应的模板文件，项目里按需要创建"}</p></Group>
        {n.paths.length > 0 && <Group name="位置"><ul className="plain">{n.paths.map((p) => <li key={p}><code>{p}</code></li>)}</ul></Group>}
        {n.card !== null && <Row name="模板"><FileLink index={n.card} onSelect={onSelect} /></Row>}
      </Section>
      {(out.length > 0 || into.length > 0) && (
        <Section title="关系" ui="panel.doc-links" count={out.length + into.length}>
          {out.length > 0 && <Group name="指向"><ul className="plain">{out.map((e) => rel(e, "to"))}</ul></Group>}
          {into.length > 0 && <Group name="来自"><ul className="plain">{into.map((e) => rel(e, "from"))}</ul></Group>}
        </Section>
      )}
      <Section title="出处" ui="panel.doc-sources">
        <Group><ul className="plain">{n.from.map((f) => <li key={f}><FileLink index={f} onSelect={onSelect} /></li>)}</ul></Group>
      </Section>
    </aside>
  );
}

// 术语表、工具表里的一行：显示所在文档的正文，滚到这一行并高亮
function EntryPanel({ e, onSelect, nav, font }) {
  const jump = useMemo(() => ({ row: e.name }), [e]);
  return (
    <aside className="panel" aria-label="详情" data-ui="panel">
      <Head title={e.name} nav={nav} />
      <Section title="位置" ui="panel.entry">
        <Row name="文档"><FileLink index={e.file} onSelect={onSelect} /></Row>
        <Row name="原文"><a className="open" href={vscodeUrl(e.file, e.line)} data-tip="在 VSCode 里打开这一行">{files[e.file].path}:{e.line}</a></Row>
      </Section>
      <div className="learn-body panel-doc" data-ui="panel.entry-doc">
        <DocView card={e.file} jump={jump} onLink={(i) => onSelect(i)} font={font} />
      </div>
    </aside>
  );
}

// 选中对象的名称，详情面板收起时的提示用它
export function titleOf(value) {
  const q = qaOf(value), e = entryOf(value);
  return q ? q.title : e ? e.name : docOf(value) !== null ? docNodes[docOf(value)].name : files[value].title;
}

// 文档的详情分三个标签：概要、关系、原文（被引用处的段落）；面板记住上次停在哪个标签
const TABS = [["summary", "概要"], ["links", "关系"], ["quotes", "原文"]];
let lastTab = TABS.some(([id]) => id === store.get("panel.tab")) ? store.get("panel.tab") : "summary";

// 右侧详情面板，照 draw.io 的属性面板：分节可以折叠，每行左边是名称、右边是值。
// file 是文档的卡片编号；问答的选中值是 "qa:编号"，交给 QaPanel；文档关系图的节点是 "doc:编号"，交给 DocPanel。
export default function DetailPanel({ file, onSelect, onBack, onForward, font }) {
  const [tab, setTab] = useState(lastTab);
  const pickTab = (t) => { lastTab = t; store.set("panel.tab", t); setTab(t); };
  const nav = { onBack, onForward };
  const q = qaOf(file), e = entryOf(file);
  if (q) return <QaPanel key={file} q={q} onSelect={onSelect} nav={nav} />;
  if (e) return <EntryPanel key={file} e={e} onSelect={onSelect} nav={nav} font={font} />;
  if (docOf(file) !== null) return <DocPanel key={file} k={docOf(file)} onSelect={onSelect} nav={nav} />;
  if (file === null) {
    return (
      <aside className="panel" aria-label="详情" data-ui="panel">
        <Head title="详情" nav={nav} />
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
      {(l.main || l.cond) && <div className="cond">{l.main && <span className="tag">主线</span>}{l.cond}</div>}<FileLink index={l[end]} onSelect={onSelect} />
    </li>
  );
  return (
    <aside className="panel" aria-label="详情" data-ui="panel" key={file}>
      <Head title={f.title} nav={nav} />
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
            <Group name="用途"><p className="text">{f.purpose || "第一段没有用途说明"}</p></Group>
            <Row name="分组"><span className={"dot g-" + f.group} aria-hidden="true"></span>{groupName[f.group]}</Row>
            <Row name="路径"><a className="open" href={vscodeUrl(file)} data-tip="在 VSCode 里打开">{f.path}</a></Row>
          </Section>
          {f.outline.length > 0 && (
            <Section title="大纲" ui="panel.outline" count={f.outline.length}>
              <Group><ul className="plain">{f.outline.map((h, i) => <li key={i}>{h}</li>)}</ul></Group>
            </Section>
          )}
        </>
      )}
      {tab === "links" && (
        <>
          {(next.length > 0 || prev.length > 0) && (
            <Section title="场景衔接" ui="panel.steps">
              {next.length > 0 && <Group name="下一步"><ul className="plain">{next.map((l) => step(l, "to"))}</ul></Group>}
              {prev.length > 0 && <Group name="上一步"><ul className="plain">{prev.map((l) => step(l, "from"))}</ul></Group>}
            </Section>
          )}
          {(basis.length > 0 || refs.length > 0) && (
            <Section title="引用" ui="panel.refs" count={basis.length + refs.length}>
              {basis.length > 0 && <Group name="依据"><ul className="plain">{basis.map((l) => <li key={l.to}><FileLink index={l.to} onSelect={onSelect} /></li>)}</ul></Group>}
              {refs.length > 0 && <Group name={basis.length > 0 ? "引用" : null}><ul className="plain">{refs.map((l) => <li key={l.to}><FileLink index={l.to} onSelect={onSelect} /></li>)}</ul></Group>}
            </Section>
          )}
          <Section title="被引用" ui="panel.cited" count={citing.length}>
            <Group>{citing.length ? <ul className="plain">{citing.map((l) => <li key={l.from}><FileLink index={l.from} onSelect={onSelect} /></li>)}</ul>
              : <p className="empty-line">没有其他文档链接到它</p>}</Group>
          </Section>
        </>
      )}
      {tab === "quotes" && (cited.length ? cited.map((l, i) => <Quote key={i} link={l} current={file} onSelect={onSelect} />)
        : <p className="empty">没有其他文档链接到它</p>)}
    </aside>
  );
}
