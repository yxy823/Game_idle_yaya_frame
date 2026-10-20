import { cn } from "cn";
import { Tabs as TabsPrimitive } from "radix-ui";

function Tabs({ className, ...props }) { return <TabsPrimitive.Root data-slot="tabs" className={cn("min-w-0", className)} {...props} />; }
function TabsList({ className, variant = "default", ...props }) {
  return <TabsPrimitive.List data-slot="tabs-list" data-variant={variant}
    className={cn("inline-flex rounded-md border border-input bg-background", variant === "panel" && "grid w-full grid-flow-col auto-cols-fr rounded-none border-x-0 border-t-0 border-b-border mb-1 -mt-1", className)} {...props} />;
}
function TabsTrigger({ className, ...props }) {
  return <TabsPrimitive.Trigger data-slot="tabs-trigger"
    className={cn("inline-flex h-[calc(var(--control-h)-2px)] items-center justify-center border-0 bg-transparent px-2.5 text-xs text-foreground cursor-pointer hover:bg-accent data-[state=active]:bg-primary data-[state=active]:text-primary-foreground [&+&]:border-l [&+&]:border-input [[data-variant=panel]>&]:h-(--control-h) [[data-variant=panel]>&]:bg-(--chrome) [[data-variant=panel]>&]:text-muted-foreground [[data-variant=panel]>&]:px-1.5 [[data-variant=panel]>&]:data-[state=active]:bg-card [[data-variant=panel]>&]:data-[state=active]:text-foreground [[data-variant=panel]>&]:data-[state=active]:font-semibold [[data-variant=panel]>&]:border-border focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2", className)} {...props} />;
}
function TabsContent({ className, ...props }) { return <TabsPrimitive.Content data-slot="tabs-content" className={cn("min-h-0 min-w-0", className)} {...props} />; }
export { Tabs, TabsList, TabsTrigger, TabsContent };
