class_name TaskManager
extends Node

signal task_updated(index: int)
signal task_completed(index: int, faction: int)


var _task_targets: Array[Vector2i] = []
var _target_tasks: Array[TargetTask] = []
var _task_lookup: Dictionary = {}
var _grid: Node2D

# Progress tracking: _location_progress[task_index][faction_id] = accumulated_points
var _task_progress: Array[Dictionary] = []

# location definitions derived from nodes or defaults
# { "type": String, "amount": int }
# location definitions derived from nodes or defaults
var _task_definitions: Array[TaskDefinition] = []

func setup(location_coords: Array[Vector2i], locations: Array[TargetTask], grid: Node2D) -> void:
	_grid = grid
	_clear_state()

	# _update_visuals() # This function is not defined in TaskManager, likely intended for a visual component.

func _update_visuals() -> void:
	pass # Placeholder for visual updates, if any.

# ... (visuals code remains same) ...

func process_turn_progress(unit_manager: UnitManager) -> void:
	if _task_lookup.is_empty():
		return

	var count = unit_manager.get_unit_count()
	for i in range(count):
		var unit = unit_manager.get_unit(i)
		if not unit or unit.willpower <= 0:
			continue
		var coord = unit_manager.get_coord(i)
		if coord == Vector2i(-1, -1):
			continue
		if not _task_lookup.has(coord):
			continue
		var task_index = int(_task_lookup[coord])
		_apply_progress(task_index, unit)

func apply_progress(task_index: int, unit: Unit) -> void:
	_apply_progress(task_index, unit)

func _apply_progress(task_index: int, unit: Unit) -> void:

	var def = _task_definitions[task_index]
	var faction = unit.faction
	var progress = _get_or_create_progress(task_index, faction)

	if progress.completed:
		return

	if progress.step_index >= def.steps.size():
		progress.completed = true
		return

	var step = def.steps[progress.step_index]
	var amount = _calculate_unit_contribution(unit, step)

	progress.current_amount += amount
	task_updated.emit(task_index)

	_check_step_completion(progress, def, task_index, faction)

func is_task_completed(target_task: TargetTask) -> bool:
	var task_index = get_target_task_node_index(target_task)
	if task_index == -1:
		return false # location not found

	# Assuming player's perspective for now.
	# If this panel needs to show completion status for other factions,
	# the 'update_details' function in locationDetailsPanel might need
	# to pass the faction.
	return is_task_reached(task_index, Unit.Faction.PLAYER)

func are_all_required_tasks_completed() -> bool:
	if get_total_required_tasks_count() == 0:
		return false
	for i in range(_task_definitions.size()):
		var def = _task_definitions[i]
		if def.is_optional:
			continue
		if not is_task_reached(i, Unit.Faction.PLAYER):
			return false
	return true

func is_task_reached(index: int, faction: int) -> bool:
	if index < 0 or index >= _task_definitions.size():
		return false

	if not _task_progress[index].has(faction):
		return false

	return _task_progress[index][faction].completed

func get_progress(index: int, faction: int) -> int:
	if index < 0 or index >= _task_progress.size():
		return 0

	if not _task_progress[index].has(faction):
		return 0

	return _task_progress[index][faction].current_amount

func get_remaining_task_titles(faction: int = Unit.Faction.PLAYER) -> PackedStringArray:
	var titles := PackedStringArray()
	for i in range(_task_definitions.size()):
		var def = _task_definitions[i]
		if def.is_optional:
			continue
		if not is_task_reached(i, faction):
			var title: String = def.title if def and def.title else ""
			titles.append(title)
	return titles

func get_total_required_tasks_count() -> int:
	var count = 0
	for def in _task_definitions:
		if not def.is_optional:
			count += 1
	return count

func get_completed_required_tasks_count(faction: int) -> int:
	var count = 0
	for i in range(_task_definitions.size()):
		var def = _task_definitions[i]
		if def.is_optional:
			continue
		if is_task_reached(i, faction):
			count += 1
	return count

