// 交付前的界面冒烟检查：用本机 Edge 无头打开构建好的 dist/index.html，检查界面设计「验证」一条列出的几项。
// 先运行 npm run build，再运行 npm run check；有一项不通过时退出码为 1。
import path from "node:path";
import { existsSync } from "node:fs";
import { readFile, readdir } from "node:fs/promises";
import vm from "node:vm";
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
      // 图谱画布的高度：第三方样式压过布局类时，容器高度会变成 0，图谱整片空白而不报错
      graphHeight: document.querySelector(`[data-ui='${id}.graph']`)?.getBoundingClientRect().height ?? null,
    };
  }, id);
  check(`进入 ${id}：页面没有白屏`, !state.blank);
  if (state.blank) continue;
  check(`进入 ${id}：主区域没有只放一个控件的行`, state.lone.length === 0, state.lone.slice(0, 3).join("，"));
  if (SEARCH_IN_TOPBAR.includes(id)) check(`进入 ${id}：搜索在顶栏`, state.topbarSearch);
  if (state.graphHeight !== null) check(`进入 ${id}：图谱画布有高度`, state.graphHeight > 0, `高 ${state.graphHeight}px`);
}
check("切换模块过程中控制台没有报错", errors.length === 0, errors.slice(0, 3).join(" | "));

