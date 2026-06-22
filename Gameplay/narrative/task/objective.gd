class_name Objective
extends Resource

signal objective_started
signal objective_updated(objective: Objective)
signal stage_transitioned(stage: Stage)
signal objective_completed
signal objective_failed
signal stage_completed(next_stage: Stage, completing_stage: Stage)
signal task_completed(task: Task, faction: int, unit: Target)
signal task_failed(task: Task)
signal task_updated(task: Task, faction: int)
 
@export var objective_id: String = "" # New property for unique ID
@export var title: String = "Objective"
@export var description: String
@export var starting_stage: Stage
@export var stages: Array[Stage] = []
@export var journal_entry_id: String = ""
var level: Level = null

# Runtime State
var current_stage: Stage
var is_active: bool = false

func _init(p_objective_id: String = "", p_title: String = "Objective", p_description: String = "", p_starting_stage: Stage = null, p_level: Level = null) -> void:
	objective_id = p_objective_id
	title = p_title
	description = p_description
	starting_stage = p_starting_stage
	level = p_level

func start_objective(level_resource: Level) -> void:
	is_active = true
	objective_started.emit()
	level = level_resource
	# Prioritize an explicitly set starting_stage, otherwise use the first
	# stage from the exported stages array. If neither exists, complete.
	if starting_stage:
		_transition_to_stage(starting_stage)
	elif stages and not stages.is_empty():
		_transition_to_stage(stages[0])
	else:
		# Immediate completion if no stages defined
		_complete_objective()

## Manually marks a task for carryover to the next stage.
func transplant_task(task_id: StringName) -> void:
	if not current_stage: return
	for task in current_stage.active_tasks:
		if task.id == task_id:
			task.carryover_to_next_stage = true
			break

func _transition_to_stage(stage_res: Stage) -> void:
	var tasks_to_carry: Array[Task] = []
	if current_stage:
		for task in current_stage.active_tasks:
			if task.carryover_to_next_stage and task.status == Task.Status.ACTIVE:
				tasks_to_carry.append(task)
		_disconnect_stage_signals(current_stage)
		current_stage.end_stage()

	if not stage_res:
		_complete_objective()
		return

	# Duplicate stage to ensure unique state
	current_stage = stage_res.duplicate(true)
	_connect_stage_signals(current_stage)

	current_stage.start_stage(tasks_to_carry)
	objective_updated.emit(self )
	stage_transitioned.emit(current_stage)

func _connect_stage_signals(stage: Stage) -> void:
	if not stage.stage_completed.is_connected(_on_stage_completed):
		stage.stage_completed.connect(_on_stage_completed)
	if not stage.stage_failed.is_connected(_fail_objective):
		stage.stage_failed.connect(_fail_objective)

	if stage.has_signal("task_completed"):
		if not stage.task_completed.is_connected(_on_task_completed_relay):
			stage.task_completed.connect(_on_task_completed_relay)
	if stage.has_signal("task_failed"):
		if not stage.task_failed.is_connected(_on_task_failed_relay):
			stage.task_failed.connect(_on_task_failed_relay)
	if stage.has_signal("task_updated"):
		if not stage.task_updated.is_connected(_on_task_updated_relay):
			stage.task_updated.connect(_on_task_updated_relay)

func _disconnect_stage_signals(stage: Stage) -> void:
	if stage.stage_completed.is_connected(_on_stage_completed):
		stage.stage_completed.disconnect(_on_stage_completed)
	if stage.stage_failed.is_connected(_fail_objective):
		stage.stage_failed.disconnect(_fail_objective)

	if stage.has_signal("task_completed"):
		if stage.task_completed.is_connected(_on_task_completed_relay):
			stage.task_completed.disconnect(_on_task_completed_relay)
	if stage.has_signal("task_failed"):
		if stage.task_failed.is_connected(_on_task_failed_relay):
			stage.task_failed.disconnect(_on_task_failed_relay)
	if stage.has_signal("task_updated"):
		if stage.task_updated.is_connected(_on_task_updated_relay):
			stage.task_updated.disconnect(_on_task_updated_relay)

func _on_task_completed_relay(task: Task, faction: int, unit: Target) -> void:
	task_completed.emit(task, faction, unit)

func _on_task_failed_relay(task: Task) -> void:
	task_failed.emit(task)

func _on_task_updated_relay(task: Task, faction: int) -> void:
	task_updated.emit(task, faction)

func _on_stage_completed(next_stage: Stage) -> void:
	stage_completed.emit(next_stage, current_stage)
	if next_stage:
		_transition_to_stage(next_stage)
	else:
		_complete_objective()

func _complete_objective() -> void:
	is_active = false
	objective_completed.emit()

func _fail_objective() -> void:
	is_active = false
	objective_failed.emit()

func handle_event(type: String, data: CombatResult) -> void:
	if current_stage:
		current_stage.handle_event(type, data)

func create_memento() -> Dictionary:
	return {
		"objective_id": objective_id,
		"is_active": is_active,
		"current_stage": current_stage.create_memento() if current_stage else {}
	}

func restore_from_memento(memento: Dictionary) -> void:
	is_active = memento.get("is_active", false)
	objective_id = memento.get("objective_id", "")
	var stage_data = memento.get("current_stage", {})
	if current_stage and not stage_data.is_empty():
		current_stage.restore_from_memento(stage_data)
