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

- **[MUST]** Recoverable business failure is represented through a real Result/return/state/event contract. Required node/resource/configuration failures remain distinguishable from successful empty values; defaults are only for inputs whose contract allows omission. `push_error()`/`push_warning()` are diagnostics, not control flow.
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

# An empty JSON object is valid here; failed loading is a different result.
func load_config(path: String) -> Result:
	var result := Result.new()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		result.error = "cannot open config %s: %s" % [path, FileAccess.get_open_error()]
		return result
	var contents: String = file.get_as_text()
	var read_error: Error = file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		result.error = "cannot read config %s: %s" % [path, read_error]
		return result
	var parsed: Variant = JSON.parse_string(contents)
	if not parsed is Dictionary:
		result.error = "config must contain a valid JSON object: %s" % path
		return result
	result.success = true
	result.data = parsed
	return result

func find_enemy_by_id(id: int) -> Enemy:
	for enemy: Enemy in enemies:
		if enemy.id == id:
			return enemy
	return null

class Result:
	var success: bool = false
	var data: Variant
	var error: String = ""
```

The caller checks `success` before consuming `data`; it handles or reports the
failure using the existing project convention. The small Result above illustrates
that distinction and does not require a shared Result framework. For file APIs
that expose an error code, preserve it with the relevant path and stop at the
failure boundary. Optional defaults must not turn a required load failure into
an apparently successful empty Dictionary or PackedByteArray.