// 详情面板里的各级元素左缘相同：标题、分组和路径一行、小节标题、关系图和正文；小节的实心三角挂在左内边距里
async function panelEdges(label) {
  const edges = await page.evaluate(() => {
    const left = document.querySelector(".panel").getBoundingClientRect().left;
    const pick = (sel) => [...document.querySelectorAll(sel)].filter((e) => e.getClientRects().length)
      .map((e) => Math.round((e.getBoundingClientRect().left - left) * 10) / 10);
    return {
      title: pick(".panel-title"), sub: pick("[data-ui='panel.sub'] > :first-child"), section: pick(".section [data-slot='collapsible-trigger'] .section-title"),
      graph: pick(".local-graph svg"), text: pick(".panel-doc > div > :is(p, h2, h3)"),
    };
  });
  const carets = await page.evaluate(() => {
    const left = document.querySelector(".panel").getBoundingClientRect().left;
    return [...document.querySelectorAll(".section [data-slot='collapsible-trigger'] .twisty svg")].filter((e) => e.getClientRects().length)
      .map((e) => { const r = e.getBoundingClientRect(); return [r.left - left, r.right - left]; });
  });
  const base = edges.title[0];
  const hang = carets.filter(([l, r]) => l < 1 || r > base);
  check(`${label}小节三角在左内边距里`, edges.title.length === 1 && carets.length > 0 && carets.length === edges.section.length && hang.length === 0, hang.slice(0, 3).map(([l, r]) => `${l.toFixed(1)}–${r.toFixed(1)}`).join("，"));
  const off = Object.entries(edges).flatMap(([k, list]) => list.filter((x) => Math.abs(x - base) > 1).map((x) => `${k}=${x}`));
  check(`${label}左缘都在 ${base}px`, edges.title.length === 1 && edges.graph.length === 1 && edges.text.length > 0 && off.length === 0, [...new Set(off)].slice(0, 5).join("，"));
}
await open("files");
await page.locator("[data-ui='files.view-switch']").getByRole("tab", { name: "列表", exact: true }).click();
if (await page.evaluate(() => document.querySelector(".workspace").classList.contains("panel-closed"))) await page.click("[data-ui='topbar.panel-toggle']");
await page.click(".cards .card");
await page.waitForTimeout(300);
await panelEdges("文件全景卡片的详情面板，");
// 文档关系：悬停面板里的关系时图上对应的点写名称；跳到画面外的点时视口移过去；跳到不在本图里的文档时保留高亮并提示
await open("docs");
const docsCy = (fn) => page.evaluate((fn) => new Function("cy", fn)(document.querySelector("[data-ui='docs.graph']")._cyreg.cy), fn);
await verify("文档关系：悬停面板里的关系，图上对应的点写名称", async () => {
  await docsCy(`cy.nodes(":visible").not(".group").sort((a, b) => b.degree() - a.degree())[0].emit("tap");`);
  await page.waitForTimeout(200);
  await page.locator("[data-ui='panel.graph'] .lg-node").first().hover();
  assert.equal(await docsCy(`const n = cy.nodes(".hovered"); return n.length === 1 && n.style("label") === n.data("label");`), true);
  await page.mouse.move(5, 5);
  assert.equal(await docsCy(`return cy.nodes(".hovered").length;`), 0);
});
await verify("文档关系：从面板跳到画面外的点，视口移到它", async () => {
  await docsCy(`cy.panBy({ x: 5000, y: 5000 });`);
  await page.locator("[data-ui='panel.graph'] .lg-node").first().click();
  await page.waitForTimeout(200);
  assert.equal(await docsCy(`const p = cy.nodes(".chosen").renderedPosition(); return p.x > 0 && p.y > 0 && p.x < cy.width() && p.y < cy.height();`), true);
});
await verify("文档关系：跳到不在本图里的文档，保留高亮并写“不在本图里”", async () => {
  // 文档关系的点链到的文档不在这张图里：模板全文里的链接，或没有模板时“出处”里的文档
  const away = page.locator("[data-ui='panel'] :is(.panel-doc a[data-card], [data-ui='panel.summary'] .link-btn)");
  for (let k = 0; k < 20 && !(await away.count()); k++) {
    await docsCy(`cy.nodes(":visible").not(".group").sort((a, b) => b.degree() - a.degree())[${k}].emit("tap");`);
    await page.waitForTimeout(150);
  }
  const before = await docsCy(`return cy.nodes(".chosen").data("key");`);
  await away.first().click();
  await page.waitForTimeout(200);
  assert.equal(await docsCy(`return cy.nodes(".chosen").data("key");`), before);
  assert.equal(await page.locator("[data-ui='panel.away']").isVisible(), true);
  await page.keyboard.press("Escape");
  await page.waitForTimeout(200);
  assert.equal(await docsCy(`return cy.nodes(".chosen").length;`), 0);
});
// 浮窗：悬停文档链接 500ms 后弹出；浮窗里的链接再弹一层；鼠标回到第一层时第二层关掉；钉住后移开不关；
// 拖动标题栏自动钉住；点浮窗正文里的链接在详情面板打开，没钉住的关掉；按住 Alt 不弹；设置为关闭时不弹
const floats = () => page.locator(".float").count();
const away = async () => { await page.mouse.move(60, 780); await page.waitForTimeout(400); };
await open("files");
await page.locator("[data-ui='files.view-switch']").getByRole("tab", { name: "列表", exact: true }).click();
// 第一张卡片前面已经选中过，再点会取消选中
await page.locator(".cards .card").nth(1).click();
await verify("浮窗：悬停弹出、嵌套、回到上一层时关掉更深的层", async () => {
  // 找一个弹出后正文里还有文档链接的链接，才能试嵌套
  const links = page.locator(".panel-doc a[data-card]");
  let found = false;
  for (let k = 0; k < Math.min(8, await links.count()) && !found; k++) {
    await away();
    await links.nth(k).hover(); await page.waitForTimeout(700);
    found = (await floats()) === 1 && (await page.locator(".float .float-body a[data-card]").count()) > 0;
  }
  assert.ok(found, "没有找到能嵌套的链接");
  // 能弹浮窗的链接用专用色；浮窗外框里有一圈 2px 的分组色
  assert.equal(await links.first().evaluate((a) => getComputedStyle(a).color), "rgb(177, 85, 42)");
  assert.deepEqual(await page.locator(".float").evaluate((f) => {
    const ring = getComputedStyle(f, "::after"), probe = document.createElement("i");
    probe.style.color = f.style.getPropertyValue("--float-ring"); f.append(probe);
    const group = getComputedStyle(probe).color; probe.remove();
    return [ring.borderTopWidth, ring.borderTopColor === group, group === getComputedStyle(f).borderTopColor];
  }), ["2px", true, false]);
  await page.locator(".float .float-body a[data-card]").first().hover(); await page.waitForTimeout(700);
  assert.equal(await floats(), 2);
  assert.deepEqual(await page.locator(".float").evaluateAll((els) => els.map((e) => e.style.zIndex > 0)), [true, true]);
  await page.locator(".float").first().locator(".float-head span").hover(); await page.waitForTimeout(400);
  assert.equal(await floats(), 1);
  await away();
  assert.equal(await floats(), 0);
});
await verify("浮窗：钉住后移开不关，拖动标题栏自动钉住", async () => {
  const link = page.locator(".panel-doc a[data-card]").first();
  await link.hover(); await page.waitForTimeout(700);
  await page.locator("[data-ui='float.pin']").click();
  await away();
  assert.equal(await floats(), 1);
  await page.locator("[data-ui='float.close']").click();
  assert.equal(await floats(), 0);
  await link.hover(); await page.waitForTimeout(700);
  const head = await page.locator(".float-head span").boundingBox();
  await page.mouse.move(head.x + 10, head.y + 5); await page.mouse.down();
  await page.mouse.move(head.x - 50, head.y + 45, { steps: 5 }); await page.mouse.up();
  assert.equal(await page.locator("[data-ui='float.pin']").getAttribute("aria-pressed"), "true");
  const moved = await page.locator(".float-head span").boundingBox();
  assert.ok(Math.abs(moved.x - head.x + 60) < 2 && Math.abs(moved.y - head.y - 40) < 2, `${head.x},${head.y} → ${moved.x},${moved.y}`);
  await away();
  assert.equal(await floats(), 1);
});
await verify("浮窗：点正文里的链接在详情面板打开，钉住的留着，切换模块也留着", async () => {
  const before = await page.locator(".panel-title").innerText();
  await page.locator(".panel-doc a[data-card]").nth(1).hover(); await page.waitForTimeout(700);
  assert.equal(await floats(), 2);
  const target = page.locator(".float").nth(1).locator(".float-body a[data-card]").first();
  const title = await target.evaluate((a) => a.dataset.card);
  await target.click(); await page.waitForTimeout(200);
  assert.equal(await floats(), 1);
  assert.notEqual(await page.locator(".panel-title").innerText(), before, "详情面板没有换文档 " + title);
  await open("qa");
  assert.equal(await floats(), 1);
  await page.locator("[data-ui='float.close']").click();
  await open("files");
});
await verify("浮窗：按住 Alt 不弹，设置为关闭时不弹，宽度按设置", async () => {
  const link = page.locator(".panel-doc a[data-card]").first();
  await away();
  await page.keyboard.down("Alt"); await link.hover(); await page.waitForTimeout(700); await page.keyboard.up("Alt");
  assert.equal(await floats(), 0);
  await away();
  await page.evaluate(() => localStorage.setItem("float.mode", "off"));
  // 选中对象不随刷新保留，刷新后重新选一张卡片
  await page.reload(); await page.waitForSelector("[data-ui='panel']");
  await page.locator(".cards .card").nth(1).click();
  await page.locator(".panel-doc a[data-card]").first().hover(); await page.waitForTimeout(700);
  assert.equal(await floats(), 0);
  // 设置里选的宽度用在新弹出的浮窗上
  await page.evaluate(() => { localStorage.removeItem("float.mode"); localStorage.setItem("float.width", "640"); });
  await page.reload(); await page.waitForSelector("[data-ui='panel']");
  await page.locator(".cards .card").nth(1).click();
  await page.locator(".panel-doc a[data-card]").first().hover(); await page.waitForTimeout(700);
  assert.equal(Math.round((await page.locator(".float").boundingBox()).width), 640);
  await page.evaluate(() => localStorage.removeItem("float.width"));
  await page.reload(); await page.waitForSelector("[data-ui='panel']");
});

