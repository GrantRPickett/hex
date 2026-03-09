class_name Task
extends Resource

signal progress_changed(current: int, required: int, faction_id: int)
signal completed(faction_id: int, unit: Unit)
signal failed()
signal dialogue_requested(dialogue_id: StringName, unit_index: int)

enum Status {PENDING, ACTIVE, COMPLETED, FAILED, CANCELLED}

@export_group("Identity")
@export var id: StringName
@export var title: String = "New Task"
@export_multiline var description: String = "A new task."
@export var icon: Texture2D
@export var owning_faction: int = Unit.Faction.PLAYER

@export_group("Criteria")
@export var event_type: String = GameConstants.TaskEvents.INTERACT
@export var target_coord: Vector2i = GameConstants.INVALID_COORD
@export var target_id: String = ""
# Optional target kind hint for validation/routing: "unit"|"location"|"item"|"none"
@export var target_kind: StringName = GameConstants.Tasks.KIND_NONE
@export var target_faction: int = Unit.Faction.PLAYER
@export var target_filters: Array = []
@export var completion_condition: CompletionCondition

@export_group("Requirements")
@export var effort_required: int = 10
@export var is_optional: bool = false

@export_group("Duration")
# If > 0, task supports turn-based completion in addition to effort.
@export var duration_turns: int = 0 # When >0, do not use effort; stage should model AND/OR with multiple tasks.
# "cumulative" or "consecutive"; cumulative avoids stalemates.
@export var duration_mode: StringName = GameConstants.Tasks.DURATION_CUMULATIVE
var elapsed_turns: int = 0
var streak_turns: int = 0

@export_group("Opposition")
@export var is_opposed: bool = false
@export var opposition_value: int = 0 ## Static difficulty if no target unit is present

@export_group("Rewards")
@export var journal_entry_id: String = ""
@export var reward_id: String = ""
@export var reward_resource: TaskReward

# Runtime State
var status: Status = Status.PENDING
var current_effort: int = 0
var winning_faction: int = -1
var _target_unit: Unit = null # The unit/object being acted upon, if any

func initialize(target: Unit = null) -> void:
	status = Status.ACTIVE
	current_effort = 0
	winning_faction = -1
	_target_unit = target
	elapsed_turns = 0
	streak_turns = 0

func handle_event(type: String, data: Dictionary) -> void:
	if status != Status.ACTIVE:
		return

	if not _is_event_type_supported(type):
		return

	# Determine who the logical "actor" is for this event to check ownership
	var actor: Unit = null
	if type == GameConstants.TaskEvents.UNIT_DEFEATED:
		actor = data.get("attacker") as Unit
	else:
		actor = data.get("unit") as Unit

	# Faction Guard: Only the owning faction's actions can progress this task.
	# External system events (like ROUND_CHANGED) won't have an actor and bypass this check.
	if actor and actor.faction != owning_faction:
		return

	if not _is_event_processed(type, data):
		return

	var progress = _calculate_event_progress(actor, data, type)

	# If duration is in effect, avoid effort-based completion; stages can compose separate tasks for AND/OR.
	if duration_turns <= 0 and effort_required > 0:
		current_effort = min(effort_required, current_effort + progress)
		progress_changed.emit(current_effort, effort_required, actor.faction if actor else owning_faction)
		if current_effort >= effort_required:
			_complete_task(actor.faction if actor else owning_faction, data.get("target"), type)

func _is_event_processed(type: String, data: Dictionary) -> bool:
	match type:
		GameConstants.TaskEvents.VISIT: return _validate_interaction_data(type, data)
		GameConstants.TaskEvents.INTERACT: return _validate_interaction_data(type, data)
		GameConstants.TaskEvents.EXPLORE: return _validate_interaction_data(type, data)
		GameConstants.TaskEvents.MOVE: return _process_move_explore(type, data)
		GameConstants.TaskEvents.LOOT: return _validate_interaction_data(type, data)
		GameConstants.TaskEvents.TRAPPED: return _validate_interaction_data(type, data)
		GameConstants.TaskEvents.ATTACK: return _validate_interaction_data(type, data)
		GameConstants.TaskEvents.CONVINCE: return _validate_interaction_data(type, data)
		GameConstants.TaskEvents.ABILITY_USED: return _process_ability_used(type, data)
		GameConstants.TaskEvents.DIALOGUE_STARTED: return _process_dialogue_started(type, data)
		GameConstants.TaskEvents.UNIT_DEFEATED: return _process_unit_defeated(type, data)
		GameConstants.TaskEvents.ROUND_CHANGED: return _process_round_changed(data)
	return false

