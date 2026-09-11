# Shader Validation

- **[MUST]** Compile with actual target Godot 4.7 shader compiler; regex/third-party text parsing is not sufficient.
- **[MUST]** Validate through the real ShaderMaterial/Node/render path, not only isolated source.
- **[MUST]** A `.gdshaderinc` change recompiles/validates all direct and transitive consumers.
- **[MUST]** Validate relevant renderer/HDR2D/viewport/atlas/import settings where they are part of the effect contract.
- **[MUST]** Particle shaders validate multi-frame state/restart semantics when those paths changed.
- **[MUST]** Screen-reading shaders validate the real backbuffer/sampling path, including 2D tree order/`BackBufferCopy` region behavior and 3D opaque/transparent capture boundaries; Shader compile PASS alone is not sufficient.
- **[MUST]** v1 does not require screenshot/golden-image/pixel-diff regression. Visual composition and animation feel remain manual acceptance.
