class_name Objective
extends Resource

signal objective_started
signal objective_updated(objective: Objective)
signal stage_transitioned(stage: Stage)
signal objective_completed
signal objective_failed
signal task_completed(task: Task, faction: int, unit: Unit)
signal task_failed(task: Task)
signal task_updated(task: Task, faction: int)

@export var objective_id: String = "" # New property for unique ID
@export var title: String = "Objective"
@export var description: String
@export var starting_stage: Stage
@export var stages: Array[Stage] = []
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

func handle_event(type: String, data: Dictionary) -> void:
	if is_active and current_stage:
		current_stage.handle_event(type, data)

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
		current_stage.end_stage()

	if not stage_res:
		_complete_objective()
		return

	# Duplicate stage to ensure unique state
	current_stage = stage_res.duplicate(true)
	current_stage.stage_completed.connect(_on_stage_completed)
	current_stage.stage_failed.connect(_fail_objective)
	if current_stage.has_signal("task_completed"):
		current_stage.task_completed.connect(func(task, faction, unit): task_completed.emit(task, faction, unit))
	if current_stage.has_signal("task_failed"):
		current_stage.task_failed.connect(func(task): task_failed.emit(task))
	if current_stage.has_signal("task_updated"):
		current_stage.task_updated.connect(func(task, faction): task_updated.emit(task, faction))

	current_stage.start_stage(tasks_to_carry)
	objective_updated.emit(self )
	stage_transitioned.emit(current_stage)

func _on_stage_completed(next_stage: Stage) -> void:
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
