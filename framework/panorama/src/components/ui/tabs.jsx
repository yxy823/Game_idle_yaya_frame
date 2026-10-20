import { cn } from "cn";
import { Tabs as TabsPrimitive } from "radix-ui";

function Tabs({ className, ...props }) { return <TabsPrimitive.Root data-slot="tabs" className={cn("min-w-0", className)} {...props} />; }
function TabsList({ className, variant = "default", ...props }) {
  return <TabsPrimitive.List data-slot="tabs-list" data-variant={variant}
    className={cn("inline-flex rounded-md border border-input bg-background", className)} {...props} />;
}
function TabsTrigger({ className, ...props }) {
  return <TabsPrimitive.Trigger data-slot="tabs-trigger"
    className={cn("inline-flex h-[calc(var(--control-h)-2px)] items-center justify-center border-0 bg-transparent px-2.5 text-xs text-foreground cursor-pointer hover:bg-accent data-[state=active]:bg-primary data-[state=active]:text-primary-foreground [&+&]:border-l [&+&]:border-input focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2", className)} {...props} />;
}
function TabsContent({ className, ...props }) { return <TabsPrimitive.Content data-slot="tabs-content" className={cn("min-h-0 min-w-0", className)} {...props} />; }
export { Tabs, TabsList, TabsTrigger, TabsContent };
