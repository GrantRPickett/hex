# Deprecated: This class has been renamed from GoalDefinition to TaskDefinition.
# The concept of a "goal" has been split into "location" and "task" terms.
# This file now represents a TaskDefinition.
class_name TaskDefinition
extends Resource

enum TaskType {
	## Unopposed arrival at a location (triggers on-enter effects)
	VISIT,
	## Opposed effort task at a location (attribute check vs difficulty)
	EXPLORE,
	## Combat: eliminate an enemy unit
	FIGHT,
	## Persuade a neutral unit to switch sides
	CONVINCE,
	## Pick up an item (unopposed)
	LOOT,
	## Overcome a trap on an item (opposed)
	TRAPPED,
	## Use a specific ability
	ABILITY_USED,
	## Survive or hold for N rounds
	COUNTDOWN
}

@export var title: String = "Task"
@export var is_optional: bool = false
@export var task_type: TaskType = TaskType.VISIT
@export var rewards: Array[TaskReward] = []
