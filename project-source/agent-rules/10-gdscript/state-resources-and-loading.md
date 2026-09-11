# GDScript State, Resources, Loading, Errors, Time, and RNG

Keep definition/config data, mutable runtime state, I/O, time, and randomness explicit.

## Resource and state semantics

- **[MUST]** Choose Node, RefCounted, and Resource according to lifecycle and state semantics, not convenience.
- **[MUST]** Definition/config Resources are runtime read-only by default. Mutable runtime state normally belongs to a separate authoritative state owner/model.
- **[MUST]** Do not save runtime gameplay mutations back into project definition `.tres` files.
- **[MUST]** When code relies on shared/cached Resources, respect ResourceLoader cache identity; do not assume repeated `load()` returns a fresh copy.

## Loading

- **[PREFER]** Use `preload()` for stable load-time dependencies and `load()`/ResourceLoader for runtime-selected dependencies.
- **[MUST]** Do not perform first-time resource loads in hot loops or latency-sensitive paths without an explicit reason/preload strategy.
- **[MUST]** Threaded ResourceLoader code uses the official request/status/get lifecycle; do not use `load_threaded_get()` as a polling operation.

## Errors and determinism

- **[MUST]** Recoverable business failure is represented through a real Result/return/state/event contract. `push_error()`/`push_warning()` are diagnostics, not control flow.
- **[MUST]** Use `assert` only for development invariants. Assertion conditions must be side-effect free because assertions are ignored in non-debug/release builds.
- **[MUST]** GDScript has no `throw`, `try`, `except`, or `finally`; use explicit return/null/result contracts and lifecycle callbacks for cleanup.
- **[MUST]** Document typed Object returns that may be `null`, require callers to check them, and default collections to `[]` / `{}` rather than `null`.
- **[PREFER]** Use deterministic, injectable or owned RNG for gameplay rules where reproducibility matters. Do not depend on uncontrolled global RNG state.
- **[MUST]** Use explicit time domains. Gameplay-scaled time, physics time, monotonic elapsed time, and wall-clock/calendar time are not interchangeable.
- **[MUST]** Shader/VFX/animation time is not authoritative gameplay state.
- **[PREFER]** Keep pure rules deterministic: same explicit inputs and declared dependencies should produce the same result.

```gdscript
# Development invariant; this assertion is not a runtime recovery path.
func take_damage(amount: int) -> void:
	assert(amount >= 0, "damage amount must be non-negative")
	health -= amount

# Recoverable failure: report it and return a safe result.
func load_config(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("config file not found: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("config root must be a Dictionary: %s" % path)
	return {}

func find_enemy_by_id(id: int) -> Enemy:
	for enemy: Enemy in enemies:
		if enemy.id == id:
			return enemy
	return null

class Result:
	var success: bool
	var data: Variant
	var error: String
```

For file APIs that expose an error code, preserve the code and stop at the failure boundary:

```gdscript
func read_save(path: String) -> PackedByteArray:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var error: Error = FileAccess.get_open_error()
		push_error("failed to open save: %s" % error)
		return PackedByteArray()
	return file.get_buffer(file.get_length())
```
