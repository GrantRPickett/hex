class_name locationManager
extends Node

const locationStep := preload("res://Resources/location_step.gd")

signal location_updated(index: int)
signal location_completed(index: int, faction: int)


var _location_targets: Array[Vector2i] = []
var _locations: Array[location] = []
var _location_lookup: Dictionary = {}
var _grid: Node2D

# Progress tracking: _location_progress[location_index][faction_id] = accumulated_points
var _location_progress: Array[Dictionary] = []

# location definitions derived from nodes or defaults
# { "type": String, "amount": int }
# location definitions derived from nodes or defaults
var _location_definitions: Array[locationDefinition] = []

func setup(location_coords: Array[Vector2i], locations: Array[location], grid: Node2D) -> void:
	_grid = grid
	_clear_state()

	for i in range(location_coords.size()):
		_setup_location_at_index(i, location_coords[i], locations)

	# _update_visuals() # This function is not defined in locationManager, likely intended for a visual component.

func _update_visuals() -> void:
	pass # Placeholder for visual updates, if any.

# ... (visuals code remains same) ...

func process_turn_progress(unit_manager: UnitManager) -> void:
	if _location_lookup.is_empty():
		return

	var count = unit_manager.get_unit_count()
	for i in range(count):
		var unit = unit_manager.get_unit(i)
		if not unit or unit.willpower <= 0:
			continue
		var coord = unit_manager.get_coord(i)
		if coord == Vector2i(-1, -1):
			continue
		if not _location_lookup.has(coord):
			continue
		var location_index = int(_location_lookup[coord])
		print_debug("locationManager: apply progress at ", coord, " location_index=", location_index, " unit_faction=", unit.faction)
		_apply_progress(location_index, unit)

func apply_progress(location_index: int, unit: Unit) -> void:
	_apply_progress(location_index, unit)

func _apply_progress(location_index: int, unit: Unit) -> void:
	if not _is_valid_location_index(location_index):
		return

	var def = _location_definitions[location_index]
	var faction = unit.faction
	var progress = _get_or_create_progress(location_index, faction)

	if progress.completed:
		return

	if _should_block_rare_location(def, progress):
		return

	if progress.step_index >= def.steps.size():
		progress.completed = true
		return

	var step = def.steps[progress.step_index]
	var amount = _calculate_unit_contribution(unit, step)

	progress.current_amount += amount
	location_updated.emit(location_index)

	_check_step_completion(progress, def, location_index, faction)

func is_location_completed(location: location) -> bool:
	var location_index = get_location_node_index(location)
	if location_index == -1:
		return false # location not found

	# Assuming player's perspective for now.
	# If this panel needs to show completion status for other factions,
	# the 'update_details' function in locationDetailsPanel might need
	# to pass the faction.
	return is_location_reached(location_index, Unit.Faction.PLAYER)

func are_all_required_locations_completed() -> bool:
	if get_total_required_locations_count() == 0:
		return false
	for i in range(_location_definitions.size()):
		var def = _location_definitions[i]
		if def.is_optional:
			continue
		if not is_location_reached(i, Unit.Faction.PLAYER):
			return false
	return true

func is_location_reached(index: int, faction: int) -> bool:
	if index < 0 or index >= _location_definitions.size():
		return false

	if not _location_progress[index].has(faction):
		return false

	return _location_progress[index][faction].completed

func get_progress(index: int, faction: int) -> int:
	if index < 0 or index >= _location_progress.size():
		return 0

	if not _location_progress[index].has(faction):
		return 0

	return _location_progress[index][faction].current_amount

func get_remaining_location_titles(faction: int = Unit.Faction.PLAYER) -> PackedStringArray:
	var titles := PackedStringArray()
	for i in range(_location_definitions.size()):
		var def = _location_definitions[i]
		if def.is_optional:
			continue
		if not is_location_reached(i, faction):
			var title: String = def.title if def and def.title else ""
			titles.append(title)
	return titles

