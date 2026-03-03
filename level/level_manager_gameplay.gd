class_name LevelManagerGameplay
extends RefCounted
const HOMETOWN_EXIT_COORD := Vector2i(1, 1)
signal level_complete
signal quit_to_title
signal quit_to_level_select

var _game_state: GameState
var _controls: Node
var _level_resource: Level
var _save_manager: Node
var _roster_loader: RosterLoader
var _level_catalog: LevelCatalog
var _dialogue_service: DialogueActionService
var _level_row_loader: LevelRowLoader
var _auto_fix_options: LevelAutoFixOptions
var _auto_fix_enabled: bool = OS.is_debug_build()
var _enemy_roster_definition: UnitRosterDefinition
var _neutral_roster_definition: UnitRosterDefinition

var _task_reached_state: bool = false
var _grid_width: int = 0
var _grid_height: int = 0
var _defeat_return_delay := 2.0

func _init(game_state: GameState, controls: Node) -> void:
	_game_state = game_state
	_controls = controls
	_save_manager = null
	_roster_loader = RosterLoader.new()
	_level_catalog = LevelCatalog.new()
	_level_row_loader = LevelRowLoader.new()
	_auto_fix_options = LevelAutoFixOptions.new()
	_auto_fix_options.enabled = _auto_fix_enabled
	_level_row_loader.set_auto_fix_options(_auto_fix_options)

func set_save_manager(save_manager: SaveManager) -> void:
	_save_manager = save_manager
	_refresh_rosters()

func set_dialogue_service(service: DialogueActionService) -> void:
	_dialogue_service = service
	if _dialogue_service and _level_resource:
		_dialogue_service.prepare_for_level(_level_resource)
		_dialogue_service.dialogue_finished.connect(_on_dialogue_finished)

func set_auto_fix_enabled(enabled: bool) -> void:
	_auto_fix_enabled = enabled
	if _auto_fix_options == null:
		_auto_fix_options = LevelAutoFixOptions.new()
	_auto_fix_options.enabled = enabled
	if _level_row_loader:
		_level_row_loader.set_auto_fix_options(_auto_fix_options)

func _on_dialogue_finished(flag_id: StringName) -> void:
	if not _game_state or not _game_state.task_controller:
		return
	_game_state.task_controller.handle_event("dialogue_finished", {"flag_id": flag_id})

func set_level_resource(level: Level) -> void:
	_level_resource = level
	_update_safe_zone_ui(level)
	if _dialogue_service:
		_dialogue_service.prepare_for_level(_level_resource)

func apply_level_if_available() -> void:
	if not _level_resource or not _game_state:
		return
	LevelLog.debug("[LevelManagerGameplay] apply_level_if_available called for resource: %s" % _level_resource.resource_path)
	_apply_row_resources(_level_resource)
	_refresh_rosters()
	_update_safe_zone_ui(_level_resource)

	if _dialogue_service:
		_dialogue_service.prepare_for_level(_level_resource)

	if _game_state and is_instance_valid(_game_state.journal_manager):
		_game_state.journal_manager.set_level(_level_resource)

	if not is_instance_valid(_game_state.map_controller):
		LevelLog.error("[LevelManagerGameplay] ERROR: map_controller is invalid!")
		return
	if not is_instance_valid(_game_state.unit_manager):
		LevelLog.error("[LevelManagerGameplay] ERROR: unit_manager is invalid!")
		return
	if not is_instance_valid(_game_state.task_manager):
		LevelLog.error("[LevelManagerGameplay] ERROR: task_manager is invalid!")
		return

	var context = _create_build_context()
	var builder = LevelBuilder.new(context)
	var terrain_map = _game_state.map_controller.get_terrain_map()
	var result = builder.build(_level_resource, terrain_map)

	_handle_build_result(result)
	LevelLog.debug("[LevelManagerGameplay] Level loaded successfully into scene.")
	_connect_morale_panel_signals()

	if _game_state.task_controller and _level_resource:
		_game_state.task_controller.set_level(_level_resource)

	if _game_state.unit_manager:
		_game_state.unit_manager.reset_all_neutral_loyalties()

	# Register rosters with UnitManager so systems can resolve faction stashes/services without scene traversal
	if _game_state.unit_manager:
		if _game_state.player_roster:
			_game_state.unit_manager.set_roster_for_faction(Unit.Faction.PLAYER, _game_state.player_roster)
		if "enemy_roster" in _game_state and _game_state.enemy_roster:
			_game_state.unit_manager.set_roster_for_faction(Unit.Faction.ENEMY, _game_state.enemy_roster)
		if "neutral_roster" in _game_state and _game_state.neutral_roster:
			_game_state.unit_manager.set_roster_for_faction(Unit.Faction.NEUTRAL, _game_state.neutral_roster)

	# Queue hometown progression dialogues if this is a hometown level
	_queue_hometown_progression_dialogues()


