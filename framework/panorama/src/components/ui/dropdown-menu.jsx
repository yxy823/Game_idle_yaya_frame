import { cn } from "cn";
import { DropdownMenu as DropdownMenuPrimitive } from "radix-ui";
import { CheckIcon } from "lucide-react";

function DropdownMenu(props) { return <DropdownMenuPrimitive.Root {...props} />; }
function DropdownMenuTrigger(props) { return <DropdownMenuPrimitive.Trigger data-slot="dropdown-menu-trigger" {...props} />; }
function DropdownMenuContent({ className, align = "end", sideOffset = 4, ...props }) {
  return <DropdownMenuPrimitive.Portal><DropdownMenuPrimitive.Content data-slot="dropdown-menu-content" data-pick-ignore align={align} sideOffset={sideOffset}
    className={cn("z-(--z-menu) min-w-(--menu-w) rounded-md border border-border bg-popover py-1 text-popover-foreground shadow-(--shadow)", className)} {...props} /></DropdownMenuPrimitive.Portal>;
}
const itemClasses = "relative flex h-(--control-h) items-center gap-2 pr-3 pl-(--menu-item-pad) text-sm cursor-pointer select-none outline-none focus:bg-accent";
function DropdownMenuCheckboxItem({ className, children, ...props }) {
  return <DropdownMenuPrimitive.CheckboxItem data-slot="dropdown-menu-checkbox-item" className={cn(itemClasses, className)} {...props}>
    <span aria-hidden="true" className="absolute left-2 inline-flex size-(--icon)" />{children}
  </DropdownMenuPrimitive.CheckboxItem>;
}
function DropdownMenuRadioGroup(props) { return <DropdownMenuPrimitive.RadioGroup data-slot="dropdown-menu-radio-group" {...props} />; }
function DropdownMenuRadioItem({ className, children, ...props }) {
  return <DropdownMenuPrimitive.RadioItem data-slot="dropdown-menu-radio-item" className={cn(itemClasses, className)} {...props}>
    <span className="absolute left-2 inline-flex size-(--icon) items-center justify-center"><DropdownMenuPrimitive.ItemIndicator><CheckIcon className="size-(--icon)" aria-hidden="true" /></DropdownMenuPrimitive.ItemIndicator></span>{children}
  </DropdownMenuPrimitive.RadioItem>;
}
function DropdownMenuLabel({ className, ...props }) {
  return <DropdownMenuPrimitive.Label data-slot="dropdown-menu-label" className={cn("px-3 pt-1 pb-0.5 text-xs text-muted-foreground", className)} {...props} />;
}
function DropdownMenuSeparator({ className, ...props }) {
  return <DropdownMenuPrimitive.Separator data-slot="dropdown-menu-separator" className={cn("my-1 h-px bg-border", className)} {...props} />;
}
export { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuCheckboxItem, DropdownMenuRadioGroup, DropdownMenuRadioItem, DropdownMenuLabel, DropdownMenuSeparator };
