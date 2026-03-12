class_name RosterLoader
extends RefCounted

const LOG_PREFIX := "[RosterLoader]"
const DEFAULT_PLAYER_ROSTER_PATH := FilePaths.Resources.DEFAULT_PLAYER_ROSTER
const DEFAULT_ENEMY_ROSTER_PATH := FilePaths.Resources.DEFAULT_ENEMY_ROSTER
const DEFAULT_NEUTRAL_ROSTER_PATH := FilePaths.Resources.DEFAULT_NEUTRAL_ROSTER
const CORE_PLAYER_ROSTER_DIR := FilePaths.Directories.CORE_CHARACTERS

func load_player_roster(provided_roster: PlayerRoster, save_manager: Node, fallback_path: String = DEFAULT_PLAYER_ROSTER_PATH) -> PlayerRoster:
	if provided_roster:
		if not provided_roster.units.is_empty():
			print(LOG_PREFIX, " Using provided player roster with ", provided_roster.units.size(), " units.")
			return provided_roster
		print(LOG_PREFIX, " Provided player roster is empty. Falling back to defaults.")

	var saved_roster := _load_saved_player_roster(save_manager)
	if saved_roster:
		return saved_roster

	var default_roster: PlayerRoster = _load_player_roster_resource(fallback_path)
	if default_roster:
		return default_roster

	print(LOG_PREFIX, " Returning new empty PlayerRoster.")
	return PlayerRoster.new()

func load_enemy_roster(provided_roster: EnemyRoster, fallback_path: String = DEFAULT_ENEMY_ROSTER_PATH) -> EnemyRoster:
	return _load_unit_roster(provided_roster, fallback_path, EnemyRoster, "EnemyRoster", "default_enemy_roster.tres") as EnemyRoster

func load_neutral_roster(provided_roster: NeutralRoster, fallback_path: String = DEFAULT_NEUTRAL_ROSTER_PATH) -> NeutralRoster:
	return _load_unit_roster(
		provided_roster,
		fallback_path,
		NeutralRoster,
		"NeutralRoster",
		"default_neutral_roster.tres",
		false
	) as NeutralRoster

func _load_saved_player_roster(save_manager: Node) -> PlayerRoster:
	if save_manager and save_manager.has_method("has_saved_roster") and save_manager.has_saved_roster():
		var saved = save_manager.load_roster()
		if saved and not saved.units.is_empty():
			print(LOG_PREFIX, " Loaded saved player roster with ", saved.units.size(), " units.")
			return saved
	return null

func _load_player_roster_resource(path: String) -> PlayerRoster:
	if not path.is_empty() and ResourceLoader.exists(path):
		print(LOG_PREFIX, " Loading default player roster from ", path)
		var loaded_roster_data = load(path)
		if loaded_roster_data is PlayerRoster:
			# Duplicate to avoid modifying the cached resource and ensure unique sub-resources
			var roster: PlayerRoster = loaded_roster_data.duplicate(true)
			
			# Ensure stash items are unique instances with unique UUIDs for this session
			var new_stash: Array[InventoryItem] = []
			for item in roster.stash_items:
				if item:
					new_stash.append(item.duplicate_instance(true))
			roster.stash_items = new_stash
			
			print(LOG_PREFIX, " Default player roster loaded successfully with ", roster.units.size(), " units.")
			return roster
		printerr(LOG_PREFIX, " Error: ", path, " is not a PlayerRoster resource. It is: ", loaded_roster_data)
	elif not path.is_empty():
		printerr(LOG_PREFIX, " Error: Default player roster not found at ", path)

	var dynamic_roster := _build_core_player_roster()
	if dynamic_roster:
		return dynamic_roster

	return null

