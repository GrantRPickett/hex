class_name CombatResult
extends RefCounted

var attacker: Unit = null
var defender: Target = null
var damage: int = 0
var counter_damage: int = 0
var type: String = ""
var is_opposed: bool = false
var quality: GameConstants.Combat.AttackQuality = GameConstants.Combat.AttackQuality.IDLE
var attribute_index: int = -1

func to_dict() -> Dictionary:
	return {
		"damage": damage,
		"counter_damage": counter_damage,
		"type": type,
		"is_opposed": is_opposed,
		"quality": quality,
		"attribute_index": attribute_index,
		"actor_faction": get_actor_faction(),
		"target_faction": get_target_faction()
	}

static func from_dict(dict: Dictionary) -> CombatResult:
	var res = CombatResult.new()
	if dict.is_empty(): return res
	res.attacker = dict.get("attacker")
	res.defender = dict.get("defender")
	res.damage = dict.get("damage", 0)
	res.counter_damage = dict.get("counter_damage", 0)
	res.type = dict.get("type", "")
	res.is_opposed = dict.get("is_opposed", false)
	res.quality = dict.get("quality", GameConstants.Combat.AttackQuality.IDLE)
	res.attribute_index = dict.get("attribute_index", -1)
	return res

func is_equal(other: CombatResult) -> bool:
	if other == null: return false
	return (
		attacker == other.attacker and
		defender == other.defender and
		damage == other.damage and
		counter_damage == other.counter_damage and
		type == other.type and
		is_opposed == other.is_opposed and
		quality == other.quality and
		attribute_index == other.attribute_index
	)

func get_actor_faction() -> int:
	if is_instance_valid(attacker):
		return attacker.get_effective_faction()
	return GameConstants.INVALID_INDEX

func get_target_faction() -> int:
	if is_instance_valid(defender) and (defender is Unit or defender.has_method("get_effective_faction")):
		return defender.get_effective_faction()
	return GameConstants.INVALID_INDEX