func get_required_amount(index: int, faction: int = Unit.Faction.PLAYER) -> int:
	if index < 0 or index >= _task_definitions.size():
		return 0

	var def = _task_definitions[index]
	var step_idx = 0
	if _task_progress[index].has(faction):
		step_idx = _task_progress[index][faction].step_index

	if step_idx < def.steps.size():
		return def.steps[step_idx].required_amount
	return 0 # Completed? Or return last step?

func get_required_type(index: int, faction: int = Unit.Faction.PLAYER) -> String:
	if index < 0 or index >= _task_definitions.size():
		return ""

	var def = _task_definitions[index]
	var step_idx = 0
	if _task_progress[index].has(faction):
		step_idx = _task_progress[index][faction].step_index

	if step_idx < def.steps.size():
		return def.steps[step_idx].required_attribute
	return ""

func get_current_step_description(index: int, faction: int, _default_faction: int = Unit.Faction.PLAYER) -> String:
	if index < 0 or index >= _task_definitions.size():
		return ""

	var def = _task_definitions[index]
	var step_idx = 0
	if _task_progress[index].has(faction):
		step_idx = _task_progress[index][faction].step_index

	if step_idx < def.steps.size():
		return def.steps[step_idx].description
	return "Completed" # Or last step desc?

func get_target_task_at_cell(cell: Vector2i) -> TargetTask:
	if not _task_lookup.has(cell):
		return null
	return get_target_task_node(int(_task_lookup[cell]))

func get_target_tasks() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(_task_targets)
	return result

func get_target_task_node(index: int) -> TargetTask:
	if index < 0 or index >= _target_tasks.size():
		return null
	return _target_tasks[index]

func get_task_info(task_index: int, faction: int = Unit.Faction.PLAYER) -> Dictionary:
	if not _is_valid_task_index(task_index):
		return {}
	var def: TaskDefinition = _task_definitions[task_index] if task_index < _task_definitions.size() else null
	var progress := _get_or_create_progress(task_index, faction)
	var total_steps := def.steps.size() if def and def.steps else 0
	var step_idx := int(progress.get("step_index", 0))
	if total_steps > 0:
		step_idx = clamp(step_idx, 0, total_steps - 1)
	var current_step: TaskStep = def.steps[step_idx] if def and total_steps > 0 else null
	var description := ""
	var required_attribute := ""
	var required_amount := 0
	if current_step:
		description = current_step.description
		required_attribute = current_step.required_attribute
		required_amount = current_step.required_amount
	var title := def.title if def and not String(def.title).is_empty() else "Task"
	return {
		"title": title,
		"description": description,
		"player_progress": int(progress.get("current_amount", 0)),
		"required_attribute": required_attribute,
		"required_amount": required_amount,
		"completed": bool(progress.get("completed", false))
	}

func get_target_task_node_index(target_task_node: TargetTask) -> int:
	return _target_tasks.find(target_task_node)

func get_task_count() -> int:
	return _task_targets.size()

func get_target_task_at_index(index: int) -> Vector2i:
	if index < 0 or index >= _task_targets.size():
		return Vector2i(-1, -1)
	return _task_targets[index]

func set_target_task_at_index(index: int, coord: Vector2i) -> void:
	if index >= 0 and index < _task_targets.size():
		_task_targets[index] = coord
	else:
		printerr("TaskManager: Cannot set target task, index out of bounds: ", index)

func create_memento() -> Dictionary:
	var progress_snapshot: Array = []
	for entry in _task_progress:
		var serialized_entry := {}
		for faction_id in entry.keys():
			var state: Dictionary = entry[faction_id]
			serialized_entry[str(faction_id)] = {
				"step_index": state.get("step_index", 0),
				"current_amount": state.get("current_amount", 0),
				"completed": state.get("completed", false)
			}
		progress_snapshot.append(serialized_entry)

	return { "task_progress": progress_snapshot, "task_targets": _task_targets.duplicate() }

