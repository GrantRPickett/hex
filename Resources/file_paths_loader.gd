## Godot utility to load and access centralized file paths from file_paths.json
##
## Usage:
##   var paths = FilePathsLoader.load_paths()
##   var gameplay_scene = paths.get_path("scenes.gameplay")
##   var all_autoloads = paths.get_category("autoloads")
##   var warnings = paths.get_warnings()

extends RefCounted
class_name FilePathsLoader

const FILE_PATHS_JSON := "res://Resources/file_paths.json"

var _paths_dict: Dictionary = {}
var _load_errors: Array[String] = []


## Load the paths from file_paths.json
static func load_paths() -> FilePathsLoader:
	var loader: FilePathsLoader = FilePathsLoader.new()
	loader._load_internal()
	return loader


func _load_internal() -> void:
	if not ResourceLoader.exists(FILE_PATHS_JSON):
		_load_errors.append("File not found: %s" % FILE_PATHS_JSON)
		return

	var json: JSON = JSON.new()
	var file = FileAccess.open(FILE_PATHS_JSON, FileAccess.READ)
	if file == null:
		_load_errors.append("Cannot open file: %s" % FILE_PATHS_JSON)
		return

	var file_content = file.get_as_text()
	var error = json.parse(file_content)
	if error != OK:
		_load_errors.append("JSON parse error: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return

	_paths_dict = json.get_data()
	if _paths_dict.is_empty():
		_load_errors.append("Loaded JSON is empty")


## Get a single path using dot notation: "scenes.gameplay" returns "res://Gameplay/gameplay.tscn"
func get_path(path_key: String) -> String:
	var keys = path_key.split(".")
	var current = _paths_dict

	for key in keys:
		if current is Dictionary and key in current:
			current = current[key]
		else:
			_load_errors.append("Path not found: %s" % path_key)
			return ""

	if current is String:
		return current
	else:
		_load_errors.append("Value is not a string: %s -> %s" % [path_key, str(current)])
		return ""


## Get all paths in a category: get_category("scenes") returns dict of all scene paths
func get_category(category: String) -> Dictionary:
	if category in _paths_dict and _paths_dict[category] is Dictionary:
		return _paths_dict[category]

	_load_errors.append("Category not found: %s" % category)
	return {}


## Get all warnings from the _meta section
func get_warnings() -> Array[String]:
	if "_meta" in _paths_dict and "warnings" in _paths_dict["_meta"]:
		var warnings: Array[String] = []
		warnings.assign(_paths_dict["_meta"]["warnings"])
		return warnings
	return []


## Get all dynamic path patterns that can't be fully centralized
func get_dynamic_paths() -> Dictionary:
	if "dynamic_paths" in _paths_dict:
		return _paths_dict["dynamic_paths"]
	return {}


## Validate that all static paths exist in the resource system
func validate_paths() -> Dictionary:
	var results = {
		"valid": [],
		"missing": [],
		"invalid_format": [],
		"total_checked": 0
	}

	_validate_category_recursive("scenes", _paths_dict.get("scenes", {}), results)
	_validate_category_recursive("autoloads", _paths_dict.get("autoloads", {}), results)
	_validate_category_recursive("resources", _paths_dict.get("resources", {}), results)
	_validate_category_recursive("gameplay", _paths_dict.get("gameplay", {}), results)
	_validate_category_recursive("addons", _paths_dict.get("addons", {}), results)
	_validate_category_recursive("tests", _paths_dict.get("tests", {}), results)

	# Also check directories
	var dirs = _paths_dict.get("directories", {})
	for dir_name in dirs:
		var path = dirs[dir_name]
		if path is String:
			results["total_checked"] += 1
			if ResourceLoader.exists(path):
				results["valid"].append(path)
			else:
				results["missing"].append({"path": path, "category": "directories." + dir_name})

	return results


func _validate_category_recursive(category: String, dict: Dictionary, results: Dictionary) -> void:
	for key in dict:
		var value = dict[key]

		if value is String and value.begins_with("res://"):
			results["total_checked"] += 1
			if ResourceLoader.exists(value):
				results["valid"].append(value)
			else:
				results["missing"].append({"path": value, "category": category + "." + key})
		elif value is Dictionary:
			_validate_category_recursive(category + "." + key, value, results)


## Get all errors that occurred during loading or validation
func get_errors() -> Array[String]:
	return _load_errors


## Print a summary of the loaded paths
func print_summary() -> void:
	if _load_errors.size() > 0:
		GameLogger.info(GameLogger.Category.SYSTEM, "=== LOAD ERRORS ===")
		for error in _load_errors:
			GameLogger.error(GameLogger.Category.SYSTEM, error)

	var warnings = get_warnings()
	if warnings.size() > 0:
		GameLogger.info(GameLogger.Category.SYSTEM, "=== WARNINGS ===")
		for warning in warnings:
			GameLogger.info(GameLogger.Category.SYSTEM, "  ⚠️  " + warning)

	GameLogger.info(GameLogger.Category.SYSTEM, "=== LOADED CATEGORIES ===")
	for category in ["scenes", "autoloads", "resources", "gameplay", "directories", "tests"]:
		if category in _paths_dict:
			var count = _count_paths(_paths_dict[category])
			GameLogger.info(GameLogger.Category.SYSTEM, "  %s: %d paths" % [category, count])

	var dynamic = get_dynamic_paths()
	if dynamic.size() > 0:
		GameLogger.info(GameLogger.Category.SYSTEM, "\n=== DYNAMIC PATH PATTERNS (Cannot be fully centralized) ===")
		for pattern_name in dynamic:
			if pattern_name.begins_with("_"):
				continue
			GameLogger.info(GameLogger.Category.SYSTEM, "  - %s" % pattern_name)


func _count_paths(dict: Dictionary) -> int:
	var count: int = 0
	for key in dict:
		var value = dict[key]
		if value is String and value.begins_with("res://"):
			count += 1
		elif value is Dictionary:
			count += _count_paths(value)
	return count


## Helper: Load paths and return scene path (common use case)
static func get_scene(scene_key: String) -> String:
	var paths = load_paths()
	return paths.get_path("scenes." + scene_key)


## Helper: Load paths and return autoload path (common use case)
static func get_autoload(autoload_key: String) -> String:
	var paths = load_paths()
	return paths.get_path("autoloads." + autoload_key)
