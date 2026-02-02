extends RefCounted
const RosterLoader := preload("res://Gameplay/roster_loader.gd")
const LevelCatalog := preload("res://Resources/levels/level_catalog.gd")
const LevelRowLoader := preload("res://Resources/level_data/level_row_loader.gd")
signal level_complete(next_level_path)
signal quit_to_title
signal quit_to_level_select

var _game_state: GameState
var _coordinator: Node2D
var _controls: Node
var _level_resource: Resource
var _save_manager: Node
var _roster_loader: RosterLoader
var _level_catalog: LevelCatalog
var _dialogue_service: DialogueActionService
var _level_row_loader: LevelRowLoader

var _require_all_units_state := false
var _goal_reached_state := false
var _grid_width: int = 0
var _grid_height: int = 0

func _init(game_state: GameState, coordinator: Node2D, controls: Node) -> void:
	_game_state = game_state
	_coordinator = coordinator
	_controls = controls
	_save_manager = null
	_roster_loader = RosterLoader.new()
	_level_catalog = LevelCatalog.new()
	_level_row_loader = LevelRowLoader.new()
	if _controls:
		_require_all_units_state = _controls.require_all_units_to_goal

func set_save_manager(save_manager: Node) -> void:
	_save_manager = save_manager
	_refresh_rosters()

func set_dialogue_service(service: DialogueActionService) -> void:
	_dialogue_service = service
	if _dialogue_service and _level_resource:
		_dialogue_service.prepare_for_level(_level_resource)
		_dialogue_service.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished(flag_id: StringName) -> void:
	if flag_id == "res://Resources/dialogue/quit_to_level_select.dtl":
		quit_to_level_select.emit()

func set_level_resource(level: Resource) -> void:
	_level_resource = level
	_apply_row_resources(level)
	_update_safe_zone_ui(level)
	if _dialogue_service:
		_dialogue_service.prepare_for_level(_level_resource)

func apply_level_if_available() -> void:
	if not _level_resource or not _game_state:
		return
	_apply_row_resources(_level_resource)
	_refresh_rosters()
	_update_safe_zone_ui(_level_resource)

	if _dialogue_service:
		_dialogue_service.prepare_for_level(_level_resource)

	if not is_instance_valid(_game_state.map_controller) or not is_instance_valid(_game_state.unit_manager) or not is_instance_valid(_game_state.goal_manager):
		return

	_set_goal_reached_state(false)

	var player_roster = _coordinator.player_roster
	var enemy_roster = _coordinator.enemy_roster
	var neutral_roster = _coordinator.neutral_roster
	var camera = _coordinator.get_node_or_null("Camera2D")
	var grid = _coordinator.get_node_or_null("Grid")
	var level_path: String = ""
	if _level_resource and _level_resource.resource_path != "":
		level_path = _level_resource.resource_path
	var allow_loot_spawn := true
	if _save_manager and not level_path.is_empty():
		allow_loot_spawn = not _save_manager.is_level_looted(level_path)

	var goal_templates: Array[Goal] = []
	# Removed logic for adding leave_hometown_goal.tscn


	var context = LevelBuildContext.new(
		_coordinator,
		_game_state.unit_manager,
		_game_state.goal_manager,
		_game_state.loot_manager,
		_game_state.combat_system,
		grid,
		camera,
		_controls,
		player_roster,
		enemy_roster,
		neutral_roster,
		goal_templates,
		level_path,
		allow_loot_spawn,
		_dialogue_service
	)

	var result = _game_state.map_controller.load_level(_level_resource, context)


	if "grid_width" in result:
		_grid_width = result.grid_width
		_grid_height = result.grid_height
		_game_state.move_controller.update_grid_dimensions(result.grid_width, result.grid_height)

	if "require_all_units" in result:
		_set_require_all_units_state(result.require_all_units)

	_game_state.turn_controller.rebuild_turn_roster()
	_coordinator._update_terrain_overlay()
	# Connect to MoralePanel signals after HUD is fully set up
	if _game_state.hud:
		await _game_state.hud.ready # Ensure HUD is ready before trying to get child nodes
		var morale_panel: MoralePanel = _game_state.hud.get_node_or_null("HUDMarginContainer/BottomCenterContainer/MoralePanel")
		if is_instance_valid(morale_panel):
			if not morale_panel.player_retreat_triggered.is_connected(_on_player_retreat_triggered):
				morale_panel.player_retreat_triggered.connect(_on_player_retreat_triggered)
			if not morale_panel.enemy_retreat_triggered.is_connected(_on_enemy_retreat_triggered):
				morale_panel.enemy_retreat_triggered.connect(_on_enemy_retreat_triggered)
			if morale_panel.has_method("reset_state"):
				morale_panel.reset_state(_game_state.unit_manager)

