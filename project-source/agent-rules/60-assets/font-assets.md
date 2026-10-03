# Font Assets

Font role, shaping, localization coverage, scaling and fallback are separate concerns.

## Font roles

- **[MUST]** Classify a font's role as dynamic and scalable or as bitmap and pixel. Pixel-art presentation does not automatically require bitmap fonts.
- **[MUST]** By default, share one source file for the same logical font and reuse it through Theme or Resource references. Do not duplicate source fonts or font Resources solely for different UI scenes or font sizes; font size is usually usage or theme state.
- **[MUST]** Pixel clarity is a combined contract of the font, import settings, filtering, scaling and layout.
- **[REVIEW]** Choose MSDF only after weighing the actual needs for dynamic scaling, large sizes, `Label3D` and outlines against its rendering cost and readability tradeoffs; it is not automatic for those uses.
- **[MUST]** When using MSDF, validate readability at small sizes because hinting is unavailable, and check compatibility with self-intersecting or overlapping glyph outlines. Set `msdf_pixel_range` to at least twice the largest required outline size so that outlines are not clipped.

## Coverage and fallback

- **[MUST]** Fallback order is semantic; do not alphabetize fallbacks.
- **[MUST]** Check localization coverage with representative real text, and validate shaping and layout, not just the presence of code points.
- **[MUST]** Do not rely on system fallback as the only formal guarantee of language coverage.
- **[MUST]** Do not preload every Unicode glyph by default; configure and preload only justified coverage.
- **[PREFER]** Use FontVariation for the axes of variable fonts rather than duplicating source fonts.
- **[REVIEW]** Simulated bold or slant may degrade the intended font design and needs visual review.
- **[MUST]** An explicit `SystemFont` and a dynamic font's `allow_system_fallback` are separate mechanisms with different platform implications.
- **[MUST]** A Unicode character is not necessarily one rendered glyph; shaping, language and script behavior matter.
