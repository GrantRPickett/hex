class_name LevelStateController
extends Object

signal level_complete
signal quit_to_title
signal quit_to_level_select

var _game_state: GameState
var _task_reached_state: bool = false
var _grid_width: int = 0
var _grid_height: int = 0
var _defeat_return_delay := 2.0

func setup(game_state: GameState) -> void:
	_game_state = game_state

func update_grid_dimensions(width: int, height: int) -> void:
	_grid_width = width
	_grid_height = height

func on_task_reached(level_resource: Level, save_manager: SaveManager) -> void:
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

		if save_manager and save_manager.has_method("save_roster"):
			save_manager.save_roster(player_roster)

		if save_manager:
			var current_level_path: String = ""
			if level_resource and level_resource.resource_path != "":
				current_level_path = level_resource.resource_path
			if not current_level_path.is_empty():
				save_manager.mark_level_looted(current_level_path)

	level_complete.emit()

func get_task_reached_state() -> bool:
	if _game_state and _game_state.task_controller:
		_task_reached_state = _game_state.task_controller.is_task_reached()
	return _task_reached_state

func set_task_reached_state(value: bool) -> void:
	_task_reached_state = value
	if not _game_state or not _game_state.task_controller:
		return
	if not value:
		_game_state.task_controller.reset_task_state()

func update_task_progress() -> void:
	if _game_state and _game_state.task_controller:
		_game_state.task_controller.check_objective_conditions()
		_task_reached_state = _game_state.task_controller.is_task_reached()

func handle_player_defeat(message: String) -> void:
	if _game_state and _game_state.hud:
		_game_state.hud.show_warning_message(message)

	var scene_tree := _resolve_scene_tree()
	if scene_tree and _defeat_return_delay > 0.0:
		await scene_tree.create_timer(_defeat_return_delay).timeout

	quit_to_level_select.emit()

func handle_enemy_retreat() -> void:
	if _game_state.hud:
		_game_state.hud.show_warning_message("Enemy morale broken! Victory!")

	if _game_state.unit_manager:
		var enemy_units_to_remove = _game_state.unit_manager.get_enemy_units()
		for unit in enemy_units_to_remove:
			if is_instance_valid(unit):
				_game_state.unit_manager.remove_unit(unit)

	var scene_tree := _resolve_scene_tree()
	if scene_tree:
		await scene_tree.create_timer(2.0).timeout
	update_task_progress()

func handle_neutral_retreat() -> void:
	if _game_state.hud:
		_game_state.hud.show_warning_message("Neutral forces withdraw!")

	if _game_state.unit_manager:
		var neutral_units = _game_state.unit_manager.get_neutral_units()
		for unit in neutral_units:
			if is_instance_valid(unit):
				_game_state.unit_manager.remove_unit(unit)

	update_task_progress()

func update_safe_zone_ui(is_hometown: bool) -> void:
	if not _game_state: return
	var hud_controller: HUDController = _game_state.hud_controller
	if is_instance_valid(hud_controller):
		hud_controller.set_safe_zone_mode(is_hometown)

func _resolve_scene_tree() -> SceneTree:
	if _game_state and _game_state.hud:
		return _game_state.hud.get_tree()
	if Engine.get_main_loop() is SceneTree:
		return Engine.get_main_loop() as SceneTree
	return null
