// 交付前的界面冒烟检查：用本机 Edge 无头打开构建好的 dist/index.html，检查界面设计「验证」一条列出的几项。
// 先运行 npm run build，再运行 npm run check；有一项不通过时退出码为 1。
import path from "node:path";
import { readFile, readdir } from "node:fs/promises";
import { pathToFileURL } from "node:url";
import { chromium } from "playwright-core";
import assert from "node:assert/strict";

const dist = path.resolve(import.meta.dirname, "..", "dist");
const page_ = pathToFileURL(path.join(dist, "index.html")).href;
const MODULES = ["home", "scenes", "docs", "learn", "files", "qa", "search"];
// 在顶栏放搜索的模块；首页不放，全局搜索页的输入框留在页面里
const SEARCH_IN_TOPBAR = ["scenes", "docs", "learn", "files", "qa"];

const results = [];
const check = (name, ok, detail = "") => results.push({ name, ok, detail });
const verify = async (name, run) => {
  try { const detail = await run(); check(name, true, detail ?? ""); }
  catch (error) { check(name, false, error.stack); }
};

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
      if (getComputedStyle(el).display === "contents" || !el.getClientRects().length || el.children.length !== 1 || el.textContent.trim() !== el.children[0].textContent.trim()) return false;
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
    const tabs = await page.$$("[data-ui='panel.tabs'] [role='tab']");
    if (tabs[t]) { await tabs[t].click(); await page.waitForTimeout(200); }
    const edges = await page.evaluate(() => {
      const left = document.querySelector(".panel").getBoundingClientRect().left;
      const pick = (sel) => [...document.querySelectorAll(sel)].filter((e) => e.getClientRects().length)
        .map((e) => Math.round((e.getBoundingClientRect().left - left) * 10) / 10);
      return {
        title: pick(".panel-title"), section: pick(".section [data-slot='collapsible-trigger'] .section-title"),
        group: pick(".group-name"), cond: pick(".plain .cond"), name: pick(".row .name"), link: pick(".plain .link-btn"),
      };
    });
    const carets = await page.evaluate(() => {
      const left = document.querySelector(".panel").getBoundingClientRect().left;
      return [...document.querySelectorAll(".section [data-slot='collapsible-trigger'] .twisty svg")].filter((e) => e.getClientRects().length)
        .map((e) => { const r = e.getBoundingClientRect(); return [r.left - left, r.right - left]; });
    });
    const base = edges.title[0];
    const hang = carets.filter(([l, r]) => l < 1 || r > base);
    check(`${label}第 ${t + 1} 个标签：小节三角在左内边距里`, edges.title.length === 1 && tabs.length === 3 && carets.length === edges.section.length && (t === 2 || carets.length > 0) && hang.length === 0, hang.slice(0, 3).map(([l, r]) => `${l.toFixed(1)}–${r.toFixed(1)}`).join("，"));
    const off = Object.entries(edges).flatMap(([k, list]) => list.filter((x) => Math.abs(x - base) > 1).map((x) => `${k}=${x}`));
    check(`${label}第 ${t + 1} 个标签：左缘都在 ${base}px`, edges.title.length === 1 && off.length === 0, [...new Set(off)].slice(0, 5).join("，"));
    if (!tabs.length) break;
  }
}
await open("files");
await page.locator("[data-ui='files.view-switch']").getByRole("tab", { name: "列表", exact: true }).click();
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


