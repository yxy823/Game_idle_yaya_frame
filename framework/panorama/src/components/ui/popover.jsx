import { cn } from "cn";
import { Popover as PopoverPrimitive } from "radix-ui";

function Popover(props) { return <PopoverPrimitive.Root {...props} />; }
function PopoverAnchor(props) { return <PopoverPrimitive.Anchor data-slot="popover-anchor" {...props} />; }
function PopoverContent({ className, align = "start", sideOffset = 4, ...props }) {
  return <PopoverPrimitive.Portal><PopoverPrimitive.Content data-slot="popover-content" data-pick-ignore align={align} sideOffset={sideOffset}
    className={cn("z-(--z-menu) w-(--search-list-w) rounded-md border border-border bg-popover py-1 text-popover-foreground shadow-(--shadow)", className)} {...props} /></PopoverPrimitive.Portal>;
}
export { Popover, PopoverAnchor, PopoverContent };
