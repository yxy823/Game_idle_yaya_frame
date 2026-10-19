function Row({ name, value }) {
  return <div className="row"><span className="name">{name}</span><span className="value">{value}</span></div>;
}

// 右侧详情面板，照 draw.io 的属性面板：分节可以折叠，每行左边是名称、右边是值。
export default function DetailPanel({ file }) {
  return (
    <aside className="panel" aria-label="详情" data-ui="panel">
      <div className="panel-head" data-ui="panel.head">{file ? file.path.split("/").pop() : "详情"}</div>
      {!file ? <p className="empty" data-ui="panel.empty">在主区域选中一个文件</p> : (
        <div>
          <details className="section" open data-ui="panel.summary"><summary>摘要</summary>
            <Row name="用途" value={file.summary} />
          </details>
          <details className="section" open data-ui="panel.outline"><summary>大纲</summary>
            <Row name="标题" value={file.outline} />
          </details>
          <details className="section" open data-ui="panel.usage"><summary>用在哪里</summary>
            <Row name="场景" value={file.scenes} />
            <Row name="被引用" value={file.refs} />
            <Row name="问答" value={file.qa} />
          </details>
          <details className="section" open data-ui="panel.history"><summary>修改</summary>
            <Row name="最近" value={file.changed} />
          </details>
        </div>
      )}
    </aside>
  );
}
