import { Button } from "@/components/ui/button";
import { useMemo, useState } from "react";
import { ArrowLeftIcon, ArrowRightIcon, CodeIcon, TriangleIcon } from "lucide-react";
import DocView from "./DocView.jsx";
import LocalGraph from "./LocalGraph.jsx";
import { files, groupName, incoming, outgoing, paras, vscodePath, vscodeUrl } from "./docs.js";
import { qaOf } from "./QaModule.jsx";
import { docEdges, docKey, docKinds, docNodes, docOf } from "./DocsModule.jsx";
import { entryOf } from "./SearchModule.jsx";
import { store } from "./store.js";
import { Collapsible, CollapsibleTrigger, CollapsibleContent } from "@/components/ui/collapsible";
import { hoverNode, useShownGraph } from "./Graph.jsx";

// 右侧详情面板显示选中对象的原文：标题行、关系图、全文，最后是收起的“被引用处”。
// 选中值有四种：文档的卡片编号；"qa:编号" 是问答的一条；"doc:编号" 是文档关系图的点；"entry:编号" 是术语表、工具表的一行。
// 全文里的文档链接在面板里打开那篇，所以顺着链接一路读下去时，面板的后退、前进就是走过的路。

// 照 draw.io 的格式面板：成对的短属性用“名称 + 取值”两栏的 Row；列表和长文字用 Group，名称写在上方一行，内容占满整行。
// 层级靠字号和间距分开：小节标题比正文大 1px 并加粗，组名用小字次要色；小节之间 12px，组之间 8px，组名到内容 2px
function Row({ name, children }) {
  return <div className="row grid min-h-(--control-h) grid-cols-[var(--prop-name-w)_1fr] items-start gap-2 px-(--pad)"><span className="name text-xs leading-(--control-h) text-muted-foreground">{name}</span><span className="value pt-(--prop-value-top) leading-normal [overflow-wrap:anywhere]">{children}</span></div>;
}
function Group({ name, children }) {
  return <div className="group px-(--pad) pb-2">{name && <div className="group-name mb-0.5 pt-0.5 text-xs text-muted-foreground">{name}</div>}{children}</div>;
}

// 可折叠的小节。给出 store 时记住开合状态（关系图），否则按 open 的初值
function Section({ title, ui, count, open: initial = true, store: key, children }) {
  const [open, setOpen] = useState(() => (key ? store.get(key) !== "closed" : initial));
  const toggle = (v) => { setOpen(v); if (key) store.set(key, v ? "open" : "closed"); };
  return (
    <Collapsible className="section" open={open} data-ui={ui} onOpenChange={toggle}>
      <CollapsibleTrigger asChild><Button variant="ghost" size="none" className="section-trigger h-(--control-h) w-full justify-start gap-0 rounded-none border-0 px-(--pad) text-[length:calc(var(--fs)+1px)] font-semibold">
        <span className="twisty -ml-3 inline-grid place-items-center w-3 text-muted-foreground [&>svg]:size-2!"><TriangleIcon className={"fill-current stroke-0 " + (open ? "rotate-180" : "rotate-90")} aria-hidden="true" /></span>
        <span className="section-title">{title}</span>{count !== undefined && <span className="count">{count}</span>}
      </Button></CollapsibleTrigger>
      <CollapsibleContent>{children}</CollapsibleContent>
    </Collapsible>
  );
}

