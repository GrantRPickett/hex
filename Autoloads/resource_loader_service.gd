extends Node

## Recursively collects all resources of a specific type or extension from a path.
func collect_resources_recursive(path: String, extension: String = GameConstants.TRES_EXTENSION, type_hint: String = "") -> Array:
	var resources: Array = []

	if not DirAccess.dir_exists_absolute(path):
		GameLogger.debug(GameLogger.Category.RESOURCES, "ResourceLoaderService: Path does not exist: %s" % path)
		return resources

	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()

		while file_name != "":
			var full_path := path.path_join(file_name)

			if dir.current_is_dir():
				if not file_name.begins_with("."):
					# Manual loop instead of append_array to avoid internal assign() errors
					var sub_resources = collect_resources_recursive(full_path, extension, type_hint)
					for sub_res in sub_resources:
						resources.append(sub_res)
			else:
				# In exported builds, resources might have .remap or .import suffixes
				var clean_file_name := file_name.trim_suffix(".remap").trim_suffix(".import")
				if clean_file_name.to_lower().ends_with(extension.to_lower()):
					GameLogger.debug(GameLogger.Category.RESOURCES, "ResourceLoaderService: Loading resource: %s" % full_path)
					var res: Resource = load(full_path)
					if res is Resource:
						if _matches_type(res, type_hint):
							resources.append(res)
					else:
						GameLogger.warning(GameLogger.Category.RESOURCES, "ResourceLoaderService: Failed to load resource as Resource: %s" % full_path)

			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		GameLogger.error(GameLogger.Category.RESOURCES, "ResourceLoaderService: Failed to open directory: %s" % path)

	return resources

## Checks if a resource matches a type hint (supports built-ins and custom class_names).
func _matches_type(res: Resource, type_hint: String) -> bool:
	if type_hint == "":
		return true

	# Built-in types and exact matches
	if res.is_class(type_hint):
		return true

	# Custom class inheritance check
	var script: Script = res.get_script()
	while script:
		if script.get_global_name() == type_hint:
			return true
		script = script.get_base_script()

	return false

## Loads all resources from a directory (non-recursive).
func load_resources_in_dir(path: String, extension: String = GameConstants.TRES_EXTENSION, type_hint: String = "") -> Array:
	var resources: Array = []
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var clean_file_name := file_name.trim_suffix(".remap").trim_suffix(".import")
				if clean_file_name.to_lower().ends_with(extension.to_lower()):
					var full_path := path.path_join(file_name)
					var res: Resource = load(full_path)
					if res is Resource and _matches_type(res, type_hint):
						resources.append(res)
			file_name = dir.get_next()
	return resources
