class_name CombatSystem
extends Node

signal attack_occurred(attacker: Unit, defender: Unit, results: Dictionary)
signal unit_defeated(unit: Unit, attacker: Unit)

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
	var validation = _validate_combatants(attacker, defender)
	if not validation.valid:
		print_debug("[CombatSystem] _execute_attack validation failed: ", validation.error)
		return {}

	var can_counter: bool = allow_counter and defender.res.has_reaction_available()

	var results = _simulate_attack(attacker, defender, pair_index, can_counter)

	# Apply damage (Willpower acts as HP)
	defender.willpower -= results.damage_to_target
	attacker.willpower -= results.counter_damage_to_self

	if defender and defender.faction == Unit.Faction.NEUTRAL and defender.has_method("handle_attack_from"):
		defender.loyalty.handle_attack_from(attacker)
	if attacker and attacker.faction == Unit.Faction.NEUTRAL and attacker.has_method("handle_attack_from") and results.counter_damage_to_self > 0:
		attacker.loyalty.handle_attack_from(defender)

	if can_counter:
		defender.res.consume_reaction()

	if consume_attacker_reaction and attacker.has_method("consume_reaction"):
		attacker.res.consume_reaction()

	attack_occurred.emit(attacker, defender, results)

	# Death is handled by Unit.willpower setter, but we emit for combat log/UI
	if defender.willpower <= 0:
		unit_defeated.emit(defender, attacker)

	if attacker.willpower <= 0:
		unit_defeated.emit(attacker, defender)

	return results

func get_combat_forecast(attacker: Target, defender: Target, pair_index: int) -> Dictionary:
	var validation = _validate_combatants(attacker, defender)
	if not validation.valid:
		return {}

	var can_counter := false
	if defender is Unit:
		can_counter = defender.res.has_reaction_available()

	return _simulate_attack(attacker, defender, pair_index, can_counter)

func get_attack_of_opportunity_forecast(attacker: Target, defender: Target, pair_index: int) -> Dictionary:
	var validation = _validate_combatants(attacker, defender)
	if not validation.valid:
		return {}

	return _simulate_attack(attacker, defender, pair_index, false)

func _validate_combatants(attacker: Target, defender: Target) -> Dictionary:
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return {"valid": false, "error": "Invalid attacker or defender."}
	return {"valid": true}

func _get_stat(unit: Target, pair_index: int, use_consumable: bool = true) -> int:
	if pair_index < 0 or pair_index >= PAIRS.size():
		push_error("[CombatSystem] _get_stat: Invalid pair_index %d" % pair_index)
		return 0

	var attrs = null
	var consumables = {}
	var aid_buffs = []

	if unit is Unit:
		attrs = unit.inv.get_attributes() if unit.inv else null
		consumables = unit.consumables_active
		aid_buffs = unit.aid_buffs
	else:
		attrs = unit # Target implements get_attribute directly

	if not attrs: return 0

	var pair = PAIRS[pair_index]
	var val_a = attrs.get_attribute(pair[0])
	var val_b = attrs.get_attribute(pair[1])

	var bonus = 0
	if use_consumable and consumables.has(pair_index):
		bonus = consumables[pair_index]

	var aid_bonus = 0
	if not aid_buffs.is_empty() and pair_index < aid_buffs.size():
		aid_bonus = aid_buffs[pair_index]

	var result = max(val_a, val_b) + bonus + aid_bonus
	return result

func _compute_defense(unit: Target, pair_index: int) -> float:
	if pair_index < 0 or pair_index >= PAIRS.size():
		push_error("[CombatSystem] _compute_defense: Invalid pair_index %d" % pair_index)
		return 0.0

	var attrs = null
	var aid_buffs = []

	if unit is Unit:
		attrs = unit.inv.get_attributes() if unit.inv else null
		aid_buffs = unit.aid_buffs
	else:
		attrs = unit

	if not attrs: return 0.0

	var pair = PAIRS[pair_index]
	var val_a = attrs.get_attribute(pair[0])
	var val_b = attrs.get_attribute(pair[1])

	var aid_bonus = 0
	if not aid_buffs.is_empty() and pair_index < aid_buffs.size():
		aid_bonus = aid_buffs[pair_index]

	return GameConstants.Combat.DEFENSE_MIN_WEIGHT * (min(val_a, val_b) + aid_bonus) + GameConstants.Combat.DEFENSE_MAX_WEIGHT * (max(val_a, val_b) + aid_bonus)

func _simulate_attack(attacker: Target, defender: Target, pair_index: int, can_counter: bool = true) -> Dictionary:
	var atk_val = float(_get_stat(attacker, pair_index, true))
	var def_val = float(_compute_defense(defender, pair_index))

	var damage = max(0, int(atk_val - def_val))

	# Counter attack: full stat, no consumables
	var counter_damage = 0
	if can_counter:
		var counter_val = float(_get_stat(defender, pair_index, false))
		var attacker_def = float(_compute_defense(attacker, pair_index))
		counter_damage = max(0, int(counter_val - attacker_def))

	return {
		"damage_to_target": damage,
		"counter_damage_to_self": counter_damage
	}
