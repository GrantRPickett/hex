class_name UnitCombatBehavior
extends RefCounted

## Component responsible for unit combat actions including attacking and aiding allies.
##
## This component handles:
## - Attack logic with grid distance calculations
## - Ally aid functionality
## - Combat system integration
## - Action consumption for combat actions

var _unit # Unit (type hint removed to avoid circular dependency)
var _combat_system: CombatSystem

func _init(unit: Unit) -> void:
	_unit = unit

func set_combat_system(combat_system: CombatSystem) -> void:
	_combat_system = combat_system

## Attempts to attack the target unit.
## Returns true if the attack was successful, false otherwise.
func attack(target: Unit) -> bool:
	if not _unit.has_action_available():
		return false

	if target == null:
		return false

	if not _is_adjacent_to_target(target):
		return false

	if _combat_system == null:
		return false

	# TODO: Allow choosing which stat pair to use
	_combat_system.execute_combat(_unit, target, 0)
	_unit.consume_action()
	return true

## Attempts to aid an ally unit, restoring 1 willpower.
## Returns true if aid was successful, false otherwise.
func aid_ally(ally: Unit) -> bool:
	if not _unit.has_action_available():
		return false

	if ally == null or ally == _unit:
		return false

	if not _is_adjacent_to_target(ally):
		return false

	# Encouragement through a shared affinity
	# Restore willpower equal to the highest shared attribute (grit, flow, gusto, clarity, shine, temper)
	var user_attr: UnitAttributes = _unit.get_attributes()
	var ally_attr: UnitAttributes = ally.get_attributes()

	var max_shared := 0
	if user_attr and ally_attr:
		for attr in UnitAttributes.ATTRIBUTE_NAMES:
			var shared_val = min(user_attr.get_attribute(attr), ally_attr.get_attribute(attr))
			max_shared = max(max_shared, shared_val)
	else:
		# Fallback if attributes are missing for some reason
		max_shared = 1

	ally.willpower += max_shared

	_unit.consume_action()
	return true

## Private helper to check if target is adjacent to the unit
func _is_adjacent_to_target(target: Unit) -> bool:
	var adjacent_units: Array = _unit.get_adjacent_units([target])
	return adjacent_units.has(target)
