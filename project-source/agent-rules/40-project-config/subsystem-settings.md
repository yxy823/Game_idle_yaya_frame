# Subsystem Settings

Audio, physics, localization and rendering settings are whole-project runtime contracts. Read the section for the subsystem whose settings change.

## Audio

- **[MUST]** The configured default bus layout path is a project Resource dependency and must resolve and load.
- **[MUST]** Audio bus names are cross-file APIs. Renaming or removing a bus migrates its AudioStreamPlayer, code, animation and mixer consumers.
- **[MUST]** Do not assume that a missing bus fails loudly; the fallback to Master can silently hide migration errors.
- **[MUST]** The configured driver, mix rate and latency are not necessarily the actual runtime device state. Validate on the platform and at runtime where relevant.

## Physics

- **[REVIEW]** `physics_ticks_per_second` is a whole-project timing and simulation setting; do not change it to speed up tests.
- **[REVIEW]** Changing `physics_ticks_per_second` can change damping and gameplay feel. Evaluate those effects instead of treating the change as pure precision or performance tuning.
- **[MUST]** When substantially increasing the physics tick rate, check `max_physics_steps_per_frame` at low rendering FPS so that the simulation does not fall behind or slow down.
- **[REVIEW]** Evaluate physics interpolation together with the display refresh rate and the render cadence, checking for jitter at nonstandard tick rates.
- **[MUST]** Physics interpolation is a global simulation and rendering contract. When it changes, validate movement, camera and physics consumers.
- **[REVIEW]** A physics backend change is a migration-level behavior change. Pin and validate the backend when project correctness depends on backend-specific behavior.
- **[REVIEW]** Running physics on a separate thread changes API and threading constraints and requires a review of the code that crosses threads.

## Localization

- **[MUST]** A translation file that exists in the project is not necessarily registered for runtime localization.
- **[MUST]** Define the fallback locale deliberately; do not rely accidentally on English or the editor locale.
- **[MUST]** Use locale identifiers that the target Godot version and the project's localization contract support.
- **[MUST]** Locale overrides for tests are temporary test or runtime state, not persistent production project configuration.
- **[MUST]** `internationalization/locale/test` also affects exported projects. Isolate Editor-only locale tests with an appropriate `editor` feature override or another test configuration, so that the test locale does not enter production exports.
- **[MUST]** Translation remaps create a dependency between the source and each locale, and are migrated together.
- **[PREFER]** Use pseudolocalization as a validation tool where UI localization coverage matters.

## Renderer

- **[MUST]** The configured renderer and driver are not necessarily the actual runtime renderer. Validate runtime behavior where it is renderer-specific.
- **[REVIEW]** A renderer or driver change affects compatibility, performance and rendering across the whole project.
- **[MUST]** Do not change the renderer baseline merely to simplify one shader or effect.

## Viewport, window, and stretch

- **[MUST]** The base viewport or render size and the initial window size are distinct concepts.
- **[MUST]** Set the stretch mode and aspect deliberately, and validate both world camera and UI behavior.
- **[PREFER]** Low-resolution pixel games often use viewport or integer-scale strategies, but do not impose a universal pixel-perfect configuration.
- **[MUST]** Pixel snapping of transforms and pixel snapping of vertices are distinct settings, and UI pixel snapping is separate from both.
- **[MUST]** Pixel-perfect output is a combined system of viewport, stretch, import, sampling and layout settings, not one checkbox.
- **[MUST]** Runtime window preferences belong to user and runtime APIs and `user://`, not to permanent `project.godot` rewrites.

## HDR

- **[REVIEW]** HDR 2D is a global rendering contract that affects shader and color behavior, and requires representative render validation.
