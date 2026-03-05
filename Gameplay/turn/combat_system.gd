class_name CombatSystem
extends Node

signal attack_occurred(attacker: Unit, defender: Unit, results: Dictionary)
signal unit_defeated(unit: Unit)

const PAIRS = [
	[Target.COMBAT_ATTRIBUTE_NAMES[0], Target.COMBAT_ATTRIBUTE_NAMES[1]],
	[Target.COMBAT_ATTRIBUTE_NAMES[2], Target.COMBAT_ATTRIBUTE_NAMES[3]],
	[Target.COMBAT_ATTRIBUTE_NAMES[4], Target.COMBAT_ATTRIBUTE_NAMES[5]]
]

func execute_combat(attacker: Unit, defender: Unit, pair_index: int) -> Dictionary:
	return _execute_attack(attacker, defender, pair_index, true)

## Executes an attack of opportunity that cannot be countered.
func execute_attack_of_opportunity(attacker: Unit, defender: Unit, pair_index: int) -> Dictionary:
	print_debug("[Combat] execute_attack_of_opportunity: ", attacker.unit_name, " -> ", defender.unit_name)
	return _execute_attack(attacker, defender, pair_index, false, true)

func _execute_attack(attacker: Unit, defender: Unit, pair_index: int, allow_counter: bool, consume_attacker_reaction: bool = false) -> Dictionary:
	print_debug("[CombatSystem] _execute_attack called: Attacker=", attacker.unit_name, ", Defender=", defender.unit_name, ", allow_counter=", allow_counter, ", consume_attacker_reaction=", consume_attacker_reaction)
	var validation = _validate_combatants(attacker, defender)
	if not validation.valid:
		print_debug("[CombatSystem] _execute_attack validation failed: ", validation.error)
		return {}
	var attacker_attrs = validation.attacker_attrs
	var defender_attrs = validation.defender_attrs

	var can_counter: bool = allow_counter and defender.res.has_reaction_available()
	print_debug("[CombatSystem] Defender ", defender.unit_name, " has reaction available: ", defender.res.has_reaction_available(), ". Can counter: ", can_counter)

	var results = _simulate_attack(attacker_attrs, attacker.consumables_active, defender_attrs, pair_index, can_counter)

	print_debug("[CombatSystem] Attack results: ", results)
	# Apply damage (Willpower acts as HP)
	defender.willpower -= results.damage_to_target
	print_debug("[CombatSystem] Defender ", defender.unit_name, " willpower: ", defender.willpower)

	attacker.willpower -= results.counter_damage_to_self
	print_debug("[CombatSystem] Attacker ", attacker.unit_name, " willpower after counter: ", attacker.willpower)

	if defender and defender.faction == Unit.Faction.NEUTRAL and defender.has_method("handle_attack_from"):
		defender.loyalty.handle_attack_from(attacker)
	if attacker and attacker.faction == Unit.Faction.NEUTRAL and attacker.has_method("handle_attack_from") and results.counter_damage_to_self > 0:
		attacker.loyalty.handle_attack_from(defender)

	if can_counter:
		defender.res.consume_reaction()
		print_debug("[CombatSystem] Defender ", defender.unit_name, " consumed reaction.")

	if consume_attacker_reaction and attacker.has_method("consume_reaction"):
		attacker.res.consume_reaction()
		print_debug("[CombatSystem] Attacker ", attacker.unit_name, " consumed reaction for attack of opportunity.")

	attack_occurred.emit(attacker, defender, results)

	# Death is handled by Unit.willpower setter, but we emit for combat log/UI
	if defender.willpower <= 0:
		unit_defeated.emit(defender)

	if attacker.willpower <= 0:
		unit_defeated.emit(attacker)

	return results

func get_combat_forecast(attacker: Target, defender: Target, pair_index: int) -> Dictionary:
	var validation = _validate_combatants(attacker, defender)
	if not validation.valid:
		return {}
	var attacker_attrs = validation.attacker_attrs
	var defender_attrs = validation.defender_attrs

	var attacker_consumables = {}
	if attacker is Unit:
		attacker_consumables = attacker.consumables_active

	var can_counter := false
	if defender is Unit:
		can_counter = defender.res.has_reaction_available()

	return _simulate_attack(attacker_attrs, attacker_consumables, defender_attrs, pair_index, can_counter)

