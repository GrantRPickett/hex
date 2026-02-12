class_name TaskController
extends Node

signal task_reached
signal game_over

# This is the new controller that will handle task-related actions, formerly location_controller

var _task_manager: TaskManager
var _unit_manager: UnitManager
var _task_reached_state: bool = false

func setup(task_manager: TaskManager, unit_manager: UnitManager) -> void:
	_task_manager = task_manager
	_unit_manager = unit_manager
	# Connect signals from task_manager if needed
	# Example: _task_manager.task_updated.connect(_on_task_updated)

func check_task_progress() -> void:
	# Placeholder for checking individual task progress, not game win/loss
	pass

func is_task_reached() -> bool:
	return _task_reached_state

func reset_task_state() -> void:
	_task_reached_state = false

func create_memento() -> Dictionary:
	# Placeholder
	return {}

func restore_from_memento(memento: Dictionary) -> void:
	# Placeholder
	pass

func get_task(index: int) -> TargetTask:
	if _task_manager:
		return _task_manager.get_target_task_node(index)
	return null

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