const panelWidth = () => page.locator(".panel").evaluate(el => Math.round(el.getBoundingClientRect().width));
const tocWidth = () => page.locator(".side-toc").evaluate(el => Math.round(el.getBoundingClientRect().width));
const dragHandle = async (selector, x) => {
  const r = await page.locator(selector).boundingBox();
  await page.mouse.move(r.x, r.y + Math.min(100, r.height / 2));
  await page.mouse.down(); await page.mouse.move(x, r.y + Math.min(100, r.height / 2), { steps: 8 }); await page.mouse.up();
  await page.waitForTimeout(100);
};
for (const key of ["Tab", "Shift+Tab", "Escape"]) await verify("设置菜单 " + key + " 关闭并保留焦点", async () => {
  const chosen = await page.locator("[data-ui='scenes.graph']").evaluate(el => el._cyreg.cy.nodes(".chosen").map(n => n.id()));
  await page.click("[data-ui='topbar.settings']");
  await page.waitForTimeout(50);
  assert.equal(await page.locator("[role='menuitemcheckbox']").evaluate(el => el === document.activeElement), true);
  await page.keyboard.press(key); await page.waitForTimeout(50);
  assert.equal(await page.locator("[role='menu']").count(), 0);
  assert.equal(await page.evaluate(() => document.activeElement.dataset.ui), key === "Tab" ? "activity.home" : key === "Shift+Tab" ? "topbar.panel-toggle" : "topbar.settings");
  assert.deepEqual(await page.locator("[data-ui='scenes.graph']").evaluate(el => el._cyreg.cy.nodes(".chosen").map(n => n.id())), chosen);
});
await verify("搜索 Portal 结果可选，Esc 只关闭搜索", async () => {
  const input = page.locator("input[data-ui='scenes.search']");
  await input.fill("GDD");
  const item = page.locator("[cmdk-item]").first();
  assert.ok(await item.count());
  await item.click();
  await page.waitForTimeout(100);
  const selected = await page.locator(".panel-title").innerText();
  assert.notEqual(selected, "详情");
  await input.focus(); await page.keyboard.press("Escape");
  assert.equal(await page.locator("input[data-ui='scenes.search']").count(), 0);
  assert.equal(await page.locator(".panel-title").innerText(), selected);
  assert.equal(await page.evaluate(() => document.activeElement.dataset.ui), "scenes.search");
});
await verify("学习搜索 keyboard.type 连续 10 次保留 Stage", async () => {
  await open("learn");
  for (let i = 0; i < 10; i++) {
    await page.click("[data-ui='learn.search']");
    await page.keyboard.type("Stage");
    assert.equal(await page.inputValue("input[data-ui='learn.search']"), "Stage");
    assert.match(await page.locator("input[data-ui='learn.search']").getAttribute("data-src"), /PageSearch\.jsx:\d+$/);
    await page.keyboard.press("Escape");
  }
  return "10/10";
});

await page.setViewportSize({ width: 1440, height: 900 });
await verify("详情分隔条 16px 键步长与双击恢复 320px", async () => {
  const handle = page.locator("[data-ui='panel.resizer']");
  await handle.focus();
  const before = await panelWidth();
  await page.keyboard.press("ArrowLeft"); assert.equal(await panelWidth(), before + 16);
  await page.keyboard.press("ArrowRight"); assert.equal(await panelWidth(), before);
  const r = await handle.boundingBox();
  await page.mouse.dblclick(r.x, r.y + 100);
  assert.equal(await panelWidth(), 320);
});
await verify("详情分隔条 240px 下限、主区至少 480px", async () => {
  await dragHandle("[data-ui='panel.resizer']", 1438);
  assert.equal(await panelWidth(), 240);
  await dragHandle("[data-ui='panel.resizer']", 44);
  assert.equal(await page.locator(".main").evaluate(el => Math.round(el.getBoundingClientRect().width)), 480);
  assert.equal(await panelWidth(), 916);
});
await verify("详情宽度保存：480 → 窄窗 376 → 480", async () => {
  await dragHandle("[data-ui='panel.resizer']", 960);
  assert.equal(await panelWidth(), 480);
  assert.equal(await page.evaluate(() => localStorage.getItem("panel-w")), "480");
  await page.setViewportSize({ width: 900, height: 900 }); await page.waitForTimeout(150);
  assert.equal(await panelWidth(), 376);
  assert.equal(await page.evaluate(() => localStorage.getItem("panel-w")), "480");
  await page.setViewportSize({ width: 1440, height: 900 }); await page.waitForTimeout(150);
  assert.equal(await panelWidth(), 480);
  await page.reload(); await page.waitForSelector("[data-ui='panel']");
  assert.equal(await panelWidth(), 480);
});
await verify("收起详情后内容不可聚焦，展开恢复宽度", async () => {
  await page.click("[data-ui='topbar.panel-toggle']");
  assert.equal(await page.locator("[data-ui='panel.resizer']").isVisible(), false);
  assert.equal(await page.locator(".panel").isVisible(), false);
  await page.locator("[data-ui='panel.back']").evaluate(el => el.focus());
  assert.notEqual(await page.evaluate(() => document.activeElement.dataset.ui), "panel.back");
  await page.click("[data-ui='topbar.panel-toggle']");
  assert.equal(await panelWidth(), 480);
});

