import { Toaster as Sonner } from "sonner";

function Toaster({ theme, ...props }) {
  return <Sonner theme={theme} position="bottom-center" visibleToasts={1} hotkey={[]} duration={Infinity}
    offset="var(--toast-bottom)" style={{ zIndex: "var(--z-toast)" }}
    toastOptions={{ unstyled: true, classNames: {
      toast: "w-max! max-w-full! rounded-md! bg-(--tip-bg)! px-3! py-1! text-xs! text-(--tip-fg)! transition-none! animate-none!",
      content: "text-xs!",
    } }} {...props} />;
}
export { Toaster };
