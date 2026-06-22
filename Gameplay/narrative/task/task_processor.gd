class_name TaskProcessor
extends RefCounted

static func is_event_type_supported(task: Task, type: String) -> bool:
	if type == GameConstants.Activity.ROUND_CHANGED:
		return true

	if task.target_filters.is_empty():
		if type == task.event_type:
			return true
		if type == GameConstants.Activity.MOVE and task.event_type == GameConstants.Activity.EXPLORE_ZONE:
			return true
		return false

	for filter in task.target_filters:
		if filter is Dictionary:
			var filter_type : String = str(filter.get("event_type", ""))
			if filter_type.is_empty() or filter_type == type:
				return true
	return false

static func is_event_processed(task: Task, type: String, data: CombatResult) -> bool:
	match type:
		GameConstants.Activity.VISIT, \
		GameConstants.Activity.INTERACT, \
		GameConstants.Activity.EXPLORE, \
		GameConstants.Activity.GATHER, \
		GameConstants.Activity.TRAPPED, \
		GameConstants.Activity.FIGHT, \
		GameConstants.Activity.CONVINCE:
			return validate_interaction_data(task, type, data)
		GameConstants.Activity.MOVE:
			return process_move(task, type, data)
		GameConstants.Activity.ABILITY_USED:
			return process_ability_used(task, type, data)
		GameConstants.Activity.DIALOGUE_STARTED:
			return process_dialogue_started(task, type, data)
		GameConstants.Activity.UNIT_DEFEATED:
			return process_unit_defeated(task, type, data)
		GameConstants.Activity.ROUND_CHANGED:
			return process_round_changed(task, data)
	return false

static func validate_interaction_data(task: Task, _type: String, data: Variant) -> bool:
	if not task.target_filters.is_empty():
		return matches_any_filter(task, _type, data)

	if task.target_coord != GameConstants.INVALID_COORD:
		var coord = _get_coord(data)
		if coord != task.target_coord:
			return false

	if not task.target_id.is_empty():
		var target = _get_target(data)
		var resolved_id = TaskManager.resolve_target_id(target) if target else ""
		if resolved_id.is_empty() and data is Dictionary:
			resolved_id = str(data.get("id", ""))
		
		if resolved_id != task.target_id:
			return false
	return true

static func _get_coord(data: Variant) -> Vector2i:
	if data is CombatResult and is_instance_valid(data.defender):
		return data.defender.get_grid_location()
	elif data is Dictionary:
		return to_vector2i(data.get("coord", GameConstants.INVALID_COORD))
	return GameConstants.INVALID_COORD

static func _get_target(data: Variant) -> Target:
	if data is CombatResult:
		return data.defender
	elif data is Dictionary:
		return data.get("target")
	return null

static func matches_any_filter(task: Task, type: String, data: Variant) -> bool:
	for filter in task.target_filters:
		if filter_matches(task, filter, type, data):
			return true
	return false

static func filter_matches(task: Task, filter: Variant, type: String, data: Variant) -> bool:
	if filter is Dictionary:
		var f_dict := filter as Dictionary
		var filter_type := str(f_dict.get("event_type", ""))
		if filter_type != "" and filter_type != type:
			return false
		if f_dict.has("target_id"):
			var target = _get_target(data)
			var id_val = TaskManager.resolve_target_id(target) if target else ""
			if id_val == "" and data is Dictionary:
				id_val = str(data.get("id", data.get("target_id", "")))
			
			if str(f_dict.get("target_id")) != str(id_val):
				return false
		if f_dict.has("target_kind"):
			var target = _get_target(data)
			var data_kind: String = ""
			if target:
				data_kind = str(target.target_kind)
			elif data is Dictionary:
				data_kind = str(data.get("target_kind", task.target_kind))
			else:
				data_kind = str(task.target_kind)
			
			if data_kind != str(f_dict.get("target_kind", task.target_kind)):
				return false
		if f_dict.has("target_coord"):
			var coord = _get_coord(data)
			var filter_coord = to_vector2i(f_dict.get("target_coord", GameConstants.INVALID_COORD))
			if coord != filter_coord:
				return false
		if f_dict.has("target_faction"):
			var target = _get_target(data)
			var faction_val: int = -1
			if data is CombatResult:
				faction_val = data.get_target_faction()
			elif target:
				faction_val = target.get_effective_faction() if target.has_method("get_effective_faction") else target.faction
			elif data is Dictionary:
				faction_val = int(data.get("target_faction", data.get("faction", -1)))
			
			if int(f_dict.get("target_faction", faction_val)) != faction_val:
				return false
		return true
	elif filter is String or filter is StringName:
		return str(filter) == type
	return false

