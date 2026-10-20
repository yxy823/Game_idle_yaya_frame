// 交付前的界面冒烟检查：用本机 Edge 无头打开构建好的 dist/index.html，检查界面设计「验证」一条列出的几项。
// 先运行 npm run build，再运行 npm run check；有一项不通过时退出码为 1。
import path from "node:path";
import { readFile, readdir } from "node:fs/promises";
import { pathToFileURL } from "node:url";
import { chromium } from "playwright-core";

const dist = path.resolve(import.meta.dirname, "..", "dist");
const page_ = pathToFileURL(path.join(dist, "index.html")).href;
const MODULES = ["home", "scenes", "docs", "learn", "files", "qa", "search"];
// 在顶栏放搜索的模块；首页不放，全局搜索页的输入框留在页面里
const SEARCH_IN_TOPBAR = ["scenes", "docs", "learn", "files", "qa"];

const results = [];
const check = (name, ok, detail = "") => results.push({ name, ok, detail });

const outputs = await readdir(dist, { recursive: true });
check("dist 只包含 index.html", outputs.length === 1 && outputs[0] === "index.html", outputs.join("，"));
const html = await readFile(path.join(dist, "index.html"), "utf8");
const browser = await chromium.launch({ channel: "msedge", headless: true });
const context = await browser.newContext({ offline: true, viewport: { width: 1280, height: 800 } });
const page = await context.newPage();
const errors = [];
const remote = [];
const failedRequests = [];
page.on("request", (r) => { if (/^https?:/i.test(r.url())) remote.push(r.url()); });
page.on("requestfailed", (r) => failedRequests.push(`${r.url()}: ${r.failure()?.errorText}`));
page.on("pageerror", (e) => errors.push(e.message));
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()); });
await page.goto(page_);
await page.waitForSelector("[data-ui='activity.home']");

const resources = await page.evaluate((html) => {
  const doc = new DOMParser().parseFromString(html, "text/html");
  const external = [...doc.querySelectorAll("script[src], link[href]")]
    .map((el) => el.getAttribute("src") ?? el.getAttribute("href"))
    .filter((url) => !url.startsWith("data:"));
  const imports = [...doc.querySelectorAll("style")].flatMap((el) => el.textContent.match(/@import\b[^;]*;/gi) || []);
  return [...external, ...imports];
}, html);
check("HTML 不引用外部脚本、样式或字体", resources.length === 0, resources.join(" | "));

const open = async (id) => { await page.click(`[data-ui='activity.${id}']`); await page.waitForTimeout(800); };

// 依次进入每个模块，再切回首页：切走时各模块卸载，图谱的清理代码在这时运行
for (const id of [...MODULES, "home"]) {
  await open(id);
  const state = await page.evaluate((id) => {
    const main = document.querySelector(".module");
    if (!main) return { blank: true };
    const width = main.getBoundingClientRect().width;
    // 只放了一个控件的行：占主区域一半以上的宽度，里面只有一个按钮或输入框，没有别的文字；正文里的文字链接（.link-btn）不算
    const lone = [...main.querySelectorAll("*")].filter((el) => {
      if (el.children.length !== 1 || el.textContent.trim() !== el.children[0].textContent.trim()) return false;
      const c = el.children[0];
      if (!c.matches("button:not(.link-btn), input, .page-search")) return false;
      return el.getBoundingClientRect().width > width / 2 && c.getBoundingClientRect().width < width / 4;
    });
    return {
      blank: false,
      lone: lone.map((el) => el.className || el.tagName),
      topbarSearch: Boolean(document.querySelector(`.search-slot [data-ui='${id}.search']`)),
    };
  }, id);
  check(`进入 ${id}：页面没有白屏`, !state.blank);
  if (state.blank) continue;
  check(`进入 ${id}：主区域没有只放一个控件的行`, state.lone.length === 0, state.lone.slice(0, 3).join("，"));
  if (SEARCH_IN_TOPBAR.includes(id)) check(`进入 ${id}：搜索在顶栏`, state.topbarSearch);
}
check("切换模块过程中控制台没有报错", errors.length === 0, errors.slice(0, 3).join(" | "));

// 详情面板里的各级元素左缘相同：标题、小节标题、组名、条件、名称列和列表链接；小节的实心三角挂在左内边距里
async function panelEdges(label) {
  for (let t = 0; t < 3; t++) {
    const tabs = await page.$$(".panel-tabs button");
    if (tabs[t]) { await tabs[t].click(); await page.waitForTimeout(200); }
    const edges = await page.evaluate(() => {
      const left = document.querySelector(".panel").getBoundingClientRect().left;
      const pick = (sel) => [...document.querySelectorAll(sel)].filter((e) => e.getClientRects().length)
        .map((e) => Math.round((e.getBoundingClientRect().left - left) * 10) / 10);
      return {
        title: pick(".panel-title"), section: pick(".section > summary .section-title"),
        group: pick(".group-name"), cond: pick(".plain .cond"), name: pick(".row .name"), link: pick(".plain .link-btn"),
      };
    });
    const carets = await page.evaluate(() => {
      const left = document.querySelector(".panel").getBoundingClientRect().left;
      return [...document.querySelectorAll(".section > summary .twisty svg path:not([stroke='none'])")].filter((e) => e.getClientRects().length)
        .map((e) => { const r = e.getBoundingClientRect(); return [r.left - left, r.right - left]; });
    });
    const base = edges.title[0];
    const hang = carets.filter(([l, r]) => l < 1 || r > base);
    check(`${label}第 ${t + 1} 个标签：小节三角在左内边距里`, hang.length === 0, hang.slice(0, 3).map(([l, r]) => `${l.toFixed(1)}–${r.toFixed(1)}`).join("，"));
    const off = Object.entries(edges).flatMap(([k, list]) => list.filter((x) => Math.abs(x - base) > 1).map((x) => `${k}=${x}`));
    check(`${label}第 ${t + 1} 个标签：左缘都在 ${base}px`, off.length === 0, [...new Set(off)].slice(0, 5).join("，"));
    if (!tabs.length) break;
  }
}
await open("files");
if (await page.isVisible("[data-ui='files.view-switch'] button:first-child")) await page.click("[data-ui='files.view-switch'] button:first-child");
if (await page.evaluate(() => document.querySelector(".workspace").classList.contains("panel-closed"))) await page.click("[data-ui='topbar.panel-toggle']");
await page.click(".cards .card");
await page.waitForTimeout(300);
await panelEdges("文件全景卡片的详情面板，");
// 开发场景从顶栏搜索选中一个场景，场景衔接一节有条件和“主线”标记
await open("scenes");
await page.click("[data-ui='scenes.search']");
await page.fill("input[data-ui='scenes.search']", "GDD");
await page.keyboard.press("Enter");
await page.waitForTimeout(800);
await panelEdges("开发场景的详情面板，");

check("离线进入七个模块没有远程请求或资源加载失败", remote.length === 0 && failedRequests.length === 0,
  [...remote, ...failedRequests].join(" | "));
await browser.close();
for (const r of results) console.log(`${r.ok ? "通过" : "不通过"}  ${r.name}${r.detail ? "：" + r.detail : ""}`);
const failed = results.filter((r) => !r.ok).length;
console.log(`共 ${results.length} 项，不通过 ${failed} 项`);
process.exit(failed ? 1 : 0);
