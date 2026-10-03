# Shader Includes and Reuse

Use `.gdshaderinc` for stable shared shader logic without creating a maze of tiny includes.

## Includes

- **[PREFER]** Extract a `.gdshaderinc` when several shaders genuinely share stable logic or a coherent utility domain.
- **[MUST]** Do not create tiny one-off include fragments that make shader behavior harder to trace than duplicated trivial expressions would.
- **[MUST]** Include dependency graphs contain no cycles.
- **[MUST]** Give functions and macros stable, semantically prefixed names across includes to avoid symbol collisions; redefinition is not a supported reuse mechanism.
- **[MUST]** Keep include chains comfortably below the shader preprocessor depth limit of 25 in Godot. Do not build dependency chains that approach the limit.
- **[MUST]** Give include files semantic, stable names and responsibilities.
- **[MUST]** Changing an include is a change for every transitive consumer. Recompile and validate every direct and transitive shader consumer.
- **[MUST]** Renaming or moving an include is a dependency migration across shaders; parsing the include alone is not sufficient validation.