func _create_build_context() -> LevelBuildContext:
	var player_roster = _game_state.player_roster

	var enemy_roster: EnemyRoster = EnemyRoster.new()
	if _enemy_roster_definition:
		for entry in _enemy_roster_definition.spawn_entries:
			if entry.unit_scene:
				enemy_roster.units.append(entry.unit_scene)

	var neutral_roster: NeutralRoster = NeutralRoster.new()
	if _neutral_roster_definition:
		for entry in _neutral_roster_definition.spawn_entries:
			if entry.unit_scene:
				neutral_roster.units.append(entry.unit_scene)

	var camera = _game_state.camera_2d
	var grid = _game_state.grid

	var allow_loot_spawn := true

	var leader_name := _determine_leader_name(player_roster)
	LevelLog.debug("[LevelManagerGameplay] Using leader name '%s'" % leader_name)
	return LevelBuildContext.new(
		_game_state,
		_game_state.grid, # Using grid as root if coordinator is gone, but LevelBuildContext might need adjustment
		_game_state.unit_manager,
		_game_state.unit_controller,
		_game_state.task_manager,
		_game_state.loot_manager,
		_game_state.combat_system,
		grid,
		camera,
		_controls,
		player_roster,
		enemy_roster,
		neutral_roster,
		[], # target_task_templates
		_level_resource,
		allow_loot_spawn,
		_dialogue_service,
		_game_state.animation_service,
		leader_name
	)


func _handle_build_result(result: Dictionary) -> void:
	if "grid_width" in result:
		_grid_width = result.grid_width
		_grid_height = result.grid_height
		_game_state.move_controller.update_grid_dimensions(result.grid_width, result.grid_height)

		# Build the visual grid cells
		if _game_state.grid_controller:
			_game_state.grid_controller.build_grid(_grid_width, _grid_height)

		# Re-cache navigation vectors if grid orientation changed
		if _game_state.hex_navigator and _game_state.grid:
			_game_state.hex_navigator.cache_analog_vectors(_game_state.grid)

		_game_state.turn_controller.rebuild_turn_roster()
		_apply_hometown_exploration_rules()

		if is_instance_valid(_game_state.grid_visuals) and _game_state.grid:
			_game_state.grid_visuals.update_terrain_overlay(_game_state.grid, _game_state.map_controller.get_terrain_map())


func _connect_morale_panel_signals() -> void:
	if not _game_state.hud:
		return

	if not _game_state.hud.is_node_ready():
		await _game_state.hud.ready

	var morale_panel: MoralePanel = _game_state.hud.get_node_or_null("HUDMarginContainer/BottomCenterContainer/MoralePanel")
	if is_instance_valid(morale_panel):
		if not morale_panel.player_retreat_triggered.is_connected(_on_player_retreat_triggered):
			morale_panel.player_retreat_triggered.connect(_on_player_retreat_triggered)
		if not morale_panel.enemy_retreat_triggered.is_connected(_on_enemy_retreat_triggered):
			morale_panel.enemy_retreat_triggered.connect(_on_enemy_retreat_triggered)
		if not morale_panel.neutral_retreat_triggered.is_connected(_on_neutral_retreat_triggered):
			morale_panel.neutral_retreat_triggered.connect(_on_neutral_retreat_triggered)
		if morale_panel.has_method("reset_state"):
			morale_panel.reset_state(_game_state.unit_manager)

func set_level_and_rebuild(level: Level) -> void:
	LevelLog.debug("[LevelManagerGameplay] set_level_and_rebuild called for: %s" % (level.resource_path if level else "NULL"))
	_level_resource = level
	if not _game_state:
		return
	if not is_instance_valid(_game_state.task_controller):
		return

	_game_state.task_controller.reset_task_state()
	# apply_level_if_available handles building the grid and caching vectors
	apply_level_if_available()

	_game_state.camera_controller.init_camera_snap()
	_game_state.camera_controller.center_on_selected()

