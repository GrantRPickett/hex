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

func execute_combat(attacker: Unit, defender: Target, type: String, attribute_index: int, precomputed_results: Dictionary = {}) -> Dictionary:
	return _execute_attack(attacker, defender, type, attribute_index, precomputed_results)

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
	var can_counter := false

	var results = precomputed_results if not precomputed_results.is_empty() else _simulate_attack(attacker, defender, attribute_index, can_counter, is_convince)
	if is_opposed:
		results["is_reaction"] = true

	_apply_damage_and_loyalty(attacker, defender, results, is_convince)
	if defender is Unit:
		_consume_reactions(defender)
	#if defender is Loot and is_opposed:
		#idk if traps go off more than once
	_emit_attack_events(attacker, defender, results, attribute_index) #no idea if this does anything
	# State changed, clear caches
	_forecast_cache.clear()
	_best_quality_cache.clear()

	return results

func _apply_damage_and_loyalty(attacker: Unit, defender: Target, results: Dictionary, is_convince: bool = false) -> void:
	var damage = results.get("damage_to_target", 0)
	if is_convince:
		damage = _clamp_social_damage(defender, damage)

	if "willpower" in defender:
		defender.willpower -= max(0, damage)

	if is_convince:
		if defender is Unit and defender.faction == GameConstants.Faction.NEUTRAL:
			var threshold = defender.get_attribute(GameConstants.AttributeIndex.WILLPOWER) >> 1
			if defender.willpower <= threshold:
				defender.loyalty.apply_persuasion(attacker.faction)
		return # Convincing actions don't trigger retaliation or counter-damage

	attacker.willpower -= results.get("counter_damage_to_self", 0)

	if defender and defender.faction == GameConstants.Faction.NEUTRAL and defender.has_method("handle_attack_from"):
		defender.loyalty.handle_attack_from(attacker)
	if attacker and attacker.faction == GameConstants.Faction.NEUTRAL and attacker.has_method("handle_attack_from") and results.get("counter_damage_to_self", 0) > 0:
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

	# Death is handled by Unit.willpower setter, but we emit for combat log/UI
	if defender.willpower <= 0:
		if defender is Unit:
			unit_defeated.emit(defender, attacker)
		if EventBus: EventBus.unit_died.emit(defender)

	if attacker.willpower <= 0:
		unit_defeated.emit(attacker, defender)
		if EventBus: EventBus.unit_died.emit(attacker)


func get_combat_forecast(attacker: Target, defender: Target, attribute_index: int, is_convince: bool = false, allow_counter: bool = true) -> Dictionary:
	var validation = _validate_combatants(attacker, defender)
	if not validation.valid:
		return {}

	var can_counter := false

	return _simulate_attack(attacker, defender, attribute_index, can_counter, is_convince)

## Returns the best forecast for a given combat pair (Grit/Flow, etc).
func get_combat_pair_forecast(attacker: Target, defender: Target, pair_index: int, is_convince: bool = false) -> Dictionary:
	if pair_index < 0 or pair_index >= PAIRS.size():
		return {}

	var pair = PAIRS[pair_index]
	var forecast_a = get_combat_forecast(attacker, defender, pair[0], is_convince)
	var forecast_b = get_combat_forecast(attacker, defender, pair[1], is_convince)

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
		GameLogger.error(GameLogger.Category.COMBAT, "[CombatSystem] _get_stat: Invalid attribute_index %d" % attribute_index)
		return 0

	var attr_idx := attribute_index as GameConstants.AttributeIndex

	if unit is Unit and unit.query:
		return unit.query.get_total_attribute(attr_idx)

	return unit.get_attribute_by_index(attr_idx)

