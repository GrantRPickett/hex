class_name CombatPriorityProfile
extends Resource

@export var priorities: Array[StringName] = [
	&"attack", &"finish_low_hp", &"protect_ally", &"objective", &"avoid_risk", &"flank", &"retreat"
]

# Fixed weights table; keys map to scoring lookups in combat behavior.
@export var weight_table: Dictionary = {
	"attack": 10,
	"finish_low_hp": 6,
	"protect_ally": 5,
	"objective": 5,
	"avoid_risk": 4,
	"flank": 3,
	"retreat": 2
}

func get_weight(key: StringName) -> int:
	var k := String(key)
	if weight_table.has(k):
		return int(weight_table[k])
	var idx := priorities.find(key)
	if idx == -1:
		return 0
	# Order-derived fallback: higher priority earlier → larger weight
	return (priorities.size() - idx)