func on_task_reached() -> void:
	var player_roster = _game_state.player_roster

	if player_roster and _game_state.unit_manager:
		var player_units: Array[Unit] = []
		for i in range(_game_state.unit_manager.get_unit_count()):
			if _game_state.unit_manager.is_player_controlled(i):
				var unit = _game_state.unit_manager.get_unit(i)
				if is_instance_valid(unit):
					player_units.append(unit)
		player_roster.update_roster(player_units, false)

		if _game_state.loot_manager:
			var stash_drop: Array = _game_state.loot_manager.collect_all_loot_items()
			if not stash_drop.is_empty():
				player_roster.add_to_stash(stash_drop)

		if _save_manager and _save_manager.has_method("save_roster"):
			_save_manager.save_roster(player_roster)

		if _save_manager:
			var current_level_path: String = ""
			if _level_resource and _level_resource.resource_path != "":
				current_level_path = _level_resource.resource_path
			if not current_level_path.is_empty():
				_save_manager.mark_level_looted(current_level_path)

	level_complete.emit()

func _get_task_reached_state() -> bool:
	if _game_state:
		_task_reached_state = _game_state.task_controller.is_task_reached()
	return _task_reached_state

func _set_task_reached_state(value: bool) -> void:
	_task_reached_state = value
	if not _game_state:
		return
	if value:
		return
	_game_state.task_controller.reset_task_state()

func update_task_progress() -> void:
	if _game_state.task_controller:
		_game_state.task_controller.check_objective_conditions()
		_task_reached_state = _game_state.task_controller.is_task_reached()

func _refresh_rosters() -> void:
	if _roster_loader == null:
		_roster_loader = RosterLoader.new()
	if _game_state == null:
		return
	var refreshed_player: UnitRoster = _roster_loader.load_player_roster(_game_state.player_roster, _save_manager)
	if refreshed_player:
		_game_state.player_roster = refreshed_player

func _on_player_retreat_triggered() -> void:
	print_debug("Player morale dropped below 20%. Game Over!")
	await _handle_player_defeat("GAME OVER! Morale Broken!")

func on_task_failed() -> void:
	print_debug("Enemy completed too many tasks. Player defeated.")
	await _handle_player_defeat("Enemy secured the objectives! Retreat!")

func _handle_player_defeat(message: String) -> void:
	if _game_state and _game_state.hud:
		_game_state.hud.show_warning_message(message)
	var scene_tree := _resolve_scene_tree()
	if scene_tree and _defeat_return_delay > 0.0:
		await scene_tree.create_timer(_defeat_return_delay).timeout
	quit_to_level_select.emit()

func _resolve_scene_tree() -> SceneTree:
	if _game_state and _game_state.hud:
		return _game_state.hud.get_tree()
	if Engine.get_main_loop() is SceneTree:
		return Engine.get_main_loop() as SceneTree
	return null


func _on_enemy_retreat_triggered() -> void:
	print_debug("Enemy morale dropped below 20%. Enemies retreat!")
	if _game_state.hud:
		_game_state.hud.show_warning_message("Enemy morale broken! Victory!")

	if _game_state.unit_manager:
		var enemy_units_to_remove = _game_state.unit_manager.get_enemy_units() # Get a copy to avoid issues during iteration
		for unit in enemy_units_to_remove:
			if is_instance_valid(unit):
				_game_state.unit_manager.remove_unit(unit)

	var scene_tree: SceneTree = null
	if _game_state and _game_state.hud:
		scene_tree = _game_state.hud.get_tree()
	elif Engine.get_main_loop() is SceneTree:
		scene_tree = Engine.get_main_loop() as SceneTree
	if scene_tree:
		await scene_tree.create_timer(2.0).timeout
	update_task_progress()

func _on_neutral_retreat_triggered() -> void:
	print_debug("Neutral morale dropped below 20%. Neutrals retreat!")
	if _game_state.hud:
		_game_state.hud.show_warning_message("Neutral forces withdraw!")

	if _game_state.unit_manager:
		var neutral_units = _game_state.unit_manager.query.get_neutral_units()
		for unit in neutral_units:
			if is_instance_valid(unit):
				_game_state.unit_manager.remove_unit(unit)

	update_task_progress()

func _update_safe_zone_ui(level: Level) -> void:
	if not _game_state:
		return
	var hud_controller: HUDController = _game_state.hud_controller
	if not is_instance_valid(hud_controller):
		return
	hud_controller.set_safe_zone_mode(_is_hometown_level(level))

func _get_level_id_for_level(level: Level) -> StringName:
	if level == null:
		return StringName()
	if _level_catalog == null:
		_level_catalog = LevelCatalog.new()
	var resource_path := ""
	if level.resource_path != "":
		resource_path = level.resource_path
	if resource_path.is_empty():
		return StringName()
	var info := _level_catalog.find_level_by_path(resource_path)
	var level_id: String = info.get("id", "")
	if String(level_id).is_empty():
		return StringName()
	return StringName(level_id)