func get_total_required_locations_count() -> int:
	var count = 0
	for def in _location_definitions:
		if not def.is_optional:
			count += 1
	return count

func get_completed_required_locations_count(faction: int) -> int:
	var count = 0
	for i in range(_location_definitions.size()):
		var def = _location_definitions[i]
		if def.is_optional:
			continue
		if is_location_reached(i, faction):
			count += 1
	return count

func get_required_amount(index: int, faction: int = Unit.Faction.PLAYER) -> int:
	if index < 0 or index >= _location_definitions.size():
		return 0

	var def = _location_definitions[index]
	var step_idx = 0
	if _location_progress[index].has(faction):
		step_idx = _location_progress[index][faction].step_index

	if step_idx < def.steps.size():
		return def.steps[step_idx].required_amount
	return 0 # Completed? Or return last step?

func get_required_type(index: int, faction: int = Unit.Faction.PLAYER) -> String:
	if index < 0 or index >= _location_definitions.size():
		return ""

	var def = _location_definitions[index]
	var step_idx = 0
	if _location_progress[index].has(faction):
		step_idx = _location_progress[index][faction].step_index

	if step_idx < def.steps.size():
		return def.steps[step_idx].required_attribute
	return ""

func get_current_step_description(index: int, faction: int = Unit.Faction.PLAYER) -> String:
	if index < 0 or index >= _location_definitions.size():
		return ""

	var def = _location_definitions[index]
	var step_idx = 0
	if _location_progress[index].has(faction):
		step_idx = _location_progress[index][faction].step_index

	if step_idx < def.steps.size():
		return def.steps[step_idx].description
	return "Completed" # Or last step desc?

func get_location_at_cell(cell: Vector2i) -> location:
	if not _location_lookup.has(cell):
		return null
	return get_location_node(int(_location_lookup[cell]))

func get_targets() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(_location_targets)
	return result

func get_location_node(index: int) -> location:
	if index < 0 or index >= _locations.size():
		return null
	return _locations[index]


func get_location_index_at(cell: Vector2i) -> int:
	if _location_lookup.has(cell):
		return int(_location_lookup[cell])
	return -1

func get_location_info(location_index: int, faction: int = Unit.Faction.PLAYER) -> Dictionary:
	if not _is_valid_location_index(location_index):
		return {}
	var def: locationDefinition = _location_definitions[location_index] if location_index < _location_definitions.size() else null
	var progress := _get_or_create_progress(location_index, faction)
	var total_steps := def.steps.size() if def and def.steps else 0
	var step_idx := int(progress.get("step_index", 0))
	if total_steps > 0:
		step_idx = clamp(step_idx, 0, total_steps - 1)
	var current_step: locationStep = def.steps[step_idx] if def and total_steps > 0 else null
	var description := ""
	var required_attribute := ""
	var required_amount := 0
	if current_step:
		description = current_step.description
		required_attribute = current_step.required_attribute
		required_amount = current_step.required_amount
	var title := def.title if def and not String(def.title).is_empty() else "location"
	return {
		"title": title,
		"description": description,
		"player_progress": int(progress.get("current_amount", 0)),
		"required_attribute": required_attribute,
		"required_amount": required_amount,
		"completed": bool(progress.get("completed", false))
	}

func get_location_node_index(location_node: location) -> int:
	return _locations.find(location_node)

func get_location_count() -> int:
	return _location_targets.size()

func get_target(index: int) -> Vector2i:
	if index < 0 or index >= _location_targets.size():
		return Vector2i(-1, -1)
	return _location_targets[index]

func set_target(index: int, coord: Vector2i) -> void:
	if index >= 0 and index < _location_targets.size():
		_location_targets[index] = coord
	else:
		printerr("locationManager: Cannot set target, index out of bounds: ", index)

func create_memento() -> Dictionary:
	var progress_snapshot: Array = []
	for entry in _location_progress:
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
		"location_progress": progress_snapshot,
		"location_targets": _location_targets.duplicate()
	}

