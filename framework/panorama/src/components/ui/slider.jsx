import { cn } from "cn";
import { Slider as SliderPrimitive } from "radix-ui";

// 单个滑块：拖动或用方向键按 step 调整
function Slider({ className, ...props }) {
  return <SliderPrimitive.Root data-slot="slider" className={cn("relative flex h-(--control-h) w-(--slider-w) touch-none items-center select-none", className)} {...props}>
    <SliderPrimitive.Track data-slot="slider-track" className="relative h-1 grow overflow-hidden rounded-full bg-border">
      <SliderPrimitive.Range data-slot="slider-range" className="absolute h-full bg-primary" />
    </SliderPrimitive.Track>
    <SliderPrimitive.Thumb data-slot="slider-thumb" className="block size-(--slider-thumb) cursor-pointer rounded-full border border-primary bg-background focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2" />
  </SliderPrimitive.Root>;
}
export { Slider };
