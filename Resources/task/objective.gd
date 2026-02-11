class_name Objective
extends Resource

signal objective_started
signal objective_updated(current_stage: Stage)
signal objective_completed
signal objective_failed

@export var title: String = "Objective"
@export var description: String
@export var starting_stage: Stage

# Runtime State
var current_stage: Stage
var is_active: bool = false
var _context_target: Unit = null

func start_objective(target: Unit = null) -> void:
	_context_target = target
	is_active = true
	objective_started.emit()

	if starting_stage:
		_transition_to_stage(starting_stage)
	else:
		# Immediate completion if no stages defined
		objective_completed.emit()

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