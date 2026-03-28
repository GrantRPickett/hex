class_name CombatSystem
extends Node

## Helper for typed suffix results
class ActionSuffixes:
	var near: String = ""
	var far: String = ""

signal attack_occurred(attacker: Unit, defender: Unit, results: Dictionary)
signal unit_defeated(unit: Unit, attacker: Unit)

const PAIRS = GameConstants.Combat.COMBAT_ATTRIBUTE_PAIRS

var _forecast_cache: Dictionary = {}
var _best_quality_cache: Dictionary = {}

func _ready() -> void:
	if EventBus:
		EventBus.turn_changed.connect(_on_turn_changed)

## Performs a standard interaction (Combat or Task) between unit and target.
func execute_combat(attacker: Unit, defender: Target, type: String, attribute_index: int, precomputed_results: Dictionary = {}) -> Dictionary:
	return _execute_attack(attacker, defender, type, attribute_index, precomputed_results)

## Performs a counter-attack or reactive strike.
func execute_attack_of_opportunity(attacker: Unit, defender: Target, attribute_index: int, precomputed_results: Dictionary = {}) -> Dictionary:
	GameLogger.debug(GameLogger.Category.COMBAT, "[Combat] execute_attack_of_opportunity: ", attacker.unit_name, " -> ", defender.name)
	var type = GameConstants.Interactions.FIGHT
	return _execute_attack(attacker, defender, type, attribute_index, precomputed_results)

func _execute_attack(attacker: Unit, defender: Target, type: String, attribute_index: int, precomputed_results: Dictionary = {}) -> Dictionary:
	var validation = _validate_combatants(attacker, defender)
	if not validation.valid:
		GameLogger.debug(GameLogger.Category.COMBAT, "[CombatSystem] _execute_attack validation failed: ", validation.error)
		return {}

	var is_convince := type in [GameConstants.Interactions.CONVINCE]
	var is_opposed := type in [GameConstants.Interactions.FIGHT, GameConstants.Interactions.TRAPPED, GameConstants.Interactions.EXPLORE]

	var results = precomputed_results if not precomputed_results.is_empty() else _simulate_attack(attacker, defender, attribute_index, type)
	if is_opposed:
		results["is_reaction"] = true

	_apply_damage_and_loyalty(attacker, defender, results, is_convince)
	if defender is Unit:
		_consume_reactions(defender)
		
	_emit_attack_events(attacker, defender, results, attribute_index)
	# State changed, clear caches
	_forecast_cache.clear()
	_best_quality_cache.clear()

	return results

func _apply_damage_and_loyalty(attacker: Unit, defender: Target, results: Dictionary, is_convince: bool = false) -> void:
	var damage = results.get("damage_to_target", 0)
	if is_convince:
		damage = _clamp_social_damage(defender, damage)

	if "willpower_current" in defender:
		defender.willpower_current -= max(0, damage)
	elif "willpower" in defender:
		defender.willpower -= max(0, damage)

	if is_convince:
		if defender is Unit and defender.faction == GameConstants.Faction.NEUTRAL:
			var threshold = (defender.res.get_max_willpower() if defender.res else 1) >> 1
			if (defender.willpower_current if "willpower_current" in defender else defender.willpower) <= threshold:
				defender.loyalty.apply_persuasion(attacker.faction)
		return

	attacker.willpower -= results.get("counter_damage_to_self", 0)

	if defender is Unit and defender.faction == GameConstants.Faction.NEUTRAL and defender.has_method("handle_attack_from"):
		defender.loyalty.handle_attack_from(attacker)
	if attacker is Unit and attacker.faction == GameConstants.Faction.NEUTRAL and attacker.has_method("handle_attack_from") and results.get("counter_damage_to_self", 0) > 0:
		attacker.loyalty.handle_attack_from(defender)

func _consume_reactions(defender: Unit) -> void:
	if defender.res.has_reaction_available():
		defender.res.consume_reaction()

func _emit_attack_events(attacker: Unit, defender: Target, results: Dictionary, attribute_index: int = -1) -> void:
	if defender is Unit:
		attack_occurred.emit(attacker, defender, results)

	if EventBus:
		if attribute_index != -1:
			EventBus.combat_action_performed.emit(attacker, defender, attribute_index, results)

		EventBus.unit_attacked.emit(attacker, defender)
		if results.damage_to_target > 0:
			EventBus.unit_damaged.emit(defender, results.damage_to_target, attacker)
		if results.counter_damage_to_self > 0:
			EventBus.unit_damaged.emit(attacker, results.counter_damage_to_self, defender)

	var def_wp = defender.willpower_current if "willpower_current" in defender else defender.willpower
	if def_wp <= 0:
		if defender is Unit:
			unit_defeated.emit(defender, attacker)
			if EventBus: EventBus.unit_died.emit(defender)
		elif defender is Location:
			defender.claimer_faction = attacker.faction
			defender.is_explored = true

	if attacker.willpower <= 0:
		unit_defeated.emit(attacker, defender)
		if EventBus: EventBus.unit_died.emit(attacker)

func _validate_combatants(attacker: Target, defender: Target) -> Dictionary:
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return {"valid": false, "error": "Invalid attacker or defender."}
	return {"valid": true}

func _get_stat(unit: Target, attribute_index: int) -> int:
	if attribute_index < 0 or attribute_index >= GameConstants.COMBAT_ATTRIBUTE_INDICES.size():
		return 0
	var attr_idx := attribute_index as GameConstants.AttributeIndex
	if unit is Unit and unit.query:
		return unit.query.get_total_attribute(attr_idx)
	return unit.get_attribute_by_index(attr_idx)