func _calculate_event_progress(actor: Unit, data: Dictionary, type: String) -> int:
	if type == GameConstants.TaskEvents.ELIMINATE:
		return 1 # Fixed progress for elimination unless overridden

	if not actor:
		return 1

	var used_attribute = data.get("attribute", "")
	if used_attribute.is_empty() or typeof(used_attribute) != TYPE_STRING:
		used_attribute = _get_best_attribute_name(actor)

	var val = actor.get_attribute(used_attribute) if actor.has_method("get_attribute") else 0

	if not is_opposed:
		return max(1, val)

	var opp_val = opposition_value
	var target = data.get("target", _target_unit)

	if target:
		if target.has_method("get_attribute"):
			opp_val = target.get_attribute(used_attribute)

	return max(1, val - opp_val)

func _get_best_attribute_name(actor: Unit) -> String:
	var best_name = GameConstants.Attributes.GRIT
	var best_val = -9999
	var attrs = actor.inv.get_attributes() if "inv" in actor and actor.inv else null
	if attrs:
		for attr_name in Target.COMBAT_ATTRIBUTE_NAMES:
			var val = attrs.get_attribute(attr_name)
			if val > best_val:
				best_val = val
				best_name = attr_name
	return best_name

func _validate_interaction_data(type: String, data: Dictionary) -> bool:
	if not target_filters.is_empty():
		return _matches_any_filter(type, data)

	if target_coord != GameConstants.INVALID_COORD:
		var coord = data.get("coord", GameConstants.INVALID_COORD)
		if coord != target_coord:
			return false
	if not target_id.is_empty():
		var id_val = data.get("id", "")
		if id_val != target_id:
			return false
	return true

func _is_event_type_supported(type: String) -> bool:
	if type == GameConstants.TaskEvents.ROUND_CHANGED:
		return true

	if target_filters.is_empty():
		if type == event_type:
			return true
		if type == GameConstants.TaskEvents.MOVE and event_type == GameConstants.TaskEvents.EXPLORE_ZONE:
			return true
		return false

	for filter in target_filters:
		var filter_type := str(filter.get("event_type", ""))
		if filter_type.is_empty() or filter_type == type:
			return true
	return false

func _matches_any_filter(type: String, data: Dictionary) -> bool:
	for filter in target_filters:
		if _filter_matches(filter, type, data):
			return true
	return false

func _filter_matches(filter, type: String, data: Dictionary) -> bool:
	if filter is Dictionary:
		var filter_type := str(filter.get("event_type", ""))
		if filter_type != "" and filter_type != type:
			return false
		if filter.has("target_id"):
			var id_val = data.get("id", data.get("target_id", ""))
			if str(filter.get("target_id")) != str(id_val):
				return false
		if filter.has("target_kind"):
			var data_kind = str(data.get("target_kind", target_kind))
			if data_kind != str(filter.get("target_kind", target_kind)):
				return false
		if filter.has("target_coord"):
			var coord = _to_vector2i(data.get("coord", GameConstants.INVALID_COORD))
			var filter_coord = _to_vector2i(filter.get("target_coord", GameConstants.INVALID_COORD))
			if coord != filter_coord:
				return false
		if filter.has("target_faction"):
			var faction_val = data.get("target_faction", data.get("faction", -1))
			if int(filter.get("target_faction", faction_val)) != int(faction_val):
				return false
		return true
	elif filter is String or filter is StringName:
		return str(filter) == type
	return false

func _process_unit_defeated(type: String, data: Dictionary) -> bool:
	# Elimination-style task: completes when a target unit or faction unit is defeated
	if type != GameConstants.TaskEvents.ELIMINATE:
		return false
	var u: Unit = data.get("unit")
	if u == null:
		return false

	# If we have a completion condition, it might specify a faction
	if completion_condition and completion_condition.type == GameConstants.Tasks.CONDITION_DEFEAT_ALL:
		if u.faction != completion_condition.faction:
			return false
		return true

	# If target_id is set, match by unit name/id; otherwise accept any enemy defeat
	if not target_id.is_empty():
		if String(u.unit_name) != target_id and StringName(u.unit_name) != StringName(target_id):
			return false
	elif u.faction != Unit.Faction.ENEMY:
		return false

	return true

