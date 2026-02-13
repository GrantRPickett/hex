class_name TaskController
extends Node

const StageResource := preload("res://Resources/task/stage.gd")
const TargetSpawner := preload("res://Gameplay/target_spawner.gd")

signal task_reached
signal game_over
signal dialogue_requested(timeline: Resource)

var _task_manager: TaskManager
var _unit_manager: UnitManager
var _unit_controller: UnitController
var _turn_controller: TurnController
var _loot_manager: LootManager # New
var _combat_system: CombatSystem # New
var _grid: Node2D # New
var _task_reached_state: bool = false
var _game_over_state: bool = false

func setup(task_manager: TaskManager, unit_manager: UnitManager, unit_controller: UnitController = null, turn_controller: TurnController = null, loot_manager: LootManager = null, combat_system: CombatSystem = null, grid: Node2D = null) -> void:
	_task_manager = task_manager
	_unit_manager = unit_manager
	_unit_controller = unit_controller
	_turn_controller = turn_controller
	_loot_manager = loot_manager # Assign new parameter
	_combat_system = combat_system # Assign new parameter
	_grid = grid # Assign new parameter
	if _task_manager:
		if not _task_manager.task_completed.is_connected(on_task_completed):
			_task_manager.task_completed.connect(on_task_completed)
		if not _task_manager.objective_updated.is_connected(_on_objective_updated):
			_task_manager.objective_updated.connect(_on_objective_updated)

func on_unit_defeated(unit: Unit) -> void:
	# Check for defend unit failure
	if _task_manager:
		var obj = _task_manager.get_active_objective()
		if obj:
			# Let objective handle death event
			obj.handle_event("unit_defeated", {"unit": unit})
	check_objective_conditions()

func on_task_completed(_index: int, _faction: int) -> void:
	check_objective_conditions()

func _on_objective_updated(objective: Resource) -> void:
	if objective and objective.is_active and objective.current_stage:
		_handle_stage_spawns(objective.current_stage)
		if objective.current_stage.start_dialogue_timeline:
			dialogue_requested.emit(objective.current_stage.start_dialogue_timeline)
	check_objective_conditions()

func on_round_changed(current_round: int) -> void:
	if _task_manager == null:
		return

	var obj = _task_manager.get_active_objective()
	if obj:
		obj.handle_event("round_changed", {"round": current_round})

	check_objective_conditions()

func check_objective_conditions() -> void:
	if _task_reached_state or _game_over_state:
		return

	# Check inventory tasks
	if _unit_manager:
		var player_units: Array[Unit] = []
		for i in range(_unit_manager.get_unit_count()):
			var u = _unit_manager.get_unit(i)
			if u and u.faction == Unit.Faction.PLAYER and u.willpower > 0:
				player_units.append(u)
		check_inventory_objectives(player_units)

	if _task_manager:
		var obj = _task_manager.get_active_objective()
		if obj:
			if not obj.is_active: # Completed
				_task_reached_state = true
				task_reached.emit()
			# TODO: Check failure condition on objective

func check_inventory_objectives(player_units: Array[Unit]) -> void:
	if _task_manager == null: return

	var obj = _task_manager.get_active_objective()
	if obj:
		obj.handle_event("inventory_check", {"units": player_units})

func _handle_stage_spawns(stage: Resource) -> void:
	if not stage.get("spawns") or stage.spawns.is_empty() or not _unit_controller:
		return

	for spawn in stage.spawns:
		TargetSpawner.spawn_unit(
			spawn,
			_unit_manager,
			_loot_manager,
			_task_manager,
			_combat_system,
			_grid
		)

	if _turn_controller:
		_turn_controller.rebuild_turn_roster()

func is_task_reached() -> bool:
	return _task_reached_state

func reset_task_state() -> void:
	_task_reached_state = false
	_game_over_state = false

func create_memento() -> Dictionary:
	if _task_manager:
		return _task_manager.create_memento()
	return {}

func restore_from_memento(memento: Dictionary) -> void:
	if _task_manager:
		_task_manager.restore_from_memento(memento)


func get_task_info(index: int) -> Dictionary:
	# For now, return a dummy dictionary. This will be replaced with actual task data.
	# The index can be used to differentiate dummy tasks if needed.
	return {
		"title": "Dummy Task " + str(index),
		"description": "This is a placeholder task description.",
		"status": "In Progress",
		"current_stage": 1,
		"total_stages": 3,
		"sub_tasks": [
			{"name": "Sub-task A", "completed": false},
			{"name": "Sub-task B", "completed": true}
		]
	}
