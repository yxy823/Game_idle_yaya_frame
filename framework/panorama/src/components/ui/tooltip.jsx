import { cn } from "cn";
import { Tooltip as TooltipPrimitive } from "radix-ui";

function TooltipProvider({ delayDuration = 0, ...props }) {
  return <TooltipPrimitive.Provider delayDuration={delayDuration} {...props} />;
}
function Tooltip(props) { return <TooltipPrimitive.Root {...props} />; }
function TooltipTrigger(props) { return <TooltipPrimitive.Trigger data-slot="tooltip-trigger" {...props} />; }
function TooltipContent({ className, ...props }) {
  return <TooltipPrimitive.Portal><TooltipPrimitive.Content data-slot="tooltip-content" data-pick-ignore
    className={cn("pointer-events-none z-(--z-tip) w-fit rounded-md bg-(--tip-bg) px-2 py-1 text-xs text-(--tip-fg) whitespace-nowrap", className)} {...props} /></TooltipPrimitive.Portal>;
}
export { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger };
