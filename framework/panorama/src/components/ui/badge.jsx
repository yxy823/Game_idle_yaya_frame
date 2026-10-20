import { cn } from "cn";
import { Slot } from "radix-ui";

function Badge({ className, variant = "default", asChild = false, ...props }) {
  const Comp = asChild ? Slot.Root : "span";
  return <Comp data-slot="badge" className={cn("inline-block shrink-0 rounded-md px-1 text-xs font-normal", variant === "outline" ? "border border-input text-muted-foreground" : "bg-primary text-primary-foreground", className)} {...props} />;
}
export { Badge };