func _process_round_changed(data: Dictionary) -> bool:
	if data.get("faction", -1) != owning_faction:
		return false
	# Countdown-style task: advances each round until reaching effort_required
	var progressed := false
	if event_type == GameConstants.TaskEvents.COUNTDOWN:
		progressed = true
	# Duration support: when duration_turns > 0, we consider contextual condition satisfaction.
	if duration_turns > 0:
		var holds := _duration_condition_holds(data)
		if holds:
			elapsed_turns += 1
			streak_turns += 1
		else:
			streak_turns = 0
		progressed = progressed or holds

		if progressed:
			progress_changed.emit(elapsed_turns, duration_turns, owning_faction)

		# Duration-based completion independent of effort
		if duration_mode == GameConstants.Tasks.DURATION_CUMULATIVE and elapsed_turns >= duration_turns:
			var winner = owning_faction
			if data.has("unit") and data.get("unit"):
				winner = data.get("unit").faction
			_complete_task(winner)
		elif duration_mode == GameConstants.Tasks.DURATION_CONSECUTIVE and streak_turns >= duration_turns:
			var winner = owning_faction
			if data.has("unit") and data.get("unit"):
				winner = data.get("unit").faction
			_complete_task(winner)
	return progressed

func _duration_condition_holds(data: Dictionary) -> bool:
	# Non-obvious: uses current task criteria to infer whether the ongoing condition still holds this round.
	# For protect/hold-type tasks, external systems should supply pertinent fields in data.
	# Fallback heuristics below avoid tight coupling.
	var factions = data.get("factions", {})
	var my_faction_data = factions.get(owning_faction, {})

	match event_type:
		GameConstants.TaskEvents.INTERACT:
			# Treat presence at target location as holding condition if coords match.
			if target_coord != GameConstants.INVALID_COORD:
				var coords = my_faction_data.get("coords", [])
				return target_coord in coords
			return false
		GameConstants.TaskEvents.LOOT:
			# If we have a target_id, check if our faction holds THAT specific item
			if not target_id.is_empty():
				var held_items = my_faction_data.get("held_items", [])
				return target_id in held_items
			return bool(data.get("holding", false))
		GameConstants.TaskEvents.EXPLORE_ZONE:
			# Presence in zone continues condition
			var coords = my_faction_data.get("coords", [])
			for c in coords:
				if c in zone_coords:
					return true
			return false
		GameConstants.TaskEvents.COUNTDOWN:
			return true
		_:
			return false

func _process_move_explore(type: String, data: Dictionary) -> bool:
	if event_type != GameConstants.TaskEvents.EXPLORE_ZONE:
		return false
	var unit_coord = data.get("coord", Vector2i.ZERO)
	var unit_index = data.get("unit_index", -1)
	if zone_coords.is_empty():
		push_warning("Task '%s': explore_zone task has no zone_coords defined." % id)
		return false
	if unit_coord in zone_coords:
		if not dialogue_id.is_empty():
			if unit_index != -1:
				dialogue_requested.emit(dialogue_id, unit_index)
			else:
				push_warning("Task '%s': explore_zone dialogue could not start, unit_index missing." % id)
		return true
	return false

func _process_loot(type: String, data: Dictionary) -> bool:
	if type != GameConstants.TaskEvents.LOOT:
		return false
	if not target_id.is_empty():
		var item_id = data.get("id", "")
		if item_id != target_id:
			return false
	return true

func _process_ability_used(type: String, data: Dictionary) -> bool:
	if type != GameConstants.TaskEvents.ABILITY_USED:
		return false
	if not target_id.is_empty():
		var ability_id = data.get("id", "")
		if ability_id != target_id:
			return false
	return true

func _process_dialogue_started(type: String, data: Dictionary) -> bool:
	if type != GameConstants.TaskEvents.DIALOGUE_STARTED:
		return false
	if not target_id.is_empty():
		var d_id = data.get("id", "")
		if d_id != target_id and StringName(d_id) != dialogue_id:
			return false
	return true

