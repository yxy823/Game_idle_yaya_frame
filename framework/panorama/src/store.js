// 记住模块、面板、主题和选取开关；浏览器禁用本地存储时照常运行，只是不记住。
export const store = {
  get(key) { try { return localStorage.getItem(key); } catch { return null; } },
  set(key, value) { try { localStorage.setItem(key, value); } catch { /* 不记住 */ } },
};