func _load_unit_roster(provided_roster: UnitRoster, fallback_path: String, roster_class: GDScript, roster_label: String, resource_label: String, warn_on_empty := true) -> UnitRoster:
	if provided_roster and not provided_roster.units.is_empty():
		return provided_roster
	if provided_roster and provided_roster.units.is_empty():
		if warn_on_empty:
			print(LOG_PREFIX, " Provided %s roster is empty. Falling back to defaults." % roster_label)
		provided_roster = null

	if fallback_path.is_empty():
		return provided_roster if provided_roster else roster_class.new()

	if ResourceLoader.exists(fallback_path):
		var loaded = load(fallback_path)
		if loaded is UnitRoster and loaded.get_script() == roster_class:
			return loaded
		printerr(LOG_PREFIX, " Error: ", fallback_path, " is not a ", roster_label, ".")
	else:
		printerr(LOG_PREFIX, " Error: Default ", resource_label, " not found at ", fallback_path)

	if provided_roster:
		return provided_roster
	return roster_class.new()

func _populate_roster_from_resource(target_roster: UnitRoster, path: String, roster_class: GDScript, roster_label: String, resource_label: String) -> void:
	if path.is_empty():
		return
	if not ResourceLoader.exists(path):
		printerr(LOG_PREFIX, " Warning: ", resource_label, " not found at ", path)
		return

	var loaded_roster_data = load(path)
	if loaded_roster_data is UnitRoster and loaded_roster_data.get_script() == roster_class:
		target_roster.units.clear()
		for scene in loaded_roster_data.units:
			if scene is PackedScene:
				target_roster.units.append(scene)
			else:
				printerr(LOG_PREFIX, " Warning: Element in ", path, " is not a PackedScene. Skipping.")
	elif loaded_roster_data is UnitRoster:
		printerr(LOG_PREFIX, " Warning: ", path, " is not a ", roster_label, " resource. Using empty roster.")
	else:
		printerr(LOG_PREFIX, " Warning: Resource at ", path, " is not a UnitRoster. Using empty roster.")

func _build_core_player_roster() -> PlayerRoster:
	var dir := DirAccess.open(CORE_PLAYER_ROSTER_DIR)
	if dir == null:
		printerr(LOG_PREFIX, " Warning: Could not open core roster directory ", CORE_PLAYER_ROSTER_DIR)
		return null
	var files := dir.get_files()
	files.sort()
	var roster := PlayerRoster.new()

	for file_name in files:
		if file_name.begins_with("."):
			continue
		var extension := file_name.get_extension()
		if extension != "tscn" and extension != "scn":
			continue
		var scene_path := CORE_PLAYER_ROSTER_DIR.path_join(file_name)
		if not ResourceLoader.exists(scene_path):
			printerr(LOG_PREFIX, " Warning: Core character scene not found at ", scene_path)
			continue
		var packed = load(scene_path)

		if packed is PackedScene:
			var instance = packed.instantiate()
			if instance is Unit:
				roster.units.append(packed)
			else:
				printerr(LOG_PREFIX, " Warning: Scene at ", scene_path, " is not a Unit.")
			if instance is Node:
				instance.queue_free()
		else:
			printerr(LOG_PREFIX, " Warning: Resource at ", scene_path, " is not a PackedScene.")
	if roster.units.is_empty():
		printerr(LOG_PREFIX, " Warning: No core character scenes found in ", CORE_PLAYER_ROSTER_DIR)
		return null

	# Add bronze item set to stash
	var items_dir := DirAccess.open(FilePaths.Directories.ITEMS)
	if items_dir:
		for item_file in items_dir.get_files():
			if item_file.begins_with("bronze") and item_file.ends_with(".tres"):
				var item_path = FilePaths.Directories.ITEMS.path_join(item_file)
	# Add bronze item set to stash via ItemRegistry
	var templates = ItemRegistry.get_all_templates()
	for template in templates:
		if template.item_id.begins_with("bronze"):
			var instance = ItemRegistry.create_instance(template.item_id)
			if instance:
				roster.stash_items.append(instance)
				
	return roster
