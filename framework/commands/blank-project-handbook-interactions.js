'use strict';

// Geometry and matching are independent of the page DOM.
function clamp(value, min, max) { return Math.min(max, Math.max(min, value)); }
function lastAt(positions, value) {
  let low = 0, high = positions.length;
  while (low < high) {
    const middle = (low + high) >>> 1;
    if (positions[middle] <= value) low = middle + 1;
    else high = middle;
  }
  return low - 1;
}
function matchesWords(text, query) {
  const words = query.trim().toLocaleLowerCase().split(/\s+/).filter(Boolean);
  return words.every(word => text.toLocaleLowerCase().includes(word));
}
function searchRank(title, body, query) {
  if (!query.trim()) return Infinity;
  if (matchesWords(title, query)) return 0;
  return matchesWords(title + ' ' + body, query) ? 1 : Infinity;
}
function zoomAt(view, scale, point) {
  const next = clamp(scale, .05, 4);
  const ratio = next / view.scale;
  return {scale: next, x: point.x - (point.x - view.x) * ratio, y: point.y - (point.y - view.y) * ratio};
}
function readPreference(key) {
  try { return localStorage.getItem(key); } catch { return null; }
}
function savePreference(key, value) {
  try { localStorage.setItem(key, value); return true; } catch { return false; }
}
function decodeAnchor(hash) {
  try { return decodeURIComponent(hash.replace(/^#/, '')); } catch { return ''; }
}

document.documentElement.classList.add('js');
let readingHold = null;
const settingsDialog = document.getElementById('reading-settings');
const fontSaveStatus = document.getElementById('font-save-status');
const fontFields = [
  {key: 'body', label: '正文', group: '正文与标题', min: 14, max: 28},
  {key: 'cover', label: '封面标题', group: '正文与标题', min: 28, max: 60},
  {key: 'h1', label: '章节标题 · H1', group: '正文与标题', min: 24, max: 48},
  {key: 'h2', label: '小节标题 · H2', group: '正文与标题', min: 18, max: 40},
  {key: 'h3', label: '三级标题 · H3', group: '正文与标题', min: 16, max: 32},
  {key: 'nav', label: '主目录', group: '目录与界面', min: 13, max: 22},
  {key: 'subnav', label: '子目录', group: '目录与界面', min: 12, max: 22},
  {key: 'ui', label: '辅助文字 · 工具栏、按钮、图注', group: '目录与界面', min: 12, max: 20},
  {key: 'table', label: '表格文字', group: '表格与代码', min: 13, max: 24},
  {key: 'code', label: '代码块与行内代码', group: '表格与代码', min: 12, max: 24}
];
const fontPresets = {
  compact: {name: '紧凑浏览', sizes: {body: 16, cover: 36, h1: 30, h2: 22, h3: 19, nav: 14, subnav: 13, ui: 13, table: 14, code: 14}},
  comfortable: {name: '舒适阅读', sizes: {body: 18, cover: 42, h1: 34, h2: 26, h3: 21, nav: 15, subnav: 14, ui: 14, table: 16, code: 16}},
  large: {name: '大字阅读', sizes: {body: 22, cover: 48, h1: 40, h2: 32, h3: 26, nav: 18, subnav: 17, ui: 16, table: 20, code: 20}}
};
const fontStorageKey = 'yaya.handbook.typography';
const fontSizes = {...fontPresets.comfortable.sizes};
const fontInputs = {};
const presetButtons = {};
let storedFonts;
try {
  storedFonts = localStorage.getItem(fontStorageKey);
} catch {
  fontSaveStatus.textContent = '浏览器限制保存，设置仅本次有效';
}
if (storedFonts) {
  try {
    const stored = JSON.parse(storedFonts);
    for (const field of fontFields) {
      const size = stored?.[field.key];
      if (Number.isInteger(size) && size >= field.min && size <= field.max) fontSizes[field.key] = size;
    }
  } catch {
    fontSaveStatus.textContent = '保存的设置无法读取，已恢复默认';
  }
}
function applyTypography(changes, persist = true) {
  for (const field of fontFields) {
    const value = changes[field.key];
    if (value !== undefined && value !== '' && Number.isFinite(Number(value))) {
      fontSizes[field.key] = Math.min(field.max, Math.max(field.min, Math.round(Number(value))));
    }
    const size = fontSizes[field.key];
    document.documentElement.style.setProperty(`--font-${field.key}`, `${size}px`);
    fontInputs[field.key].range.value = String(size);
    fontInputs[field.key].number.value = String(size);
    fontInputs[field.key].range.setAttribute('aria-valuetext', `${size} 像素`);
  }
  let selectedName = '自定义';
  for (const [key, preset] of Object.entries(fontPresets)) {
    const selected = fontFields.every(field => fontSizes[field.key] === preset.sizes[field.key]);
    presetButtons[key].setAttribute('aria-pressed', String(selected));
    if (selected) selectedName = preset.name;
  }
  document.getElementById('active-font-preset').textContent = selectedName;
  if (persist) {
    try {
      localStorage.setItem(fontStorageKey, JSON.stringify(fontSizes));
      fontSaveStatus.textContent = '当前搭配已保存';
    } catch {
      fontSaveStatus.textContent = '浏览器限制保存，设置仅本次有效';
    }
    restoreReadingAnchor();
    invalidateLayout();
  }
}
const fontControls = document.getElementById('font-controls');
const groups = new Map();
for (const field of fontFields) {
  if (!groups.has(field.group)) {
    const group = document.createElement('details');
    group.className = 'font-group';
    group.open = groups.size === 0;
    const summary = document.createElement('summary');
    summary.textContent = field.group;
    group.append(summary);
    groups.set(field.group, group);
    fontControls.append(group);
  }
  const row = document.createElement('div');
  row.className = 'font-control';
  const label = document.createElement('label');
  label.htmlFor = `font-${field.key}`;
  label.textContent = field.label;
  const controls = document.createElement('div');
  controls.className = 'size-controls';
  const range = document.createElement('input');
  const number = document.createElement('input');
  range.type = 'range';
  range.id = label.htmlFor;
  number.type = 'number';
  number.setAttribute('aria-label', `${field.label}字号，单位像素`);
  for (const input of [range, number]) {
    input.min = String(field.min);
    input.max = String(field.max);
    input.step = '1';
  }
  range.addEventListener('input', () => applyTypography({[field.key]: range.value}));
  number.addEventListener('change', () => applyTypography({[field.key]: number.value}));
  number.addEventListener('keydown', event => {
    if (event.key === 'Enter') { event.preventDefault(); applyTypography({[field.key]: number.value}); }
  });
  const unit = document.createElement('span');
  unit.textContent = 'px';
  unit.setAttribute('aria-hidden', 'true');
  controls.append(range, number, unit);
  row.append(label, controls);
  groups.get(field.group).append(row);
  fontInputs[field.key] = {range, number};
}
for (const [key, preset] of Object.entries(fontPresets)) {
  const button = document.createElement('button');
  button.type = 'button';
  button.textContent = preset.name;
  const description = document.createElement('small');
  description.textContent = `正文 ${preset.sizes.body}px`;
  button.append(description);
  button.addEventListener('click', () => applyTypography(preset.sizes));
  document.getElementById('font-presets').append(button);
  presetButtons[key] = button;
}
applyTypography({}, false);
document.getElementById('open-settings').addEventListener('click', () => {
  readingHold = captureReadingAnchor();
  pinHeader();
  settingsDialog.showModal();
  presetButtons.comfortable.focus();
});
document.getElementById('close-settings').addEventListener('click', () => settingsDialog.close());
settingsDialog.addEventListener('close', () => { readingHold = null; pinHeader(); invalidateLayout(); });
document.getElementById('reset-font').addEventListener('click', () => applyTypography(fontPresets.comfortable.sizes));

const sidebar = document.getElementById('handbook-sidebar');
const sideNav = sidebar.querySelector('nav');
const readingBar = document.querySelector('.reading-bar');
const currentChapter = document.getElementById('current-chapter');
const progress = document.getElementById('reading-progress');
const progressLabel = document.getElementById('reading-position');
const search = document.getElementById('nav-search');
const searchStatus = document.getElementById('nav-search-status');
const sidebarToggle = document.getElementById('toggle-sidebar');
const sidebarShade = document.getElementById('sidebar-shade');
const narrowWindow = matchMedia('(max-width: 1099px)');
const chapters = Array.from(document.querySelectorAll('article.chapter'));
const records = chapters.map(chapter => {
  const link = document.querySelector('[data-chapter="' + chapter.id + '"]');
  const row = link.closest('.nav-chapter');
  return {chapter, link, row, title: chapter.dataset.title, number: chapter.dataset.number,
    isScenario: chapter.dataset.scenarios === 'true',
    toggle: row.querySelector('.nav-toggle'), outline: row.querySelector('.nav-sections'),
    sections: Array.from(row.querySelectorAll('[data-section]'))};
});
const entryLinks = new Map();
const entries = [];
for (const record of records) {
  entryLinks.set(record.chapter.id, record.link);
  entries.push({id: record.chapter.id, element: record.chapter, record, title: ''});
  for (const heading of record.chapter.querySelectorAll('h2[id], h3[id]')) {
    entries.push({id: heading.id, element: heading, record, title: heading.dataset.title});
  }
  for (const link of record.sections) entryLinks.set(link.dataset.section, link);
  setExpanded(record, false);
  record.toggle.addEventListener('click', () => setExpanded(record, record.outline.hidden));
}
const entriesById = new Map(entries.map(entry => [entry.id, entry]));
let positions = [], layoutDirty = true, framePending = false, activeEntry = null;
let previousY = window.scrollY, downwardDistance = 0, headerPinnedUntil = 0;
let sidebarCollapsed = readPreference('yaya.handbook.sidebar') === 'collapsed';
let drawerOpen = false, sideHovered = false, sidePausedUntil = 0, sideFollowTimer;
let filterQuery = '', expansionBeforeSearch = null, searchTargets = [];
let positionTimer, pendingPosition = '';
const positionKey = document.body.dataset.readingKey;

function setExpanded(record, expanded) {
  record.outline.hidden = !expanded;
  record.toggle.setAttribute('aria-expanded', String(expanded));
  record.toggle.setAttribute('aria-label', (expanded ? '收起' : '展开') + record.title + '的小节');
}
function pinHeader() {
  headerPinnedUntil = performance.now() + 400;
  downwardDistance = 0;
  readingBar.classList.remove('header-hidden');
}
function syncSidebar(restoreFocus = false) {
  const visible = narrowWindow.matches ? drawerOpen : !sidebarCollapsed;
  document.body.classList.toggle('sidebar-collapsed', sidebarCollapsed);
  document.body.classList.toggle('drawer-open', narrowWindow.matches && drawerOpen);
  sidebar.inert = !visible;
  sidebarToggle.setAttribute('aria-expanded', String(visible));
  sidebarToggle.setAttribute('aria-label', visible ? '收起目录' : '打开目录');
  sidebarShade.hidden = !(narrowWindow.matches && drawerOpen);
  for (const element of [document.querySelector('main'), readingBar]) element.inert = narrowWindow.matches && drawerOpen;
  if (narrowWindow.matches && drawerOpen) {
    sidebar.setAttribute('role', 'dialog');
    sidebar.setAttribute('aria-modal', 'true');
  } else {
    sidebar.removeAttribute('role');
    sidebar.removeAttribute('aria-modal');
  }
  if (restoreFocus) sidebarToggle.focus({preventScroll: true});
  invalidateLayout();
  pinHeader();
}
function closeSidebar(restoreFocus = true) {
  if (narrowWindow.matches) drawerOpen = false;
  else { sidebarCollapsed = true; savePreference('yaya.handbook.sidebar', 'collapsed'); }
  syncSidebar(restoreFocus);
}
function openSidebar(focusSearch = false) {
  if (narrowWindow.matches) drawerOpen = true;
  else { sidebarCollapsed = false; savePreference('yaya.handbook.sidebar', 'expanded'); }
  syncSidebar();
  if (focusSearch || narrowWindow.matches) search.focus({preventScroll: true});
  followActiveLink();
}
sidebarToggle.addEventListener('click', () => {
  if (narrowWindow.matches ? drawerOpen : !sidebarCollapsed) closeSidebar();
  else openSidebar();
});
document.getElementById('close-sidebar').addEventListener('click', () => closeSidebar());
sidebarShade.addEventListener('click', () => closeSidebar());
narrowWindow.addEventListener('change', () => { drawerOpen = false; syncSidebar(sidebar.contains(document.activeElement)); });

function pauseSidebar() {
  sidePausedUntil = performance.now() + 1200;
  clearTimeout(sideFollowTimer);
  sideFollowTimer = setTimeout(followActiveLink, 1250);
}
function followActiveLink() {
  if (!activeEntry || filterQuery || sidebar.inert || sideHovered || sidebar.contains(document.activeElement) || performance.now() < sidePausedUntil) return;
  const target = entryLinks.get(activeEntry.id);
  if (!target || target.hidden || activeEntry.record.outline.hidden && target !== activeEntry.record.link) return;
  const viewport = sideNav.getBoundingClientRect(), rect = target.getBoundingClientRect();
  const delta = rect.top < viewport.top + 8 ? rect.top - viewport.top - 8 :
    rect.bottom > viewport.bottom - 8 ? rect.bottom - viewport.bottom + 8 : 0;
  // Scroll this container only; scrollIntoView could also move the article.
  if (delta) sideNav.scrollBy({top: delta, behavior: 'auto'});
}
sidebar.addEventListener('pointerenter', () => { sideHovered = true; });
sidebar.addEventListener('pointerleave', () => { sideHovered = false; followActiveLink(); });
for (const type of ['wheel', 'pointerdown', 'keydown']) sidebar.addEventListener(type, pauseSidebar, {passive: true});
sidebar.addEventListener('focusout', () => setTimeout(followActiveLink, 0));

function filterNavigation() {
  const query = search.value.trim();
  if (query && !filterQuery) expansionBeforeSearch = new Map(records.map(record => [record, !record.outline.hidden]));
  filterQuery = query;
  searchTargets = [];
  const candidates = [];
  for (const record of records) {
    const chapterRank = searchRank(record.number + ' ' + record.title, record.link.dataset.searchText || '', query);
    const sectionRanks = new Map(record.sections.map(link =>
      [link, searchRank(link.textContent, link.dataset.searchText || '', query)]));
    const matched = new Set(record.sections.filter(link => Number.isFinite(sectionRanks.get(link))));
    const visible = new Set(matched);
    let parent;
    for (const link of record.sections) {
      if (link.dataset.level === '2') parent = link;
      else if (matched.has(link) && parent) visible.add(parent);
    }
    record.row.hidden = !!query && !Number.isFinite(chapterRank) && !matched.size;
    for (const link of record.sections) {
      link.hidden = !!query && chapterRank !== 0 && !visible.has(link);
      if (sectionRanks.get(link) === 1) link.dataset.searchMatch = 'body';
      else delete link.dataset.searchMatch;
    }
    if (query) {
      setExpanded(record, true);
      if (Number.isFinite(chapterRank)) candidates.push({id: record.chapter.id, rank: chapterRank,
        priority: record.isScenario ? 1 : 2});
      for (const link of matched) candidates.push({id: link.dataset.section, rank: sectionRanks.get(link),
        priority: record.isScenario ? 0 : 2});
    } else if (expansionBeforeSearch) setExpanded(record, expansionBeforeSearch.get(record));
  }
  // Keep book order in the outline; Enter favors actionable SOP sections, then title matches.
  candidates.sort((left, right) => left.priority - right.priority || left.rank - right.rank);
  searchTargets = candidates.map(candidate => candidate.id);
  for (const heading of sidebar.querySelectorAll('.nav-group')) {
    heading.hidden = !records.some(record => !record.row.hidden && record.row.dataset.group === heading.dataset.group);
  }
  searchStatus.textContent = query ? (searchTargets.length ? '匹配 ' + searchTargets.length + ' 处，Enter ' +
    (candidates[0].priority === 0 ? '优先进入场景检查单' : '跳到首个结果') : '没有匹配的标题或正文') : '搜索标题与正文；Ctrl + F 查找全文';
  document.getElementById('clear-nav-search').disabled = !query;
  if (!query) { expansionBeforeSearch = null; followActiveLink(); }
}
search.addEventListener('input', filterNavigation);
document.getElementById('clear-nav-search').addEventListener('click', () => {
  search.value = ''; filterNavigation(); search.focus();
});
search.addEventListener('keydown', event => {
  if (event.isComposing) return;
  if (event.key === 'Enter' && searchTargets.length) {
    event.preventDefault(); navigateTo(searchTargets[0]);
  } else if (event.key === 'Escape' && search.value) {
    event.preventDefault(); event.stopPropagation(); search.value = ''; filterNavigation();
  }
});
document.addEventListener('keydown', event => {
  const editing = event.target.closest('input, textarea, select, [contenteditable="true"]');
  if (event.key === '/' && !editing && !event.ctrlKey && !event.metaKey && !event.altKey && !document.querySelector('dialog[open]')) {
    event.preventDefault(); openSidebar(true);
  }
  if (event.key === 'Escape' && drawerOpen) { event.preventDefault(); closeSidebar(); }
  if (event.key === 'Tab' && drawerOpen) {
    const controls = Array.from(sidebar.querySelectorAll('a, button, input')).filter(element => !element.disabled && element.getClientRects().length);
    const first = controls[0], last = controls[controls.length - 1];
    if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
    else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
  }
});

function invalidateLayout() { layoutDirty = true; scheduleReadingUpdate(); }
function scheduleReadingUpdate() {
  if (!framePending) { framePending = true; requestAnimationFrame(updateReading); }
}
function measureReading() {
  const y = window.scrollY;
  positions = entries.map(entry => entry.element.getBoundingClientRect().top + y);
  layoutDirty = false;
}
function rememberPosition(entry) {
  pendingPosition = entry.id;
  clearTimeout(positionTimer);
  positionTimer = setTimeout(() => savePreference(positionKey, pendingPosition), 300);
}
function updateReading() {
  framePending = false;
  if (layoutDirty) measureReading();
  const y = Math.max(0, window.scrollY);
  const anchorLine = readingBar.offsetHeight + 18;
  const entry = entries[lastAt(positions, y + anchorLine)] || null;
  if (entry?.id !== activeEntry?.id) {
    const previousChapter = activeEntry?.record;
    activeEntry = entry;
    for (const record of records) {
      const selected = entry?.record === record;
      record.link.classList.toggle('active', selected);
      if (selected) record.link.setAttribute('aria-current', 'page');
      else record.link.removeAttribute('aria-current');
      for (const link of record.sections) {
        const current = link.dataset.section === entry?.id;
        link.classList.toggle('active', current);
        if (current) link.setAttribute('aria-current', 'location');
        else link.removeAttribute('aria-current');
      }
    }
    if (entry) {
      if (entry.record !== previousChapter && !filterQuery) setExpanded(entry.record, true);
      currentChapter.textContent = entry.record.number + ' ' + entry.record.title + (entry.title ? ' · ' + entry.title : '');
      currentChapter.title = currentChapter.textContent;
      followActiveLink();
      if (y > 0 && !document.querySelector('dialog[open]')) rememberPosition(entry);
    } else currentChapter.textContent = '使用手册 · 阅读入口';
  }
  const maximum = Math.max(0, document.documentElement.scrollHeight - innerHeight);
  const percent = maximum ? clamp(Math.round(y / maximum * 100), 0, 100) : 100;
  progress.value = percent;
  progressLabel.textContent = (entry?.record.number || '00') + ' / ' + String(chapters.length).padStart(2, '0') + ' · ' + percent + '%';
  const delta = y - previousY;
  const pinned = y < 80 || performance.now() < headerPinnedUntil || !!readingBar.querySelector(':focus-visible') || drawerOpen || !!document.querySelector('dialog[open]');
  if (pinned || delta < 0) { readingBar.classList.remove('header-hidden'); downwardDistance = 0; }
  else if (delta > 0) {
    downwardDistance += delta;
    if (downwardDistance > 80) readingBar.classList.add('header-hidden');
  }
  previousY = y;
}
readingBar.addEventListener('focusin', pinHeader);
window.addEventListener('scroll', scheduleReadingUpdate, {passive: true});
window.addEventListener('resize', invalidateLayout);
window.addEventListener('pagehide', () => { if (pendingPosition) savePreference(positionKey, pendingPosition); });
new ResizeObserver(invalidateLayout).observe(document.querySelector('.book'));
new ResizeObserver(() => {
  document.documentElement.style.setProperty('--header-height', readingBar.offsetHeight + 'px');
  invalidateLayout();
}).observe(readingBar);

function navigateTo(id, push = true) {
  const target = document.getElementById(id);
  if (!target) return;
  if (drawerOpen) { drawerOpen = false; syncSidebar(); }
  pinHeader();
  if (push && decodeAnchor(location.hash) !== id) {
    try { history.pushState(null, '', '#' + encodeURIComponent(id)); } catch { location.hash = id; }
  }
  target.scrollIntoView({block: 'start', behavior: 'auto'});
  target.tabIndex = -1;
  target.focus({preventScroll: true});
  invalidateLayout();
}
document.addEventListener('click', event => {
  const link = event.target.closest('a[href^="#"]');
  if (!link || event.button || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
  const id = decodeAnchor(link.hash);
  if (document.getElementById(id)) { event.preventDefault(); navigateTo(id); }
});
function followHash() {
  const id = decodeAnchor(location.hash);
  if (id) navigateTo(id, false);
  else { pinHeader(); invalidateLayout(); }
}
window.addEventListener('hashchange', followHash);
window.addEventListener('popstate', followHash);
const previousAnchor = readPreference(positionKey);
const previousEntry = entriesById.get(previousAnchor);
if (previousEntry && !location.hash) {
  const resume = document.getElementById('resume-reading');
  resume.hidden = false;
  const button = document.getElementById('continue-reading');
  button.textContent = '继续上次阅读：' + previousEntry.record.number + ' / ' + (previousEntry.title || previousEntry.record.title);
  button.addEventListener('click', () => { resume.hidden = true; navigateTo(previousEntry.id); });
  document.getElementById('dismiss-resume').addEventListener('click', () => { resume.hidden = true; });
}
function captureReadingAnchor() {
  if (layoutDirty) measureReading();
  const entry = entries[lastAt(positions, window.scrollY + readingBar.offsetHeight + 18)];
  const element = entry?.element || document.getElementById('handbook-top');
  return {element, top: element.getBoundingClientRect().top};
}
function restoreReadingAnchor() {
  if (!readingHold) return;
  const delta = readingHold.element.getBoundingClientRect().top - readingHold.top;
  if (delta) window.scrollBy({top: delta, behavior: 'auto'});
  pinHeader();
}

const toast = document.querySelector('.toast');
let toastTimer;
function message(text) {
  clearTimeout(toastTimer);
  toast.textContent = text;
  toastTimer = setTimeout(() => { toast.textContent = ''; }, 3500);
}
async function copyText(text) {
  try { await navigator.clipboard.writeText(text); return true; } catch {
    const input = document.createElement('textarea');
    input.value = text;
    input.style.cssText = 'position:fixed;left:-10000px;top:0';
    (document.querySelector('dialog[open]') || document.body).append(input);
    input.select();
    let copied = false;
    try { copied = document.execCommand('copy'); } catch { copied = false; }
    input.remove();
    return copied;
  }
}
const feedbackTimers = new WeakMap();
function buttonFeedback(button, text) {
  const prior = feedbackTimers.get(button);
  if (prior) clearTimeout(prior.timer);
  const original = prior?.original || button.textContent;
  button.textContent = text;
  feedbackTimers.set(button, {original, timer: setTimeout(() => {
    button.textContent = original; feedbackTimers.delete(button);
  }, 1800)});
}
document.querySelectorAll('.copy-code').forEach(button => {
  button.addEventListener('click', async () => {
    const code = button.closest('.code-block').querySelector('code');
    const copied = await copyText(code.textContent);
    if (!copied) {
      const range = document.createRange();
      range.selectNodeContents(code);
      const selection = window.getSelection();
      selection.removeAllRanges(); selection.addRange(range);
      message('浏览器未允许自动复制，已选中代码，请按 Ctrl + C');
    } else {
      buttonFeedback(button, '✓ 已复制');
      message('代码已复制');
    }
  });
});
document.querySelectorAll('.toggle-code-wrap').forEach(button => {
  button.addEventListener('click', () => {
    const wrapped = button.closest('.code-block').classList.toggle('code-wrapped');
    button.setAttribute('aria-pressed', String(wrapped));
    button.textContent = wrapped ? '自动换行：开' : '自动换行';
    invalidateLayout();
  });
});
document.querySelectorAll('.heading-link').forEach(button => {
  button.addEventListener('click', async () => {
    const url = new URL(location.href);
    url.hash = button.dataset.anchor;
    try { history.replaceState(null, '', url.href); } catch { location.hash = button.dataset.anchor; }
    if (await copyText(url.href)) {
      buttonFeedback(button, '✓'); message('当前位置链接已复制');
    } else message('浏览器未允许自动复制，请从地址栏复制当前位置链接');
  });
});

// Keep one SVG instance, so markers and accessible label IDs remain unique.
const diagramDialog = document.querySelector('.diagram-dialog');
const diagramViewport = document.getElementById('diagram-viewport');
const diagramStage = document.getElementById('diagram-stage');
const diagramScale = document.getElementById('diagram-scale');
let diagramSource = null, diagramSvg = null, sourceHeight = '';
let diagramSize = {width: 1, height: 1}, view = {scale: 1, x: 0, y: 0}, diagramMode = 'fit', drag = null;
function paintDiagram() {
  diagramStage.style.width = diagramSize.width + 'px';
  diagramStage.style.height = diagramSize.height + 'px';
  diagramStage.style.transform = 'translate(' + view.x + 'px,' + view.y + 'px) scale(' + view.scale + ')';
  diagramScale.value = Math.round(view.scale * 100) + '%';
}
function fitDiagram() {
  if (!diagramSvg) return;
  const width = diagramViewport.clientWidth, height = diagramViewport.clientHeight;
  const scale = clamp(Math.min((width - 40) / diagramSize.width, (height - 40) / diagramSize.height, 1), .05, 4);
  view = {scale, x: (width - diagramSize.width * scale) / 2, y: (height - diagramSize.height * scale) / 2};
  diagramMode = 'fit';
  paintDiagram();
}
function setDiagramScale(scale, point = {x: diagramViewport.clientWidth / 2, y: diagramViewport.clientHeight / 2}) {
  view = zoomAt(view, scale, point);
  diagramMode = 'custom';
  paintDiagram();
}
document.querySelectorAll('.expand-diagram').forEach(button => {
  button.addEventListener('click', () => {
    diagramSource = button.closest('.diagram').querySelector('.diagram-canvas');
    diagramSvg = diagramSource.querySelector('svg');
    sourceHeight = diagramSource.style.height;
    diagramSource.style.height = diagramSource.getBoundingClientRect().height + 'px';
    const box = diagramSvg.viewBox.baseVal;
    diagramSize = {width: box.width, height: box.height};
    diagramStage.append(diagramSvg);
    document.getElementById('diagram-dialog-title').textContent = button.closest('figure').querySelector('figcaption').firstChild.textContent.trim() + ' · 图表查看器';
    pinHeader();
    diagramDialog.showModal();
    fitDiagram();
    diagramViewport.focus();
  });
});
document.querySelectorAll('[data-diagram-action]').forEach(button => {
  button.addEventListener('click', () => {
    const action = button.dataset.diagramAction;
    if (action === 'fit' || action === 'reset') fitDiagram();
    else setDiagramScale(action === 'actual' ? 1 : view.scale * (action === 'in' ? 1.2 : 1 / 1.2));
  });
});
diagramViewport.addEventListener('wheel', event => {
  if (!event.ctrlKey) return;
  event.preventDefault();
  const rect = diagramViewport.getBoundingClientRect();
  setDiagramScale(view.scale * Math.exp(-event.deltaY * .002), {x: event.clientX - rect.left, y: event.clientY - rect.top});
}, {passive: false});
diagramViewport.addEventListener('pointerdown', event => {
  if (event.button !== 0 || !diagramSvg) return;
  diagramViewport.focus({preventScroll: true});
  drag = {id: event.pointerId, x: event.clientX, y: event.clientY, viewX: view.x, viewY: view.y};
  diagramViewport.setPointerCapture(event.pointerId);
  diagramViewport.classList.add('dragging');
  diagramMode = 'custom';
  event.preventDefault();
});
diagramViewport.addEventListener('pointermove', event => {
  if (!drag || drag.id !== event.pointerId) return;
  view.x = drag.viewX + event.clientX - drag.x;
  view.y = drag.viewY + event.clientY - drag.y;
  paintDiagram();
});
function endDrag() {
  if (drag && diagramViewport.hasPointerCapture(drag.id)) diagramViewport.releasePointerCapture(drag.id);
  drag = null; diagramViewport.classList.remove('dragging');
}
diagramViewport.addEventListener('pointerup', endDrag);
diagramViewport.addEventListener('pointercancel', endDrag);
diagramViewport.addEventListener('keydown', event => {
  if (event.ctrlKey || event.metaKey || event.altKey) return;
  if (['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(event.key)) {
    event.preventDefault(); diagramMode = 'custom';
    view.x += event.key === 'ArrowLeft' ? 40 : event.key === 'ArrowRight' ? -40 : 0;
    view.y += event.key === 'ArrowUp' ? 40 : event.key === 'ArrowDown' ? -40 : 0;
    paintDiagram();
  } else if (['+', '=', '-'].includes(event.key)) {
    event.preventDefault(); setDiagramScale(view.scale * (event.key === '-' ? 1 / 1.2 : 1.2));
  } else if (event.key === 'Home') { event.preventDefault(); fitDiagram(); }
});
new ResizeObserver(() => { if (diagramDialog.open && diagramMode === 'fit') fitDiagram(); }).observe(diagramViewport);
document.getElementById('close-diagram').addEventListener('click', () => diagramDialog.close());
diagramDialog.addEventListener('close', () => {
  endDrag();
  if (diagramSvg && diagramSource) { diagramSource.append(diagramSvg); diagramSource.style.height = sourceHeight; }
  diagramSvg = null; diagramSource = null;
  pinHeader(); invalidateLayout();
});
for (const modal of [settingsDialog, diagramDialog]) {
  let outsidePointer = null;
  const outside = event => {
    const rect = modal.getBoundingClientRect();
    return event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom;
  };
  modal.addEventListener('pointerdown', event => { outsidePointer = event.target === modal && outside(event) ? event.pointerId : null; });
  modal.addEventListener('pointerup', event => {
    if (outsidePointer === event.pointerId && event.target === modal && outside(event)) modal.close();
    outsidePointer = null;
  });
}
filterNavigation();
syncSidebar();
invalidateLayout();
if (location.hash) requestAnimationFrame(followHash);
