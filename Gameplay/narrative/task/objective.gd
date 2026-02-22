class_name Objective
extends Resource

signal objective_started
signal objective_updated(current_stage: Stage)
signal objective_completed
signal objective_failed

@export var objective_id: String = "" # New property for unique ID
@export var title: String = "Objective"
@export var description: String
@export var starting_stage: Stage
@export var stages: Array[Stage] = []

# Runtime State
var current_stage: Stage
var is_active: bool = false
var _context_target: Unit = null

func _init(p_objective_id: String = "", p_title: String = "Objective", p_description: String = "", p_starting_stage: Stage = null) -> void:
	objective_id = p_objective_id
	title = p_title
	description = p_description
	starting_stage = p_starting_stage

func start_objective(target: Unit = null) -> void:
	_context_target = target
	is_active = true
	objective_started.emit()

	# Prioritize an explicitly set starting_stage, otherwise use the first
	# stage from the exported stages array. If neither exists, complete.
	if starting_stage:
		_transition_to_stage(starting_stage)
	elif stages and not stages.is_empty():
		_transition_to_stage(stages[0])
	else:
		# Immediate completion if no stages defined
		objective_completed.emit()

func handle_event(type: String, data: Dictionary) -> void:
	if is_active and current_stage:
		current_stage.handle_event(type, data)

func _transition_to_stage(stage_res: Stage) -> void:
	if current_stage:
		current_stage.end_stage()

	if not stage_res:
		objective_completed.emit()
		return

	# Duplicate stage to ensure unique state
	current_stage = stage_res.duplicate(true)
	current_stage.stage_completed.connect(_on_stage_completed)
	current_stage.stage_failed.connect(func(): objective_failed.emit())

	current_stage.start_stage(_context_target)
	objective_updated.emit(current_stage)

func _on_stage_completed(next_stage: Stage) -> void:
	if next_stage:
		_transition_to_stage(next_stage)
	else:
		objective_completed.emit()
