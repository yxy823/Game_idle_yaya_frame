import { useEffect, useRef } from "react";
import { mount } from "pele";
import { useToast } from "./overlays.jsx";

// Mermaid 图由 Pele 渲染，颜色取页面的语义变量（见 styles.css 的 .pele），换主题时不用重画。
// 渲染失败时保留原文，并在底部提示。
export default function Diagram({ ui, text }) {
  const ref = useRef(null);
  const toast = useToast();
  useEffect(() => {
    const el = ref.current;
    let mounted;
    try {
      mounted = mount(el, text);
      if (mounted.error) throw mounted.error;
    } catch (err) {
      mounted?.destroy();
      el.textContent = text;
      toast("图渲染失败：" + err.message);
      return undefined;
    }
    return () => mounted.destroy();
  }, [text, toast]);
  return <div className="diagram" data-ui={ui} ref={ref} />;
}
