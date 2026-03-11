class_name LevelStateController
extends Object

signal level_complete(level_path: String)
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

func on_task_reached(level_resource: Level, _save_manager: SaveManager) -> void:
	var level_path := level_resource.resource_path if level_resource else ""

	if _game_state.unit_manager:
		var stash_items: Array[InventoryItem] = []
		if _game_state.loot_manager:
			var loot = _game_state.loot_manager.collect_all_loot_items()
			for item in loot:
				if item is InventoryItem:
					stash_items.append(item)
		
		if RosterManager:
			RosterManager.sync_from_combat(_game_state.unit_manager, stash_items)
		else:
			# Fallback if RosterManager is not an autoload (e.g. in tests)
			var player_roster = _game_state.player_roster
			if player_roster:
				var player_units: Array[Unit] = []
				for i in range(_game_state.unit_manager.get_unit_count()):
					if _game_state.unit_manager.is_player_controlled(i):
						var unit = _game_state.unit_manager.get_unit(i)
						if is_instance_valid(unit):
							player_units.append(unit)
				player_roster.update_roster(player_units, false)
				if not stash_items.is_empty():
					player_roster.add_to_stash(stash_items)
				if _save_manager and _save_manager.has_method("save_roster"):
					_save_manager.save_roster(player_roster)

	level_complete.emit(level_path)
	if EventBus: EventBus.level_completed.emit(level_path)

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

	if EventBus: EventBus.level_failed.emit(_game_state.level.level_id if _game_state and _game_state.level else "unknown")

	# Sync roster state even on defeat (to capture stress, etc.)
	if _game_state.unit_manager and RosterManager:
		RosterManager.sync_from_combat(_game_state.unit_manager, [])

	var scene_tree := _resolve_scene_tree()
	if scene_tree and _defeat_return_delay > 0.0:
		await scene_tree.create_timer(_defeat_return_delay).timeout

	quit_to_level_select.emit()

func handle_enemy_retreat() -> void:
	if _game_state.hud:
		_game_state.hud.show_warning_message(tr("msg.victory_morale"))

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
		_game_state.hud.show_warning_message(tr("msg.neutral_withdraw"))

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
