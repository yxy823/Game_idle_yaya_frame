# GDScript State, Resources, Loading, Errors, Time, and RNG

Keep definition and configuration data, mutable runtime state, I/O, time and randomness explicit.

## Resource and state semantics

- **[MUST]** Choose Node, RefCounted, and Resource according to lifecycle and state semantics, not convenience.
- **[MUST]** Keep definition and configuration Resources read-only at runtime, as defined in [Resource roles](../21-resources/roles-sharing-and-locality.md#roles). Mutable runtime state normally belongs to a separate authoritative state owner or model, and runtime mutations are never saved back into project definition `.tres` files ([saving rules](../21-resources/identity-paths-and-saving.md#saving-and-generation)).
- **[MUST]** When code relies on shared or cached Resources, respect ResourceLoader cache identity. Do not assume that a repeated `load()` returns a fresh copy.

## Loading

- **[PREFER]** Use `preload()` for stable load-time dependencies, and `load()` or ResourceLoader for dependencies selected at runtime.
- **[MUST]** Do not perform first-time resource loads in hot loops or latency-sensitive paths without an explicit reason or preload strategy.
- **[MUST]** Threaded ResourceLoader code uses the official request, status and get lifecycle. Do not use `load_threaded_get()` as a polling operation.

## Errors and determinism

- **[MUST]** Represent a recoverable business failure through a real result, return value, state or event contract.
- **[MUST]** Keep failures of required Nodes, Resources and configuration distinguishable from successful empty values. Use defaults only for inputs whose contract allows omission.
- **[MUST]** `push_error()` and `push_warning()` are diagnostics, not control flow.
- **[MUST]** Use `assert` only for development invariants. Keep assertion conditions free of side effects, because release (non-debug) builds ignore assertions.
- **[MUST]** GDScript has no `throw`, `try`, `except` or `finally`. Use explicit return, null or result contracts, and use lifecycle callbacks for cleanup.
- **[MUST]** Document typed Object returns that may be `null`, and require callers to check them. Default collections to `[]` or `{}` rather than `null`.
- **[PREFER]** Use a deterministic, injectable or owned RNG for gameplay rules where reproducibility matters. Do not depend on uncontrolled global RNG state.
- **[MUST]** Use explicit time domains. Gameplay-scaled time, physics time, monotonic elapsed time and wall-clock or calendar time are not interchangeable.
- **[MUST]** Shader, VFX and animation time is not authoritative gameplay state.
- **[PREFER]** Keep pure rules deterministic: the same explicit inputs and declared dependencies produce the same result.

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

The caller checks `success` before consuming `data`; it handles or reports the failure using the existing project convention. The small Result above illustrates that distinction and does not require a shared Result framework. For file APIs that expose an error code, preserve it with the relevant path and stop at the failure boundary. Optional defaults must not turn a required load failure into an apparently successful empty Dictionary or PackedByteArray.
