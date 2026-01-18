class_name CombatSystem
extends Node

signal attack_occurred(attacker: Unit, defender: Unit, results: Dictionary)
signal unit_defeated(unit: Unit)

const PAIRS = [
	["grit", "flow"],
	["gusto", "clarity"],
	["shine", "temper"]
]

func execute_combat(attacker: Unit, defender: Unit, pair_index: int) -> Dictionary:
	if not attacker or not defender:
		return {}

	var results = _simulate_attack(attacker, defender, pair_index)

	# Apply damage (Willpower acts as HP)
	defender.willpower -= results.damage_to_target
	defender.morale -= results.morale_to_target

	attacker.willpower -= results.counter_damage_to_self
	attacker.morale -= results.counter_morale_to_self

	attack_occurred.emit(attacker, defender, results)

	# Death is handled by Unit.willpower setter, but we emit for combat log/UI
	if defender.willpower <= 0:
		unit_defeated.emit(defender)

	if attacker.willpower <= 0:
		unit_defeated.emit(attacker)

	return results

func _get_stat(unit: Unit, pair_index: int, use_consumable: bool = true) -> int:
	var attrs = unit.get_attributes()
	if not attrs:
		return 0

	var pair = PAIRS[pair_index]
	var val_a = attrs.get_attribute(pair[0])
	var val_b = attrs.get_attribute(pair[1])

	var bonus = 0
	if use_consumable and unit.consumables_active.has(pair_index):
		bonus = unit.consumables_active[pair_index]

	return max(val_a, val_b) + bonus

func _compute_defense(unit: Unit, pair_index: int) -> float:
	var attrs = unit.get_attributes()
	if not attrs:
		return 0.0

	var pair = PAIRS[pair_index]
	var val_a = attrs.get_attribute(pair[0])
	var val_b = attrs.get_attribute(pair[1])

	return 0.34 * min(val_a, val_b) + 0.66 * max(val_a, val_b)

func _simulate_attack(attacker: Unit, defender: Unit, pair_index: int) -> Dictionary:
	var atk_val = _get_stat(attacker, pair_index, true)
	var def_val = _compute_defense(defender, pair_index)
	var damage = max(0, int(atk_val - def_val))
	var morale_damage = int(damage / 2.0)

	# Counter attack: full stat, no consumables
	var counter_val = _get_stat(defender, pair_index, false)
	var attacker_def = _compute_defense(attacker, pair_index)
	var counter_damage = max(0, int(counter_val - attacker_def))
	var counter_morale = int(counter_damage / 2.0)

	return {
		"damage_to_target": damage,
		"morale_to_target": morale_damage,
		"counter_damage_to_self": counter_damage,
		"counter_morale_to_self": counter_morale
	}