import { IconAffiliate, IconBook, IconFiles, IconHelpCircle, IconHome, IconLayoutGrid, IconSearch } from "@tabler/icons-react";
import data from "virtual:panorama-data";
import Diagram from "./Diagram.jsx";
import DocsModule from "./DocsModule.jsx";
import FilesModule from "./FilesModule.jsx";
import { unfoldGroup } from "./Graph.jsx";
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

// 首页流程图的每一步对应开发场景的哪个分类；键是 framework/README.md 流程图里的节点 ID。
// null 表示只打开开发场景，不展开分类
const STEP_SCENES = {
  creator: "项目与环境", project: "项目与环境", you: null, gdd: "游戏想法与 GDD", product: "规划 Product 与 Feature",
  plan: "规划 Product 与 Feature", execute: "实施与调参", accept: "审核与人工验收", sync: "要求变了",
};
const stepLinks = Object.fromEntries(Object.entries(STEP_SCENES)
  .map(([id, c]) => [id, c ? `到开发场景，展开“${c}”` : "到开发场景"]));

function Home({ onModule }) {
  const open = (id) => { if (STEP_SCENES[id]) unfoldGroup("scenes", STEP_SCENES[id]); onModule("scenes"); };
  return (
    <>
      <h1 data-ui="home.title">框架做什么</h1>
      <p className="lead">创建器生成 Godot 项目，项目里按下面的主线开发。方框里是负责这一步的 Skill；点一步，跳到开发场景并展开这一步相关的分类。</p>
      <Diagram ui="home.flow" text={data.homeFlow} links={stepLinks} onNode={open} />
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
  { id: "home", label: "首页", tip: "首页：框架做什么", Icon: IconHome, render: (p) => <Home {...p} /> },
  { id: "scenes", label: "开发场景", tip: "开发场景", Icon: IconAffiliate, render: (p) => <ScenesModule {...p} /> },
  { id: "docs", label: "文档关系", tip: "文档关系", Icon: IconFiles, render: (p) => <DocsModule {...p} /> },
  { id: "learn", label: "学习", tip: "学习：Godot 项目手册", Icon: IconBook, render: () => (
    <Simple title="学习" lead="第一次了解框架和生成项目时，按章节顺序读 Godot 项目手册。" ui="learn.placeholder"
      todo="手册的章节目录，按阅读顺序排列；点章节在页面里显示正文。" source="framework/godot-project-manual/ 的 README 和各章标题" />
  ) },
  { id: "files", label: "文件全景", tip: "文件全景", Icon: IconLayoutGrid, render: (p) => <FilesModule {...p} /> },
  { id: "qa", label: "问答", tip: "问答", Icon: IconHelpCircle, render: (p) => <QaModule {...p} /> },
  { id: "search", label: "搜索结果", tip: "搜索结果", Icon: IconSearch, render: (p) => <SearchModule {...p} /> },
];
