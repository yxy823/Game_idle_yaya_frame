extends RefCounted

## Shared source-file contract. Godot resources are not implicitly flattened or exported.

static var capabilities: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
	"res://tools/asset_analyzer/capabilities.json"))


static func describe(asset: Resource) -> Dictionary:
	var kind := "unknown"
	if asset is AudioStream:
		kind = "audio"
	elif asset is Texture2D:
		kind = "image"
	var path := asset.resource_path
	var issue := path_issue(path, kind)
	if asset is AtlasTexture:
		issue = {"code": "source_not_file", "message": "Analyze the atlas source file separately; this is an indirect texture."}
	return {"path": path, "type": kind, "issue": issue}


static func path_issue(path: String, kind: String) -> Dictionary:
	if path.is_empty() or path.contains("::") or path.get_extension().to_lower() in ["tres", "res", "tscn"]:
		return {"code": "source_not_file", "message": "Only standalone source media files can be analyzed."}
	if not FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
		return {"code": "source_not_file", "message": "Source path is not an existing ordinary file."}
	if not capabilities.sources.has(kind):
		return {"code": "unsupported_type", "message": "Choose an audio stream or a source texture."}
	if path.get_extension().to_lower() not in capabilities.sources[kind].extensions:
		return {"code": "unsupported_format", "message": "Source extension is not supported by the declared Analyzer capabilities."}
	return {}


static func memory_mib(kind: String) -> int:
	return int(capabilities.sources.get(kind, {}).get("memory_mib", 0))
