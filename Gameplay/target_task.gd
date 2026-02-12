class_name TargetTask
extends Target

@export var definition: TaskDefinition

## Returns the coordinate as a Vector2i (from the Node2D position)
var coord: Vector2i:
	get:
		return get_grid_location()

func _ready() -> void:
	if not definition:
		_create_default_definition()

func _create_default_definition() -> void:
	definition = TaskDefinition.new()
	definition.title = "Target Task" # Changed from "location"
	definition.task_type = TaskDefinition.TaskType.COMMON

	var step = TaskStep.new()
	step.step_name = "Objective"
	step.description = "Complete the objective"
	definition.steps.append(step)

func can_be_worked_on_by(unit: Unit, interaction_range: float = 0.5) -> bool:
	if not is_instance_valid(unit):
		return false
	return unit.distance_to_target(self) <= interaction_range

func get_hover_info() -> String:
	var info_text = "location: " + definition.title
	if definition and not definition.steps.is_empty():
		info_text += "\nObjective: " + definition.steps[0].description
	return info_text
