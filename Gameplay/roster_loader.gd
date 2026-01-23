class_name RosterLoader
extends RefCounted

const LOG_PREFIX := "[RosterLoader]"
const DEFAULT_PLAYER_ROSTER_PATH := "res://Resources/default_player_roster.tres"
const DEFAULT_ENEMY_ROSTER_PATH := "res://Resources/default_enemy_roster.tres"
const DEFAULT_NEUTRAL_ROSTER_PATH := "res://Resources/default_neutral_roster.tres"

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
	return _load_unit_roster(provided_roster, fallback_path, NeutralRoster, "NeutralRoster", "default_neutral_roster.tres") as NeutralRoster

func _load_saved_player_roster(save_manager: Node) -> PlayerRoster:
	if save_manager and save_manager.has_method("has_saved_roster") and save_manager.has_saved_roster():
		var saved = save_manager.load_roster()
		if saved and not saved.units.is_empty():
			print(LOG_PREFIX, " Loaded saved player roster with ", saved.units.size(), " units.")
			return saved
	return null

func _load_player_roster_resource(path: String) -> PlayerRoster:
	if path.is_empty():
		return null

	if ResourceLoader.exists(path):
		print(LOG_PREFIX, " Loading default player roster from ", path)
		var loaded_roster_data = load(path)
		if loaded_roster_data is PlayerRoster:
			print(LOG_PREFIX, " Default player roster loaded successfully with ", loaded_roster_data.units.size(), " units.")
			return loaded_roster_data
		printerr(LOG_PREFIX, " Error: ", path, " is not a PlayerRoster resource. It is: ", loaded_roster_data)
	else:
		printerr(LOG_PREFIX, " Error: Default player roster not found at ", path)
	return null

func _load_unit_roster(provided_roster: UnitRoster, fallback_path: String, roster_class: GDScript, roster_label: String, resource_label: String) -> UnitRoster:
	if provided_roster:
		return provided_roster

	var roster: UnitRoster = roster_class.new()
	_populate_roster_from_resource(roster, fallback_path, roster_class, roster_label, resource_label)
	return roster

func _populate_roster_from_resource(target_roster: UnitRoster, path: String, roster_class: GDScript, roster_label: String, resource_label: String) -> void:
	if path.is_empty():
		return
	if not ResourceLoader.exists(path):
		printerr(LOG_PREFIX, " Warning: ", resource_label, " not found at ", path)
		return

	var loaded_roster_data = load(path)
	if loaded_roster_data is UnitRoster:
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
