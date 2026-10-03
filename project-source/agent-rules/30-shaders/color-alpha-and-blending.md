# Shader Color, Alpha, and Blending

Color space, alpha representation and blend mode are explicit rendering contracts.

## Color space

- **[MUST]** Mark actual sRGB and albedo color samplers and uniforms with `source_color`. Data textures, masks, normals, and LUT or index textures are not `source_color` by default.
- **[MUST]** Color math distinguishes linear from sRGB values. Do not add empirical `pow()` or gamma patches without a defined color-space reason.
- **[MUST]** Do not gamma-transform alpha as if it were color.
- **[MUST]** Do not mechanically clamp HDR RGB to 0..1 unless the effect contract requires clamping.

## CanvasItem and alpha

- **[MUST]** When rewriting CanvasItem `COLOR`, explicitly preserve or intentionally bypass the texture, `modulate` and `self_modulate` semantics.
- **[MUST]** The alpha representation matches the blend mode. Do not premultiply RGB twice or mix straight and premultiplied assumptions.
- **[REVIEW]** A blend-mode change alters composition; review it as rendering behavior, not as a convenient fix.
- **[REVIEW]** Use `discard` for cutout or mask semantics where appropriate, not as a generic optimization for zero alpha.
- **[MUST]** Diagnose transparent-edge artifacts across import, filtering, atlas packing, alpha, blending and the shader; do not assume that the shader alone is the cause.

## Special cases

- **[MUST]** Palette and exact-color lookups require proof that discrete identity is preserved through import, filtering, mipmapping and shader math.
- **[MUST]** Reading or writing `ALPHA` in a Spatial shader sends the material through the transparent pipeline, even when the shader always writes `1.0`. Do not treat that as an ordinary opaque path.
- **[MUST]** Use Spatial `ALPHA` only when transparency semantics are intended, and review the resulting sorting, shadow and depth behavior, and screen- and depth-texture behavior.
