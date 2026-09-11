# Shader Includes and Reuse

Use `.gdshaderinc` for stable shared shader logic without creating a micro-include maze.

## Includes

- **[PREFER]** Extract a `.gdshaderinc` when multiple shaders genuinely share stable logic or a coherent utility domain.
- **[MUST]** Do not create tiny one-off include fragments that make shader behavior harder to trace than duplicated trivial expressions.
- **[MUST]** Include dependency graphs must not contain cycles.
- **[MUST]** Use stable, semantically prefixed names for functions and macros across includes to avoid symbol collisions; redefinition is not a supported reuse mechanism.
- **[MUST]** Keep include chains comfortably below Godot's shader preprocessor depth limit of 25; do not construct dependency chains that approach the limit.
- **[MUST]** Include file names and responsibilities should be semantic and stable.
- **[MUST]** Changing an include is a transitive consumer change. Recompile/validate every direct and transitive shader consumer.
- **[MUST]** Include rename/move is cross-shader dependency migration; include self-parse alone is not sufficient validation.
