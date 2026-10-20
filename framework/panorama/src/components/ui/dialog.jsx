import { cn } from "cn";
import { Dialog as DialogPrimitive } from "radix-ui";
import { XIcon } from "lucide-react";
import { Button } from "@/components/ui/button";

function Dialog(props) {
  return <DialogPrimitive.Root data-slot="dialog" {...props} />;
}
function DialogTrigger(props) {
  return <DialogPrimitive.Trigger data-slot="dialog-trigger" {...props} />;
}
// 居中的窗口：遮罩盖住页面，右上角有关闭按钮；遮罩和窗口都带 data-pick-ignore，元素选取不会选中它们
function DialogContent({ className, children, ...props }) {
  return <DialogPrimitive.Portal>
    <DialogPrimitive.Overlay data-slot="dialog-overlay" data-pick-ignore className="fixed inset-0 z-(--z-menu) bg-(--scrim)" />
    <DialogPrimitive.Content data-slot="dialog-content" data-pick-ignore aria-describedby={undefined}
      className={cn("fixed top-1/2 left-1/2 z-(--z-menu) w-(--dialog-w) max-w-[calc(100vw-2*var(--space-4))] max-h-[calc(100vh-2*var(--space-4))] -translate-1/2 overflow-auto rounded-md border border-border bg-popover text-popover-foreground shadow-(--shadow) outline-none", className)} {...props}>
      {children}
      <DialogPrimitive.Close asChild>
        <Button variant="ghost" size="icon" className="icon-btn absolute top-(--space-2) right-(--space-2)" aria-label="关闭" data-tip="关闭"><XIcon aria-hidden="true" /></Button>
      </DialogPrimitive.Close>
    </DialogPrimitive.Content>
  </DialogPrimitive.Portal>;
}
function DialogTitle({ className, ...props }) {
  return <DialogPrimitive.Title data-slot="dialog-title" className={cn("font-semibold", className)} {...props} />;
}
export { Dialog, DialogTrigger, DialogContent, DialogTitle };
