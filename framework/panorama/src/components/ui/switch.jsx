import { cn } from "cn";
import { Switch as SwitchPrimitive } from "radix-ui";

function Switch({ className, ...props }) {
  return <SwitchPrimitive.Root data-slot="switch" className={cn("relative inline-flex h-(--switch-h) w-(--switch-w) shrink-0 items-center rounded-full border-0 bg-input p-0.5 data-[state=checked]:bg-primary", className)} {...props}>
    <SwitchPrimitive.Thumb data-slot="switch-thumb" className="pointer-events-none block size-(--switch-thumb) rounded-full bg-background data-[state=checked]:translate-x-(--switch-travel)" />
  </SwitchPrimitive.Root>;
}
export { Switch };