// 面板标题行：名称、去处按钮和后退、前进，固定在面板顶上，长文档滚到下面时按钮也在；后退、前进在本模块选中过的对象之间移动。
// 下面一行小字写分组和路径。选中的对象不在当前图谱里时，再写一行说明，图上仍突出上一个选中的点
function Head({ title, nav, links = [], sub }) {
  return (
    <>
      <div className="sticky top-0 z-2 flex h-(--panel-head-h) items-center gap-0.5 border-b border-border bg-card pt-1 pr-1 pl-(--pad) font-semibold" data-ui="panel.head">
        <span className="panel-title min-w-0 flex-1 truncate" data-tip={title}>{title}</span>
        {links.map(({ href, tip, icon: Icon, ui }) => (
          <Button key={ui} asChild variant="ghost" size="icon" className="icon-btn"><a href={href} aria-label={tip} data-tip={tip} data-ui={ui}><Icon aria-hidden="true" /></a></Button>
        ))}
        <Button variant="ghost" size="icon" className="icon-btn" aria-label="后退" data-tip={nav.onBack ? "后退" : "没有更早选中的对象"} aria-disabled={!nav.onBack}
          onClick={() => nav.onBack?.()} data-ui="panel.back"><ArrowLeftIcon aria-hidden="true" /></Button>
        <Button variant="ghost" size="icon" className="icon-btn" aria-label="前进" data-tip={nav.onForward ? "前进" : "没有后退过"} aria-disabled={!nav.onForward}
          onClick={() => nav.onForward?.()} data-ui="panel.forward"><ArrowRightIcon aria-hidden="true" /></Button>
      </div>
      {sub && <div className="flex min-w-0 items-center px-(--pad) pt-1.5 text-xs text-muted-foreground" data-ui="panel.sub">{sub}</div>}
      {nav.away && <p className="px-(--pad) pt-0.5 text-xs text-muted-foreground" data-ui="panel.away">不在本图里</p>}
    </>
  );
}

// 文档的分组和路径
function FileSub({ file, line }) {
  const f = files[file];
  return <><span className={"dot g-" + f.group} aria-hidden="true"></span><span className="flex-none">{groupName[f.group]}</span><span className="mx-1.5 flex-none">·</span>
    <span className="min-w-0 truncate" data-tip-clip>{f.path}{line ? ":" + line : ""}</span></>;
}
const vscodeLink = (href) => ({ href, tip: "在 VSCode 里打开", icon: CodeIcon, ui: "panel.vscode" });

// 悬停一项时，图谱上对应的点高亮并写名称
const hover = (key) => ({ onMouseEnter: () => hoverNode(key), onMouseLeave: () => hoverNode(null) });

function FileLink({ index, onSelect }) {
  return <Button variant="link" size="none" className="link-btn max-w-full truncate [.plain_&]:block" onClick={() => onSelect(index)} {...hover(index)} data-float={index} data-tip={files[index].title + "（" + files[index].path + "）"}>{files[index].title}</Button>;
}

// 每个目标只列一次，按第一次出现的顺序
const unique = (list, key) => list.filter((x, i) => list.findIndex((y) => key(y) === key(x)) === i);

// 关系图的两侧：左边指向当前对象的，右边当前对象指向的；同一个对象两个方向都有时只放右边，画两头箭头。主线排在前面，先写名称
function sides(into, out, node) {
  const merge = (list) => {
    const m = new Map();
    for (const { key, main, note } of list) {
      const n = m.get(key) || { ...node(key), main: false, notes: [] };
      n.main ||= Boolean(main);
      if (note && !n.notes.includes(note)) n.notes.push(note);
      m.set(key, n);
    }
    return [...m.values()].map(({ notes, ...n }) => ({ ...n, note: notes.join("；") })).sort((a, b) => b.main - a.main);
  };
  const right = merge(out), rightKeys = new Set(right.map((n) => n.key));
  const left = merge(into);
  for (const n of right) n.both = left.some((l) => l.key === n.key);
  return { left: left.filter((n) => !rightKeys.has(n.key)), right };
}
// float 是悬停弹浮窗时显示的卡片编号
const fileNode = (i) => ({ key: i, label: files[i].title, color: `var(--g-${files[i].group})`, float: i });
const kindColor = (k) => `var(--p${docKinds.findIndex((g) => g.id === docNodes[k].kind) + 1})`;
function fileSides(file) {
  return sides(incoming[file].filter((l) => l.from !== file).map((l) => ({ key: l.from, main: l.main, note: l.cond })),
    outgoing[file].filter((l) => l.to !== file).map((l) => ({ key: l.to, main: l.main, note: l.cond })), fileNode);
}

