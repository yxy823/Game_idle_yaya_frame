// 记住模块、面板、主题、字号、浮窗设置和选取开关；浏览器禁用本地存储时照常运行，只是不记住。
export const store = {
  get(key) { try { return localStorage.getItem(key); } catch { return null; } },
  set(key, value) { try { localStorage.setItem(key, value); } catch { /* 不记住 */ } },
};

// 设置里的四档字号；样式里按 <html data-font> 换 --fs 等变量
export const fonts = [["s", "小（12px）"], ["m", "默认（13px）"], ["l", "大（14px）"], ["xl", "特大（16px）"]];

// 设置里的浮窗：怎样弹出、悬停多久弹出
export const floatModes = [["hover", "悬停弹出"], ["ctrl", "按住 Ctrl 悬停才弹出"], ["off", "关闭"]];
export const floatDelays = [["300", "300ms"], ["500", "500ms"], ["800", "800ms"], ["1200", "1200ms"]];
