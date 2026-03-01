# Deprecated: This class has been renamed from GoalDefinition to TaskDefinition.
# The concept of a "goal" has been split into "location" and "task" terms.
# This file now represents a TaskDefinition.
class_name TaskDefinition
extends Resource

enum TaskType {
	INTERACT,
	MOVE,
	PICKUP,
	ABILITY_USED,
	DIALOGUE_STARTED,
	EXPLORE_ZONE,
	ELIMINATE,
	COUNTDOWN
}

@export var title: String = "Task" # Renamed from "Goal"
@export var is_optional: bool = false
@export var task_type: TaskType = TaskType.INTERACT
@export var rewards: Array[TaskReward] = []
