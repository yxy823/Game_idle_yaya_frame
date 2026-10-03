# Texture and Image Assets

Classify a texture's role before choosing its compression, mipmaps, filtering, alpha, color space or resizing behavior.

## Roles

- **[MUST]** Classify textures by actual use as pixel color, continuous color, palette or lookup, data, normal, HDR, SVG or vector, or CPU-readable.
- **[PREFER]** Import pixel-exact color and source art losslessly. VRAM or lossy compression requires a deliberate review of quality and role.
- **[MUST]** The mipmap policy follows minification and lookup semantics. Fixed or integer-scaled pixel UI often disables mipmaps; this is not a universal project rule.
- **[MUST]** Filtering and repeat are primarily a sampling contract of the consumer, not one global image-format rule.

## CPU access

- **[PREFER]** Import assets that need frequent CPU pixel access as `Image`, or maintain an explicit contract for a cached CPU-side `Image`.
- **[MUST]** `Texture2D.get_image()` creates an `Image` from GPU data and is a readback from GPU to CPU. Do not call it every frame or at another high frequency, especially for large textures.
- **[MUST]** When the same source needs both rendering and CPU analysis, define a cache or a lifecycle for both representations. Do not mechanically change the import type for an occasional one-off read.

## Special data

- **[MUST]** Palette, LUT and index textures preserve discrete sampling and avoid unintended filtering or mipmap interpolation.
- **[REVIEW]** Alpha border processing helps color textures but may corrupt data or mask semantics; choose it by role.
- **[REVIEW]** Premultiplied alpha on import is a contract shared by import, blending, materials and shaders.
- **[MUST]** Normal maps are data. Follow the normal convention that Godot expects, and explicitly handle the inverted Y axis of DirectX-style maps when needed.
- **[MUST]** Channel-packed textures have an explicit channel schema.
- **[MUST]** PNG is not an HDR source format.

## Resizing and vector images

- **[MUST]** Import Size Limit is destructive resampling. Do not apply it without review to pixel art, palette or index images, masks, atlases or exact lookup data.
- **[MUST]** Where the project already uses external tooling that normalizes source art to exact sizes, that tooling remains the authority; do not replace it with import-time cubic resizing.
- **[MUST]** SVG import considers the rasterization scale and DPI, dependencies on text-to-path conversion and fonts, and compatibility with the target ThorVG version.
