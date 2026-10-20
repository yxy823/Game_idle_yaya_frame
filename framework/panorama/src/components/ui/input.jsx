import { cn } from "cn";

export const inputClasses = "h-(--control-h) min-w-0 rounded-md border border-input bg-background px-2 py-0 text-base text-foreground placeholder:text-muted-foreground focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2";
function Input({ className, type = "text", ...props }) {
  return <input type={type} data-slot="input" className={cn(inputClasses, className)} {...props} />;
}
export { Input };
