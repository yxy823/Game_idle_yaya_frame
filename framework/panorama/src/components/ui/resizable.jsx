import { cn } from "cn";
import { Group, Panel, Separator } from "react-resizable-panels";

export const dimension = (name) => parseFloat(getComputedStyle(document.documentElement).getPropertyValue(name));

function ResizablePanelGroup({ className, ref, ...props }) {
  return <Group data-slot="resizable-panel-group" elementRef={ref} className={cn("flex w-full min-w-0", className)} {...props} />;
}
function ResizablePanel({ ref, ...props }) { return <Panel data-slot="resizable-panel" elementRef={ref} {...props} />; }
function ResizableHandle({ className, ref, ...props }) {
  return <Separator data-slot="resizable-handle" elementRef={ref} className={cn("relative z-(--z-resizer) w-0 shrink-0 cursor-col-resize touch-none before:absolute before:inset-y-0 before:left-0 before:w-(--resize-hit) before:-translate-x-1/2 after:pointer-events-none after:absolute after:inset-y-0 after:left-0 after:w-(--resize-line) after:-translate-x-1/2 hover:after:bg-primary data-[separator=active]:after:bg-primary focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2", className)} {...props} />;
}
export { ResizableHandle, ResizablePanel, ResizablePanelGroup };
