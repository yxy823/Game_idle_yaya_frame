# Font Assets

Font role, shaping, localization coverage, scaling, and fallback are separate concerns.

## Font roles

- **[MUST]** Classify font role as dynamic/scalable versus bitmap/pixel. Pixel-art presentation does not automatically require bitmap fonts.
- **[MUST]** Font size is usually usage/theme state; do not duplicate a font Resource solely for every size.
- **[MUST]** Pixel clarity is a combined font/import/filter/scale/layout contract.
- **[REVIEW]** Choose MSDF only after weighing actual dynamic scaling, large-size, `Label3D`, and outline needs against its rendering cost and readability tradeoffs; it is not automatic for those uses.
- **[MUST]** When using MSDF, validate small-size readability because hinting is unavailable, and check self-intersecting/overlapping glyph-outline compatibility. Set `msdf_pixel_range` to at least twice the maximum required outline size so outlines are not clipped.

## Coverage/fallback

- **[MUST]** Fallback order is semantic; do not alphabetize fallbacks.
- **[MUST]** Localization coverage uses representative real text and validates shaping/layout, not just code-point presence.
- **[MUST]** Do not rely on system fallback as sole formal language-coverage guarantee.
- **[MUST]** Do not preload every Unicode glyph by default; configure/preload only justified coverage.
- **[PREFER]** Use FontVariation for variable-font axes rather than duplicating source fonts.
- **[REVIEW]** Simulated bold/slant may degrade intended font design and needs visual review.
- **[MUST]** Explicit `SystemFont` and dynamic-font `allow_system_fallback` are separate mechanisms with different platform implications.
- **[MUST]** A Unicode character is not necessarily one rendered glyph; shaping/language/script behavior matters.
