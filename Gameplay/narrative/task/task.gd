class_name Task
extends Resource

signal progress_changed(current: int, required: int, faction_id: int)
signal completed(faction_id: int)
signal failed()
signal dialogue_requested(dialogue_id: StringName, unit_index: int)

enum Status {PENDING, ACTIVE, COMPLETED, FAILED, CANCELLED}

@export_group("Identity")
@export var id: StringName
@export var title: String = "New Task"
@export_multiline var description: String = "A new task."
@export var icon: Texture2D

@export_group("Criteria")
@export var event_type: String = GameConstants.TaskEvents.TARGET_INTERACTION
@export var target_coord: Vector2i = GameConstants.INVALID_COORD
@export var target_id: String = ""
# Optional target kind hint for validation/routing: "unit"|"location"|"item"|"none"
@export var target_kind: StringName = GameConstants.Tasks.KIND_NONE
@export var target_faction: int = Unit.Faction.PLAYER
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
	print_debug("[Task %s] handle_event received type: %s with data: %s" % [id, type, data])
	if status != Status.ACTIVE:
		print_debug("[Task %s] handle_event ignored: status is not ACTIVE" % id)
		return

	if not _is_event_processed(type, data):
		print_debug("[Task %s] handle_event ignored: _is_event_processed returned false" % id)
		return

	var actor = data.get("unit") as Unit
	var progress = _calculate_event_progress(actor, data)

	# Special case for eliminate: if progress was made, check completion_condition
	if type == GameConstants.TaskEvents.UNIT_DEFEATED and event_type == GameConstants.TaskEvents.ELIMINATE:
		if completion_condition and completion_condition.type == GameConstants.Tasks.CONDITION_DEFEAT_ALL:
			# This is handled by TaskManager or Stage checking UnitManager
			# But we can still track progress here if effort_required is set correctly
			pass

	# If duration is in effect, avoid effort-based completion; stages can compose separate tasks for AND/OR.
	if duration_turns <= 0 and effort_required > 0:
		current_effort += progress
		progress_changed.emit(current_effort, effort_required, actor.faction if actor else 0)
		if current_effort >= effort_required:
			_complete_task(actor.faction if actor else 0, data.get("target"))

func _is_event_processed(type: String, data: Dictionary) -> bool:
	match type:
		GameConstants.TaskEvents.VISIT: return _process_visit(data)
		GameConstants.TaskEvents.EXPLORE: return _process_explore(data)
		GameConstants.TaskEvents.MOVE: return _process_move_explore(data)
		GameConstants.TaskEvents.LOOT: return _process_loot(data)
		GameConstants.TaskEvents.TRAPPED: return _process_trapped(data)
		GameConstants.TaskEvents.FIGHT: return _process_fight(data)
		GameConstants.TaskEvents.CONVINCE: return _process_convince(data)
		GameConstants.TaskEvents.ABILITY_USED: return _process_ability_used(data)
		GameConstants.TaskEvents.DIALOGUE_STARTED: return _process_dialogue_started(data)
		GameConstants.TaskEvents.UNIT_DEFEATED: return _process_unit_defeated(data)
		GameConstants.TaskEvents.ROUND_CHANGED: return _process_round_changed(data)
	return false

func _calculate_event_progress(actor: Unit, data: Dictionary) -> int:
	if event_type == GameConstants.TaskEvents.ELIMINATE:
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

func _process_visit(data: Dictionary) -> bool:
	if event_type != GameConstants.TaskEvents.VISIT:
		return false
	return _validate_interaction_data(data)

func _process_interact(data: Dictionary) -> bool:
	if event_type != GameConstants.TaskEvents.TARGET_INTERACTION:
		return false
	return _validate_interaction_data(data)

func _validate_interaction_data(data: Dictionary) -> bool:
	if target_coord != GameConstants.INVALID_COORD:
		var coord = data.get("coord", GameConstants.INVALID_COORD)
		if coord != target_coord:
			return false
	if not target_id.is_empty():
		var id_val = data.get("id", "")
		if id_val != target_id:
			return false
	return true

func _process_explore(data: Dictionary) -> bool:
	if event_type != GameConstants.TaskEvents.EXPLORE:
		return false
	return _validate_interaction_data(data)

func _process_loot(data: Dictionary) -> bool:
	if event_type != GameConstants.TaskEvents.LOOT:
		return false
	return _validate_interaction_data(data)

func _process_trapped(data: Dictionary) -> bool:
	if event_type != GameConstants.TaskEvents.TRAPPED:
		return false
	return _validate_interaction_data(data)

func _process_fight(data: Dictionary) -> bool:
	if event_type != GameConstants.TaskEvents.FIGHT:
		return false
	return _validate_interaction_data(data)

func _process_convince(data: Dictionary) -> bool:
	if event_type != GameConstants.TaskEvents.CONVINCE:
		return false
	return _validate_interaction_data(data)

