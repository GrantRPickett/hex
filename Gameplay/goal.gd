class_name Goal
extends Target

@export var required_attribute: String = "grit"
@export var required_amount: int = 100
@export var is_optional: bool = false

## Returns the coordinate as a Vector2i (from the Node2D position)
var coord: Vector2i:
	get:
		return get_grid_location()

func can_be_worked_on_by(unit: Unit, interaction_range: float = 0.5) -> bool:
	if not is_instance_valid(unit):
		return false
	return unit.distance_to_target(self) <= interaction_range
