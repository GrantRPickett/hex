class_name AIAction
extends BaseAction

## Represents a single candidate action the AI may take.
## Immutable by convention — evaluators construct and return these; 
## the AIController selects the highest-scoring one.

var score: float = 0.0

func _init(p_type: GameConstants.ActionType = GameConstants.ActionType.UNKNOWN, p_score: float = 0.0) -> void:
	super(p_type)
	score = p_score
