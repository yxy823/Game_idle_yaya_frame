import { cn } from "cn";
import { Command as CommandPrimitive } from "cmdk";
import { inputClasses } from "@/components/ui/input";

function Command({ className, ...props }) { return <CommandPrimitive data-slot="command" className={cn("min-w-0", className)} {...props} />; }
function CommandInput({ className, ...props }) {
  return <CommandPrimitive.Input data-slot="command-input" className={cn(inputClasses, className)} {...props} />;
}
function CommandList({ className, ...props }) { return <CommandPrimitive.List data-slot="command-list" className={cn("max-h-(--search-list-h) overflow-x-hidden overflow-y-auto", className)} {...props} />; }
function CommandEmpty({ className, ...props }) { return <CommandPrimitive.Empty data-slot="command-empty" className={cn("px-3 py-1 text-muted-foreground", className)} {...props} />; }
function CommandItem({ className, ...props }) {
  return <CommandPrimitive.Item data-slot="command-item" className={cn("flex min-h-(--control-h) items-center gap-2 px-3 text-sm cursor-pointer data-[selected=true]:bg-accent", className)} {...props} />;
}
export { Command, CommandInput, CommandList, CommandEmpty, CommandItem };