func _compute_defense(target: Target, attribute_index: int) -> float:
	if attribute_index < 0 or attribute_index >= GameConstants.COMBAT_ATTRIBUTE_INDICES.size():
		GameLogger.error(GameLogger.Category.COMBAT, "[CombatSystem] _compute_defense: Invalid attribute_index %d" % attribute_index)
		return 0.0

	var pair_index: int = int(attribute_index) >> 1
	var pair = PAIRS[pair_index]
	#track the orignal attr and the paired attr
	var attr_is_first: bool = attribute_index == pair[0]
	var attr_idx: int = pair[0] if attr_is_first else pair[1]
	var paired_idx: int = pair[1] if attr_is_first else pair[0]

	var val_attr: int = 0
	var val_paired: int = 0

	if target is Unit and target.query:
		val_attr = target.query.get_total_attribute(attr_idx)
		val_paired = target.query.get_total_attribute(paired_idx)
	else:
		val_attr = target.get_attribute_by_index(attr_idx)
		val_paired = target.get_attribute_by_index(paired_idx)

	return GameConstants.Combat.DEFENSE_MIN_WEIGHT * val_paired + GameConstants.Combat.DEFENSE_MAX_WEIGHT * val_attr

func _simulate_attack(attacker: Target, defender: Target, attribute_index: int, can_counter: bool = true, is_convince: bool = false) -> Dictionary:
	var cache_key := _get_cache_key(attacker, defender, attribute_index, can_counter) + ("_convince" if is_convince else "")
	if _forecast_cache.has(cache_key):
		return _forecast_cache[cache_key]

	var atk_val: float = float(_get_stat(attacker, attribute_index))
	var def_val: float = float(_compute_defense(defender, attribute_index))

	var damage: int = max(0, int(atk_val - def_val))
	if is_convince:
		damage = _clamp_social_damage(defender, damage)

	# Counter attack: full stat, no consumables
	var counter_damage: int = 0
	if can_counter:
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
	if not is_instance_valid(defender):
		return damage

	var threshold = defender.get_attribute(GameConstants.AttributeIndex.WILLPOWER) >> 1
	if defender.willpower - damage < threshold:
		return max(0, defender.willpower - threshold)
	return damage

func _get_cache_key(attacker: Target, defender: Target, attr: int, counter: bool) -> String:
	return "%d_%d_%d_%s" % [attacker.get_instance_id(), defender.get_instance_id(), attr, str(counter)]

func _on_turn_changed(_num: int, _side: int) -> void:
	_forecast_cache.clear()
	_best_quality_cache.clear()

func get_aid_bonus(unit: Unit, attribute_index: int) -> int:
	if not is_instance_valid(unit):
		return 0
	var val := _get_stat(unit, attribute_index)
	return val >> 1

## Evaluates the quality of an attack.
## Returns an enum representing the quality for both AI and UI consumption.
func get_attack_quality(actor: Unit, target: Target, attribute_index: int = -1, is_convince: bool = false) -> GameConstants.Combat.AttackQuality:
	# Ensure attribute index
	var i := attribute_index
	if i == -1:
		i = _get_best_attribute_index(actor)

	var forecast := get_combat_forecast(actor, target, i, is_convince)
	var damage: int = forecast.get("damage_to_target", 0)
	var counter: int = forecast.get("counter_damage_to_self", 0)

	var threshold: int = 1
	var actor_willpower: int = actor.willpower if actor is Unit else 0

	if target is Unit:
		threshold = target.willpower
		if is_convince and target.faction == GameConstants.Faction.NEUTRAL:
			threshold = target.max_willpower >> 1 # Threshold for neutral lock
	else:
		threshold = target.base_willpower

	return _interpret_quality(damage, threshold, counter, actor_willpower)

func _interpret_quality(progress: int, threshold: int, counter_damage: int = 0, actor_willpower: int = 0) -> GameConstants.Combat.AttackQuality:
	# Lethal counter-risk downgrades to "Risky"
	var is_dangerous: bool = counter_damage >= actor_willpower and counter_damage > 0 and actor_willpower > 0

	if progress >= threshold and progress > 0:
		return GameConstants.Combat.AttackQuality.RISKY if is_dangerous else GameConstants.Combat.AttackQuality.SUCCESS

	if progress > counter_damage:
		return GameConstants.Combat.AttackQuality.RISKY if is_dangerous else GameConstants.Combat.AttackQuality.PROGRESS

	if progress > 0:
		return GameConstants.Combat.AttackQuality.RISKY

	if counter_damage > 0:
		return GameConstants.Combat.AttackQuality.INEFFECTIVE

	return GameConstants.Combat.AttackQuality.IDLE