function GraphSection({ center, left, right, onSelect, font }) {
  return (
    <Section title="关系" ui="panel.links" count={left.length + right.length} store="panel.graph">
      <LocalGraph center={center} left={left} right={right} onSelect={onSelect} font={font} />
    </Section>
  );
}

// 全文：链接到别的文档时在面板里打开那篇；链接到本文的锚点时只滚动
function Doc({ card, jump: initial, only, onSelect, font }) {
  const [jump, setJump] = useState(initial);
  return (
    <article className="learn-body panel-doc" data-ui="panel.doc">
      <DocView card={card} jump={jump} only={only} font={font} onLink={(i, anchor) => (i === card ? setJump({ anchor }) : onSelect(i))} />
    </article>
  );
}

// 引用它的那一段原文：指向当前文档的链接高亮，点它跳到来源文档
function Quote({ link, current, onSelect }) {
  const p = paras[link.para];
  return (
    <div className="border-t border-border px-(--pad) py-1.5">
      <div className="flex items-baseline gap-2">
        <FileLink index={p.file} onSelect={onSelect} />
        <Button asChild variant="link" size="none"><a className="open ml-auto flex-none text-xs text-primary" href={vscodeUrl(p.file, p.line)} data-tip="在 VSCode 里打开这一行">第 {p.line} 行</a></Button>
      </div>
      <p className="mt-1 line-clamp-4 text-xs text-muted-foreground [overflow-wrap:anywhere]">
        {p.parts.map((part, i) => (typeof part === "string" ? part
          : part.to === current ? <mark key={i} className="rounded-(--mark-radius) bg-accent font-bold text-foreground">{part.text}</mark> : <span key={i} className="text-foreground">{part.text}</span>))}
      </p>
    </div>
  );
}
// 被引用处放在全文后面，默认收起，因为它是别的文档怎样引用这篇，读全文时用不到
function Cited({ file, onSelect }) {
  const cited = unique(incoming[file].filter((l) => l.from !== file), (l) => l.para);
  if (!cited.length) return null;
  return (
    <Section title="被引用处" ui="panel.cited" count={cited.length} open={false}>
      {cited.map((l, i) => <Quote key={i} link={l} current={file} onSelect={onSelect} />)}
    </Section>
  );
}

// 文档：标题行、关系图、全文、被引用处
function FilePanel({ file, onSelect, nav, font }) {
  const f = files[file];
  const { left, right } = useMemo(() => fileSides(file), [file]);
  return (
    <aside className="panel" aria-label="详情" data-ui="panel">
      <Head title={f.title} nav={nav} links={[vscodeLink(vscodeUrl(file))]} sub={<FileSub file={file} />} />
      <GraphSection center={fileNode(file)} left={left} right={right} onSelect={onSelect} font={font} />
      <Doc card={file} onSelect={onSelect} font={font} />
      <Cited file={file} onSelect={onSelect} />
    </aside>
  );
}

// 问答的一条：只显示所在问答文件里这一条的正文，不带同一主题的其他问答；关系图右边是它的依据
function QaPanel({ q, onSelect, nav, font }) {
  const right = q.basis.map((i) => ({ ...fileNode(i), main: false, note: "" }));
  return (
    <aside className="panel" aria-label="详情" data-ui="panel">
      <Head title={q.title} nav={nav} sub={<FileSub file={q.file} line={q.line} />}
        links={[vscodeLink(vscodeUrl(q.file, q.line))]} />
      <GraphSection center={{ key: null, label: q.title, color: `var(--g-${files[q.file].group})` }} left={[]} right={right} onSelect={onSelect} font={font} />
      <Doc card={q.file} only={q.title} onSelect={onSelect} font={font} />
    </aside>
  );
}

