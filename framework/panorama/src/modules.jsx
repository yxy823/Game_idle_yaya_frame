import { IconAffiliate, IconBook, IconFiles, IconHelpCircle, IconHome, IconLayoutGrid, IconSearch } from "@tabler/icons-react";
import data from "virtual:panorama-data";
import Diagram from "./Diagram.jsx";

// 详情面板的演示数据，等构建脚本读出真实卡片后删除
export const demoFiles = [
  { path: "framework/godot-project-manual/README.md", summary: "本册解释用框架创建的 Godot 项目：项目与框架的边界、游戏逻辑与表现、项目文档、配置、Skill 与工具。",
    outline: "先建立的整体印象、按对象查阅……", scenes: "（占位）", refs: "framework/README.md 等（占位）", qa: "（占位）", changed: "2026-10-16" },
  { path: "framework/maintenance/validation/test-change-scenarios.md", summary: "按“谁、怎样、什么时候改了什么”列出项目里文件改动的全部组合。",
    outline: "定义、维度、主表……", scenes: "修改测试选择时逐行核对（占位）", refs: "framework/maintenance/README.md 等（占位）", qa: "（占位）", changed: "（占位）" },
  { path: "project-source/skills/behavior-model-check/SKILL.md", summary: "Stage 1C 为有命名状态的行为建立 TLA+ 行为模型，用 TLC 检查设计。",
    outline: "何时使用、模型放在哪里、步骤……", scenes: "Feature 已规划并可开始，现在实施这一项（占位）", refs: "03 号规范 1C（占位）", qa: "（占位）", changed: "2026-10-19" },
];

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

function Files({ selected, onSelect }) {
  return (
    <>
      <h1>文件全景</h1>
      <p className="lead">下面的列表是演示用的假数据，点一项看详情面板。</p>
      <ul className="file-list" data-ui="files.list">
        {demoFiles.map((f, i) => (
          <li key={f.path}>
            <button aria-selected={selected === i} onClick={() => onSelect(i)}><span className="path">{f.path}</span></button>
          </li>
        ))}
      </ul>
      <div style={{ marginTop: 12 }}>
        <Placeholder ui="files.placeholder" todo="左边目录树，中间是所选目录的卡片列表，选中卡片在详情面板显示。" source="各 Markdown 文件的标题、第一段和链接，Git 记录（最后修改时间、修改次数）" />
      </div>
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
  { id: "scenes", label: "开发场景", tip: "开发场景", Icon: IconAffiliate, render: () => (
    <Simple title="开发场景" lead="每个场景是项目处在的一种情况；连线是“做完这一步，接下来可能进入哪种情况”。" ui="scenes.placeholder"
      todo="二维图谱：默认按分组折叠；点开分组展开场景；点一个场景，只留它 1–2 跳以内的邻居并重新排布。主线画实线，其余画虚线。节点连到场景页和同名提示词。"
      source="各场景页「流程关联与衔接关系」末尾的下一步清单（主线项带“主线：”）、两份预设提示词库" />
  ) },
  { id: "docs", label: "文档关系", tip: "文档关系", Icon: IconFiles, render: () => (
    <Simple title="文档关系" lead="文档从哪里找到，设计、任务、实现说明和验证依据怎样关联。" ui="docs.placeholder"
      todo="显示 Godot 项目手册中的文档关系图，点图里的文档打开它的卡片。"
      source="framework/godot-project-manual/ 中的 Mermaid 图" />
  ) },
  { id: "learn", label: "学习", tip: "学习：Godot 项目手册", Icon: IconBook, render: () => (
    <Simple title="学习" lead="第一次了解框架和生成项目时，按章节顺序读 Godot 项目手册。" ui="learn.placeholder"
      todo="手册的章节目录，按阅读顺序排列；点章节在页面里显示正文。" source="framework/godot-project-manual/ 的 README 和各章标题" />
  ) },
  { id: "files", label: "文件全景", tip: "文件全景", Icon: IconLayoutGrid, render: (p) => <Files {...p} /> },
  { id: "qa", label: "问答", tip: "问答", Icon: IconHelpCircle, render: () => (
    <Simple title="问答" lead="讨论中问过、以后还会用到的问题。" ui="qa.placeholder"
      todo="按主题列出问题，点一条在详情面板显示，按钮打开问答页面里的这一条。" source="framework/qa/ 的主题文件和 pages/" />
  ) },
  { id: "search", label: "搜索结果", tip: "搜索结果", Icon: IconSearch, render: () => (
    <Simple title="搜索结果" lead="在顶栏输入后显示；每条结果标明所在模块和文件位置。" ui="search.placeholder"
      todo="搜索标题、第一段、Skill 描述、工具用途和术语别名。" source="各文件的标题与第一段、SKILL.md 的 description、工具说明的工具表、两份术语表" />
  ) },
];