func set_level_and_rebuild(level: Resource) -> void:
	_level_resource = level
	apply_level_if_available()
	if not _game_state:
		return
	if not is_instance_valid(_game_state.goal_controller):
		return
	_game_state.goal_controller.reset_goal_state()
	_game_state.grid_controller.build_grid(_grid_width, _grid_height)

	var grid = _coordinator.get_node_or_null("Grid")
	if grid:
		_game_state.hex_navigator.cache_analog_vectors(grid)

	_game_state.camera_controller.init_camera_snap()
	_game_state.camera_controller.center_on_selected()

func on_goal_reached() -> void:
	var player_roster = _coordinator.player_roster

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
		var remaining_goal_titles := PackedStringArray()
		if _game_state.goal_manager:
			remaining_goal_titles = _game_state.goal_manager.get_remaining_goal_titles()
		player_roster.set_remaining_goal_titles(remaining_goal_titles)

		if _save_manager and _save_manager.has_method("save_roster"):
			_save_manager.save_roster(player_roster)

		if _save_manager:
			var current_level_path: String = ""
			if _level_resource and _level_resource.resource_path != "":
				current_level_path = _level_resource.resource_path
			if not current_level_path.is_empty():
				_save_manager.mark_level_looted(current_level_path)

	var next_level_path: String = ""

	if next_level_path.is_empty():
		quit_to_level_select.emit()
	else:
		level_complete.emit(next_level_path)

func _set_require_all_units_state(value: bool) -> void:
	_require_all_units_state = value
	if _controls:
		_controls.require_all_units_to_goal = value
	if _game_state:
		_game_state.goal_controller.set_require_all_units(value)

func _get_require_all_units_state() -> bool:
	return _require_all_units_state

func _get_goal_reached_state() -> bool:
	if _game_state:
		_goal_reached_state = _game_state.goal_controller.is_goal_reached()
	return _goal_reached_state

func _set_goal_reached_state(value: bool) -> void:
	_goal_reached_state = value
	if not _game_state:
		return
	if value:
		return
	_game_state.goal_controller.reset_goal_state()

func update_goal_progress() -> void:
	if _game_state.goal_controller:
		_game_state.goal_controller.check_goal_progress()
		_goal_reached_state = _game_state.goal_controller.is_goal_reached()

func _refresh_rosters() -> void:
	if _roster_loader == null:
		_roster_loader = RosterLoader.new()
	if _coordinator == null:
		return
	var refreshed_player := _roster_loader.load_player_roster(_coordinator.player_roster, _save_manager)
	if refreshed_player:
		_coordinator.player_roster = refreshed_player
	var refreshed_enemy := _roster_loader.load_enemy_roster(_coordinator.enemy_roster, RosterLoader.DEFAULT_ENEMY_ROSTER_PATH)
	if refreshed_enemy:
		_coordinator.enemy_roster = refreshed_enemy
	var refreshed_neutral := _roster_loader.load_neutral_roster(_coordinator.neutral_roster, RosterLoader.DEFAULT_NEUTRAL_ROSTER_PATH)
	if refreshed_neutral:
		_coordinator.neutral_roster = refreshed_neutral

func _on_player_retreat_triggered() -> void:
	print_debug("Player morale dropped below 20%. Game Over!")
	_coordinator._disable_gameplay()
	if _game_state.hud:
		_game_state.hud.show_warning_message("GAME OVER! Morale Broken!")
	var scene_tree: SceneTree = null
	if is_instance_valid(_coordinator):
		scene_tree = _coordinator.get_tree()
	elif _game_state and _game_state.hud:
		scene_tree = _game_state.hud.get_tree()
	elif Engine.get_main_loop() is SceneTree:
		scene_tree = Engine.get_main_loop() as SceneTree
	if scene_tree:
		await scene_tree.create_timer(2.0).timeout
	if _level_resource:
		set_level_and_rebuild(_level_resource)
	else:
		quit_to_level_select.emit()

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
	if is_instance_valid(_coordinator):
		scene_tree = _coordinator.get_tree()
	elif _game_state and _game_state.hud:
		scene_tree = _game_state.hud.get_tree()
	elif Engine.get_main_loop() is SceneTree:
		scene_tree = Engine.get_main_loop() as SceneTree
	if scene_tree:
		await scene_tree.create_timer(2.0).timeout
	update_goal_progress()

func _update_safe_zone_ui(level: Resource) -> void:
	if not _game_state:
		return
	var hud_controller := _game_state.hud_controller
	if not is_instance_valid(hud_controller):
		return
	hud_controller.set_safe_zone_mode(_is_hometown_level(level))

func _get_level_id_for_resource(level: Resource) -> StringName:
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

func _apply_row_resources(level: Resource) -> void:
	if level == null:
		return
	if _level_row_loader == null:
		_level_row_loader = LevelRowLoader.new()
	var level_id := _get_level_id_for_resource(level)
	if String(level_id).is_empty():
		return
	var errors := _level_row_loader.apply_rows_to_level(level, level_id)
	for err in errors:
		push_warning(err)

func _is_hometown_level(level: Resource) -> bool:
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
