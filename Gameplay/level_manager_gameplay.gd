extends RefCounted
const RosterLoader := preload("res://Gameplay/roster_loader.gd")
signal level_complete(next_level_path)
signal quit_to_title
signal quit_to_level_select

var _game_state: GameState
var _coordinator: Node2D
var _controls: Node
var _level_resource: Resource
var _save_manager: Node
var _roster_loader: RosterLoader

var _require_all_units_state := false
var _goal_reached_state := false

func _init(game_state: GameState, coordinator: Node2D, controls: Node) -> void:
	_game_state = game_state
	_coordinator = coordinator
	_controls = controls
	_save_manager = null
	_roster_loader = RosterLoader.new()
	if _controls:
		_require_all_units_state = _controls.require_all_units_to_goal

func set_save_manager(save_manager: Node) -> void:
	_save_manager = save_manager
	_refresh_rosters()

func set_level_resource(level: Resource) -> void:
	_level_resource = level

func apply_level_if_available() -> void:
	if not _level_resource or not _game_state:
		return
	_refresh_rosters()

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
		[],
		level_path,
		allow_loot_spawn
	)

	var result = _game_state.map_controller.load_level(_level_resource, context)


	if "grid_width" in result:
		_coordinator._grid_width = result.grid_width
		_coordinator._grid_height = result.grid_height
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
	_game_state.grid_controller.build_grid(_coordinator._grid_width, _coordinator._grid_height)

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
	if _level_resource and "next_level_path" in _level_resource and _level_resource.next_level_path != null:
		next_level_path = _level_resource.next_level_path

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
