# Rendering and Display Configuration

Renderer, viewport, stretch, pixel snapping, HDR, and window state are project-wide contracts.

## Renderer

- **[MUST]** Configured renderer/driver is not necessarily actual runtime renderer. Validate runtime behavior where renderer-specific.
- **[REVIEW]** Renderer/driver changes are project-wide compatibility/performance/rendering changes.
- **[MUST]** Do not change renderer baseline merely to simplify one shader/effect.

## Viewport/window/stretch

- **[MUST]** Base viewport/render size and initial window size are distinct concepts.
- **[MUST]** Set stretch mode/aspect deliberately and validate world camera plus UI behavior.
- **[PREFER]** Low-resolution pixel games often use viewport/integer-scale strategies, but do not impose universal pixel-perfect configuration.
- **[MUST]** Pixel snap transforms and pixel snap vertices are distinct settings; UI pixel snapping is separate.
- **[MUST]** Pixel-perfect output is a combined viewport/stretch/import/sampling/layout system, not one checkbox.
- **[MUST]** Runtime window preferences belong to user/runtime APIs and `user://`, not permanent `project.godot` rewrites.

## HDR

- **[REVIEW]** HDR 2D is a global rendering contract affecting shader/color behavior and requires representative render validation.