func restore_from_memento(memento: Dictionary) -> void:
	_restore_targets(memento.get("location_targets", null))
	_rebuild_lookup()
	_restore_progress(memento.get("location_progress", null))
	_ensure_progress_size()
	_update_visuals()

# Private Helpers

func _clear_state() -> void:
	_location_targets.clear()
	_location_progress.clear()
	_location_definitions.clear()
	_locations.clear()
	_location_lookup.clear()

func _setup_location_at_index(i: int, raw_coord: Variant, locations: Array[location]) -> void:
	var normalized_coord = _normalize_coordinate(raw_coord)
	_location_targets.append(normalized_coord)
	_location_lookup[normalized_coord] = i

	var node = _get_location_node_safe(i, locations)
	if node:
		node.set_external_grid_coord(normalized_coord)
	_locations.append(node)
	_location_progress.append({})

	var def = _resolve_location_definition(node, normalized_coord)
	_location_definitions.append(def)

func _normalize_coordinate(coord: Variant) -> Vector2i:
	if coord is Dictionary and coord.has("x") and coord.has("y"):
		return Vector2i(int(coord["x"]), int(coord["y"]))
	return coord

func _get_location_node_safe(i: int, locations: Array[location]) -> location:
	if i < locations.size() and locations[i] is location:
		return locations[i]
	printerr("Warning: locationManager missing location node for index ", i)
	return null

func _resolve_location_definition(node: location, coord: Vector2i) -> locationDefinition:
	var def: locationDefinition = null
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

	if not def or def.steps.is_empty():
		def = _create_fallback_definition(node)
	return def

func _create_fallback_definition(node: location) -> locationDefinition:
	var def = locationDefinition.new()
	def.title = node.name if node else "location"
	var fallback_step := locationStep.new()
	fallback_step.step_name = "Objective"
	fallback_step.description = "Work on the location"
	fallback_step.required_attribute = "grit"
	fallback_step.required_amount = 1
	def.steps.append(fallback_step)
	return def

func _is_valid_location_index(index: int) -> bool:
	return index >= 0 and index < _location_definitions.size()

func _get_or_create_progress(index: int, faction: int) -> Dictionary:
	if not _location_progress[index].has(faction):
		_location_progress[index][faction] = {
			"step_index": 0,
			"current_amount": 0,
			"completed": false
		}
	return _location_progress[index][faction]

func _should_block_rare_location(def: locationDefinition, progress: Dictionary) -> bool:
	if def.location_type == locationDefinition.locationType.RARE:
		# Logic from original code:
		# "rare gather tile can only be done once by a faction"
		pass
	return false

func _calculate_unit_contribution(unit: Unit, step: locationStep) -> int:
	var attr_type = step.required_attribute
	var amount = 0
	var attrs = unit.get_attributes()
	if attrs:
		amount = attrs.get_attribute(attr_type)

	if amount <= 0:
		amount = 1
	return amount

func _check_step_completion(progress: Dictionary, def: locationDefinition, location_index: int, faction: int) -> void:
	var step = def.steps[progress.step_index]
	if progress.current_amount >= step.required_amount:
		progress.current_amount = 0
		progress.step_index += 1

		if progress.step_index >= def.steps.size():
			progress.completed = true
			location_completed.emit(location_index, faction)

func _restore_targets(stored_targets: Variant) -> void:
	if stored_targets is Array:
		_location_targets = []
		for coord in stored_targets:
			_location_targets.append(_normalize_coordinate(coord))

func _rebuild_lookup() -> void:
	_location_lookup.clear()
	for i in range(_location_targets.size()):
		_location_lookup[_location_targets[i]] = i

func _restore_progress(stored_progress: Variant) -> void:
	_location_progress = []
	if stored_progress is Array:
		for entry in stored_progress:
			_location_progress.append(_normalize_progress_entry(entry))

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
	while _location_progress.size() < _location_targets.size():
		_location_progress.append({})
	if _location_progress.size() > _location_targets.size():
		_location_progress.resize(_location_targets.size())
