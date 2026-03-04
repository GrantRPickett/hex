class_name LevelRosterService
extends Object

var _roster_loader: RosterLoader
var _save_manager: SaveManager

func _init() -> void:
	_roster_loader = RosterLoader.new()

func setup(save_manager: SaveManager) -> void:
	_save_manager = save_manager

func refresh_player_roster(state: GameState) -> void:
	if state == null: return
	var refreshed_player: UnitRoster = _roster_loader.load_player_roster(state.player_roster, _save_manager)
	if refreshed_player:
		state.player_roster = refreshed_player

func determine_leader_name(roster: PlayerRoster) -> String:
	var preferred := ""
	if _save_manager and _save_manager.has_method("get_leader_unit_name"):
		preferred = _save_manager.get_leader_unit_name()

	var resolved := _resolve_leader_name_from_roster(roster, preferred)
	if resolved.is_empty():
		resolved = _resolve_leader_name_from_roster(roster, "")

	if _save_manager and not resolved.is_empty() and resolved != preferred and _save_manager.has_method("set_leader_unit_name"):
		_save_manager.set_leader_unit_name(resolved)

	return resolved

func _resolve_leader_name_from_roster(roster: PlayerRoster, preferred: String) -> String:
	if roster == null or roster.units.is_empty():
		return String(preferred)

	if not String(preferred).is_empty():
		for scene in roster.units:
			var name := _unit_name_from_scene(scene)
			if name == preferred:
				return name

	for scene in roster.units:
		var fallback := _unit_name_from_scene(scene)
		if not fallback.is_empty():
			return fallback

	return String(preferred)

func _unit_name_from_scene(scene: PackedScene) -> String:
	if scene == null: return ""
	var instance = scene.instantiate()
	var name := ""
	if instance is Unit:
		name = instance.unit_name
	if instance is Node:
		instance.queue_free()
	return name
