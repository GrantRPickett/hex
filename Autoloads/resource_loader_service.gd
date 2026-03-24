## Service for loading and managing game resources.
##
## This service provides utility methods for scanning directories and loading
## resources recursively, with support for filtering and error handling.
extends Node

## Recursively collects all resources of a specific type or extension from a path.
## [param path]: The root directory to start scanning.
## [param extension]: The file extension to look for (default is ".tres").
## [param type_hint]: Optional class_name or script to check 'is' against.
## [returns]: An Array of loaded Resource objects.
func collect_resources_recursive(path: String, extension: String = GameConstants.TRES_EXTENSION, type_hint: String = "") -> Array[Resource]:
	var resources: Array[Resource] = []

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
					resources.append_array(collect_resources_recursive(full_path, extension, type_hint))
			elif file_name.ends_with(extension):
				var res: Resource = load(full_path)
				if res is Resource:
					if type_hint == "" or res.is_class(type_hint) or (res.get_script() and res.get_script().get_global_name() == type_hint):
						resources.append(res)

			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		GameLogger.debug(GameLogger.Category.RESOURCES, "ResourceLoaderService: Failed to open directory: %s" % path)

	return resources

## Loads all resources from a directory (non-recursive).
func load_resources_in_dir(path: String, extension: String = GameConstants.TRES_EXTENSION) -> Array[Resource]:
	var resources: Array[Resource] = []
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(extension):
				var res: Resource = load(path.path_join(file_name))
				if res is Resource:
					resources.append(res)
			file_name = dir.get_next()
	return resources
