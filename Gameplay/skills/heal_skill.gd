class_name HealSkill
extends Skill

@export var heal_amount: int = 5

func activate(user: Object, target: Variant) -> bool:
	if target is Node and target.is_in_group("unit"):
		apply_willpower_change(user, target, heal_amount, skill_name)
		return true
	return false
