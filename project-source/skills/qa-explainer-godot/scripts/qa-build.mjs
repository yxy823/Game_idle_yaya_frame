// 生成一个问答目录下的全部页面：每个主题文件生成同名 .html，并生成首页 index.html。
// 首页按各主题文件的 title 和 ## 标题自动列出问题，不另外维护问题清单。
// 用法：node qa-build.mjs <问答目录>，在仓库或项目根目录运行。
import { readdirSync, readFileSync } from "node:fs";
import { join, basename } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const AM = fileURLToPath(new URL("./am.mjs", import.meta.url));
const HOME = "index.html";
const HOME_LABEL = "Q&A 首页";

const dir = process.argv[2];
if (!dir) {
  console.error("用法：node qa-build.mjs <问答目录>");
  process.exit(2);
}

// 读取 frontmatter 的 title 和代码块之外的 ## 标题；面板编号与 am.mjs 一致，按出现顺序从 A 开始。
function outline(text) {
  const lines = text.split(/\r?\n/);
  let title = "";
  let start = 0;
  if (lines[0] === "---") {
    const end = lines.indexOf("---", 1);
    for (const line of lines.slice(1, end)) {
      const m = line.match(/^title:\s*(.+)$/);
      if (m) title = m[1].trim();
    }
    start = end + 1;
  }
  const questions = [];
  let fence = false;
  for (const line of lines.slice(start)) {
    if (/^(```|~~~)/.test(line)) fence = !fence;
    else if (!fence && line.startsWith("## ")) questions.push(line.slice(3).replace(/\s*\{[^}]*\}\s*$/, "").trim());
  }
  return { title, questions };
}

function render(source, out) {
  const r = spawnSync(process.execPath, [AM, "render", "-", "-o", out, "--no-open"], { input: source, encoding: "utf8" });
  process.stdout.write(r.stdout);
  process.stderr.write(r.stderr);
  return r.status === 0;
}

const topics = readdirSync(dir).filter((f) => f.endsWith(".md") && f !== "README.md").sort();
let ok = true;
const panels = [];
for (const file of topics) {
  const path = join(dir, file);
  const text = readFileSync(path, "utf8");
  const page = file.replace(/\.md$/, ".html");
  console.log(`# ${path}`);
  // 把返回首页的链接写进 frontmatter 再渲染，主题文件本身不写这两项。
  const withHome = text.replace(/^---\r?\n/, `---\nhome: ${HOME}\nhome_label: ${HOME_LABEL}\n`);
  ok = render(withHome, join(dir, page)) && ok;
  const { title, questions } = outline(text);
  const links = questions.map((q, i) => {
    const id = i < 26 ? String.fromCharCode(65 + i) : `P${i + 1}`;
    return `- [${q}](${page}#panel-${id})`;
  });
  panels.push(`## ${title || basename(file, ".md")}\n\n${links.join("\n")}`);
}

console.log(`# ${join(dir, HOME)}`);
const index = `---\ntemplate: doc\ntitle: Q&A\n---\n按主题列出全部问答，点击问题打开对应页面。\n\n${panels.join("\n\n")}\n`;
ok = render(index, join(dir, HOME)) && ok;
process.exit(ok ? 0 : 1);
