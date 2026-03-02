class_name AIAction
extends RefCounted

## Represents a single candidate action the AI may take during its turn.
## Immutable by convention — evaluators construct and return these; the
## AIController selects the highest-scoring one.

var type: StringName
var target: Variant # Unit, Task, Vector2i, Dictionary — depends on type
var path: Array # Array[Vector2i] — empty when no movement is needed
var score: float

func _init(
		p_type: StringName,
		p_target: Variant,
		p_path: Array,
		p_score: float
) -> void:
	type = p_type
	target = p_target
	path = p_path
	score = p_score
