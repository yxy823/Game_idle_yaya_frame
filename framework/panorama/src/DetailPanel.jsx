import { files, groupName, incoming, outgoing, paras, vscodeUrl } from "./docs.js";

function Row({ name, children }) {
  return <div className="row"><span className="name">{name}</span><span className="value">{children}</span></div>;
}

function Section({ title, ui, count, children }) {
  return (
    <details className="section" open data-ui={ui}>
      <summary>{title}{count !== undefined && <span className="count">{count}</span>}</summary>
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

// 右侧详情面板，照 draw.io 的属性面板：分节可以折叠，每行左边是名称、右边是值。
export default function DetailPanel({ file, onSelect }) {
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
  const step = (l, end) => (
    <li key={l.from + "-" + l.to + "-" + l.para}>
      {l.main && <span className="tag">主线</span>}<span className="cond">{l.cond}</span><FileLink index={l[end]} onSelect={onSelect} />
    </li>
  );
  return (
    <aside className="panel" aria-label="详情" data-ui="panel">
      <div className="panel-head" data-ui="panel.head" data-tip={f.title}>{f.title}</div>
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
      <Section title="被引用" ui="panel.cited" count={cited.length}>
        {cited.length ? cited.map((l, i) => <Quote key={i} link={l} current={file} onSelect={onSelect} />)
          : <p className="empty">没有其他文档链接到它</p>}
      </Section>
      <Section title="修改" ui="panel.history">
        <Row name="最近">{f.changed || "还没提交"}</Row>
        <Row name="次数">{f.changes}</Row>
      </Section>
    </aside>
  );
}