func get_attack_of_opportunity_forecast(attacker: Target, defender: Target, pair_index: int) -> Dictionary:
	var validation = _validate_combatants(attacker, defender)
	if not validation.valid:
		return {}
	var attacker_attrs = validation.attacker_attrs
	var defender_attrs = validation.defender_attrs

	var attacker_consumables = {}
	if attacker is Unit:
		attacker_consumables = attacker.consumables_active

	return _simulate_attack(attacker_attrs, attacker_consumables, defender_attrs, pair_index, false)

func _validate_combatants(attacker: Target, defender: Target) -> Dictionary:
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return {"valid": false, "error": "Invalid attacker or defender."}

	var attacker_attrs = null
	if attacker is Unit:
		attacker_attrs = attacker.inv.get_attributes() if attacker.inv else null
	else:
		attacker_attrs = attacker # Target implements get_attribute directly

	var defender_attrs = null
	if defender is Unit:
		defender_attrs = defender.inv.get_attributes() if defender.inv else null
	else:
		defender_attrs = defender # Target implements get_attribute directly

	if not attacker_attrs or not defender_attrs:
		return {"valid": false, "error": "Missing attributes on attacker or defender."}
	return {"valid": true, "attacker_attrs": attacker_attrs, "defender_attrs": defender_attrs}

func _get_stat(attrs, consumables: Dictionary, pair_index: int, use_consumable: bool = true) -> int:
	if pair_index < 0 or pair_index >= PAIRS.size():
		push_error("[CombatSystem] _get_stat: Invalid pair_index %d" % pair_index)
		return 0
	var pair = PAIRS[pair_index]
	var val_a = attrs.get_attribute(pair[0])
	var val_b = attrs.get_attribute(pair[1])

	print_debug("[CombatSystem] _get_stat: Pair %d (%s, %s). Values: %s=%d, %s=%d" % [pair_index, pair[0], pair[1], pair[0], val_a, pair[1], val_b])

	var bonus = 0
	if use_consumable and consumables.has(pair_index):
		bonus = consumables[pair_index]
		print_debug("[CombatSystem] _get_stat: Consumable bonus for pair %d: %d" % [pair_index, bonus])

	var result = max(val_a, val_b) + bonus
	print_debug("[CombatSystem] _get_stat: Final stat value for pair %d: %d" % [pair_index, result])
	return result

func _compute_defense(attrs, pair_index: int) -> float:
	if pair_index < 0 or pair_index >= PAIRS.size():
		push_error("[CombatSystem] _compute_defense: Invalid pair_index %d" % pair_index)
		return 0.0
	var pair = PAIRS[pair_index]
	var val_a = attrs.get_attribute(pair[0])
	var val_b = attrs.get_attribute(pair[1])

	return GameConstants.Combat.DEFENSE_MIN_WEIGHT * min(val_a, val_b) + GameConstants.Combat.DEFENSE_MAX_WEIGHT * max(val_a, val_b)

func _simulate_attack(attacker_attrs, attacker_consumables: Dictionary, defender_attrs, pair_index: int, can_counter: bool = true) -> Dictionary:
	var atk_val = float(_get_stat(attacker_attrs, attacker_consumables, pair_index, true))
	var def_val = float(_compute_defense(defender_attrs, pair_index))

	print_debug("[CombatSystem] _simulate_attack: Attacker effective ATK: %f, Defender effective DEF: %f" % [atk_val, def_val])

	var damage = max(0, int(atk_val - def_val))
	if damage == 0 and atk_val > 0:
		print_debug("[CombatSystem] _simulate_attack: Attack has no effect. ATK (%f) <= DEF (%f)" % [atk_val, def_val])
	print_debug("[CombatSystem] _simulate_attack: Raw damage to target: %d" % damage)

	# Counter attack: full stat, no consumables
	var counter_damage = 0
	if can_counter:
		var counter_val = float(_get_stat(defender_attrs, {}, pair_index, false))
		var attacker_def = float(_compute_defense(attacker_attrs, pair_index))
		print_debug("[CombatSystem] _simulate_attack: Defender effective Counter ATK: %f, Attacker effective Counter DEF: %f" % [counter_val, attacker_def])
		counter_damage = max(0, int(counter_val - attacker_def))
		if counter_damage == 0 and counter_val > 0:
			print_debug("[CombatSystem] _simulate_attack: Counter attack has no effect. Counter ATK (%f) <= DEF (%f)" % [counter_val, attacker_def])
		print_debug("[CombatSystem] _simulate_attack: Raw counter damage to attacker: %d" % counter_damage)

	return {
		"damage_to_target": damage,
		"counter_damage_to_self": counter_damage
	}
