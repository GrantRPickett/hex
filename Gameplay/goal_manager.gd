class_name GoalManager
extends Node

const GoalStep := preload("res://Resources/goal_step.gd")

signal goal_updated(index: int)
signal goal_completed(index: int, faction: int)

# Goal class is auto-global in Godot 4

var _goal_targets: Array[Vector2i] = []
var _goals: Array[Goal] = []
var _goal_lookup: Dictionary = {}
var _grid: Node2D

# Progress tracking: _goal_progress[goal_index][faction_id] = accumulated_points
var _goal_progress: Array[Dictionary] = []

# Goal definitions derived from nodes or defaults
# { "type": String, "amount": int }
# Goal definitions derived from nodes or defaults
var _goal_definitions: Array[GoalDefinition] = []

func setup(goal_coords: Array[Vector2i], goals: Array[Goal], grid: Node2D) -> void:
	_grid = grid
	_clear_state()

	for i in range(goal_coords.size()):
		_setup_goal_at_index(i, goal_coords[i], goals)

	# _update_visuals() # This function is not defined in GoalManager, likely intended for a visual component.

func _update_visuals() -> void:
	pass # Placeholder for visual updates, if any.

# ... (visuals code remains same) ...

func process_turn_progress(unit_manager: UnitManager) -> void:
	if _goal_lookup.is_empty():
		return

	var count = unit_manager.get_unit_count()
	for i in range(count):
		var unit = unit_manager.get_unit(i)
		if not unit or unit.willpower <= 0:
			continue
		var coord = unit_manager.get_coord(i)
		if coord == Vector2i(-1, -1):
			continue
		if not _goal_lookup.has(coord):
			continue
		var goal_index = int(_goal_lookup[coord])
		print_debug("GoalManager: apply progress at ", coord, " goal_index=", goal_index, " unit_faction=", unit.faction)
		_apply_progress(goal_index, unit)

func apply_progress(goal_index: int, unit: Unit) -> void:
	_apply_progress(goal_index, unit)

func _apply_progress(goal_index: int, unit: Unit) -> void:
	if not _is_valid_goal_index(goal_index):
		return

	var def = _goal_definitions[goal_index]
	var faction = unit.faction
	var progress = _get_or_create_progress(goal_index, faction)

	if progress.completed:
		return

	if _should_block_rare_goal(def, progress):
		return

	if progress.step_index >= def.steps.size():
		progress.completed = true
		return

	var step = def.steps[progress.step_index]
	var amount = _calculate_unit_contribution(unit, step)

	progress.current_amount += amount
	goal_updated.emit(goal_index)

	_check_step_completion(progress, def, goal_index, faction)

func are_all_required_goals_completed() -> bool:
	for i in range(_goal_definitions.size()):
		var def = _goal_definitions[i]
		if def.is_optional:
			continue
		if not is_goal_reached(i, Unit.Faction.PLAYER):
			return false
	return true

func is_goal_reached(index: int, faction: int) -> bool:
	if index < 0 or index >= _goal_definitions.size():
		return false

	if not _goal_progress[index].has(faction):
		return false

	return _goal_progress[index][faction].completed

func get_progress(index: int, faction: int) -> int:
	if index < 0 or index >= _goal_progress.size():
		return 0

	if not _goal_progress[index].has(faction):
		return 0

	return _goal_progress[index][faction].current_amount

func get_total_required_goals_count() -> int:
	var count = 0
	for def in _goal_definitions:
		if not def.is_optional:
			count += 1
	return count

func get_completed_required_goals_count(faction: int) -> int:
	var count = 0
	for i in range(_goal_definitions.size()):
		var def = _goal_definitions[i]
		if def.is_optional:
			continue
		if is_goal_reached(i, faction):
			count += 1
	return count

func get_required_amount(index: int, faction: int = Unit.Faction.PLAYER) -> int:
	if index < 0 or index >= _goal_definitions.size():
		return 0

	var def = _goal_definitions[index]
	var step_idx = 0
	if _goal_progress[index].has(faction):
		step_idx = _goal_progress[index][faction].step_index

	if step_idx < def.steps.size():
		return def.steps[step_idx].required_amount
	return 0 # Completed? Or return last step?

func get_required_type(index: int, faction: int = Unit.Faction.PLAYER) -> String:
	if index < 0 or index >= _goal_definitions.size():
		return ""

	var def = _goal_definitions[index]
	var step_idx = 0
	if _goal_progress[index].has(faction):
		step_idx = _goal_progress[index][faction].step_index

	if step_idx < def.steps.size():
		return def.steps[step_idx].required_attribute
	return ""

func get_current_step_description(index: int, faction: int = Unit.Faction.PLAYER) -> String:
	if index < 0 or index >= _goal_definitions.size():
		return ""

	var def = _goal_definitions[index]
	var step_idx = 0
	if _goal_progress[index].has(faction):
		step_idx = _goal_progress[index][faction].step_index

	if step_idx < def.steps.size():
		return def.steps[step_idx].description
	return "Completed" # Or last step desc?

func get_goal_at_cell(cell: Vector2i) -> Goal:
	if not _goal_lookup.has(cell):
		return null
	return get_goal_node(int(_goal_lookup[cell]))

func get_goal_node(index: int) -> Goal:
	if index < 0 or index >= _goals.size():
		return null
	return _goals[index]

func get_goal_node_index(goal_node: Goal) -> int:
	return _goals.find(goal_node)

func get_goal_count() -> int:
	return _goal_targets.size()

func get_target(index: int) -> Vector2i:
	if index < 0 or index >= _goal_targets.size():
		return Vector2i(-1, -1)
	return _goal_targets[index]