func _compute_defense(target: Target, attribute_index: int) -> float:
	if attribute_index < 0 or attribute_index >= GameConstants.COMBAT_ATTRIBUTE_INDICES.size():
		return 0.0

	var pair_index: int = int(attribute_index) >> 1
	var pair = PAIRS[pair_index]
	var attr_is_first: bool = attribute_index == pair[0]
	var attr_idx: int = pair[0] if attr_is_first else pair[1]
	var paired_idx: int = pair[1] if attr_is_first else pair[0]

	var val_attr := 0
	var val_paired := 0

	if target is Unit and target.query:
		val_attr = target.query.get_total_attribute(attr_idx)
		val_paired = target.query.get_total_attribute(paired_idx)
	else:
		val_attr = target.get_attribute_by_index(attr_idx)
		val_paired = target.get_attribute_by_index(paired_idx)

	return GameConstants.Combat.DEFENSE_MIN_WEIGHT * val_paired + GameConstants.Combat.DEFENSE_MAX_WEIGHT * val_attr

## Public API for UI previews and forecasts.
func get_combat_forecast(attacker: Target, defender: Target, attribute_index: int, interaction_type: String = "") -> Dictionary:
	# If called with a pair index (0 to PAIR_COUNT-1), convert to an attribute index.
	# We'll use the first attribute in the pair as the representative.
	var final_attr = attribute_index
	if attribute_index < GameConstants.Combat.PAIR_COUNT:
		final_attr = attribute_index * 2
		
	return _simulate_attack(attacker, defender, final_attr, interaction_type)

func _simulate_attack(attacker: Target, defender: Target, attribute_index: int, interaction_type: String = "") -> Dictionary:
	var cache_key := _get_cache_key(attacker, defender, attribute_index, interaction_type)
	if _forecast_cache.has(cache_key):
		return _forecast_cache[cache_key]

	var is_convince := interaction_type == GameConstants.Interactions.CONVINCE
	var atk_val: float = float(_get_stat(attacker, attribute_index))
	var def_val: float = float(_compute_defense(defender, attribute_index))

	var damage: int = max(0, int(atk_val - def_val))
	if is_convince:
		damage = _clamp_social_damage(defender, damage)

	var counter_damage: int = 0
	if not is_convince and defender.has_method("has_reaction") and defender.has_reaction():
		var counter_val: float = float(_get_stat(defender, attribute_index))
		var attacker_def: float = float(_compute_defense(attacker, attribute_index))
		counter_damage = max(0, int(counter_val - attacker_def))

	var result = {
		"damage_to_target": damage,
		"counter_damage_to_self": counter_damage
	}
	_forecast_cache[cache_key] = result
	return result

func _clamp_social_damage(defender: Target, damage: int) -> int:
	if not is_instance_valid(defender): return damage
	var max_wp = 1.0
	if defender is Unit and defender.res: max_wp = float(defender.res.get_max_willpower())
	else: max_wp = float(defender.base_willpower)

	var threshold: int = int(max_wp) >> 1
	var current_wp = defender.willpower_current if "willpower_current" in defender else defender.willpower
	if (current_wp - damage) < threshold:
		return max(0, current_wp - threshold)
	return damage

func _get_cache_key(attacker: Target, defender: Target, attr: int, interaction_type: String) -> String:
	return "%d_%d_%d_%s" % [attacker.get_instance_id(), defender.get_instance_id(), attr, interaction_type]

func _on_turn_changed(_num: int, _side: int) -> void:
	_forecast_cache.clear()
	_best_quality_cache.clear()

func get_aid_bonus(unit: Unit, attribute_index: int) -> int:
	if not is_instance_valid(unit): return 0
	return _get_stat(unit, attribute_index) >> 1

## Evaluates the quality of an interaction (Attack, Task, Social).
func get_attack_quality(actor: Unit, target: Target, attribute_index: int = -1, interaction_type: String = "") -> GameConstants.Combat.AttackQuality:
	var i := attribute_index
	if i == -1: i = actor.get_best_attribute_index()

	var forecast := _simulate_attack(actor, target, i, interaction_type)
	var damage = forecast.damage_to_target
	var counter = forecast.counter_damage_to_self

	var threshold: int = int(target.willpower_current if "willpower_current" in target else target.willpower)
	if interaction_type == GameConstants.Interactions.CONVINCE and target is Unit and target.faction == GameConstants.Faction.NEUTRAL:
		threshold = (target.res.get_max_willpower() if target.res else 1) >> 1

	return _interpret_quality(damage, threshold, counter, actor.willpower)

func _interpret_quality(progress: int, threshold: int, counter_damage: int, actor_willpower: int) -> GameConstants.Combat.AttackQuality:
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
		var q = get_attack_quality(actor, target, i, interaction_type)
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

func get_preview_forecast(actor: Unit, target: Target, attr_idx: int = -1, interaction_type: String = "") -> Dictionary:
	if not is_instance_valid(actor) or not is_instance_valid(target): return {}
	var i = attr_idx if attr_idx != -1 else actor.get_best_attribute_index()
	var sim = _simulate_attack(actor, target, i, interaction_type)

	return {
		"is_task": target.display_as_task,
		"is_opposed": target.is_opposed and interaction_type != GameConstants.Interactions.CONVINCE,
		"progress": sim.damage_to_target,
		"counter_damage": sim.counter_damage_to_self,
		"quality": get_attack_quality(actor, target, i, interaction_type),
		"attribute_index": i
	}
