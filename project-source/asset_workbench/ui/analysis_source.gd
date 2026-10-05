extends RefCounted

## Shared source-file contract. Godot resources are not implicitly flattened or exported.

const CAPABILITIES_PATH: String = "res://yaya/asset_workbench/analyzer/capabilities.json"

static var capabilities: Dictionary = {}


## Load once on demand. Failed loads remain retryable; no file I/O at class initialization.
static func initialize() -> String:
	if not capabilities.is_empty():
		return ""
	var file := FileAccess.open(CAPABILITIES_PATH, FileAccess.READ)
	if file == null:
		return "Cannot read %s: %s" % [CAPABILITIES_PATH, error_string(FileAccess.get_open_error())]
	var contents := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		return "Cannot read %s: %s" % [CAPABILITIES_PATH, error_string(read_error)]
	var parser := JSON.new()
	if parser.parse(contents) != OK:
		return "Invalid JSON in %s: %s" % [CAPABILITIES_PATH, parser.get_error_message()]
	if not _valid_capabilities(parser.data):
		return "Invalid source formats or memory budgets in " + CAPABILITIES_PATH
	for field: String in ["defaults", "limits"]:
		if not parser.data.get(field) is Dictionary:
			return "Missing or invalid %s dictionary in %s" % [field, CAPABILITIES_PATH]
	capabilities = parser.data
	return ""


## Call initialize() successfully first. Classification does not require a current file.
static func asset_type(path: String) -> String:
	var extension := path.get_extension().to_lower()
	for kind: String in capabilities.sources:
		if extension in capabilities.sources[kind].extensions:
			return kind
	return ""


static func _valid_capabilities(value: Variant) -> bool:
	if not value is Dictionary or value.get("capability_version") != 1:
		return false
	if not _positive_integer(value.get("pool_memory_mib")):
		return false
	var sources: Variant = value.get("sources")
	if not sources is Dictionary or sources.size() != 2:
		return false
	for kind: String in ["audio", "image"]:
		if not _valid_source(sources.get(kind)):
			return false
	return true


static func _valid_source(value: Variant) -> bool:
	if not value is Dictionary or not _positive_integer(value.get("memory_mib")):
		return false
	var extensions: Variant = value.get("extensions")
	if not extensions is Array or extensions.is_empty():
		return false
	return extensions.all(func(item: Variant) -> bool:
		return item is String and not item.is_empty())


static func _positive_integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and value > 0 and float(value) == floorf(float(value))


static func describe(asset: Resource) -> Dictionary:
	var kind := "unknown"
	if asset is AudioStream:
		kind = "audio"
	elif asset is Texture2D:
		kind = "image"
	var path := asset.resource_path
	var issue := path_issue(path, kind)
	if asset is AtlasTexture:
		issue = {"code": "source_not_file", "message":
			"Analyze the atlas source file separately; this is an indirect texture."}
	return {"path": path, "type": kind, "issue": issue}


static func path_issue(path: String, kind: String) -> Dictionary:
	var issue := initialize()
	if not issue.is_empty():
		return {"code": "analyzer_config", "message": issue}
	var indirect := path.get_extension().to_lower() in ["tres", "res", "tscn"]
	if path.is_empty() or path.contains("::") or indirect:
		return {"code": "source_not_file", "message":
			"Only standalone source media files can be analyzed."}
	if not FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
		return {"code": "source_not_file", "message": "Source path is not an existing ordinary file."}
	if not capabilities.sources.has(kind):
		return {"code": "unsupported_type", "message": "Choose an audio stream or a source texture."}
	if asset_type(path) != kind:
		return {"code": "unsupported_format", "message":
			"Source extension is not supported by the declared Analyzer capabilities."}
	return {}


## Call initialize() successfully before querying reservations.
static func memory_mib(kind: String) -> int:
	return int(capabilities.sources.get(kind, {}).get("memory_mib", 0))
