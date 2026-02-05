class_name CombatSystem
extends Node

signal attack_occurred(attacker: Unit, defender: Unit, results: Dictionary)
signal unit_defeated(unit: Unit)

const PAIRS = [
	["grit", "flow"],
	["gusto", "focus"],
	["shine", "shade"]
]

func execute_combat(attacker: Unit, defender: Unit, pair_index: int) -> Dictionary:
	if not attacker or not defender:
		return {}

	var attacker_attrs = attacker.get_attributes()
	var defender_attrs = defender.get_attributes()

	if not attacker_attrs or not defender_attrs:
		return {}

	var results = _simulate_attack(attacker_attrs, attacker.consumables_active, defender_attrs, pair_index)

	# Apply damage (Willpower acts as HP)
	defender.willpower -= results.damage_to_target

	attacker.willpower -= results.counter_damage_to_self

	if defender and defender.faction == Unit.Faction.NEUTRAL and defender.has_method("handle_attack_from"):
		defender.handle_attack_from(attacker)
	if attacker and attacker.faction == Unit.Faction.NEUTRAL and attacker.has_method("handle_attack_from") and results.counter_damage_to_self > 0:
		attacker.handle_attack_from(defender)

	attack_occurred.emit(attacker, defender, results)

	# Death is handled by Unit.willpower setter, but we emit for combat log/UI
	if defender.willpower <= 0:
		unit_defeated.emit(defender)

	if attacker.willpower <= 0:
		unit_defeated.emit(attacker)

	return results

func get_combat_forecast(attacker: Unit, defender: Unit, pair_index: int) -> Dictionary:
	if not attacker or not defender:
		return {}

	var attacker_attrs = attacker.get_attributes()
	var defender_attrs = defender.get_attributes()

	if not attacker_attrs or not defender_attrs:
		return {}

	return _simulate_attack(attacker_attrs, attacker.consumables_active, defender_attrs, pair_index)

func _get_stat(attrs, consumables: Dictionary, pair_index: int, use_consumable: bool = true) -> int:
	var pair = PAIRS[pair_index]
	var val_a = attrs.get_attribute(pair[0])
	var val_b = attrs.get_attribute(pair[1])

	var bonus = 0
	if use_consumable and consumables.has(pair_index):
		bonus = consumables[pair_index]

	return max(val_a, val_b) + bonus

func _compute_defense(attrs, pair_index: int) -> float:
	var pair = PAIRS[pair_index]
	var val_a = attrs.get_attribute(pair[0])
	var val_b = attrs.get_attribute(pair[1])

	return 0.34 * min(val_a, val_b) + 0.66 * max(val_a, val_b)

func _simulate_attack(attacker_attrs, attacker_consumables: Dictionary, defender_attrs, pair_index: int) -> Dictionary:
	var atk_val = float(_get_stat(attacker_attrs, attacker_consumables, pair_index, true))
	var def_val = float(_compute_defense(defender_attrs, pair_index))

	var damage = max(0, int(atk_val - def_val))

	# Counter attack: full stat, no consumables
	var counter_val = float(_get_stat(defender_attrs, {}, pair_index, false))
	var attacker_def = float(_compute_defense(attacker_attrs, pair_index))
	var counter_damage = max(0, int(counter_val - attacker_def))

	return {
		"damage_to_target": damage,
		"counter_damage_to_self": counter_damage
	}
