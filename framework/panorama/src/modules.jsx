import { IconAffiliate, IconBook, IconFiles, IconHelpCircle, IconHome, IconLayoutGrid, IconSearch } from "@tabler/icons-react";
import data from "virtual:panorama-data";
import Diagram from "./Diagram.jsx";
import FilesModule from "./FilesModule.jsx";
import QaModule from "./QaModule.jsx";
import ScenesModule from "./ScenesModule.jsx";
import SearchModule from "./SearchModule.jsx";

function Placeholder({ ui, todo, source }) {
  return (
    <dl className="placeholder" data-ui={ui}>
      <dt>待实现</dt><dd>{todo}</dd>
      <dt>数据来源</dt><dd>{source}</dd>
    </dl>
  );
}

function Home() {
  return (
    <>
      <h1 data-ui="home.title">框架做什么</h1>
      <p className="lead">创建器生成 Godot 项目，项目里按下面的主线开发。方框里是负责这一步的 Skill。</p>
      <Diagram ui="home.flow" text={data.homeFlow} />
      <Placeholder ui="home.placeholder" todo="点图里的一步，跳到相关的模块。" source="framework/README.md 的「框架做什么」流程图" />
    </>
  );
}

function Simple({ title, lead, ui, todo, source }) {
  return (
    <>
      <h1>{title}</h1>
      <p className="lead">{lead}</p>
      <Placeholder ui={ui} todo={todo} source={source} />
    </>
  );
}

// 活动栏的顺序就是数组顺序
export const modules = [
  { id: "home", label: "首页", tip: "首页：框架做什么", Icon: IconHome, render: () => <Home /> },
  { id: "scenes", label: "开发场景", tip: "开发场景", Icon: IconAffiliate, render: (p) => <ScenesModule {...p} /> },
  { id: "docs", label: "文档关系", tip: "文档关系", Icon: IconFiles, render: () => (
    <Simple title="文档关系" lead="文档从哪里找到，设计、任务、实现说明和验证依据怎样关联。" ui="docs.placeholder"
      todo="显示 Godot 项目手册中的文档关系图，点图里的文档打开它的卡片。"
      source="framework/godot-project-manual/ 中的 Mermaid 图" />
  ) },
  { id: "learn", label: "学习", tip: "学习：Godot 项目手册", Icon: IconBook, render: () => (
    <Simple title="学习" lead="第一次了解框架和生成项目时，按章节顺序读 Godot 项目手册。" ui="learn.placeholder"
      todo="手册的章节目录，按阅读顺序排列；点章节在页面里显示正文。" source="framework/godot-project-manual/ 的 README 和各章标题" />
  ) },
  { id: "files", label: "文件全景", tip: "文件全景", Icon: IconLayoutGrid, render: (p) => <FilesModule {...p} /> },
  { id: "qa", label: "问答", tip: "问答", Icon: IconHelpCircle, render: (p) => <QaModule {...p} /> },
  { id: "search", label: "搜索结果", tip: "搜索结果", Icon: IconSearch, render: (p) => <SearchModule {...p} /> },
];
