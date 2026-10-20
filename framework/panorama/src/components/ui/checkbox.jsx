import { cn } from "cn";
import { Checkbox as CheckboxPrimitive } from "radix-ui";
import { CheckIcon, MinusIcon } from "lucide-react";

function Checkbox({ className, checked, ...props }) {
  return <CheckboxPrimitive.Root data-slot="checkbox" checked={checked}
    className={cn("inline-flex size-(--checkbox-size) shrink-0 items-center justify-center rounded-sm border border-input bg-background p-0 text-primary-foreground data-[state=checked]:border-primary data-[state=checked]:bg-primary data-[state=indeterminate]:border-primary data-[state=indeterminate]:bg-primary focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2", className)} {...props}>
    <CheckboxPrimitive.Indicator data-slot="checkbox-indicator" className="inline-flex [&>svg]:size-(--checkbox-mark)">
      {checked === "indeterminate" ? <MinusIcon aria-hidden="true" /> : <CheckIcon aria-hidden="true" />}
    </CheckboxPrimitive.Indicator>
  </CheckboxPrimitive.Root>;
}
export { Checkbox };