// 问答的一条只显示这一节正文：没有二级标题，也没有同一主题里其他问题的文字
await open("qa");
await verify("问答详情只显示选中的这一条", async () => {
  const cards = page.locator("[data-ui='qa.topic']").first().locator(".card");
  const titles = await cards.locator(".card-title").allInnerTexts();
  await cards.nth(1).click(); await page.waitForTimeout(300);
  const doc = page.locator("[data-ui='panel.doc']");
  assert.equal(await doc.locator("h2").count(), 0);
  assert.ok((await doc.innerText()).includes("结论"));
  assert.equal(await doc.locator("p").filter({ hasText: titles[0] }).count(), 0);
  assert.equal(await page.locator(".panel-title").innerText(), titles[1]);
  // 图表系列色取设计变量，不用 Pele 自带的颜色
  assert.equal(await page.evaluate(() => { const el = document.createElement("div"); el.className = "pele"; document.body.append(el); const v = getComputedStyle(el).getPropertyValue("--pele-series-1").trim(); el.remove(); return v; }), "#4e79a7");
});

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
await verify("设置窗口：Tab 留在窗口里，滑块按步长调整并记住，Esc 只关窗口", async () => {
  const chosen = await page.locator("[data-ui='scenes.graph']").evaluate(el => el._cyreg.cy.nodes(".chosen").map(n => n.id()));
  await page.click("[data-ui='topbar.settings']");
  await page.waitForTimeout(50);
  const inside = () => page.evaluate(() => Boolean(document.activeElement.closest("[data-ui='settings']")));
  for (let k = 0; k < 15; k++) { await page.keyboard.press("Tab"); assert.equal(await inside(), true); }
  await page.locator("[data-ui='settings.float-delay'] [role='slider']").focus();
  await page.keyboard.press("ArrowRight");
  assert.equal(await page.locator("[data-ui='settings.float-delay-value']").innerText(), "600ms");
  assert.equal(await page.evaluate(() => localStorage.getItem("float.delay")), "600");
  await page.keyboard.press("ArrowLeft");
  await page.keyboard.press("Escape"); await page.waitForTimeout(50);
  assert.equal(await page.locator("[data-ui='settings']").count(), 0);
  assert.equal(await page.evaluate(() => document.activeElement.dataset.ui), "topbar.settings");
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
await verify("详情分隔条 16px 键步长与双击恢复 420px", async () => {
  const handle = page.locator("[data-ui='panel.resizer']");
  await handle.focus();
  const before = await panelWidth();
  await page.keyboard.press("ArrowLeft"); assert.equal(await panelWidth(), before + 16);
  await page.keyboard.press("ArrowRight"); assert.equal(await panelWidth(), before);
  const r = await handle.boundingBox();
  await page.mouse.dblclick(r.x, r.y + 100);
  assert.equal(await panelWidth(), 420);
});
await verify("详情分隔条 240px 下限、主区至少 480px", async () => {
  await dragHandle("[data-ui='panel.resizer']", 1438);
  assert.equal(await panelWidth(), 240);
  await dragHandle("[data-ui='panel.resizer']", 44);
  assert.equal(await page.locator(".main").evaluate(el => Math.round(el.getBoundingClientRect().width)), 480);
  assert.equal(await panelWidth(), 916);
});
await verify("详情宽度保存：480 → 窄窗 436 → 480", async () => {
  await dragHandle("[data-ui='panel.resizer']", 960);
  assert.equal(await panelWidth(), 480);
  assert.equal(await page.evaluate(() => localStorage.getItem("panel-w")), "480");
  await page.setViewportSize({ width: 960, height: 900 }); await page.waitForTimeout(150);
  assert.equal(await panelWidth(), 436);
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
  // 详情面板的小节标题在选取模式下点了也不开合
  const trigger = page.locator("[data-ui='panel'] [data-slot='collapsible-trigger']").first();
  const expanded = await trigger.getAttribute("aria-expanded");
  await trigger.click();
  assert.equal(await trigger.getAttribute("aria-expanded"), expanded);
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
await verify("选取模式跳过设置窗口和 Sonner 浮层", async () => {
  const before = (await page.evaluate(() => window.pickedTexts)).length;
  await page.click("[data-ui='topbar.settings']");
  assert.deepEqual(await page.locator("[data-slot='dialog-overlay'], [data-slot='dialog-content']").evaluateAll(els => els.map(el => el.hasAttribute("data-pick-ignore"))), [true, true]);
  await page.locator("[data-ui='settings.theme']").getByRole("radio", { name: "浅色" }).click();
  assert.equal(await page.evaluate(() => document.documentElement.dataset.theme), "light");
  await page.mouse.click(5, 450); await page.waitForTimeout(50);
  assert.equal(await page.locator("[data-ui='settings']").count(), 0);
  const toaster = page.locator("[data-sonner-toaster]");
  assert.equal(await toaster.evaluate(el => Boolean(el.closest("[data-pick-ignore]"))), true);
  assert.equal((await page.evaluate(() => window.pickedTexts)).length, before);
});
await page.keyboard.press("Alt+x");

// 以下各项要换窗口大小、字号或记住的设置，每项开一个新页面；同样离线，不发远程请求
const fresh = async ({ width = 1440, height = 900, init, arg } = {}) => {
  const c = await browser.newContext({ offline: true, viewport: { width, height } });
  const p = await c.newPage();
  p.on("pageerror", (e) => errors.push(e.message));
  if (init) await p.addInitScript(init, arg);
  await p.goto(page_);
  await p.waitForSelector("[data-ui='activity.home']");
  return p;
};
const cyIn = (p, m, fn) => p.evaluate(([m, fn]) => new Function("cy", fn)(document.querySelector(`[data-ui="${m}.graph"]`)._cyreg.cy), [m, fn]);
const tapTop = (p, m) => cyIn(p, m, `cy.nodes(":visible").not(".group").sort((a, b) => b.degree() - a.degree())[0].emit("tap");`);
const cyCounts = (p, m) => cyIn(p, m, `return { faded: cy.nodes(".faded:visible").length, visible: cy.nodes(":visible").length, chosen: cy.nodes(".chosen").length };`);

// 图谱名称：两种窗口宽度乘四档字号，三张图谱在初始、展开、选中、只看邻居时，名称不出画布、不互相压住
await verify("图谱名称在各窗口宽度和字号下不出画布、不重叠", async () => {
  const bad = [];
  for (const width of [1100, 1440]) for (const font of ["s", "m", "l", "xl"]) {
    const p = await fresh({ width, height: width === 1100 ? 760 : 900, arg: font, init: (font) => { localStorage.setItem("font", font); localStorage.setItem("files.view", "graph"); } });
    const look = async (m, state) => {
      await p.waitForTimeout(120);
      const r = await cyIn(p, m, `
        const box = cy.container().getBoundingClientRect();
        const ns = cy.nodes(":visible").filter((n) => n.style("label") && Number(n.style("opacity")) > 0.1)
          .map((n) => ({ name: n.data("label"), box: n.renderedBoundingBox(), node: n.renderedBoundingBox({ includeLabels: false }) }));
        const clipped = ns.filter((n) => n.box.x1 < 0 || n.box.y1 < 0 || n.box.x2 > box.width || n.box.y2 > box.height).map((n) => n.name);
        const overlaps = [];
        for (let i = 0; i < ns.length; i++) for (let j = i + 1; j < ns.length; j++) {
          const a = ns[i], b = ns[j];
          const w = Math.min(a.box.x2, b.box.x2) - Math.max(a.box.x1, b.box.x1), h = Math.min(a.box.y2, b.box.y2) - Math.max(a.node.y2, b.node.y2);
          if (w > 1 && h > 1) overlaps.push(a.name + "/" + b.name);
        }
        return { clipped, overlaps };`);
      if (r.clipped.length || r.overlaps.length) bad.push(`${width}-${font}-${m}-${state}：${[...r.clipped, ...r.overlaps].slice(0, 3).join("，")}`);
    };
    for (const m of ["scenes", "docs", "files"]) {
      await p.click(`[data-ui="activity.${m}"]`); await p.waitForTimeout(600);
      await look(m, "初始");
      if (m === "scenes") { await p.click('[data-ui="scenes.legend-unfold"]'); await look(m, "展开"); }
      await tapTop(p, m); await look(m, "选中");
      if (m !== "files") { await p.click(`[data-ui="${m}.graph-focus"]`); await look(m, "只看邻居"); }
      await p.click(`[data-ui="${m}.graph-clear"]`);
    }
    await p.context().close();
  }
  assert.deepEqual(bad, []);
});

// 图谱的折叠、隐藏分组、点空白处和适配
await verify("图谱：只看邻居时全部折叠、隐藏所在分组、点空白处、拖远后适配", async () => {
  const p = await fresh();
  await p.click("[data-ui='activity.scenes']"); await p.waitForTimeout(600); await p.click("[data-ui='scenes.legend-unfold']");
  await tapTop(p, "scenes"); await p.click("[data-ui='scenes.graph-focus']"); await p.click("[data-ui='scenes.legend-fold']");
  assert.deepEqual(await cyCounts(p, "scenes"), { faded: 0, visible: 13, chosen: 0 });
  await p.click("[data-ui='activity.docs']"); await p.waitForTimeout(800); await tapTop(p, "docs"); await p.waitForTimeout(300);
  const group = await cyIn(p, "docs", `return cy.nodes(".chosen").data("group");`);
  const prefix = { docs: "项目文档", rules: "入口", reports: "报告" }[group];
  for (const r of await p.locator(".legend-label").all()) if ((await r.innerText()).startsWith(prefix)) await r.locator("[role=checkbox]").click();
  assert.deepEqual(await cyCounts(p, "docs"), { faded: 0, visible: 9, chosen: 0 });
  const all = p.locator(".legend-row [role=checkbox]").first();
  assert.equal(await all.getAttribute("aria-checked"), "mixed");
  // “全部分组”半选时点一次恢复全部显示
  await p.keyboard.press("Escape"); await all.click();
  await tapTop(p, "docs");
  const box = await p.locator("[data-ui='docs.graph']").boundingBox();
  await p.mouse.click(box.x + 5, box.y + box.height - 5);
  assert.deepEqual(await cyCounts(p, "docs"), { faded: 25, visible: 37, chosen: 1 });
  await p.keyboard.press("Escape");
  await cyIn(p, "docs", `cy.pan({ x: 5000, y: -3000 });`);
  await p.click("[data-ui='docs.graph-fit']");
  assert.equal(await cyIn(p, "docs", `const e = cy.extent(); return cy.nodes(":visible").every((n) => { const q = n.position(); return q.x > e.x1 && q.x < e.x2 && q.y > e.y1 && q.y < e.y2; });`), true);
  await p.context().close();
});

await verify("详情面板：JSON 模板显示路径，问答表格完整，标题行固定在顶上", async () => {
  const p = await fresh();
  await p.click("[data-ui='activity.docs']"); await p.waitForTimeout(800);
  await cyIn(p, "docs", `cy.nodes().filter((n) => n.data("label") === "methodology-config.json")[0].emit("tap");`);
  assert.ok((await p.locator("[data-ui='panel']").innerText()).includes("docs/methodology-config.json"));
  await p.click("[data-ui='activity.search']");
  await p.locator("input[data-ui='search.input']").fill("这批成品按哪一版规格做"); await p.waitForTimeout(300);
  assert.equal(await p.locator(".result").count(), 1);
  await p.locator(".result").first().click(); await p.waitForTimeout(300);
  const rows = await p.locator(".panel-doc table").filter({ hasText: "提交号回答什么问题" }).locator("tr")
    .evaluateAll((rs) => rs.map((r) => [...r.querySelectorAll("th,td")].map((c) => c.textContent)));
  assert.deepEqual(rows, [
    ["方向", "交出什么", "提交号回答什么问题"],
    ["游戏项目 → 制作项目", "规格所在的文件和章节，例如商店界面设计的资源章节", "这批成品按哪一版规格做；规格改了以后，看它判断要不要重做"],
    ["制作项目 → 游戏项目", "成品文件、母版位置和一句生成方法", "游戏里用的是哪一版成品；以后要改，从哪份母版接着改"],
  ]);
  await p.locator("input[data-ui='search.input']").fill("GDD"); await p.waitForTimeout(300);
  await p.locator(".result").first().click(); await p.waitForTimeout(300);
  const top = () => p.evaluate(() => Math.round(document.querySelector("[data-ui='panel.head']").getBoundingClientRect().top));
  const before = await top();
  const scrolled = await p.evaluate(() => { const el = document.querySelector(".panel"); el.scrollTop = el.scrollHeight; return el.scrollTop; });
  assert.ok(scrolled > 0, "面板要够长才能滚动");
  assert.equal(await top(), before);
  await p.context().close();
});

await verify("学习：搜索第一处可见，Esc 后焦点回到放大镜，跨模块后退回到小节", async () => {
  const p = await fresh();
  await p.click("[data-ui='activity.learn']"); await p.click("[data-ui='learn.search']");
  await p.locator("input[data-ui='learn.search']").fill("Stage"); await p.waitForTimeout(300);
  await p.locator("[data-slot=popover-content] [cmdk-item][role=option]").first().click(); await p.waitForTimeout(400);
  assert.equal(await p.evaluate(() => { const m = document.querySelector("mark.hit.current"); const r = m.getBoundingClientRect(); const top = document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2); return top === m || m.contains(top); }), true);
  await p.locator("input[data-ui='learn.search']").focus(); await p.keyboard.press("Escape"); await p.waitForTimeout(100);
  assert.equal(await p.evaluate(() => document.activeElement.getAttribute("aria-label")), "搜索本页");
  await p.reload(); await p.waitForSelector("[data-ui='activity.home']");
  await p.click("[data-ui='activity.learn']");
  await p.locator(".learn-body a", { hasText: "Feature 的执行阶段" }).first().click(); await p.waitForTimeout(300);
  await p.locator(".tree-row").nth(3).click();
  await p.click("[data-ui='activity.qa']");
  await p.goBack(); await p.waitForTimeout(500);
  assert.equal(await p.evaluate(() => Math.round(document.getElementById("feature-的执行阶段").getBoundingClientRect().y)), 36);
  await p.context().close();
});

// 每一章的搜索结果条数和正文里高亮的处数一致；Mermaid 图里的词不算
await verify("学习搜索：每章的条数和正文高亮一致，图里的词不算", async () => {
  const p = await fresh();
  await p.click("[data-ui='activity.learn']"); await p.click("[data-ui='learn.search']");
  for (const q of ["flowchart", "<框架源文件>", "Feature"]) {
    await p.fill("input[data-ui='learn.search']", q); await p.waitForTimeout(300);
    const options = p.locator("[data-slot='popover-content'] [cmdk-item][role='option']");
    const items = await options.allInnerTexts();
    if (q === "flowchart") { assert.equal(items.length, 0, "Mermaid 专有词不能算入正文"); continue; }
    assert.ok(items.length > 0, q + " 要有结果");
    for (let i = 0; i < items.length; i++) {
      await options.nth(i).click(); await p.waitForTimeout(100);
      assert.equal(await p.locator("mark.hit").count(), Number(items[i].match(/(\d+) 处/)[1]), q + " / " + items[i]);
      await p.locator("input[data-ui='learn.search']").focus(); await p.keyboard.press("ArrowDown");
    }
  }
  await p.context().close();
});

await verify("首页：流程图按原尺寸、没有缩放按钮，连线说明用页面底色，没有页内链接", async () => {
  const p = await fresh();
  assert.equal(await p.locator(".home [aria-label='Zoom in']").count(), 0);
  assert.equal(await p.evaluate(() => getComputedStyle(document.querySelector(".home [class*='edge-label'] rect")).fill), "rgb(250, 250, 250)");
  const widths = await p.evaluate(() => [...document.querySelectorAll(".home .diagram > svg")].map((s) => [Math.round(s.getBoundingClientRect().width), Number(s.getAttribute("width"))]));
  assert.equal(widths.length, 5);
  for (const [actual, source] of widths) assert.equal(actual, source);
  assert.equal(await p.locator("a").count(), 0);
  await p.context().close();
});

await verify("详情宽度：记住的宽度过大时主区仍留 480px，记住 Infinity 时用默认 420px", async () => {
  let p = await fresh({ width: 1100, height: 760, init: () => localStorage.setItem("panel-w", "916") });
  assert.equal(await p.evaluate(() => Math.round(document.querySelector(".main").getBoundingClientRect().width)), 480);
  await p.context().close();
  p = await fresh({ init: () => localStorage.setItem("panel-w", "Infinity") });
  assert.equal(await p.evaluate(() => Math.round(document.querySelector(".panel").getBoundingClientRect().width)), 420);
  await p.context().close();
});

// 浮窗的另几种弹出和操作：关系图的点、学习正文的链接、双击标题栏钉住、拖右下角改大小、按住 Ctrl 才弹
await verify("浮窗：关系图的点和学习正文能弹，双击钉住，拖角改大小，Ctrl 模式", async () => {
  const p = await fresh();
  const n = () => p.locator(".float").count();
  const off = async () => { await p.mouse.move(60, 860); await p.waitForTimeout(400); };
  await p.click("[data-ui='activity.files']"); await p.waitForTimeout(600);
  await p.locator("[data-ui='files.view-switch']").getByRole("tab", { name: "列表", exact: true }).click();
  await p.click(".cards .card"); await p.waitForTimeout(300);
  await p.locator("[data-ui='panel.graph'] .lg-node").first().hover(); await p.waitForTimeout(700);
  assert.equal(await n(), 1);
  await p.locator(".float-head span").dblclick();
  assert.equal(await p.locator("[data-ui='float.pin']").getAttribute("aria-pressed"), "true");
  const b = await p.locator(".float").boundingBox();
  await p.mouse.move(b.x + b.width - 2, b.y + b.height - 2); await p.mouse.down();
  await p.mouse.move(b.x + b.width - 102, b.y + b.height - 52, { steps: 5 }); await p.mouse.up();
  const b2 = await p.locator(".float").boundingBox();
  assert.deepEqual([Math.round(b.width - b2.width), Math.round(b.height - b2.height)], [100, 50]);
  await p.locator("[data-ui='float.close']").click();
  await p.click("[data-ui='activity.learn']"); await p.waitForTimeout(600);
  await off();
  await p.locator(".main .learn-body a[data-card]").first().hover(); await p.waitForTimeout(700);
  assert.equal(await n(), 1);
  await off();
  await p.click("[data-ui='topbar.settings']");
  await p.locator("[data-ui='settings.float-mode']").getByRole("radio", { name: "按住 Ctrl" }).click();
  await p.keyboard.press("Escape");
  await off();
  await p.locator(".main .learn-body a[data-card]").first().hover(); await p.waitForTimeout(700);
  assert.equal(await n(), 0);
  await p.keyboard.down("Control"); await p.waitForTimeout(100); await p.keyboard.up("Control");
  assert.equal(await n(), 1);
  await p.context().close();
});

// 窗口 960px 宽时详情面板照常展开，主区域只剩约 500px：图谱按钮折行、不伸进图例，文件卡片不被截掉
await verify("窄主区域：图谱按钮不伸进图例，全图放得进画布，文件卡片不被截掉", async () => {
  const p = await fresh({ width: 960, height: 540 });
  await p.click("[data-ui='activity.scenes']"); await p.waitForTimeout(600);
  const graph = await p.evaluate(() => {
    const canvas = document.querySelector("[data-ui='scenes.graph']").getBoundingClientRect();
    return [...document.querySelectorAll("[data-ui^='scenes.graph-']")].filter((el) => el.matches("button, [role=group]")).map((el) => Math.round(el.getBoundingClientRect().right - canvas.right)).filter((d) => d > 0);
  });
  assert.deepEqual(graph, [], "按钮伸出画布");
  assert.equal(await cyIn(p, "scenes", `const e = cy.extent(); return cy.nodes(":visible").filter((n) => { const b = n.boundingBox({ includeLabels: false }); return b.x1 < e.x1 || b.x2 > e.x2 || b.y1 < e.y1 || b.y2 > e.y2; }).length;`), 0, "有点露出画布");
  await p.click("[data-ui='activity.files']"); await p.waitForTimeout(600);
  await p.locator("[data-ui='files.view-switch']").getByRole("tab", { name: "列表", exact: true }).click();
  const cut = await p.evaluate(() => { const box = document.querySelector("[data-ui='files.cards']").getBoundingClientRect(); return [...document.querySelectorAll(".cards .card")].filter((c) => c.getBoundingClientRect().right > box.right + 1).length; });
  assert.equal(cut, 0, "卡片超出卡片列");
  await p.context().close();
});

// 正文链接：指向仓库文档的链接都能找到那份文档和锚点，用 VSCode 打开的文件都存在
await verify("正文链接都能打开：文档和锚点存在，VSCode 链接的文件存在", async () => {
  const start = html.indexOf("{home:{framework:");
  let depth = 0, quote = "", end = -1;
  for (let i = start; i < html.length; i++) {
    const c = html[i];
    if (quote) { if (c === "\\") i++; else if (c === quote) quote = ""; continue; }
    if (c === '"' || c === "'" || c === "`") { quote = c; continue; }
    if (c === "{") depth++;
    else if (c === "}" && --depth === 0) { end = i + 1; break; }
  }
  assert.ok(start >= 0 && end > 0, "页面里找不到数据");
  const data = vm.runInNewContext("(" + html.slice(start, end) + ")");
  const links = await page.evaluate((data) => {
    const docs = data.html.map((h) => new DOMParser().parseFromString(h, "text/html"));
    return data.html.flatMap((_, card) => [...docs[card].querySelectorAll("a")].map((a) => {
      const to = a.dataset.card === undefined ? null : Number(a.dataset.card), anchor = decodeURIComponent(a.dataset.anchor || "");
      const ok = to === null || (Boolean(data.files[to]) && (!anchor || Boolean(docs[to].getElementById(anchor))));
      return { from: data.files[card].path, href: a.getAttribute("href"), ok };
    }));
  }, data);
  const broken = links.filter((l) => !l.ok).map((l) => l.from + " → " + l.href);
  const missing = links.filter((l) => l.href.startsWith("vscode://file/") && !existsSync(l.href.slice("vscode://file/".length).split("#")[0])).map((l) => l.from + " → " + l.href);
  assert.deepEqual([...broken, ...missing], []);
  return `${links.length} 个链接`;
});

check("离线进入七个模块没有远程请求或资源加载失败", remote.length === 0 && failedRequests.length === 0,
  [...remote, ...failedRequests].join(" | "));
await browser.close();
for (const r of results) console.log(`${r.ok ? "通过" : "不通过"}  ${r.name}${r.detail ? "：" + r.detail : ""}`);
const failed = results.filter((r) => !r.ok).length;
console.log(`共 ${results.length} 项，不通过 ${failed} 项`);
process.exit(failed ? 1 : 0);