func _process_unit_defeated(data: Dictionary) -> bool:
	# Elimination-style task: completes when a target unit or faction unit is defeated
	if event_type != GameConstants.TaskEvents.ELIMINATE:
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
		# Duration-based completion independent of effort
		if duration_mode == GameConstants.Tasks.DURATION_CUMULATIVE and elapsed_turns >= duration_turns:
			_complete_task(data.get("unit").faction if data.has("unit") and data.get("unit") else 0)
		elif duration_mode == GameConstants.Tasks.DURATION_CONSECUTIVE and streak_turns >= duration_turns:
			_complete_task(data.get("unit").faction if data.has("unit") and data.get("unit") else 0)
	return progressed

func _duration_condition_holds(data: Dictionary) -> bool:
	# Non-obvious: uses current task criteria to infer whether the ongoing condition still holds this round.
	# For protect/hold-type tasks, external systems should supply pertinent fields in data.
	# Fallback heuristics below avoid tight coupling.
	match event_type:
		GameConstants.TaskEvents.TARGET_INTERACTION:
			# Treat presence at target location as holding condition if coords match.
			if target_coord != GameConstants.INVALID_COORD and data.has("coord"):
				return data.get("coord") == target_coord
			return false
		GameConstants.TaskEvents.PICKUP:
			# Expect data.holding: bool when item remains held by allowed holder
			return bool(data.get("holding", false))
		GameConstants.TaskEvents.EXPLORE_ZONE:
			# Presence in zone continues condition
			if data.has("coord"):
				var c: Vector2i = data.get("coord")
				return c in zone_coords
			return false
		GameConstants.TaskEvents.COUNTDOWN:
			return true
		_:
			return false

func _process_move_explore(data: Dictionary) -> bool:
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

func _process_pickup(data: Dictionary) -> bool:
	if event_type != GameConstants.TaskEvents.PICKUP:
		return false
	if not target_id.is_empty():
		var item_id = data.get("id", "")
		if item_id != target_id:
			return false
	return true

func _process_ability_used(data: Dictionary) -> bool:
	if event_type != GameConstants.TaskEvents.ABILITY_USED:
		return false
	if not target_id.is_empty():
		var ability_id = data.get("id", "")
		if ability_id != target_id:
			return false
	return true

func _process_dialogue_started(data: Dictionary) -> bool:
	if event_type != GameConstants.TaskEvents.DIALOGUE_STARTED:
		return false
	if not target_id.is_empty():
		var d_id = data.get("id", "")
		if d_id != target_id and StringName(d_id) != dialogue_id:
			return false
	return true

func _complete_task(faction: int, target: Object = null) -> void:
	status = Status.COMPLETED
	winning_faction = faction

	if target and event_type == GameConstants.TaskEvents.EXPLORE:
		if target.has_method("mark_explored"):
			target.mark_explored()
		if target.has_method("disarm_trap"):
			target.disarm_trap()

	completed.emit(faction)

func force_complete(faction: int = -1) -> void:
	if status == Status.ACTIVE:
		current_effort = effort_required
		_complete_task(faction)

func _fail_task() -> void:
	status = Status.FAILED
	failed.emit()

func cancel() -> void:
	if status == Status.ACTIVE:
		status = Status.CANCELLED
		# We do not emit failed here to avoid triggering failure logic during clean transitions

func get_progress_ratio() -> float:
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

	# For non-location/non-coordinate tasks (e.g. countdown, eliminate), anyone can work on it (if applicable)
	# or it's passive. Eliminate doesn't show up in "Work on Task" UI anyway.
	if target_coord == GameConstants.INVALID_COORD and target_id.is_empty():
		return true

	# Distance check: unit must be at or adjacent to target coordinate
	if target_coord != GameConstants.INVALID_COORD:
		var check_coord = from_coord
		if check_coord == GameConstants.INVALID_COORD:
			check_coord = unit.get_grid_location()

		var dist = 0
		if unit.grid_map and unit.grid_map.tile_set:
			dist = HexNavigator.get_hex_distance(check_coord, target_coord, unit.grid_map.tile_set.tile_offset_axis)
		else:
			# Fallback if no grid info
			dist = int(Vector2(check_coord).distance_to(Vector2(target_coord)))

		match target_kind:
			GameConstants.Tasks.KIND_UNIT:
				# Tasks for units need to be adjacent
				return dist == 1
			GameConstants.Tasks.KIND_LOCATION, GameConstants.Tasks.KIND_ITEM:
				# Location or loot tasks need to be on the same hex
				return dist == 0
			_:
				# Default: Must be same cell or adjacent if kind unknown but coord set
				return dist <= 1

	return true

@export_group("Dialogue & Zones")
@export var dialogue_id: StringName = &""
@export var start_dialogue_resource: String = ""
@export var exit_dialogue_resource: String = ""
@export var enter_dialogue_id: StringName = &""
@export var exit_dialogue_id: StringName = &""
@export var enter_journal_id: String = ""
@export var exit_journal_id: String = ""
@export var zone_coords: Array[Vector2i] = [] # For "explore_zone" type tasks