await open("learn");
await verify("目录分隔条 160–480px 与 16px 键步长", async () => {
  const handle = page.locator("[data-ui='learn.toc-resizer']");
  const r = await handle.boundingBox();
  await page.mouse.dblclick(r.x, r.y + 100);
  assert.equal(await tocWidth(), 220);
  await handle.focus(); await page.keyboard.press("ArrowRight"); assert.equal(await tocWidth(), 236);
  await page.keyboard.press("ArrowLeft"); assert.equal(await tocWidth(), 220);
  await dragHandle("[data-ui='learn.toc-resizer']", 80); assert.equal(await tocWidth(), 160);
  await dragHandle("[data-ui='learn.toc-resizer']", 800); assert.equal(await tocWidth(), 480);
});
await verify("目录双击恢复 220px，学习与问答共用保存宽度", async () => {
  const r = await page.locator("[data-ui='learn.toc-resizer']").boundingBox();
  await page.mouse.dblclick(r.x, r.y + 100);
  assert.equal(await tocWidth(), 220);
  await page.locator("[data-ui='learn.toc-resizer']").focus(); await page.keyboard.press("ArrowRight");
  await open("qa"); assert.equal(await tocWidth(), 236);
  await open("learn"); assert.equal(await tocWidth(), 236);
  assert.equal(await page.evaluate(() => localStorage.getItem("toc-w")), "236");
});

await verify("data-tip 延迟显示，代理描述保留真实目标的原描述", async () => {
  await page.mouse.move(0, 0); await page.waitForTimeout(350);
  await page.locator("[data-ui='topbar.panel-toggle']").evaluate(el => el.setAttribute("aria-describedby", "existing-description"));
  await page.locator("[data-ui='topbar.panel-toggle']").hover(); await page.waitForTimeout(100);
  assert.equal(await page.locator("[data-slot='tooltip-content']").count(), 0);
  await page.waitForTimeout(350);
  assert.equal(await page.locator("[data-slot='tooltip-content']").count(), 1);
  const ids = (await page.locator("[data-ui='topbar.panel-toggle']").getAttribute("aria-describedby")).split(" ");
  assert.equal(ids[0], "existing-description"); assert.equal(ids.length, 2);
  assert.equal(await page.locator("[data-slot='tooltip-content']").evaluate(el => el.hasAttribute("data-pick-ignore")), true);
  await page.mouse.move(0, 0);
  assert.equal(await page.locator("[data-ui='topbar.panel-toggle']").getAttribute("aria-describedby"), "existing-description");
});
await verify("data-tip-clip：未截断不提示，截断才提示", async () => {
  const candidates = page.locator(".side-toc [data-tip-clip]");
  const states = await candidates.evaluateAll(els => els.map(el => el.scrollWidth > el.clientWidth));
  const full = states.indexOf(false), clipped = states.indexOf(true);
  assert.ok(full >= 0 && clipped >= 0, "需要未截断和截断两个实际目录项");
  await candidates.nth(full).hover(); await page.waitForTimeout(450);
  assert.equal(await page.locator("[data-slot='tooltip-content']").count(), 0);
  await candidates.nth(clipped).hover(); await page.waitForTimeout(450);
  assert.equal(await page.locator("[data-slot='tooltip-content']").innerText(), await candidates.nth(clipped).innerText());
});
await verify("键盘焦点获得 data-tip，Esc 隐藏提示", async () => {
  await page.mouse.move(0, 0); await page.waitForTimeout(350);
  await page.locator("[data-ui='topbar.panel-toggle']").focus(); await page.waitForTimeout(450);
  assert.ok((await page.locator("[data-slot='tooltip-content']").innerText()).includes("Alt+B"));
  await page.keyboard.press("Escape");
  assert.equal(await page.locator("[data-slot='tooltip-content']").count(), 0);
});

