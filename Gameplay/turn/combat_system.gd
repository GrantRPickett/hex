class_name CombatSystem
extends Node

## Helper for typed suffix results
class ActionSuffixes:
	var near: String = ""
	var far: String = ""

signal attack_occurred(attacker: Unit, defender: Target, results: Dictionary)
signal unit_defeated(unit: Unit, attacker: Unit)

const PAIRS = GameConstants.Combat.COMBAT_ATTRIBUTE_PAIRS

var _forecast_cache: Dictionary = {}
var _best_quality_cache: Dictionary = {}

func _ready() -> void:
	if EventBus:
		EventBus.turn_changed.connect(_on_turn_changed)
		EventBus.unit_attributes_changed.connect(_on_unit_attributes_changed)

## Performs a standard interaction (Combat or Task) between unit and target.
func execute_combat(results: CombatResult) -> CombatResult:
	return _execute_attack(results)

## Performs a counter-attack or reactive strike.
func execute_attack_of_opportunity(results: CombatResult) -> CombatResult:
	GameLogger.debug(GameLogger.Category.COMBAT, "[Combat] execute_attack_of_opportunity: ", results.attacker.unit_name, " -> ", results.defender.name)
	results.type = GameConstants.Activity.FIGHT
	return _execute_attack(results)

func _execute_attack(results: CombatResult) -> CombatResult:
	if results == null:
		push_error("[CombatSystem] _execute_attack: Must provide precomputed_results. Forecast first!")
		return null

	if not _validate_combatants(results.attacker, results.defender):
		GameLogger.debug(GameLogger.Category.COMBAT, "[CombatSystem] _execute_attack validation failed")
		return null

	var is_convince: bool = results.type == GameConstants.Activity.CONVINCE

	_apply_damage(results)
	if is_convince:
		_apply_loyalty(results)

	_emit_attack_events(results)
	# State changed, clear caches
	_forecast_cache.clear()
	_best_quality_cache.clear()

	return results

func _apply_damage(results: CombatResult) -> void:
	var is_social = results.type == GameConstants.Activity.CONVINCE
	if results.damage > 0:
		change_willpower(results.defender, results.damage, results.attacker, is_social)
	if results.counter_damage > 0:
		_consume_reaction(results.attacker, results.defender, results.counter_damage, is_social)

func change_willpower(target: Target, damage: int, attacker: Unit, is_social: bool = false) -> void:
	target.set_willpower(target.get_current_willpower() - damage)
	if not is_social and target is Unit and target.loyalty.faction == GameConstants.Faction.NEUTRAL:
		target.loyalty.handle_attack_from(attacker)

func _consume_reaction(attacker: Unit, defender: Unit, counter_damage: int, is_social: bool = false) -> void:
	# Units spend reaction but traps and hazards always "react"
	if defender is Unit and defender.res.has_reaction_available():
		defender.res.consume_reaction()
		change_willpower(attacker, counter_damage, defender, is_social)
	else:
		change_willpower(attacker, counter_damage, defender, is_social)
	# Revisit design later maybe locations reactions are pass through or end of turn damage
	# Also maybe traps only react 1 time ever?

func _apply_loyalty(results: CombatResult) -> void:
	var defender = results.defender
	if not (defender is Unit and defender.faction == GameConstants.Faction.NEUTRAL):
		return

	var threshold := _get_half_willpower(defender)
	var current_wp := defender.get_current_willpower()
	# Loyalty changes when WP drops to or below half (and unit isn't defeated)
	# Note: current_wp has already been reduced by _apply_damage()
	if current_wp > 0 and current_wp <= threshold:
		defender.loyalty.apply_persuasion(results.attacker.faction)

func _emit_attack_events(results: CombatResult) -> void:
	var attacker = results.attacker
	var defender = results.defender
	if defender is Unit:
		attack_occurred.emit(attacker, defender, results.to_dict()) # Signals still use dict for now

	if EventBus:
		if results.attribute_index != -1:
			EventBus.combat_action_performed.emit(attacker, defender, results.attribute_index, results)

		EventBus.unit_attacked.emit(attacker, defender)
		if results.damage > 0:
			EventBus.unit_damaged.emit(defender, results.damage, attacker)
		if results.counter_damage > 0:
			EventBus.unit_damaged.emit(attacker, results.counter_damage, defender)

	if defender.get_current_willpower() <= 0:
		if defender is Unit:
			unit_defeated.emit(defender, attacker)
		elif defender is Location:
			defender.claimer_faction = attacker.faction
			defender.is_explored = true

	if attacker is Unit and attacker.get_current_willpower() <= 0:
		unit_defeated.emit(attacker, defender)

