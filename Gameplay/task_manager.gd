class_name TaskManager
extends Node

const Objective := preload("res://Resources/task/objective.gd")
const TargetSpawner := preload("res://Gameplay/target_spawner.gd")

signal objective_updated(objective: Objective)
signal objective_completed(objective: Objective)
signal task_completed(index: int, faction: int)
signal task_failed(index: int, faction: int)
signal task_updated(index: int, faction: int)

var _active_objective: Objective
var _locations: Array[Location] = []
var _location_lookup: Dictionary = {}
var _unit_manager: UnitManager

func setup(level_objective: Objective, game_state: GameState) -> void:
	_unit_manager = game_state.unit_manager
	_locations.clear()
	_location_lookup.clear()

	if _unit_manager:
		if not _unit_manager.unit_moved.is_connected(_on_unit_moved):
			_unit_manager.unit_moved.connect(_on_unit_moved)

	if level_objective:
		_active_objective = level_objective.duplicate(true)
		_active_objective.objective_updated.connect(_on_objective_updated)
		_active_objective.objective_completed.connect(_on_objective_completed)
		_active_objective.start_objective()
		objective_updated.emit(_active_objective)

func register_location(location: Location) -> void:
	_locations.append(location)
	_location_lookup[location.coord] = location
	if not location.interacted.is_connected(_on_location_interacted):
		location.interacted.connect(_on_location_interacted.bind(location))

func get_active_objective() -> Objective:
	return _active_objective

func get_location_at(coord: Vector2i) -> Location:
	return _location_lookup.get(coord)

func _on_location_interacted(unit: Unit, location: Location) -> void:
	if _active_objective:
		_active_objective.handle_event("interact", {
			"unit": unit,
			"coord": location.coord,
			"id": location.loc_name
		})

func _on_unit_moved(index: int, coord: Vector2i) -> void:
	if _active_objective and _unit_manager:
		var unit = _unit_manager.get_unit(index)
		if unit:
			_active_objective.handle_event("move", {
				"unit": unit,
				"coord": coord
			})

func _on_objective_updated(current_stage: Stage) -> void:
	objective_updated.emit(_active_objective)
	
	if not is_instance_valid(current_stage):
		push_warning("TaskManager: _on_objective_updated called with invalid current_stage.")
		return

	# Spawn reinforcements defined in the current_stage
	if not current_stage.spawns.is_empty():
		for spawn_entry in current_stage.spawns:
			if not is_instance_valid(spawn_entry) or not is_instance_valid(spawn_entry.unit_scene):
				push_warning("TaskManager: Invalid spawn entry in stage '%s'." % current_stage.id)
				continue
			
			var spawn_data = {
				"unit_scene": spawn_entry.unit_scene,
				"coord": spawn_entry.coord
			}
			
			var spawned_unit = TargetSpawner.spawn_unit(
				spawn_data,
				_unit_manager,
				null, # loot_manager (not needed for reinforcements)
				self, # task_manager (self)
				null, # combat_system (not needed for simple spawn)
				null, # grid (not needed for TargetSpawner.spawn_unit directly)
				spawn_entry.faction
			)
			if is_instance_valid(spawned_unit):
				print_debug("TaskManager: Spawned reinforcement '%s' at %s for faction %d." % [spawned_unit.unit_name, spawned_unit.get_grid_location(), spawned_unit.faction])
			else:
				push_warning("TaskManager: Failed to spawn reinforcement from stage '%s'." % current_stage.id)

func _on_objective_completed() -> void:
	objective_completed.emit(_active_objective)

func create_memento() -> Dictionary:
	# TODO: Serialize objective state
	return {}

func restore_from_memento(memento: Dictionary) -> void:
	# TODO: Restore objective state
	pass

func get_task_for_location(location: Location) -> Task:
	if not _active_objective or not _active_objective.current_stage:
		return null

	for task in _active_objective.current_stage.active_tasks:
		if task == null or task.status != Task.Status.ACTIVE:
			continue

		if task.event_type == "interact":
			var matches_coord = false
			if task.target_coord != Vector2i(-999, -999): # -999,-999 is sentinel for no coord target
				matches_coord = (task.target_coord == location.coord)

			var matches_id = false
			if not task.target_id.is_empty():
				matches_id = (task.target_id == location.loc_name)

			if matches_coord or matches_id:
				return task
	return null

func get_task_by_id(task_id: String) -> Task:
	if not _active_objective or not _active_objective.current_stage:
		return null

	for task in _active_objective.current_stage.active_tasks:
		if task == null:
			continue
		if String(task.id) == task_id: # Compare StringName id to String
			return task
	return null

func get_active_tasks_for_location(location: Location) -> Array[Task]:
	var matching_tasks: Array[Task] = []
	if not _active_objective or not _active_objective.current_stage or location == null:
		return matching_tasks

	for task in _active_objective.current_stage.active_tasks:
		if task == null or task.status != Task.Status.ACTIVE:
			continue
		
		var matches_coord = false
		if task.target_coord != Vector2i(-999, -999):
			matches_coord = (task.target_coord == location.coord)
		
		var matches_id = false
		if not task.target_id.is_empty():
			matches_id = (task.target_id == location.loc_name)
		
		if matches_coord or matches_id:
			matching_tasks.append(task)
			
	return matching_tasks
