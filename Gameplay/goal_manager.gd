class_name GoalManager
extends Node

signal goal_updated(index: int)
signal goal_completed(index: int, faction: int)

# Goal class is auto-global in Godot 4

var _goal_targets: Array[Vector2i] = []
var _goals: Array[Goal] = []
var _grid: Node2D

# Progress tracking: _goal_progress[goal_index][faction_id] = accumulated_points
var _goal_progress: Array[Dictionary] = []

# Goal definitions derived from nodes or defaults
# { "type": String, "amount": int }
var _goal_definitions: Array[Dictionary] = []

func setup(goal_coords: Array[Vector2i], goals: Array[Goal], grid: Node2D) -> void:
	_goal_targets = goal_coords.duplicate()
	_goals = goals
	_grid = grid

	_goal_progress.clear()
	_goal_definitions.clear()

	for i in range(goal_coords.size()):
		_goal_progress.append({})

		var def = {
			"type": "grit",
			"amount": 100
		}

		if i < goals.size():
			var node = goals[i]
			if node:
				if grid is TileMapLayer:
					node._grid = grid
				if "required_attribute" in node:
					def["type"] = node.required_attribute
				if "required_amount" in node:
					def["amount"] = node.required_amount

		_goal_definitions.append(def)

	_update_visuals()

func _update_visuals() -> void:
	if not is_instance_valid(_grid):
		return

	if not _grid.has_method("map_to_local"):
		return

	for i in range(_goals.size()):
		var goal = _goals[i]
		if i < _goal_targets.size():
			goal.visible = true
			goal.position = _grid.map_to_local(_goal_targets[i])
		else:
			goal.visible = false

func get_target(index: int) -> Vector2i:
	if index >= 0 and index < _goal_targets.size():
		return _goal_targets[index]
	return Vector2i(-999, -999)

func set_target(index: int, coord: Vector2i) -> void:
	if index >= 0 and index < _goal_targets.size():
		_goal_targets[index] = coord
		_update_visuals()
	elif index == 0 and _goal_targets.is_empty():
		_goal_targets.append(coord)
		_update_visuals()

func get_targets() -> Array[Vector2i]:
	return _goal_targets

func get_goal_node(index: int) -> Node:
	if index >= 0 and index < _goals.size():
		return _goals[index]
	return null

func get_goal_count() -> int:
	return _goal_targets.size()

func process_turn_progress(unit_manager: UnitManager) -> void:
	for i in range(_goal_targets.size()):
		var coord = _goal_targets[i]
		var unit_index = unit_manager.index_of_unit_at(coord)

		if unit_index != -1:
			var unit = unit_manager.get_unit(unit_index)
			if unit and unit.willpower > 0:
				_apply_progress(i, unit)

func apply_progress(goal_index: int, unit: Unit) -> void:
	_apply_progress(goal_index, unit)

func _apply_progress(goal_index: int, unit: Unit) -> void:
	var def = _goal_definitions[goal_index]
	var attr_type = def["type"]
	var faction = unit.faction

	var amount = 0
	var attrs = unit.get_attributes()
	if attrs:
		amount = attrs.get_attribute(attr_type)

	if amount <= 0:
		amount = 1

	var current = _goal_progress[goal_index].get(faction, 0)
	current += amount
	_goal_progress[goal_index][faction] = current

	goal_updated.emit(goal_index)

	if current >= def["amount"]:
		goal_completed.emit(goal_index, faction)

func is_goal_reached(index: int, faction: int) -> bool:
	if index < 0 or index >= _goal_definitions.size():
		return false
	var target = _goal_definitions[index]["amount"]
	return _goal_progress[index].get(faction, 0) >= target

func get_progress(index: int, faction: int) -> int:
	if index < 0 or index >= _goal_progress.size():
		return 0
	return _goal_progress[index].get(faction, 0)

func get_required_amount(index: int) -> int:
	if index < 0 or index >= _goal_definitions.size():
		return 0
	return _goal_definitions[index]["amount"]

func get_required_type(index: int) -> String:
	if index < 0 or index >= _goal_definitions.size():
		return ""
	return _goal_definitions[index]["type"]
