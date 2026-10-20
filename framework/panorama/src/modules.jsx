import { Button } from "@/components/ui/button";
import { IconAffiliate, IconBook, IconFiles, IconHelpCircle, IconHome, IconLayoutGrid, IconSearch } from "@tabler/icons-react";
import data from "virtual:panorama-data";
import Diagram from "./Diagram.jsx";
import DocsModule from "./DocsModule.jsx";
import FilesModule from "./FilesModule.jsx";
import { files } from "./docs.js";
import { focusGroup, unfoldGroup } from "./Graph.jsx";
import LearnModule, { openChapter } from "./LearnModule.jsx";
import QaModule from "./QaModule.jsx";
import ScenesModule from "./ScenesModule.jsx";
import SearchModule from "./SearchModule.jsx";

// 首页流程图的每一步对应开发场景的哪个分类；键是 framework/README.md 流程图里的节点 ID。
// 有分类时，开发场景直接进入这个分类的邻居视图，点“返回全图”回到全图并保持分类展开；null 表示只打开开发场景，不展开分类；STAGES 表示滚到首页的「Feature 的执行阶段」一段
const STAGES = "stages";
const STEP_SCENES = {
  creator: "项目与环境", project: "项目与环境", you: null, gdd: "游戏想法与 GDD", product: "规划 Product 与 Feature",
  plan: "规划 Product 与 Feature", execute: STAGES, accept: "审核与人工验收", done: "复盘与沉淀", sync: "要求变了",
};
const stepLinks = Object.fromEntries(Object.entries(STEP_SCENES)
  .map(([id, c]) => [id, c === STAGES ? "看下面的 Feature 的执行阶段" : c ? `到开发场景，只看“${c}”和直接相连的场景` : "到开发场景"]));

// 文档里的一张表，第一行是表头
function Table({ rows, ui }) {
  return (
    <div className="learn-body home-table" data-ui={ui}>
      <table>
        <thead><tr>{rows[0].map((c, i) => <th key={i}>{c}</th>)}</tr></thead>
        <tbody>{rows.slice(1).map((r, i) => <tr key={i}>{r.map((c, j) => <td key={j}>{c}</td>)}</tr>)}</tbody>
      </table>
    </div>
  );
}

const frameworkCard = files.findIndex((f) => f.path === "framework/README.md");

// 首页四段的文字、图和表都从文档读出：框架入口的开头一段、「框架做什么」一节，Godot 项目手册 README 的「先建立的整体印象」，
// 以及手册「任务类型、开发阶段与完成语义」的「Feature 的执行阶段」
function Home({ onModule, font }) {
  const open = (id) => {
    if (STEP_SCENES[id] === STAGES) { document.querySelector("[data-ui='home.stages']").scrollIntoView({ behavior: "smooth" }); return; }
    if (STEP_SCENES[id]) { unfoldGroup("scenes", STEP_SCENES[id]); focusGroup("scenes", STEP_SCENES[id]); }
    onModule("scenes");
  };
  const learn = () => { openChapter(0); onModule("learn"); };
  return (
    <div className="home">
      <h2 className="home-h2" data-ui="home.what">框架是什么</h2>
      <p className="lead">{files[frameworkCard].purpose}</p>
      <p className="home-links">
        <Button variant="link" size="none" className="link-btn max-w-full truncate [.plain_&]:block" onClick={() => onModule("files")}>到文件全景看全部文件</Button>
      </p>
      <h2 className="home-h2">框架做什么</h2>
      <p className="lead">{data.home.framework.lead}</p>
      <Diagram ui="home.flow" text={data.home.framework.flow} links={stepLinks} onNode={open} font={font} />
      <h2 className="home-h2">生成项目里一个 Feature 怎样走完</h2>
      <p className="lead">{data.home.feature.lead}</p>
      <Diagram ui="home.feature" text={data.home.feature.flow} font={font} />
      {data.home.feature.legend && <p className="lead">{data.home.feature.legend}</p>}
      <p className="home-links">
        <Button variant="link" size="none" className="link-btn max-w-full truncate [.plain_&]:block" onClick={learn}>到学习，从手册首页读起</Button>
        <Button variant="link" size="none" className="link-btn max-w-full truncate [.plain_&]:block" onClick={() => onModule("docs")}>到文档关系看这些文档怎样关联</Button>
      </p>
      <h2 className="home-h2" data-ui="home.stages">Feature 的执行阶段</h2>
      <p className="lead">{data.home.stages.lead}</p>
      <Diagram ui="home.stage-flow" text={data.home.stages.flow} font={font} />
      {data.home.stages.subs.map((s) => (
        <div key={s.caption}>
          <p className="lead">{s.caption}</p>
          <Diagram ui="home.stage-sub" text={s.flow} font={font} />
        </div>
      ))}
      {data.home.stages.legend && <p className="lead">{data.home.stages.legend}</p>}
      {data.home.stages.table && <Table rows={data.home.stages.table} ui="home.stage-table" />}
    </div>
  );
}

// 活动栏的顺序就是数组顺序
export const modules = [
  { id: "home", label: "首页", tip: "首页", Icon: IconHome, render: (p) => <Home {...p} /> },
  { id: "scenes", label: "开发场景", tip: "开发场景", Icon: IconAffiliate, render: (p) => <ScenesModule {...p} /> },
  { id: "docs", label: "文档关系", tip: "文档关系", Icon: IconFiles, render: (p) => <DocsModule {...p} /> },
  { id: "learn", label: "学习", tip: "学习：Godot 项目手册", Icon: IconBook, render: (p) => <LearnModule {...p} /> },
  { id: "files", label: "文件全景", tip: "文件全景", Icon: IconLayoutGrid, render: (p) => <FilesModule {...p} /> },
  { id: "qa", label: "问答", tip: "问答", Icon: IconHelpCircle, render: (p) => <QaModule {...p} /> },
  { id: "search", label: "全局搜索", tip: "全局搜索：查全部文档、问答、术语和工具", Icon: IconSearch, render: (p) => <SearchModule {...p} /> },
];