func _apply_row_resources(level: Level) -> void:
	if level == null:
		return
	if _level_row_loader == null:
		_level_row_loader = LevelRowLoader.new()
		_level_row_loader.set_auto_fix_options(_auto_fix_options)
	var level_id := _get_level_id_for_level(level)
	if String(level_id).is_empty():
		return
	var row_result: Dictionary = _level_row_loader.apply_rows_to_level(level, level_id)
	_enemy_roster_definition = level.enemy_roster_definition
	_neutral_roster_definition = level.neutral_roster_definition
	var errors: Array = row_result.get("errors", [])
	for err in errors:
		push_warning(err)
	var auto_fix_report: Dictionary = row_result.get("auto_fix", {})
	if auto_fix_report:
		var messages: Array = auto_fix_report.get("messages", [])
		for message in messages:
			push_warning(message)
		var summary := String(auto_fix_report.get("summary", ""))
		if not summary.is_empty():
			push_warning(summary)

func _is_hometown_level(level: Level) -> bool:
	if level == null:
		return false
	if _level_catalog == null:
		_level_catalog = LevelCatalog.new()
	var resource_path := ""
	if level.resource_path != "":
		resource_path = level.resource_path
	if resource_path.is_empty():
		return false
	var info := _level_catalog.find_level_by_path(resource_path)
	return info.get("is_hometown", false)


func _queue_hometown_progression_dialogues() -> void:
	"""Queue dialogue skits for newly unlocked levels when returning to hometown."""
	if not _is_hometown_level(_level_resource):
		return

	if not _game_state or not _game_state.task_controller:
		return

	# Create hometown progression service
	var hometown_svc := HometownProgressionService.new(_level_catalog, _save_manager)

	var skit := hometown_svc.pop_skit()
	# Log popping a skit in hometown including level_id and dialogue/journal id
	if skit != null:
		var level_id := ""
		if _level_resource and _level_resource.resource_path != "":
			var info := _level_catalog.find_level_by_path(_level_resource.resource_path)
			level_id = String(info.get("id", ""))
		var dialogue_path := String(skit.dialogue_path) if "dialogue_path" in skit else ""
		var skit_level_id := String(skit.level_id) if "level_id" in skit else level_id
		# No explicit journal id on Skit; left blank for now
		print_debug("[HometownSkit] pop_skit: level_id=%s skit_level=%s dialogue=%s journal=%s" % [level_id, skit_level_id, dialogue_path, ""])
	if skit != null:
		hometown_svc.queue_dialogue(skit.dialogue_path)

func _determine_leader_name(roster: PlayerRoster) -> String:
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

func _unit_name_from_scene(scene) -> String:
	if scene == null:
		return ""
	var instance = scene.instantiate()
	var name := ""
	if instance is Unit:
		name = instance.unit_name
	if instance is Node:
		instance.queue_free()
	return name

func on_unit_moved(index: int, coord: Vector2i) -> void:
	if not _game_state.unit_manager or not _game_state.task_manager:
		return

	# Only trigger explore_zone for the selected player unit
	var selected_unit_index = _game_state.unit_manager.get_selected_index()
	#if index == selected_unit_index and _game_state.unit_manager.is_player_controlled(index):
		#_game_state.task_manager.get_active_objective().handle_event("move", {
			#"unit": _game_state.unit_manager.get_unit(index),
			#"unit_index": index,
			#"coord": coord
		#})

	if index != selected_unit_index: # Only act on the currently selected unit for other logic
		return

	if not _is_hometown_level(_level_resource):
		return
	if coord != HOMETOWN_EXIT_COORD:
		return
	print_debug("Player reached hometown exit (%s). Emitting quit_to_level_select." % HOMETOWN_EXIT_COORD)
	quit_to_level_select.emit()


func _apply_hometown_exploration_rules() -> void:
	if _game_state == null or _game_state.unit_manager == null:
		return
	var explorer := _get_primary_player_unit()
	if explorer == null or not explorer.has_method("set_free_roam_mode"):
		return
	var enable := _is_hometown_level(_level_resource)
	explorer.set_free_roam_mode(enable)
	var label := explorer.unit_name if explorer.unit_name != "" else "Player"
	print_debug("[LevelManagerGameplay] Free roam ", "enabled" if enable else "disabled", " for ", label)


func _get_primary_player_unit() -> Unit:
	if _game_state == null or _game_state.unit_manager == null:
		return null
	var unit_manager: UnitManager = _game_state.unit_manager
	for i in range(unit_manager.get_unit_count()):
		if not unit_manager.is_player_controlled(i):
			continue
		var candidate := unit_manager.get_unit(i)
		if is_instance_valid(candidate):
			return candidate
	return null
