class_name GoalDefinition
extends Resource

enum GoalType {
	COMMON,
	RARE
}

@export var title: String = "Goal"
@export var is_optional: bool = false
@export var goal_type: GoalType = GoalType.COMMON
@export var steps: Array[GoalStep] = []
@export var rewards: Array[GoalReward] = []
