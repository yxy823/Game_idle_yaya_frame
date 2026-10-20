import { cva } from "class-variance-authority";
import { cn } from "cn";
import { Slot } from "radix-ui";

const buttonVariants = cva(
  "inline-flex shrink-0 items-center justify-center gap-1.5 rounded-md border border-transparent bg-transparent text-sm text-foreground no-underline cursor-pointer select-none focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2 aria-disabled:border-transparent! aria-disabled:bg-transparent! aria-disabled:opacity-45 aria-disabled:cursor-not-allowed [&_svg]:shrink-0 [&_svg]:pointer-events-none",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/80",
        outline: "border-input bg-background text-xs hover:bg-accent",
        ghost: "hover:bg-accent aria-pressed:bg-accent aria-[current=page]:bg-accent aria-[current=page]:shadow-[inset_2px_0_0_var(--primary)]",
        link: "h-auto justify-start border-0 p-0 text-left whitespace-normal hover:text-primary hover:underline [overflow-wrap:anywhere]",
        card: "h-auto flex-col items-stretch justify-start gap-1 border-[color-mix(in_srgb,var(--border)_60%,var(--card))] bg-card p-2.5 text-left whitespace-normal hover:border-[color-mix(in_srgb,var(--input)_50%,var(--border))] aria-selected:border-(--input) aria-selected:bg-(--selection)",
        row: "h-(--tree-row-h) w-full justify-start gap-0.5 border-0 pr-1.5 text-left whitespace-nowrap hover:bg-accent aria-selected:bg-(--selection)",
        result: "h-auto w-full flex-col items-stretch justify-start gap-0.5 border-0 px-2 py-1 text-left whitespace-normal hover:bg-accent aria-selected:bg-(--selection)",
        twisty: "size-(--icon) border-0 p-0 text-muted-foreground aria-expanded:text-primary",
      },
      size: {
        default: "h-(--control-h) px-2.5",
        icon: "size-(--control-h) p-0",
        activity: "size-(--activity-button) p-0",
        none: "",
      },
    },
    defaultVariants: { variant: "default", size: "default" },
  }
);

function Button({ className, variant = "default", size = "default", asChild = false, ...props }) {
  const Comp = asChild ? Slot.Root : "button";
  return <Comp data-slot="button" data-variant={variant} data-size={size} className={cn(buttonVariants({ variant, size, className }))} {...props} />;
}
export { Button, buttonVariants };