func _validate_combatants(attacker: Target, defender: Target) -> bool:
	return is_instance_valid(attacker) and is_instance_valid(defender)

func _get_stat(unit: Target, attribute_index: int) -> int:
	if attribute_index < 0 or attribute_index >= GameConstants.COMBAT_ATTRIBUTE_INDICES.size():
		return 0
	var attr_idx := attribute_index as GameConstants.AttributeIndex
	if unit is Unit and unit.query:
		return unit.query.get_total_attribute(attr_idx)
	return unit.get_attribute_by_index(attr_idx)

func _compute_defense(target: Target, attribute_index: int) -> int:
	if attribute_index < 0 or attribute_index >= GameConstants.COMBAT_ATTRIBUTE_INDICES.size():
		return 0

	var pair_index: int = int(attribute_index) >> 1
	var pair = PAIRS[pair_index]
	var attr_is_first: bool = attribute_index == pair[0]
	var attr_idx: int = pair[0] if attr_is_first else pair[1]
	var paired_idx: int = pair[1] if attr_is_first else pair[0]

	var val_attr: float = 0.0
	var val_paired: float = 0.0

	if target is Unit and target.query:
		val_attr = float(target.query.get_total_attribute(attr_idx))
		val_paired = float(target.query.get_total_attribute(paired_idx))
	else:
		val_attr = float(target.get_attribute_by_index(attr_idx))
		val_paired = float(target.get_attribute_by_index(paired_idx))

	return int(GameConstants.Combat.DEFENSE_MIN_WEIGHT * val_paired + GameConstants.Combat.DEFENSE_MAX_WEIGHT * val_attr)

func _simulate_attack(attacker: Target, defender: Target, attribute_index: int, interaction_type: String = "") -> CombatResult:
	var cache_key := _get_cache_key(attacker, defender, attribute_index, interaction_type)
	if _forecast_cache.has(cache_key):
		return _forecast_cache[cache_key]
	var damage: int = _calculate_raw_damage(attacker, defender, attribute_index)

	if interaction_type == GameConstants.Activity.CONVINCE:
		damage = _clamp_social_damage(defender, damage)

	var is_opposed := interaction_type in [GameConstants.Activity.FIGHT, GameConstants.Activity.TRAPPED, GameConstants.Activity.EXPLORE]
	var counter_damage: int = 0

	#TODO will Units save instead of waste reaction AoO? difficulty?
	if is_opposed and defender.has_method("has_reaction") and defender.has_reaction():
		counter_damage = _calculate_raw_damage(defender, attacker, attribute_index)

	var result = CombatResult.new()
	result.attacker = attacker
	result.defender = defender
	result.damage = max(0, damage)
	result.counter_damage = max(0, counter_damage)
	result.type = interaction_type
	result.is_opposed = is_opposed
	result.attribute_index = attribute_index

	_forecast_cache[cache_key] = result
	return result

func _calculate_raw_damage(attacker: Target, defender: Target, attribute_index: int) -> int:
	var atk_val := _get_stat(attacker, attribute_index)
	var def_val := _compute_defense(defender, attribute_index)
	# Ensure damage is never negative (clamped to 0 minimum)
	return max(0, atk_val - def_val)

func _clamp_social_damage(defender: Target, damage: int) -> int:
	var threshold: int = _get_half_willpower(defender)
	var current_wp = defender.get_current_willpower()
	var proposed_wp: int = current_wp - damage

	# Only clamp if we're crossing threshold from above going below
	# If already below threshold, apply full damage
	if current_wp >= threshold and proposed_wp < threshold:
		# Clamp damage so final WP = exactly threshold
		return current_wp - threshold

	return damage

func _get_cache_key(attacker: Target, defender: Target, attr: int, interaction_type: String) -> String:
	return "%d_%d_%d_%s" % [attacker.get_instance_id(), defender.get_instance_id(), attr, interaction_type]

func _on_turn_changed(_num: int, _side: int) -> void:
	_forecast_cache.clear()
	_best_quality_cache.clear()

func _on_unit_attributes_changed(_unit: Unit) -> void:
	_forecast_cache.clear()
	_best_quality_cache.clear()

## Helper to consistently calculate half willpower (with proper bitshift handling for odd numbers)
func _get_half_willpower(target: Target) -> int:
	return target.get_max_willpower() >> 1