func restore_from_memento(memento: Dictionary) -> void:
	_restore_targets(memento.get("task_targets", null))
	_rebuild_lookup()
	_restore_progress(memento.get("task_progress", null))
	_ensure_progress_size()
	_update_visuals()

# Private Helpers

func _clear_state() -> void:
	_task_targets.clear()
	_task_progress.clear()
	_task_definitions.clear()
	_target_tasks.clear()
	_task_lookup.clear()

func _setup_task_at_index(i: int, raw_coord: Variant, target_tasks: Array[TargetTask]) -> void:
	var normalized_coord = _normalize_coordinate(raw_coord)
	_task_targets.append(normalized_coord)
	_task_lookup[normalized_coord] = i

	var node = _get_target_task_node_safe(i, target_tasks)
	if node:
		node.set_external_grid_coord(normalized_coord)
	_target_tasks.append(node)
	_task_progress.append({})

	var def = _resolve_task_definition(node, normalized_coord)
	_task_definitions.append(def)

func _normalize_coordinate(coord: Variant) -> Vector2i:
	if coord is Dictionary and coord.has("x") and coord.has("y"):
		return Vector2i(int(coord["x"]), int(coord["y"]))
	return coord

func _get_target_task_node_safe(i: int, target_tasks: Array[TargetTask]) -> TargetTask:
	if i < target_tasks.size() and target_tasks[i] is TargetTask:
		return target_tasks[i]
	printerr("Warning: TaskManager missing target task node for index ", i)
	return null

func _resolve_task_definition(node: TargetTask, coord: Vector2i) -> TaskDefinition:
	var def: TaskDefinition = null
	if node:
		if _grid is TileMapLayer:
			node.grid_map = _grid
			node.position = _grid.map_to_local(coord)
			node.set_external_grid_coord(coord)
		if node.definition:
			def = node.definition
		else:
			node._create_default_definition()
			def = node.definition

	return def

func _is_valid_task_index(index: int) -> bool:
	return index >= 0 and index < _task_definitions.size()

func _get_or_create_progress(index: int, faction: int) -> Dictionary:
	if not _task_progress[index].has(faction):
		_task_progress[index][faction] = {
			"step_index": 0,
			"current_amount": 0,
			"completed": false
		}
	return _task_progress[index][faction]

func _should_block_rare_task(def: TaskDefinition, progress: Dictionary) -> bool:
	if def.task_type == TaskDefinition.TaskType.RARE:
		# Logic from original code:
		# "rare gather tile can only be done once by a faction"
		pass
	return false

func _calculate_unit_contribution(unit: Unit, step: TaskStep) -> int:
	var attr_type = step.required_attribute
	var amount = 0
	var attrs = unit.get_attributes()
	if attrs:
		amount = attrs.get_attribute(attr_type)

	if amount <= 0:
		amount = 1
	return amount

func _check_step_completion(progress: Dictionary, def: TaskDefinition, task_index: int, faction: int) -> void:
	var step = def.steps[progress.step_index]
	if progress.current_amount >= step.required_amount:
		progress.current_amount = 0
		progress.step_index += 1

		if progress.step_index >= def.steps.size():
			progress.completed = true
			task_completed.emit(task_index, faction)

func _restore_targets(stored_targets: Variant) -> void:
	if stored_targets is Array:
		_task_targets = []
		for coord in stored_targets:
			_task_targets.append(_normalize_coordinate(coord))

func _rebuild_lookup() -> void:
	_task_lookup.clear()
	for i in range(_task_targets.size()):
		_task_lookup[_task_targets[i]] = i

func _restore_progress(stored_progress: Variant) -> void:
	_task_progress = []
	if stored_progress is Array:
		for entry in stored_progress:
			_task_progress.append(_normalize_progress_entry(entry))

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
	while _task_progress.size() < _task_targets.size():
		_task_progress.append({})
	if _task_progress.size() > _task_targets.size():
		_task_progress.resize(_task_targets.size())