await open("files");
await page.locator("[data-ui='files.view-switch']").getByRole("tab", { name: "列表", exact: true }).click();
await page.locator(".cards .card").first().click();
await page.evaluate(() => {
  window.pickedTexts = [];
  Object.defineProperty(navigator, "clipboard", { configurable: true, value: { writeText: async text => { window.pickedTexts.push(text); } } });
});
await page.keyboard.press("Alt+x");
await verify("选取模式点击标签只复制，data-src 指向业务 JSX", async () => {
  const tabs = page.locator("[data-ui='files.view-switch'] [role='tab']");
  await tabs.nth(1).click();
  assert.equal(await tabs.nth(0).getAttribute("aria-selected"), "true");
  const copies = await page.evaluate(() => window.pickedTexts);
  assert.equal(copies.length, 1);
  assert.match(copies[0], /files\.view-switch.*FilesModule\.jsx:\d+/);
  const panelTabs = page.locator("[data-ui='panel.tabs'] [role='tab']");
  const active = await panelTabs.evaluateAll(els => els.findIndex(el => el.getAttribute("aria-selected") === "true"));
  await panelTabs.nth((active + 1) % 3).click();
  assert.equal(await panelTabs.nth(active).getAttribute("aria-selected"), "true");
  assert.equal((await page.evaluate(() => window.pickedTexts)).length, 2);
});
await verify("选取模式拖动详情分隔条只复制，不改宽度", async () => {
  const before = await panelWidth();
  const r = await page.locator("[data-ui='panel.resizer']").boundingBox();
  await page.mouse.click(r.x, r.y + 100);
  await dragHandle("[data-ui='panel.resizer']", r.x - 60);
  assert.equal(await panelWidth(), before);
  assert.ok((await page.evaluate(() => window.pickedTexts)).some(text => text.startsWith("panel.resizer")));
});
await verify("置灰按钮用 aria-disabled，仍可悬停、聚焦及复制", async () => {
  const button = page.locator("[data-ui='panel.forward']");
  assert.equal(await button.getAttribute("aria-disabled"), "true");
  assert.equal(await button.getAttribute("disabled"), null);
  await button.focus();
  assert.equal(await button.evaluate(el => el === document.activeElement), true);
  const r = await button.boundingBox();
  await page.mouse.click(r.x + r.width / 2, r.y + r.height / 2);
  assert.ok((await page.evaluate(() => window.pickedTexts)).some(text => text.startsWith("panel.forward")));
});
await verify("选取模式跳过菜单和 Sonner 浮层", async () => {
  const before = (await page.evaluate(() => window.pickedTexts)).length;
  await page.click("[data-ui='topbar.settings']");
  assert.equal(await page.locator("[role='menu']").evaluate(el => el.hasAttribute("data-pick-ignore")), true);
  await page.locator("[role='menuitemradio']").filter({ hasText: "浅色" }).click();
  assert.equal(await page.locator("[role='menu']").count(), 0);
  const toaster = page.locator("[data-sonner-toaster]");
  assert.equal(await toaster.evaluate(el => Boolean(el.closest("[data-pick-ignore]"))), true);
  assert.equal((await page.evaluate(() => window.pickedTexts)).length, before);
});
await page.keyboard.press("Alt+x");

check("离线进入七个模块没有远程请求或资源加载失败", remote.length === 0 && failedRequests.length === 0,
  [...remote, ...failedRequests].join(" | "));
await browser.close();
for (const r of results) console.log(`${r.ok ? "通过" : "不通过"}  ${r.name}${r.detail ? "：" + r.detail : ""}`);
const failed = results.filter((r) => !r.ok).length;
console.log(`共 ${results.length} 项，不通过 ${failed} 项`);
process.exit(failed ? 1 : 0);
