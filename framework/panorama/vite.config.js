import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { viteSingleFile } from "vite-plugin-singlefile";
import dataSrc from "./tools/babel-data-src.js";
import panoramaData from "./tools/panorama-data.js";

// 输出一个内联了全部脚本和样式的 dist/index.html：Edge 直接打开本地文件时，
// 会拦住 type="module" 的外部脚本，内联脚本不受影响。
export default defineConfig({
  plugins: [react({ babel: { plugins: [dataSrc] } }), panoramaData(), viteSingleFile()],
  build: { chunkSizeWarningLimit: 4096 },
});
