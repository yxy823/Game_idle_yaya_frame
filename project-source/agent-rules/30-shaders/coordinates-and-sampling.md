# Shader Coordinates and Sampling

Every coordinate, offset, and pixel-size calculation must have an explicit space.

## Coordinate spaces

- **[MUST]** Do not mix UV units, screen UV, render pixels, physical display pixels, logical pixels, and texture texels without explicit conversion.
- **[MUST]** `TEXTURE_PIXEL_SIZE` refers to built-in `TEXTURE`; custom samplers need their own texel-size contract or a justified `textureSize()` path.
- **[MUST]** Object texture effects normally use object UV; screen-space effects use `SCREEN_UV`/screen-texture semantics.
- **[MUST]** Do not assume one texture texel equals one screen/render pixel.
- **[MUST]** Pixel-perfect rendering is a viewport/stretch/integer-scale/system problem first; do not add a universal shader snapping hack.

## Atlas, region, filter, mip

- **[MUST]** Sprite2D region/atlas effects use region-aware coordinates (`REGION_RECT` or equivalent contract) and prevent unintended neighbor sampling.
- **[MUST]** Filtering/repeat behavior is part of the algorithm contract. Do not impose nearest filtering globally just because the game is pixel-art.
- **[MUST]** Mipmaps are not globally banned. Require or disable them based on minification/lookup/data semantics.
- **[MUST]** Sampling higher LOD requires an import/filter path that actually supplies usable mipmaps.

## Vertex and viewport

- **[MUST]** When changing vertex transform modes, keep the coordinate space of VERTEX and downstream varyings explicit.
- **[MUST]** Screen-space shaders on SubViewport/alternate resolution validate against actual render resolution rather than assuming desktop window size.

## Screen and backbuffer sampling

- **[MUST]** In 2D, the automatic full-screen backbuffer copy for the first `hint_screen_texture` use usually occurs only once; overlapping screen effects must be checked against tree order and use `BackBufferCopy` when an explicit intermediate copy is required.
- **[MUST]** A region-limited `BackBufferCopy` must not be sampled outside its copied region; such samples have undefined results.
- **[MUST]** In 3D, screen texture capture occurs after the opaque pass and before the transparent pass. Transparent objects are not captured, and a material using screen texture is itself subject to transparent-pipeline behavior; validate the intended visibility between effects.