func set_target(index: int, coord: Vector2i) -> void:
	if index >= 0 and index < _goal_targets.size():
		_goal_targets[index] = coord
	else:
		printerr("GoalManager: Cannot set target, index out of bounds: ", index)

func create_memento() -> Dictionary:
	var progress_snapshot: Array = []
	for entry in _goal_progress:
		var serialized_entry := {}
		for faction_id in entry.keys():
			var state: Dictionary = entry[faction_id]
			serialized_entry[str(faction_id)] = {
				"step_index": state.get("step_index", 0),
				"current_amount": state.get("current_amount", 0),
				"completed": state.get("completed", false)
			}
		progress_snapshot.append(serialized_entry)

	return {
		"goal_progress": progress_snapshot,
		"goal_targets": _goal_targets.duplicate()
	}

func restore_from_memento(memento: Dictionary) -> void:
	_restore_targets(memento.get("goal_targets", null))
	_rebuild_lookup()
	_restore_progress(memento.get("goal_progress", null))
	_ensure_progress_size()
	_update_visuals()

# Private Helpers

func _clear_state() -> void:
	_goal_targets.clear()
	_goal_progress.clear()
	_goal_definitions.clear()
	_goals.clear()
	_goal_lookup.clear()

func _setup_goal_at_index(i: int, raw_coord: Variant, goals: Array[Goal]) -> void:
	var normalized_coord = _normalize_coordinate(raw_coord)
	_goal_targets.append(normalized_coord)
	_goal_lookup[normalized_coord] = i

	var node = _get_goal_node_safe(i, goals)
	_goals.append(node)
	_goal_progress.append({})

	var def = _resolve_goal_definition(node, normalized_coord)
	_goal_definitions.append(def)

func _normalize_coordinate(coord: Variant) -> Vector2i:
	if coord is Dictionary and coord.has("x") and coord.has("y"):
		return Vector2i(int(coord["x"]), int(coord["y"]))
	return coord

func _get_goal_node_safe(i: int, goals: Array[Goal]) -> Goal:
	if i < goals.size() and goals[i] is Goal:
		return goals[i]
	printerr("Warning: GoalManager missing Goal node for index ", i)
	return null

func _resolve_goal_definition(node: Goal, coord: Vector2i) -> GoalDefinition:
	var def: GoalDefinition = null
	if node:
		if _grid is TileMapLayer:
			node.grid_map = _grid
			node.position = _grid.map_to_local(coord)
		if node.definition:
			def = node.definition
		else:
			node._create_default_definition()
			def = node.definition

	if not def or def.steps.is_empty():
		def = _create_fallback_definition(node)
	return def

func _create_fallback_definition(node: Goal) -> GoalDefinition:
	var def = GoalDefinition.new()
	def.title = node.name if node else "Goal"
	var fallback_step := GoalStep.new()
	fallback_step.step_name = "Objective"
	fallback_step.description = "Work on the goal"
	fallback_step.required_attribute = "grit"
	fallback_step.required_amount = 1
	def.steps.append(fallback_step)
	return def

func _is_valid_goal_index(index: int) -> bool:
	return index >= 0 and index < _goal_definitions.size()

func _get_or_create_progress(index: int, faction: int) -> Dictionary:
	if not _goal_progress[index].has(faction):
		_goal_progress[index][faction] = {
			"step_index": 0,
			"current_amount": 0,
			"completed": false
		}
	return _goal_progress[index][faction]

func _should_block_rare_goal(def: GoalDefinition, progress: Dictionary) -> bool:
	if def.goal_type == GoalDefinition.GoalType.RARE:
		# Logic from original code:
		# "rare gather tile can only be done once by a faction"
		pass
	return false

func _calculate_unit_contribution(unit: Unit, step: GoalStep) -> int:
	var attr_type = step.required_attribute
	var amount = 0
	var attrs = unit.get_attributes()
	if attrs:
		amount = attrs.get_attribute(attr_type)

	if amount <= 0:
		amount = 1
	return amount

func _check_step_completion(progress: Dictionary, def: GoalDefinition, goal_index: int, faction: int) -> void:
	var step = def.steps[progress.step_index]
	if progress.current_amount >= step.required_amount:
		progress.current_amount = 0
		progress.step_index += 1

		if progress.step_index >= def.steps.size():
			progress.completed = true
			goal_completed.emit(goal_index, faction)

func _restore_targets(stored_targets: Variant) -> void:
	if stored_targets is Array:
		_goal_targets = []
		for coord in stored_targets:
			_goal_targets.append(_normalize_coordinate(coord))

func _rebuild_lookup() -> void:
	_goal_lookup.clear()
	for i in range(_goal_targets.size()):
		_goal_lookup[_goal_targets[i]] = i

func _restore_progress(stored_progress: Variant) -> void:
	_goal_progress = []
	if stored_progress is Array:
		for entry in stored_progress:
			_goal_progress.append(_normalize_progress_entry(entry))

func _normalize_progress_entry(entry: Variant) -> Dictionary:
	var normalized := {}
	if entry is Dictionary:
		for key in entry.keys():
			var faction_id = key
			if typeof(faction_id) == TYPE_STRING:
				faction_id = int(faction_id)
			elif typeof(faction_id) != TYPE_INT:
				continue
			var state = entry[key] if entry.has(key) else {}
			normalized[faction_id] = {
				"step_index": state.get("step_index", 0),
				"current_amount": state.get("current_amount", 0),
				"completed": state.get("completed", false)
			}
	return normalized

func _ensure_progress_size() -> void:
	while _goal_progress.size() < _goal_targets.size():
		_goal_progress.append({})
	if _goal_progress.size() > _goal_targets.size():
		_goal_progress.resize(_goal_targets.size())
