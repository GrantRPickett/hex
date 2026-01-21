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
##     user: Unit - The unit using the skill
##     target: Variant - The target of the skill, can be a Unit, Vector2i, etc.
func activate(user: Unit, target: Variant) -> bool:
	push_error("Skill '" + skill_name + "' does not implement activate().")
	return false

## Called when the skill is added to a unit.
##
## This is called when the skill is first equipped, and can be used to apply
## initial effects.
func on_equip(user: Unit) -> void:
	pass

## Called when the skill is removed from a unit.
##
## This is called when the skill is unequipped, and can be used to remove
## any lingering effects.
func on_unequip(user: Unit) -> void:
	pass

func get_tooltip_text() -> String:
	return "[center][b]" + skill_name + "[/b][/center]\n" + skill_description