class_name CombatSystem
extends Node

signal attack_occurred(attacker: Unit, defender: Unit, results: Dictionary)
signal unit_defeated(unit: Unit, attacker: Unit)

const PAIRS = GameConstants.Combat.COMBAT_ATTRIBUTE_PAIRS

func execute_combat(attacker: Unit, defender: Unit, attribute_index: int) -> Dictionary:
	return _execute_attack(attacker, defender, attribute_index, true)

## Executes an attack of opportunity that cannot be countered.
func execute_attack_of_opportunity(attacker: Unit, defender: Unit, attribute_index: int) -> Dictionary:
	print_debug("[Combat] execute_attack_of_opportunity: ", attacker.unit_name, " -> ", defender.unit_name)
	return _execute_attack(attacker, defender, attribute_index, false, true)

func _execute_attack(attacker: Unit, defender: Unit, attribute_index: int, allow_counter: bool, consume_attacker_reaction: bool = false) -> Dictionary:
	var validation = _validate_combatants(attacker, defender)
	if not validation.valid:
		print_debug("[CombatSystem] _execute_attack validation failed: ", validation.error)
		return {}

	var can_counter: bool = allow_counter and defender.res.has_reaction_available()

	var results = _simulate_attack(attacker, defender, attribute_index, can_counter)

	_apply_damage_and_loyalty(attacker, defender, results)
	_consume_reactions(attacker, defender, can_counter, consume_attacker_reaction)
	_emit_attack_events(attacker, defender, results)

	return results

func _apply_damage_and_loyalty(attacker: Unit, defender: Unit, results: Dictionary) -> void:
	defender.willpower -= results.damage_to_target
	attacker.willpower -= results.counter_damage_to_self

	if defender and defender.faction == GameConstants.Faction.NEUTRAL and defender.has_method("handle_attack_from"):
		defender.loyalty.handle_attack_from(attacker)
	if attacker and attacker.faction == GameConstants.Faction.NEUTRAL and attacker.has_method("handle_attack_from") and results.counter_damage_to_self > 0:
		attacker.loyalty.handle_attack_from(defender)

func _consume_reactions(attacker: Unit, defender: Unit, can_counter: bool, consume_attacker_reaction: bool) -> void:
	if can_counter:
		defender.res.consume_reaction()

	if consume_attacker_reaction and attacker.has_method("consume_reaction"):
		attacker.res.consume_reaction()

func _emit_attack_events(attacker: Unit, defender: Unit, results: Dictionary) -> void:
	attack_occurred.emit(attacker, defender, results)

	if EventBus:
		EventBus.unit_attacked.emit(attacker, defender)
		if results.damage_to_target > 0:
			EventBus.unit_damaged.emit(defender, results.damage_to_target, attacker)
		if results.counter_damage_to_self > 0:
			EventBus.unit_damaged.emit(attacker, results.counter_damage_to_self, defender)

	# Death is handled by Unit.willpower setter, but we emit for combat log/UI
	if defender.willpower <= 0:
		unit_defeated.emit(defender, attacker)
		if EventBus: EventBus.unit_died.emit(defender)

	if attacker.willpower <= 0:
		unit_defeated.emit(attacker, defender)
		if EventBus: EventBus.unit_died.emit(attacker)


func get_combat_forecast(attacker: Target, defender: Target, attribute_index: int) -> Dictionary:
	var validation = _validate_combatants(attacker, defender)
	if not validation.valid:
		return {}

	var can_counter := false
	if defender is Unit:
		can_counter = defender.res.has_reaction_available()

	return _simulate_attack(attacker, defender, attribute_index, can_counter)

## Returns the best forecast for a given combat pair (Grit/Flow, etc).
func get_combat_pair_forecast(attacker: Target, defender: Target, pair_index: int) -> Dictionary:
	if pair_index < 0 or pair_index >= PAIRS.size():
		return {}

	var pair = PAIRS[pair_index]
	var forecast_a = get_combat_forecast(attacker, defender, pair[0])
	var forecast_b = get_combat_forecast(attacker, defender, pair[1])

	if forecast_a.get("damage_to_target", 0) >= forecast_b.get("damage_to_target", 0):
		return forecast_a
	return forecast_b

func get_attack_of_opportunity_forecast(attacker: Target, defender: Target, attribute_index: int) -> Dictionary:
	var validation = _validate_combatants(attacker, defender)
	if not validation.valid:
		return {}

	return _simulate_attack(attacker, defender, attribute_index, false)

func _validate_combatants(attacker: Target, defender: Target) -> Dictionary:
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return {"valid": false, "error": "Invalid attacker or defender."}
	return {"valid": true}

func _get_stat(unit: Target, attribute_index: int) -> int:
	if attribute_index < 0 or attribute_index >= GameConstants.COMBAT_ATTRIBUTE_INDICES.size():
		push_error("[CombatSystem] _get_stat: Invalid attribute_index %d" % attribute_index)
		return 0

	var attr_idx := attribute_index as GameConstants.AttributeIndex

	if unit is Unit and unit.query:
		return unit.query.get_total_attribute(attr_idx)

	return unit.get_attribute_by_index(attr_idx)

func _compute_defense(unit: Target, attribute_index: int) -> float:
	if attribute_index < 0 or attribute_index >= GameConstants.COMBAT_ATTRIBUTE_INDICES.size():
		push_error("[CombatSystem] _compute_defense: Invalid attribute_index %d" % attribute_index)
		return 0.0

	var pair_index: int = int(attribute_index) >> 1
	var pair = PAIRS[pair_index]

	var val_a: int = 0
	var val_b: int = 0

	if unit is Unit and unit.query:
		val_a = unit.query.get_total_attribute(pair[0])
		val_b = unit.query.get_total_attribute(pair[1])
	else:
		val_a = unit.get_attribute_by_index(pair[0])
		val_b = unit.get_attribute_by_index(pair[1])

	return GameConstants.Combat.DEFENSE_MIN_WEIGHT * min(val_a, val_b) + GameConstants.Combat.DEFENSE_MAX_WEIGHT * max(val_a, val_b)

func _simulate_attack(attacker: Target, defender: Target, attribute_index: int, can_counter: bool = true) -> Dictionary:
	var atk_val: float = float(_get_stat(attacker, attribute_index))
	var def_val: float = float(_compute_defense(defender, attribute_index))

	var damage: int = max(0, int(atk_val - def_val))

	print_debug("[CombatSim] Attacker: %s, Defender: %s, Attr: %d, Atk: %.2f, Def: %.2f, Dmg: %d" % [attacker.unit_name if "unit_name" in attacker else "Target", defender.unit_name if "unit_name" in defender else "Target", attribute_index, atk_val, def_val, damage])

	# Counter attack: full stat, no consumables
	var counter_damage: int = 0
	if can_counter:
		var counter_val: float = float(_get_stat(defender, attribute_index))
		var attacker_def: float = float(_compute_defense(attacker, attribute_index))
		counter_damage = max(0, int(counter_val - attacker_def))

	return {
		"damage_to_target": damage,
		"counter_damage_to_self": counter_damage
	}
