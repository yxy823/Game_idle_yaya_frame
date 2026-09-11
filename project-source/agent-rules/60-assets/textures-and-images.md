# Texture and Image Assets

Classify texture role before choosing compression, mipmaps, filtering, alpha, color-space, or resizing behavior.

## Roles

- **[MUST]** Classify textures as Pixel Color, Continuous Color, Palette/Lookup, Data, Normal, HDR, SVG/vector, or CPU-readable according to actual use.
- **[PREFER]** Pixel-exact color/source art uses lossless import; VRAM/lossy compression requires deliberate quality/role review.
- **[MUST]** Mipmap policy follows minification/lookup semantics. Fixed/integer pixel UI often disables mipmaps; this is not a universal project rule.
- **[MUST]** Filter/repeat is primarily a sampling/consumer contract, not one global image-format rule.

## CPU access

- **[PREFER]** Assets requiring frequent CPU pixel access should import as `Image` or maintain an explicit cached CPU-side `Image` contract.
- **[MUST]** `Texture2D.get_image()` creates an `Image` from GPU data and is a GPU-to-CPU readback; do not call it every frame or at other high frequency, especially for large textures.
- **[MUST]** When the same source needs rendering and CPU analysis, define a cache or dual-representation lifecycle. Do not mechanically change import type for an occasional one-off read.

## Special data

- **[MUST]** Palette/LUT/index textures preserve discrete sampling and avoid unintended filtering/mipmap interpolation.
- **[REVIEW]** Alpha border processing helps color textures but may corrupt data/mask semantics; choose by role.
- **[REVIEW]** Premultiplied alpha import is a cross import/blend/material/shader contract.
- **[MUST]** Normal maps are data; follow Godot expected normal convention and explicitly handle DirectX-style Y inversion when needed.
- **[MUST]** Channel-packed textures have an explicit channel schema.
- **[MUST]** PNG is not an HDR source format.

## Resize/vector

- **[MUST]** Import Size Limit is destructive resampling; do not apply it unreviewed to pixel art, palette/index, masks, atlases, or exact lookup data.
- **[MUST]** External exact 32x32 normalization/source-art tooling remains authority where project already uses it; do not replace it with import-time cubic resizing.
- **[MUST]** SVG import considers rasterization scale/DPI, text-to-path/font dependencies, and target ThorVG compatibility.
