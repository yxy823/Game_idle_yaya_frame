# Shader Validation

- **[MUST]** Compile with the actual shader compiler of the target Godot 4.7; regex or third-party text parsing is not sufficient.
- **[MUST]** Validate through the real ShaderMaterial, Node and render path, not only the isolated source.
- **[MUST]** Validate the relevant renderer, HDR 2D, viewport, atlas and import settings where they are part of the effect contract.
- **[MUST]** For screen-reading shaders, validate the real backbuffer and sampling path, including 2D tree order, `BackBufferCopy` region behavior and the 3D opaque and transparent capture boundaries. A successful shader compile alone is not sufficient.

Include consumers and particle state are validated as described in `includes-and-reuse.md` and `language-and-structure.md`. Rendering evidence follows the [visual boundary](../70-tests/testing-strategy.md#visual-boundary).