## Returns the UI symbol corresponding to an attack quality.
func get_quality_symbol(quality: GameConstants.Combat.AttackQuality) -> String:
	match quality:
		GameConstants.Combat.AttackQuality.SUCCESS: return GameConstants.UI.Indicators.SUCCESS
		GameConstants.Combat.AttackQuality.PROGRESS: return GameConstants.UI.Indicators.PROGRESS
		GameConstants.Combat.AttackQuality.RISKY: return GameConstants.UI.Indicators.RISKY
		GameConstants.Combat.AttackQuality.IDLE: return GameConstants.UI.Indicators.IDLE
		_: return GameConstants.UI.Indicators.INEFFECTIVE

func get_target_status_symbol(actor: Unit, target: Target, is_convince: bool = false, task: Task = null) -> String:
	if not is_instance_valid(actor) or not is_instance_valid(target):
		return ""

	var cache_key = "%d_%d_%s_%s" % [actor.get_instance_id(), target.get_instance_id(), str(is_convince), String(task.id) if task else "none"]
	if _best_quality_cache.has(cache_key):
		return get_quality_symbol(_best_quality_cache[cache_key])

	if task:
		# Use the task's own is_opposed if available, or fall back to the provided flag
		var quality = get_task_quality(actor, target, task)
		_best_quality_cache[cache_key] = quality
		return get_quality_symbol(quality)

	# Evaluate best possible outcome across all attributes (for Units or simple interactions)
	var best_quality := GameConstants.Combat.AttackQuality.INEFFECTIVE
	for i in range(6):
		var quality = get_attack_quality(actor, target, i, is_convince)
		if quality > best_quality:
			best_quality = quality
			if best_quality == GameConstants.Combat.AttackQuality.SUCCESS:
				break

	_best_quality_cache[cache_key] = best_quality
	return get_quality_symbol(best_quality)

## Unified helper to get near/far suffixes for an action.
## Handles both Units (direct combat) and other targets (via target_to_task mapping).
func get_action_suffixes(actor: Unit, near_targets: Array[Target], far_targets: Array[Target], is_convince: bool = false, target_to_task: Dictionary = {}) -> ActionSuffixes:
	var result := ActionSuffixes.new()

	if not is_instance_valid(actor):
		return result

	# Safety: Ensure far_targets doesn't include near_targets to avoid double-counting in suffixes
	var far_filtered: Array[Target] = []
	for t in far_targets:
		if not near_targets.has(t):
			far_filtered.append(t)

	# 1. If we have a target_to_task map, evaluate as tasks
	if not target_to_task.is_empty():
		var task_manager := actor.get_task_manager()
		if task_manager:
			result.near = get_group_task_quality_suffix(actor, near_targets, target_to_task)
			result.far = get_group_task_quality_suffix(actor, far_filtered, target_to_task)
	# 2. Otherwise evaluate as direct combat (Units)
	else:
		result.near = get_group_status_suffix(actor, near_targets, is_convince)
		result.far = get_group_status_suffix(actor, far_filtered, is_convince)

	return result

func _get_tasks_for_targets(targets: Array[Target], target_to_task: Dictionary, task_manager: TaskManager) -> Array[Task]:
	var tasks: Array[Task] = []
	for t in targets:
		var tid = target_to_task.get(t, "")
		if not str(tid).is_empty():
			var task = task_manager.get_task_by_id(str(tid))
			if task:
				tasks.append(task)
	return tasks

## Returns a unique sorted list of symbols for a group of targets e.g. "[X, !]"
func get_group_status_suffix(attacker: Unit, targets: Array[Target], is_convince: bool = false) -> String:
	if targets.is_empty(): return ""

	var symbols := {}
	for t in targets:
		if is_instance_valid(t):
			symbols[get_target_status_symbol(attacker, t, is_convince)] = true

	if symbols.is_empty(): return ""

	var list = symbols.keys()
	list.sort_custom(func(a, b):
		var order := {
			&"★": 0,
			&"▲": 1,
			&"◆": 2,
			&"●": 3,
			&"▼": 4
		}
		return order.get(a, 9) < order.get(b, 9)
	)

	return list[0] if not list.is_empty() else ""

