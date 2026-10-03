# Shader Coordinates and Sampling

Every coordinate, offset and pixel-size calculation has an explicit space.

## Coordinate spaces

- **[MUST]** Do not mix UV units, screen UV, render pixels, physical display pixels, logical pixels and texture texels without explicit conversion.
- **[MUST]** `TEXTURE_PIXEL_SIZE` refers to the built-in `TEXTURE`. Custom samplers need their own texel-size contract or a justified `textureSize()` path.
- **[MUST]** Object texture effects normally use object UV; screen-space effects use `SCREEN_UV` and screen-texture semantics.
- **[MUST]** Do not assume that one texture texel equals one screen or render pixel.
- **[MUST]** Pixel-perfect rendering is first a problem of the viewport, stretch settings and integer scaling. Do not add a universal shader snapping hack.

## Atlas, region, filter, and mipmaps

- **[MUST]** Sprite2D region and atlas effects use region-aware coordinates (`REGION_RECT` or an equivalent contract) and prevent unintended sampling of neighboring regions.
- **[MUST]** Filtering and repeat behavior are part of the algorithm contract. Do not impose nearest filtering globally just because the game uses pixel art.
- **[MUST]** Mipmaps are not globally banned. Require or disable them based on minification, lookup and data semantics.
- **[MUST]** Sampling a higher LOD requires an import and filter path that actually supplies usable mipmaps.

## Vertex and viewport

- **[MUST]** When changing vertex transform modes, keep the coordinate space of `VERTEX` and downstream varyings explicit.
- **[MUST]** Validate screen-space shaders on a SubViewport or at an alternate resolution against the actual render resolution, rather than assuming the desktop window size.

## Screen and backbuffer sampling

- **[MUST]** In 2D, the automatic full-screen backbuffer copy for the first `hint_screen_texture` use usually occurs only once. Check overlapping screen effects against tree order, and use `BackBufferCopy` when an explicit intermediate copy is required.
- **[MUST]** Do not sample a region-limited `BackBufferCopy` outside its copied region; such samples have undefined results.
- **[MUST]** In 3D, screen texture capture occurs after the opaque pass and before the transparent pass. Transparent objects are not captured, and a material that uses the screen texture is itself subject to transparent-pipeline behavior. Validate the intended visibility between effects.