static func process_move(task: Task, _type: String, data: CombatResult) -> bool:
	if task.event_type != GameConstants.Activity.EXPLORE_ZONE:
		return false
	var unit_coord = data.defender.get_grid_location() if is_instance_valid(data.defender) else GameConstants.INVALID_COORD
	var unit_index = data.attacker.get_instance_id() if is_instance_valid(data.attacker) else -1
	if task.zone_coords.is_empty():
		return false
	if unit_coord in task.zone_coords:
		if not task.dialogue_id.is_empty():
			task.dialogue_requested.emit(task.dialogue_id, unit_index)
		return true
	return false

static func process_ability_used(task: Task, _type: String, data: CombatResult) -> bool:
	if not task.target_id.is_empty():
		var ability_id = data.type # Use 'type' for ability ID when ABILITY_USED event
		return str(ability_id) == task.target_id
	return true

static func process_dialogue_started(task: Task, _type: String, data: CombatResult) -> bool:
	if not task.target_id.is_empty():
		var target = data.defender
		var resolved_id = TaskManager.resolve_target_id(target) if target else ""
		return resolved_id == task.target_id or (not task.dialogue_id.is_empty() and StringName(resolved_id) == task.dialogue_id)
	return true

static func process_unit_defeated(task: Task, _type: String, data: CombatResult) -> bool:
	var u = data.defender
	if u == null or not (u is Unit): return false
	var unit := u as Unit

	if task.completion_condition is CompletionCondition:
		if task.completion_condition.type == GameConstants.Tasks.CONDITION_DEFEAT_ALL:
			return unit.faction == task.completion_condition.faction

	if not task.target_id.is_empty():
		var resolved_id = TaskManager.resolve_target_id(unit)
		return resolved_id == task.target_id

	var default_target = GameConstants.Faction.ENEMY if task.owning_faction == GameConstants.Faction.PLAYER else GameConstants.Faction.PLAYER
	return unit.faction == default_target

static func process_round_changed(task: Task, data: CombatResult) -> bool:
	if data.get_actor_faction() != task.owning_faction:
		return false

	var progressed := false
	if task.event_type == GameConstants.Activity.COUNTDOWN:
		progressed = true

	if task.duration_turns > 0:
		progressed = duration_condition_holds(task, data) or progressed

	return progressed

static func duration_condition_holds(task: Task, data: CombatResult) -> bool:
	# In per-unit round processing, 'data.attacker' represents the unit being evaluated.
	var unit: Unit = data.attacker
	if not is_instance_valid(unit) or unit.faction != task.owning_faction:
		return false

	match task.event_type:
		GameConstants.Activity.INTERACT:
			if task.target_coord != GameConstants.INVALID_COORD:
				return unit.get_grid_location() == task.target_coord
			return false
		GameConstants.Activity.GATHER:
			if not task.target_id.is_empty():
				return unit.inv and unit.inv.has_item_by_id(task.target_id)
			return unit.inv and not unit.inv.is_empty()
		GameConstants.Activity.EXPLORE_ZONE:
			return unit.get_grid_location() in task.zone_coords
		GameConstants.Activity.COUNTDOWN:
			return true
	return false

static func calculate_event_progress(actor: Unit, data: CombatResult, type: String) -> int:
	GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskProcessor] calculate_event_progress: type=%s, data=%s" % [type, data])
	
	if not actor: return 1

	# Handle explicitly provided progress
	if data.damage > 0:
		return data.damage

	# Count-based events grant 1 progress (UNIT_DEFEATED, ABILITY_USED, DIALOGUE_STARTED, MOVE)
	var count_events = [
		GameConstants.Activity.UNIT_DEFEATED,
		GameConstants.Activity.ABILITY_USED,
		GameConstants.Activity.DIALOGUE_STARTED,
		GameConstants.Activity.MOVE
	]
	if type in count_events:
		return 1

	# No automated attribute-based calculation fallback for single target tasks.
	# These tasks must be driven by interaction willpower or explicit progress keys.
	return 0
static func get_best_attribute_index(actor: Unit) -> GameConstants.AttributeIndex:
	var best_idx: GameConstants.AttributeIndex = GameConstants.AttributeIndex.GRIT
	var best_val: int = -9999
	for idx in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var a_idx := idx as GameConstants.AttributeIndex
		var val: int = actor.get_attribute(a_idx)
		if val > best_val:
			best_val = val
			best_idx = a_idx
	return best_idx

static func to_vector2i(value) -> Vector2i:
	if value is Vector2i: return value
	if value is Vector2: return Vector2i(int(value.x), int(value.y))
	if value is Dictionary and value.has("x") and value.has("y"):
		return Vector2i(int(value["x"]), int(value["y"]))
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return GameConstants.INVALID_COORD
