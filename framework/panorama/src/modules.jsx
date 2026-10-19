import { IconAffiliate, IconBook, IconFiles, IconHelpCircle, IconHome, IconLayoutGrid, IconSearch } from "@tabler/icons-react";
import data from "virtual:panorama-data";
import Diagram from "./Diagram.jsx";
import DocsModule from "./DocsModule.jsx";
import FilesModule from "./FilesModule.jsx";
import { files } from "./docs.js";
import { unfoldGroup } from "./Graph.jsx";
import LearnModule, { openChapter } from "./LearnModule.jsx";
import QaModule from "./QaModule.jsx";
import ScenesModule from "./ScenesModule.jsx";
import SearchModule from "./SearchModule.jsx";

// 首页流程图的每一步对应开发场景的哪个分类；键是 framework/README.md 流程图里的节点 ID。
// null 表示只打开开发场景，不展开分类
const STEP_SCENES = {
  creator: "项目与环境", project: "项目与环境", you: null, gdd: "游戏想法与 GDD", product: "规划 Product 与 Feature",
  plan: "规划 Product 与 Feature", execute: "实施与调参", accept: "审核与人工验收", done: "复盘与沉淀", sync: "要求变了",
};
const stepLinks = Object.fromEntries(Object.entries(STEP_SCENES)
  .map(([id, c]) => [id, c ? `到开发场景，展开“${c}”` : "到开发场景"]));

const frameworkCard = files.findIndex((f) => f.path === "framework/README.md");

// 首页三段的文字和图都从文档读出：框架入口的开头一段、「框架做什么」一节，Godot 项目手册 README 的「先建立的整体印象」
function Home({ onModule }) {
  const open = (id) => { if (STEP_SCENES[id]) unfoldGroup("scenes", STEP_SCENES[id]); onModule("scenes"); };
  const learn = () => { openChapter(0); onModule("learn"); };
  return (
    <>
      <h1 data-ui="home.title">框架是什么</h1>
      <p className="lead">{files[frameworkCard].purpose}</p>
      <p className="home-links">
        <button className="link-btn" onClick={() => onModule("files")}>到文件全景看全部文件</button>
      </p>
      <h2 className="home-h2">框架做什么</h2>
      <p className="lead">{data.home.framework.lead}点一步，跳到开发场景并展开这一步相关的分类。</p>
      <Diagram ui="home.flow" text={data.home.framework.flow} links={stepLinks} onNode={open} />
      <h2 className="home-h2">生成项目里一个 Feature 怎样走完</h2>
      <p className="lead">{data.home.feature.lead}</p>
      <Diagram ui="home.feature" text={data.home.feature.flow} />
      <p className="home-links">
        <button className="link-btn" onClick={learn}>到学习，从手册首页读起</button>
        <button className="link-btn" onClick={() => onModule("docs")}>到文档关系看这些文档怎样关联</button>
      </p>
    </>
  );
}

// 活动栏的顺序就是数组顺序
export const modules = [
  { id: "home", label: "首页", tip: "首页：框架做什么", Icon: IconHome, render: (p) => <Home {...p} /> },
  { id: "scenes", label: "开发场景", tip: "开发场景", Icon: IconAffiliate, render: (p) => <ScenesModule {...p} /> },
  { id: "docs", label: "文档关系", tip: "文档关系", Icon: IconFiles, render: (p) => <DocsModule {...p} /> },
  { id: "learn", label: "学习", tip: "学习：Godot 项目手册", Icon: IconBook, render: (p) => <LearnModule {...p} /> },
  { id: "files", label: "文件全景", tip: "文件全景", Icon: IconLayoutGrid, render: (p) => <FilesModule {...p} /> },
  { id: "qa", label: "问答", tip: "问答", Icon: IconHelpCircle, render: (p) => <QaModule {...p} /> },
  { id: "search", label: "搜索结果", tip: "搜索结果", Icon: IconSearch, render: (p) => <SearchModule {...p} /> },
];