func get_aid_bonus(unit: Unit, attribute_index: int) -> int:
	if not is_instance_valid(unit): return 0
	return _get_stat(unit, attribute_index) >> 1

## Evaluates the quality of an interaction from a forecast result.
func get_attack_quality(results: CombatResult) -> GameConstants.Combat.AttackQuality:
	var target = results.defender
	var interaction_type = results.type

	var threshold: int = int(target.get_current_willpower())
	if interaction_type == GameConstants.Activity.CONVINCE and target is Unit and target.faction == GameConstants.Faction.NEUTRAL:
		threshold = _get_half_willpower(target)

	var quality := _interpret_quality(results, threshold)
	results.quality = quality # Store it back in the forecast object
	return quality

func _interpret_quality(results: CombatResult, threshold: int) -> GameConstants.Combat.AttackQuality:
	var progress = results.damage
	var counter_damage = results.counter_damage
	var actor_willpower = results.attacker.get_current_willpower() if results.attacker else 0

	var is_dangerous: bool = counter_damage >= actor_willpower and counter_damage > 0
	if progress >= threshold and progress > 0:
		return GameConstants.Combat.AttackQuality.RISKY if is_dangerous else GameConstants.Combat.AttackQuality.SUCCESS
	if progress > counter_damage:
		return GameConstants.Combat.AttackQuality.RISKY if is_dangerous else GameConstants.Combat.AttackQuality.PROGRESS
	if progress > 0: return GameConstants.Combat.AttackQuality.RISKY
	if counter_damage > 0: return GameConstants.Combat.AttackQuality.INEFFECTIVE
	return GameConstants.Combat.AttackQuality.IDLE

func get_quality_symbol(quality: GameConstants.Combat.AttackQuality) -> String:
	match quality:
		GameConstants.Combat.AttackQuality.SUCCESS: return GameConstants.UI.Indicators.SUCCESS
		GameConstants.Combat.AttackQuality.PROGRESS: return GameConstants.UI.Indicators.PROGRESS
		GameConstants.Combat.AttackQuality.RISKY: return GameConstants.UI.Indicators.RISKY
		GameConstants.Combat.AttackQuality.IDLE: return GameConstants.UI.Indicators.IDLE
		_: return GameConstants.UI.Indicators.INEFFECTIVE

func get_target_status_symbol(actor: Unit, target: Target, interaction_type: String = "") -> String:
	if not is_instance_valid(actor) or not is_instance_valid(target): return ""
	var cache_key = "%d_%d_%s" % [actor.get_instance_id(), target.get_instance_id(), interaction_type]
	if _best_quality_cache.has(cache_key): return get_quality_symbol(_best_quality_cache[cache_key])

	var best_quality := GameConstants.Combat.AttackQuality.INEFFECTIVE
	for i in range(6):
		var res = _simulate_attack(actor, target, i, interaction_type)
		var q = get_attack_quality(res)
		if q > best_quality:
			best_quality = q
			if best_quality == GameConstants.Combat.AttackQuality.SUCCESS: break
	_best_quality_cache[cache_key] = best_quality
	return get_quality_symbol(best_quality)

func get_action_suffixes(actor: Unit, near_targets: Array[Target], far_targets: Array[Target], interaction_type: String = "") -> ActionSuffixes:
	var res := ActionSuffixes.new()
	if not is_instance_valid(actor): return res
	res.near = get_group_status_suffix(actor, near_targets, interaction_type)
	res.far = get_group_status_suffix(actor, far_targets, interaction_type)
	return res

func get_group_status_suffix(attacker: Unit, targets: Array[Target], interaction_type: String = "") -> String:
	if targets.is_empty(): return ""
	var symbols := {}
	for t in targets:
		if is_instance_valid(t): symbols[get_target_status_symbol(attacker, t, interaction_type)] = true
	if symbols.is_empty(): return ""
	var list = symbols.keys()
	list.sort_custom(func(a, b):
		var order := {&"★": 0, &"▲": 1, &"◆": 2, &"●": 3, &"▼": 4}
		return order.get(a, 9) < order.get(b, 9)
	)
	return list[0]

func get_preview_forecast(actor: Unit, target: Target, attr_idx: int = -1, interaction_type: String = "") -> CombatResult:
	if not is_instance_valid(actor) or not is_instance_valid(target): return null
	var i = attr_idx if attr_idx != -1 else actor.get_best_attribute_index()
	var sim = _simulate_attack(actor, target, i, interaction_type)

	return sim
