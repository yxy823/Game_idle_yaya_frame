// 记住模块、面板、主题、字号、浮窗设置和选取开关；浏览器禁用本地存储时照常运行，只是不记住。
export const store = {
  get(key) { try { return localStorage.getItem(key); } catch { return null; } },
  set(key, value) { try { localStorage.setItem(key, value); } catch { /* 不记住 */ } },
};

// 设置里的四档字号；样式里按 <html data-font> 换 --fs 等变量
export const fonts = [["s", "12px"], ["m", "13px"], ["l", "14px"], ["xl", "16px"]];

// 设置里的浮窗：怎样弹出、悬停多久弹出、多宽
// 延迟和宽度用滑块，范围和步长写在这里；记住的值不在范围内或不落在步长上时用默认值
export const floatModes = [["hover", "悬停"], ["ctrl", "按住 Ctrl"], ["off", "关闭"]];
export const floatDelay = { min: 200, max: 1500, step: 100, initial: 500, unit: "ms" };
export const floatWidth = { min: 360, max: 960, step: 40, initial: 480, unit: "px" };
export const savedNumber = (key, r) => {
  const n = Number(store.get(key));
  return Number.isInteger(n) && n >= r.min && n <= r.max && (n - r.min) % r.step === 0 ? n : r.initial;
};
