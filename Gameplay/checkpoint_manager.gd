class_name CheckpointManager
extends RefCounted

var _history: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
var _max_history: int = 50

func create_checkpoint(game_state: GameState) -> void:
	_validate_unique_items(game_state)
	var snapshot := _capture_state(game_state)

	_history.append(snapshot)
	if _history.size() > _max_history:
		_history.pop_front()

	_redo_stack.clear()

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
		"goal_manager": game_state.goal_manager.create_memento(),
		"turn_controller": game_state.turn_controller.create_memento()
	}

	# Consider LootManager if it supports mementos
	if game_state.loot_manager and game_state.loot_manager.has_method("create_memento"):
		snapshot["loot_manager"] = game_state.loot_manager.create_memento()

	return snapshot

func _restore_state(game_state: GameState, snapshot: Dictionary) -> void:
	# Restore managers in a specific order if dependencies exist
	game_state.unit_manager.restore_from_memento(snapshot.get("unit_manager", {}))
	game_state.goal_manager.restore_from_memento(snapshot.get("goal_manager", {}))
	game_state.turn_controller.restore_from_memento(snapshot.get("turn_controller", {}))

	if game_state.loot_manager and game_state.loot_manager.has_method("restore_from_memento"):
		game_state.loot_manager.restore_from_memento(snapshot.get("loot_manager", {}))

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
