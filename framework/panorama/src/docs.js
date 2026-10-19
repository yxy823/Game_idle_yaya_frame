import data from "virtual:panorama-data";

// 页面里查卡片关系用的索引，按卡片编号存放，只在加载时算一次。
export const { files, paras, links, groups } = data;

export const outgoing = files.map(() => []);
export const incoming = files.map(() => []);
for (const link of links) {
  outgoing[link.from].push(link);
  incoming[link.to].push(link);
}

export const groupName = Object.fromEntries(groups.map((g) => [g.id, g.name]));

export const dirOf = (p) => p.split("/").slice(0, -1).join("/");

// 在 VSCode 里打开原文件的指定行
export const vscodeUrl = (file, line = 1) => `vscode://file/${data.repo}/${files[file].path}:${line}`;
