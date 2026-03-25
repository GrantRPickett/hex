class_name TaskProcessor
extends RefCounted

static func is_event_type_supported(task: Task, type: String) -> bool:
	if type == GameConstants.TaskEvents.ROUND_CHANGED:
		return true

	if task.target_filters.is_empty():
		if type == task.event_type:
			return true
		if type == GameConstants.TaskEvents.MOVE and task.event_type == GameConstants.TaskEvents.EXPLORE_ZONE:
			return true
		return false

	for filter in task.target_filters:
		if filter is Dictionary:
			var filter_type : String = str(filter.get("event_type", ""))
			if filter_type.is_empty() or filter_type == type:
				return true
	return false

static func is_event_processed(task: Task, type: String, data: Dictionary) -> bool:
	match type:
		GameConstants.TaskEvents.VISIT, \
		GameConstants.TaskEvents.INTERACT, \
		GameConstants.TaskEvents.EXPLORE, \
		GameConstants.TaskEvents.LOOT, \
		GameConstants.TaskEvents.TRAPPED, \
		GameConstants.TaskEvents.ATTACK, \
		GameConstants.TaskEvents.CONVINCE:
			return validate_interaction_data(task, type, data)
		GameConstants.TaskEvents.MOVE:
			return process_move(task, type, data)
		GameConstants.TaskEvents.ABILITY_USED:
			return process_ability_used(task, type, data)
		GameConstants.TaskEvents.DIALOGUE_STARTED:
			return process_dialogue_started(task, type, data)
		GameConstants.TaskEvents.UNIT_DEFEATED:
			return process_unit_defeated(task, type, data)
		GameConstants.TaskEvents.ROUND_CHANGED:
			return process_round_changed(task, data)
	return false

static func validate_interaction_data(task: Task, _type: String, data: Dictionary) -> bool:
	if not task.target_filters.is_empty():
		return matches_any_filter(task, _type, data)

	if task.target_coord != GameConstants.INVALID_COORD:
		var coord = data.get("coord", GameConstants.INVALID_COORD)
		if coord != task.target_coord:
			return false

	if not task.target_id.is_empty():
		var target = data.get("target")
		var resolved_id = TaskManager.resolve_target_id(target) if target else str(data.get("id", ""))
		if resolved_id != task.target_id:
			return false
	return true

static func matches_any_filter(task: Task, type: String, data: Dictionary) -> bool:
	for filter in task.target_filters:
		if filter_matches(task, filter, type, data):
			return true
	return false

static func filter_matches(task: Task, filter: Variant, type: String, data: Dictionary) -> bool:
	if filter is Dictionary:
		var f_dict := filter as Dictionary
		var filter_type := str(f_dict.get("event_type", ""))
		if filter_type != "" and filter_type != type:
			return false
		if f_dict.has("target_id"):
			var id_val = data.get("id", data.get("target_id", ""))
			if str(f_dict.get("target_id")) != str(id_val):
				return false
		if f_dict.has("target_kind"):
			var data_kind: String = str(data.get("target_kind", task.target_kind))
			if data_kind != str(f_dict.get("target_kind", task.target_kind)):
				return false
		if f_dict.has("target_coord"):
			var coord = to_vector2i(data.get("coord", GameConstants.INVALID_COORD))
			var filter_coord = to_vector2i(f_dict.get("target_coord", GameConstants.INVALID_COORD))
			if coord != filter_coord:
				return false
		if f_dict.has("target_faction"):
			var faction_val = data.get("target_faction", data.get("faction", -1))
			if int(f_dict.get("target_faction", faction_val)) != int(faction_val):
				return false
		return true
	elif filter is String or filter is StringName:
		return str(filter) == type
	return false

static func process_move(task: Task, _type: String, data: Dictionary) -> bool:
	if task.event_type != GameConstants.TaskEvents.EXPLORE_ZONE:
		return false
	var unit_coord = data.get("coord", Vector2i.ZERO)
	var unit_index = data.get("unit_index", -1)
	if task.zone_coords.is_empty():
		return false
	if unit_coord in task.zone_coords:
		if not task.dialogue_id.is_empty():
			task.dialogue_requested.emit(task.dialogue_id, unit_index)
		return true
	return false

static func process_ability_used(task: Task, _type: String, data: Dictionary) -> bool:
	if not task.target_id.is_empty():
		var ability_id = data.get("id", "")
		return str(ability_id) == task.target_id
	return true

static func process_dialogue_started(task: Task, _type: String, data: Dictionary) -> bool:
	if not task.target_id.is_empty():
		var data_id = data.get("id", "")
		var target = data.get("target")
		var resolved_id = TaskManager.resolve_target_id(target) if target else str(data_id)
		return resolved_id == task.target_id or StringName(str(data_id)) == task.dialogue_id
	return true

static func process_unit_defeated(task: Task, _type: String, data: Dictionary) -> bool:
	var u = data.get("unit")
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

static func process_round_changed(task: Task, data: Dictionary) -> bool:
	if data.get("faction", -1) != task.owning_faction:
		return false

	var progressed := false
	if task.event_type == GameConstants.TaskEvents.COUNTDOWN:
		progressed = true

	if task.duration_turns > 0:
		progressed = duration_condition_holds(task, data) or progressed

	return progressed

static func duration_condition_holds(task: Task, data: Dictionary) -> bool:
	var factions = data.get("factions", {})
	var my_faction_data = factions.get(task.owning_faction, {}) as Dictionary

	match task.event_type:
		GameConstants.TaskEvents.INTERACT:
			if task.target_coord != GameConstants.INVALID_COORD:
				var coords = my_faction_data.get("coords", []) as Array
				return task.target_coord in coords
			return false
		GameConstants.TaskEvents.LOOT:
			if not task.target_id.is_empty():
				var held_items = my_faction_data.get("held_items", []) as Array
				return task.target_id in held_items
			return bool(data.get("holding", false))
		GameConstants.TaskEvents.EXPLORE_ZONE:
			var coords = my_faction_data.get("coords", []) as Array
			for c in coords:
				if c in task.zone_coords: return true
			return false
		GameConstants.TaskEvents.COUNTDOWN:
			return true
	return false

static func calculate_event_progress(task: Task, actor: Unit, data: Dictionary, type: String) -> int:
	if type == GameConstants.TaskEvents.ELIMINATE: return 1
	if not actor: return 1

	var used_attribute = data.get("attribute", -1)
	if used_attribute == -1:
		used_attribute = get_best_attribute_index(actor)

	var val: int = actor.get_attribute(used_attribute as GameConstants.AttributeIndex) if actor.has_method("get_attribute") else 0
	var opp_val: int = task.opposition_value
	var target = data.get("target")
	if target and target.has_method("get_attribute"):
		opp_val = target.get_attribute(used_attribute as GameConstants.AttributeIndex)

	return max(0, val - opp_val)
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