// 文档关系图的点：有模板文件时显示模板全文；没有时写介绍、位置和出处
function DocPanel({ k, onSelect, nav, font }) {
  const n = docNodes[k];
  const { left, right } = useMemo(() => sides(
    docEdges.filter((e) => e.to === k).map((e) => ({ key: docKey(e.from), note: e.label })),
    docEdges.filter((e) => e.from === k).map((e) => ({ key: docKey(e.to), note: e.label })),
    (key) => ({ key, label: docNodes[docOf(key)].label, color: kindColor(docOf(key)), float: docNodes[docOf(key)].card ?? undefined })), [k]);
  const kind = docKinds.find((g) => g.id === n.kind);
  const sub = <><span className="dot" style={{ background: kindColor(k) }} aria-hidden="true"></span><span className="min-w-0 truncate">{kind.name}{n.card !== null ? " · 模板 " + files[n.card].path : ""}</span></>;
  return (
    <aside className="panel" aria-label="详情" data-ui="panel">
      <Head title={n.label} nav={nav} sub={sub} links={n.card !== null ? [vscodeLink(vscodeUrl(n.card))] : n.template ? [vscodeLink(vscodePath(n.template))] : []} />
      <GraphSection center={{ key: docKey(k), label: n.label, color: kindColor(k) }} left={left} right={right} onSelect={onSelect} font={font} />
      {n.card !== null ? <Doc card={n.card} onSelect={onSelect} font={font} /> : (
        <Section title="说明" ui="panel.summary">
          {n.label !== n.name && <Group name="名称"><p className="text">{n.name}</p></Group>}
          <Group name="介绍"><p className="text">{n.template ? "模板文件没有介绍文字，打开模板查看内容" : n.note || "没有对应的模板文件，项目里按需要创建"}</p></Group>
          {n.paths.length > 0 && <Group name="位置"><ul className="plain">{n.paths.map((p) => <li key={p}><code>{p}</code></li>)}</ul></Group>}
          {n.template && <Row name="模板"><Button asChild variant="link" size="none"><a className="open text-primary" href={vscodePath(n.template)} data-tip="在 VSCode 里打开">{n.template}</a></Button></Row>}
          <Group name="出处"><ul className="plain">{n.from.map((f) => <li key={f}><FileLink index={f} onSelect={onSelect} /></li>)}</ul></Group>
        </Section>
      )}
    </aside>
  );
}

// 术语表、工具表里的一行：显示所在文档的全文，滚到这一行并高亮
function EntryPanel({ e, onSelect, nav, font }) {
  const jump = useMemo(() => ({ row: e.name }), [e]);
  const { left, right } = useMemo(() => fileSides(e.file), [e]);
  return (
    <aside className="panel" aria-label="详情" data-ui="panel">
      <Head title={e.name} nav={nav} links={[vscodeLink(vscodeUrl(e.file, e.line))]} sub={<FileSub file={e.file} line={e.line} />} />
      <GraphSection center={fileNode(e.file)} left={left} right={right} onSelect={onSelect} font={font} />
      <Doc card={e.file} jump={jump} onSelect={onSelect} font={font} />
    </aside>
  );
}

// 选中对象的名称，详情面板收起时的提示用它
export function titleOf(value) {
  const q = qaOf(value), e = entryOf(value);
  return q ? q.title : e ? e.name : docOf(value) !== null ? docNodes[docOf(value)].label : files[value].title;
}

export default function DetailPanel({ file, onSelect, onBack, onForward, font }) {
  const graph = useShownGraph();
  const nav = { onBack, onForward, away: graph !== null && file !== null && !Object.hasOwn(graph, file) };
  const q = qaOf(file), e = entryOf(file);
  if (q) return <QaPanel key={file} q={q} onSelect={onSelect} nav={nav} font={font} />;
  if (e) return <EntryPanel key={file} e={e} onSelect={onSelect} nav={nav} font={font} />;
  if (docOf(file) !== null) return <DocPanel key={file} k={docOf(file)} onSelect={onSelect} nav={nav} font={font} />;
  if (file === null) {
    return (
      <aside className="panel" aria-label="详情" data-ui="panel">
        <Head title="详情" nav={nav} />
        <p className="empty" data-ui="panel.empty">在主区域选中一个文件</p>
      </aside>
    );
  }
  return <FilePanel key={file} file={file} onSelect={onSelect} nav={nav} font={font} />;
}
