class_name Goal
extends Target

@export var definition: GoalDefinition
@export var required_attribute: String = "grit" ## Deprecated: Use definition
@export var required_amount: int = 10 ## Deprecated: Use definition
@export var is_optional: bool = false ## Deprecated: Use definition

## Returns the coordinate as a Vector2i (from the Node2D position)
var coord: Vector2i:
	get:
		return get_grid_location()

func _ready() -> void:
	if not definition:
		_create_default_definition()

func _create_default_definition() -> void:
	definition = GoalDefinition.new()
	definition.title = "Goal"
	definition.is_optional = is_optional
	definition.goal_type = GoalDefinition.GoalType.COMMON

	var step = GoalStep.new()
	step.step_name = "Objective"
	step.description = "Complete the objective"
	step.required_attribute = required_attribute
	step.required_amount = required_amount
	definition.steps.append(step)

func can_be_worked_on_by(unit: Unit, interaction_range: float = 0.5) -> bool:
	if not is_instance_valid(unit):
		return false
	return unit.distance_to_target(self) <= interaction_range

func get_hover_info() -> String:
	var info_text = "Goal: " + definition.title
	if definition and not definition.steps.is_empty():
		info_text += "\nObjective: " + definition.steps[0].description
	return info_text
