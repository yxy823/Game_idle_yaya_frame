import { useEffect, useRef } from "react";
import { mount } from "pele";
import { useToast } from "./overlays.jsx";

// Mermaid 图由 Pele 渲染，颜色取页面的语义变量（见 styles.css 的 .pele），换主题时不用重画。
// 渲染失败时保留原文，并在底部提示。
// links 列出可以点的节点（Mermaid 里的节点 ID → 悬停提示），点了交给 onNode。
// 图里的字号跟设置里的字号走，取 <html> 上的 --fs
export const fontSize = () => parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--fs"));

export default function Diagram({ ui, text, links = {}, onNode, font }) {
  const ref = useRef(null);
  const toast = useToast();
  useEffect(() => {
    const el = ref.current;
    let mounted;
    try {
      // 图内字号和界面正文一致
      mounted = mount(el, text, { fontSize: fontSize() });
      if (mounted.error) throw mounted.error;
      for (const node of el.querySelectorAll("[data-id]")) {
        const tip = links[node.dataset.id];
        if (tip) { node.classList.add("diagram-link"); node.dataset.tip = tip; }
      }
    } catch (err) {
      mounted?.destroy();
      el.textContent = text;
      toast("图渲染失败：" + err.message);
      return undefined;
    }
    return () => mounted.destroy();
  }, [text, toast, font]);
  const click = (e) => { const node = e.target.closest(".diagram-link"); if (node) onNode(node.dataset.id); };
  return <div className="diagram" data-ui={ui} ref={ref} onClick={click} />;
}
