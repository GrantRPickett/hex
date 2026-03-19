class_name Skill
extends Resource

## Skill properties
@export var skill_name: String = "New Skill"
@export var skill_icon: Texture2D
@export var skill_description: String = "A new skill."
@export var is_passive: bool = false

## Called when the skill is activated as an action.
##
## Should return `true` if the activation was successful, `false` otherwise.
##
## Params:
##	user: Object - The unit using the skill
##	target: Variant - The target of the skill, can be a Unit, Vector2i, etc.
func activate(user: Object, target: Variant) -> bool:
	push_error("Skill '" + skill_name + "' does not implement activate().")
	return false

## Called when the skill is added to a unit.
##
## This is called when the skill is first equipped, and can be used to apply
## initial effects.
func on_equip(user: Object) -> void:
	pass

## Called when the skill is removed from a unit.
##
## This is called when the skill is unequipped, and can be used to remove
## any lingering effects.
func on_unequip(user: Object) -> void:
	pass

func get_tooltip_text() -> String:
	return "[center][b]" + skill_name + "[/b][/center]\n" + skill_description


func apply_willpower_change(user: Object, target: Object, amount: int, action_name: String) -> void:
	if not "willpower" in target:
		return

	var old_willpower = target.willpower
	target.willpower += amount
	var willpower_change = target.willpower - old_willpower

	if willpower_change == 0:
		return

	var u_name = user.unit_name if "unit_name" in user else "User"
	var t_name = target.unit_name if "unit_name" in target else "Target"
	var formatted_text = "%s %s %s (%s WP)" % [u_name, action_name, t_name, ("+" if willpower_change > 0 else "") + str(willpower_change)]

