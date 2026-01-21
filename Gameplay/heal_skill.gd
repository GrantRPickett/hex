class_name HealSkill
extends Skill

@export var heal_amount: int = 5

func activate(user: Unit, target: Variant) -> bool:
	if target is Unit:
		target.willpower += heal_amount
		return true
	return false