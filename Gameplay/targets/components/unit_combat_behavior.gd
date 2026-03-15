class_name UnitCombatBehavior
extends RefCounted

## Component responsible for unit combat actions including attacking and aiding allies.
##
## This component handles:
## - Attack logic with grid distance calculations
## - Ally aid functionality
## - Combat system integration
## - Action consumption for combat actions

var _unit: Unit
# (type hint removed to avoid circular dependency)
var _combat_system: CombatSystem
const ATTACK_KEY := &"attack"

func _init(unit: Unit) -> void:
	_unit = unit

func set_combat_system(combat_system: CombatSystem) -> void:
	_combat_system = combat_system

## Attempts to attack the target unit.
## Returns true if the attack was successful, false otherwise.
func attack(target: Unit, attribute_index: int = 0) -> bool:
	var w: int = 0 # Optional: _unit.get_combat_profile().get_weight(ATTACK_KEY)
	print_debug("[CombatBehavior] ", _unit.unit_name, " attempting to attack ", target.unit_name, " (w=", w, ") . Action available: ", _unit.res.has_action_available())
	if not _unit.res.has_action_available():
		return false

	if target == null:
		print_debug("[CombatBehavior] Attack failed: Target is null.")
		return false

	if not _is_near_to_target(target):
		print_debug("[CombatBehavior] Attack failed: Not near to target.")
		return false

	if _combat_system == null:
		print_debug("[CombatBehavior] Attack failed: CombatSystem is null.")
		return false

	_combat_system.execute_combat(_unit, target, attribute_index)
	_unit.res.consume_action()
	print_debug("[CombatBehavior] ", _unit.unit_name, " consumed action. Action available now: ", _unit.res.has_action_available())
	return true

## Attempts to aid an ally unit.
## Returns true if aid was successful, false otherwise.
func aid_ally(ally: Unit, attribute_index: int = 0) -> bool:
	if not _unit.res.has_action_available():
		return false

	if ally == null or ally == _unit:
		return false

	if not _is_near_to_target(ally):
		return false

	# Encouragement scaling: floor(chosen_stat / 2)
	var val = _unit.get_attribute_by_index(attribute_index)
	var buff_value := int(floor(val / 2.0))

	# Grants a stacking Encourage bonus to the chosen combat pair for the next action.
	ally.add_aid_buff(buff_value, int(attribute_index / 2))

	_unit.res.consume_action()
	return true

## Private helper to check if target is near to the unit
func _is_near_to_target(target: Unit) -> bool:
	if _unit.query == null:
		return false
	var near_units: Array = _unit.query.get_near_units([target])
	var is_near: bool = near_units.has(target)
	print_debug("[CombatBehavior] ", _unit.unit_name, " adjacency check with ", target.unit_name, ": ", is_near)
	return is_near

