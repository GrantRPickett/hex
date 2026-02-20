class_name TaskReward
extends Resource

enum RewardType {
	ITEM,
	HINT,
	UNIT_ADDITION
}

@export var reward_type: RewardType = RewardType.ITEM
@export var reward_value: String = "" # ID of item, hint text key, or unit scene path
