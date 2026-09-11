# Shader Color, Alpha, and Blending

Color-space, alpha representation, and blend mode are explicit rendering contracts.

## Color space

- **[MUST]** Mark actual sRGB/albedo color samplers appropriately; data textures, masks, normals, LUT/index textures are not `source_color` by default.
- **[MUST]** Color math understands linear versus sRGB. Do not add empirical `pow()`/gamma patches without a defined color-space reason.
- **[MUST]** Do not gamma-transform alpha as if it were color.
- **[MUST]** Do not mechanically clamp HDR RGB to 0..1 unless the effect contract requires clamping.

## CanvasItem and alpha

- **[MUST]** When rewriting CanvasItem `COLOR`, explicitly preserve or intentionally bypass texture/modulate/self_modulate semantics.
- **[MUST]** Alpha representation matches blend mode. Do not double-premultiply RGB or mix straight/premultiplied assumptions.
- **[REVIEW]** Blend-mode changes alter composition and must be reviewed as rendering behavior, not as a convenient fix.
- **[REVIEW]** `discard` is for cutout/mask semantics where appropriate, not a generic optimization for alpha zero.
- **[MUST]** Transparent-edge artifacts are diagnosed across import/filter/atlas/alpha/blend/shader; do not assume shader alone is the cause.

## Special cases

- **[MUST]** Palette/exact-color lookups require proof that discrete identity is preserved through import, filtering, mipmapping, and shader math.
- **[MUST]** Reading or writing `ALPHA` in a Spatial shader sends the material through the transparent pipeline, even when the shader always writes `1.0`; do not treat that as an ordinary opaque path.
- **[MUST]** Use Spatial `ALPHA` only when transparency semantics are intended, and review the resulting sorting, shadow/depth, and screen/depth-texture behavior.