func _complete_task(faction: int, target: Object = null, completed_event: String = "") -> void:
	status = Status.COMPLETED
	winning_faction = faction

	var resolved_event = completed_event if not completed_event.is_empty() else event_type
	if target:
		if resolved_event == GameConstants.TaskEvents.EXPLORE or resolved_event == GameConstants.TaskEvents.TRAPPED:
			if target.has_method("mark_explored"):
				target.mark_explored()
			if target.has_method("disarm_trap"):
				target.disarm_trap()

	completed.emit(faction, target if target is Unit else null)

func force_complete(faction: int = -1) -> void:
	if status == Status.ACTIVE:
		current_effort = effort_required
		_complete_task(faction, null, event_type)

func _fail_task() -> void:
	status = Status.FAILED
	failed.emit()

func cancel() -> void:
	if status == Status.ACTIVE:
		status = Status.CANCELLED
		# We do not emit failed here to avoid triggering failure logic during clean transitions

func get_progress_ratio() -> float:
	if duration_turns > 0:
		return float(elapsed_turns) / float(duration_turns)
	if effort_required <= 0: return 1.0
	return float(current_effort) / float(effort_required)

func create_memento() -> Dictionary:
	return {
		"id": id,
		"status": status,
		"current_effort": current_effort,
		"winning_faction": winning_faction,
		"elapsed_turns": elapsed_turns,
		"streak_turns": streak_turns
	}

func restore_from_memento(memento: Dictionary) -> void:
	status = memento.get("status", Status.PENDING) as Status
	current_effort = memento.get("current_effort", 0)
	winning_faction = memento.get("winning_faction", -1)
	elapsed_turns = memento.get("elapsed_turns", 0)
	streak_turns = memento.get("streak_turns", 0)

func can_be_worked_on_by(unit: Unit, from_coord: Vector2i = GameConstants.INVALID_COORD) -> bool:
	if status != Status.ACTIVE:
		return false

	if not target_filters.is_empty():
		return _can_work_filters(unit, from_coord)

	# For non-location/non-coordinate tasks (e.g. countdown, eliminate), anyone can work on it (if applicable)
	# or it's passive. Eliminate doesn't show up in "Work on Task" UI anyway.
	if target_coord == GameConstants.INVALID_COORD and target_id.is_empty():
		return true

	# Distance check: unit must be at or adjacent to target coordinate
	if target_coord != GameConstants.INVALID_COORD:
		return _coord_matches_requirement(unit, from_coord, target_coord, target_kind)

	return true

func _can_work_filters(unit: Unit, from_coord: Vector2i) -> bool:
	var has_coord_filter := false
	for filter in target_filters:
		if not (filter is Dictionary):
			continue
		if not filter.has("target_coord"):
			continue
		has_coord_filter = true
		var coord: Vector2i = _to_vector2i(filter.get("target_coord", GameConstants.INVALID_COORD))
		var kind = filter.get("target_kind", target_kind)
		if _coord_matches_requirement(unit, from_coord, coord, kind):
			return true
	if has_coord_filter:
		return false
	return true

func _coord_matches_requirement(unit: Unit, from_coord: Vector2i, coord: Vector2i, kind) -> bool:
	var check_coord = from_coord
	if check_coord == GameConstants.INVALID_COORD:
		check_coord = unit.get_grid_location()

	var dist = 0
	if unit.grid_map and unit.grid_map.tile_set:
		dist = HexNavigator.get_hex_distance(check_coord, coord, unit.grid_map.tile_set.tile_offset_axis)
	else:
		# Fallback if no grid info
		dist = int(Vector2(check_coord).distance_to(Vector2(coord)))

	var kind_value := str(kind)
	match kind_value:
		GameConstants.Tasks.KIND_UNIT:
			return dist == 1
		GameConstants.Tasks.KIND_LOCATION, GameConstants.Tasks.KIND_ITEM:
			return dist == 0
		_:
			return dist <= 1

func _to_vector2i(value) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Dictionary and value.has("x") and value.has("y"):
		return Vector2i(int(value["x"]), int(value["y"]))
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return GameConstants.INVALID_COORD

@export_group("Dialogue & Zones")
@export var dialogue_id: StringName = &""
@export var start_dialogue_resource: String
@export var exit_dialogue_resource: String
@export var enter_dialogue_id: StringName = &""
@export var exit_dialogue_id: StringName = &""

@export var enter_journal_id: String = ""
@export var exit_journal_id: String = ""
@export var zone_coords: Array[Vector2i] = [] # For "explore_zone" type tasks
