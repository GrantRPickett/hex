class_name CheckpointManager
extends RefCounted

var _history: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
var _max_history: int = 50
var _game_state: GameState

func setup(game_state: GameState) -> void:
	_game_state = game_state

func on_checkpoint_requested() -> void:
	if _game_state:
		create_checkpoint(_game_state)

func on_undo_requested() -> void:
	if not _game_state:
		return
	if undo(_game_state):
		if _game_state.hud_controller:
			_game_state.hud_controller.show_feedback("Undo")
		if _game_state.camera_controller:
			_game_state.camera_controller.center_on_selected()
		if _game_state.grid_visuals and _game_state.map_controller:
			var terrain_map = _game_state.map_controller.get_terrain_map()
			var grid = _game_state.grid_controller.get_grid() if _game_state.grid_controller else null
			if grid:
				_game_state.grid_visuals.update_range_indicator(grid, _game_state.unit_manager, terrain_map)


func on_redo_requested() -> void:
	if not _game_state:
		return
	if redo(_game_state):
		if _game_state.hud_controller:
			_game_state.hud_controller.show_feedback("Redo")
		if _game_state.camera_controller:
			_game_state.camera_controller.center_on_selected()
		if _game_state.grid_visuals and _game_state.map_controller:
			var terrain_map = _game_state.map_controller.get_terrain_map()
			var grid = _game_state.grid_controller.get_grid() if _game_state.grid_controller else null
			if grid:
				_game_state.grid_visuals.update_range_indicator(grid, _game_state.unit_manager, terrain_map)

func create_checkpoint(game_state: GameState) -> void:
	_validate_unique_items(game_state)
	var snapshot := _capture_state(game_state)

	_history.append(snapshot)
	if _history.size() > _max_history:
		_history.pop_front()

	_redo_stack.clear()

	# Persist a memento via SaveManager after creating a checkpoint (for mid-level undo continuity)
	if is_instance_valid(game_state) and is_instance_valid(game_state.save_manager):
		# SaveManager already composes a full memento and writes to disk
		game_state.save_manager.save_current_state_for_undo()

func undo(game_state: GameState) -> bool:
	if _history.is_empty():
		return false

	var current_state = _capture_state(game_state)
	_redo_stack.append(current_state)

	var snapshot = _history.pop_back()
	_restore_state(game_state, snapshot)
	return true

func redo(game_state: GameState) -> bool:
	if _redo_stack.is_empty():
		return false

	var current_state = _capture_state(game_state)
	_history.append(current_state)

	var snapshot = _redo_stack.pop_back()
	_restore_state(game_state, snapshot)
	return true

func has_history() -> bool:
	return not _history.is_empty()

func has_redo() -> bool:
	return not _redo_stack.is_empty()

func _capture_state(game_state: GameState) -> Dictionary:
	var snapshot := {
		"unit_manager": game_state.unit_manager.create_memento(),
		"task_manager": game_state.task_manager.create_memento(),
		"turn_controller": game_state.turn_controller.create_memento()
	}

	# Consider LootManager if it supports mementos
	if game_state.loot_manager and game_state.loot_manager.has_method("create_memento"):
		snapshot["loot_manager"] = game_state.loot_manager.create_memento()

	if typeof(WeatherManager) != TYPE_NIL and WeatherManager.has_method("create_memento"):
		snapshot["weather_manager"] = WeatherManager.create_memento(game_state.unit_manager)

	return snapshot

func _restore_state(game_state: GameState, snapshot: Dictionary) -> void:
	# Restore managers in a specific order if dependencies exist
	game_state.unit_manager.restore_from_memento(snapshot.get("unit_manager", {}))
	game_state.task_manager.restore_from_memento(snapshot.get("task_manager", {}))
	game_state.turn_controller.restore_from_memento(snapshot.get("turn_controller", {}))
	if game_state.unit_manager:
		game_state.unit_manager.reset_all_neutral_loyalties()

	if game_state.loot_manager and game_state.loot_manager.has_method("restore_from_memento"):
		game_state.loot_manager.restore_from_memento(snapshot.get("loot_manager", {}))
	if typeof(WeatherManager) != TYPE_NIL and WeatherManager.has_method("restore_from_memento"):
		WeatherManager.restore_from_memento(snapshot.get("weather_manager", {}), game_state.unit_manager)
	if game_state.hud_controller and game_state.hud_controller.has_method("refresh_after_state_restore"):
		game_state.hud_controller.refresh_after_state_restore()
	if game_state.hud and game_state.hud.has_method("action_refresh_requested"):
		game_state.hud.action_refresh_requested.emit()
	if game_state.hud:
		var morale_panel: MoralePanel = game_state.hud.get_node_or_null("HUDMarginContainer/BottomCenterContainer/MoralePanel")
		if is_instance_valid(morale_panel) and morale_panel.has_method("reset_state"):
			morale_panel.reset_state(game_state.unit_manager)

func _validate_unique_items(game_state: GameState) -> void:
	var seen_uuids := {}

	# Check units
	for unit in game_state.unit_manager.get_units():
		if not is_instance_valid(unit): continue
		var inv = unit.get_inventory()
		if inv:
			for item in inv.get_items():
				if item is InventoryItem and not item.uuid.is_empty():
					if seen_uuids.has(item.uuid):
						push_warning("CheckpointManager: Duplicate item UUID found on unit: " + item.uuid)
					seen_uuids[item.uuid] = true

	# Check loot
	if game_state.loot_manager:
		for loot in game_state.loot_manager.get_all_loot():
			for item in loot.inventory:
				if item is InventoryItem and not item.uuid.is_empty():
					if seen_uuids.has(item.uuid):
						push_warning("CheckpointManager: Duplicate item UUID found in loot: " + item.uuid)
					seen_uuids[item.uuid] = true