func get_task_quality(actor: Unit, target: Target, task: Task, attribute_index: int = -1) -> GameConstants.Combat.AttackQuality:
	if not is_instance_valid(actor) or not is_instance_valid(task):
		return GameConstants.Combat.AttackQuality.INEFFECTIVE

	task.calibrate_against_target(target)


	var atk_val: float = 0.0
	var counter_damage: int = 0

	if is_instance_valid(target):
		# Use combat simulation logic
		var forecast = _simulate_attack(actor, target, attribute_index, true, false)
		atk_val = float(forecast.get("damage_to_target", 0)) # This is actually 'damage' (atk - def)
		counter_damage = forecast.get("counter_damage_to_self", 0)
	else:
		# Fallback for abstract tasks without world targets
		var raw_atk: float = float(_get_stat(actor, attribute_index))
		var task_opp = float(task.opposition_value) if task.is_opposed else 0.0
		atk_val = max(0.0, raw_atk - task_opp)

	var remaining = 1
	if task.duration_turns > 0:
		remaining = task.duration_turns - task.elapsed_turns
	else:
		remaining = task.effort_required - task.current_effort

	return _interpret_quality(int(atk_val), remaining, counter_damage, actor.willpower)

## Returns a summary of task progress and difficulty for UD previews.
func get_task_forecast(actor: Unit, target: Target, task: Task, attribute_index: int = -1) -> Dictionary:
	if not is_instance_valid(actor) or not is_instance_valid(task):
		return {}

	task.calibrate_against_target(target)

	var attr_idx: GameConstants.AttributeIndex = attribute_index as GameConstants.AttributeIndex if attribute_index != -1 else _get_best_attribute_index(actor)

	var progress: int = 0
	var counter: int = 0
	var opp_val: float = 0.0

	if is_instance_valid(target):
		var forecast = _simulate_attack(actor, target, attr_idx, true, false)
		progress = forecast.get("damage_to_target", 0)
		counter = forecast.get("counter_damage_to_self", 0)
		opp_val = float(target.get_attribute(attr_idx)) if task.is_opposed else 0.0
	else:
		opp_val = float(task.opposition_value) if task.is_opposed else 0.0
		progress = int(max(0.0, float(_get_stat(actor, attr_idx)) - opp_val))

	return {
		"is_task": true,
		"is_opposed": task.is_opposed,
		"progress": progress,
		"counter_damage": counter,
		"effort_required": task.effort_required,
		"current_effort": task.current_effort,
		"duration_turns": task.duration_turns,
		"elapsed_turns": task.elapsed_turns,
		"opposition_value": opp_val,
		"attribute_index": attr_idx # Pass through for UI labeling
	}

func _get_best_attribute_index(actor: Unit) -> GameConstants.AttributeIndex:
	var best_idx: GameConstants.AttributeIndex = GameConstants.AttributeIndex.GRIT
	var best_val: int = -999
	for idx in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var a_idx := idx as GameConstants.AttributeIndex
		var val: int = actor.get_attribute(a_idx)
		if val > best_val:
			best_val = val
			best_idx = a_idx
	return best_idx

## Returns a unique sorted list of symbols for a group of tasks associated with targets
func get_group_task_quality_suffix(actor: Unit, targets: Array[Target], target_to_task: Dictionary) -> String:
	if targets.is_empty() or target_to_task.is_empty(): return ""

	var task_manager := actor.get_task_manager()
	if not task_manager: return ""

	var symbols := {}
	for t in targets:
		if not target_to_task.has(t): continue
		var tid = target_to_task[t]
		var task = task_manager.get_task_by_id(str(tid))
		if task:
			symbols[get_quality_symbol(get_task_quality(actor, t, task))] = true

	if symbols.is_empty(): return ""

	var list = symbols.keys()
	list.sort_custom(func(a, b):
		var order := {
			&"★": 0,
			&"▲": 1,
			&"◆": 2,
			&"●": 3,
			&"▼": 4
		}
		return order.get(a, 9) < order.get(b, 9)
	)

	return list[0] if not list.is_empty() else ""
