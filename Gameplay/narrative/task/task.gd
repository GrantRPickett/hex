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
@export var event_type: String = "interact"
@export var target_coord: Vector2i = Vector2i(-999, -999)
@export var target_id: String = ""
# Optional target kind hint for validation/routing: "unit"|"location"|"item"|"none"
@export var target_kind: StringName = &"none"
@export var completion_condition: CompletionCondition

@export_group("Requirements")
@export var effort_required: int = 10
@export var is_optional: bool = false

@export_group("Duration")
# If > 0, task supports turn-based completion in addition to effort.
@export var duration_turns: int = 0 # When >0, do not use effort; stage should model AND/OR with multiple tasks.
# "cumulative" or "consecutive"; cumulative avoids stalemates.
@export var duration_mode: StringName = &"cumulative"
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
	if status != Status.ACTIVE:
		return

	if not _is_event_processed(type, data):
		return

	var actor = data.get("unit") as Unit
	var progress = _calculate_event_progress(actor, data)

	# If duration is in effect, avoid effort-based completion; stages can compose separate tasks for AND/OR.
	if duration_turns <= 0 and effort_required > 0:
		current_effort += progress
		progress_changed.emit(current_effort, effort_required, actor.faction if actor else 0)
		if current_effort >= effort_required:
			_complete_task(actor.faction if actor else 0, data.get("target"))

func _is_event_processed(type: String, data: Dictionary) -> bool:
	match type:
		"interact": return _process_interact(data)
		"explore": return _process_explore(data)
		"move": return _process_move_explore(data)
		"pickup": return _process_pickup(data)
		"ability_used": return _process_ability_used(data)
		"dialogue_started": return _process_dialogue_started(data)
		"unit_defeated": return _process_unit_defeated(data)
		"round_changed": return _process_round_changed(data)
	return false

func _calculate_event_progress(actor: Unit, data: Dictionary) -> int:
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
	var best_name = "grit"
	var best_val = -9999
	var attrs = actor.inv.get_attributes() if "inv" in actor and actor.inv else null
	if attrs:
		for attr_name in Target.COMBAT_ATTRIBUTE_NAMES:
			var val = attrs.get_attribute(attr_name)
			if val > best_val:
				best_val = val
				best_name = attr_name
	return best_name

func _process_interact(data: Dictionary) -> bool:
	if event_type != "interact":
		return false
	if target_coord != Vector2i(-999, -999):
		var coord = data.get("coord", Vector2i(-999, -999))
		if coord != target_coord:
			return false
	if not target_id.is_empty():
		var id_val = data.get("id", "")
		if id_val != target_id:
			return false
	return true

func _process_explore(data: Dictionary) -> bool:
	if event_type != "explore":
		return false
	if target_coord != Vector2i(-999, -999):
		var coord = data.get("coord", Vector2i(-999, -999))
		if coord != target_coord:
			return false
	if not target_id.is_empty():
		var id_val = data.get("id", "")
		if id_val != target_id:
			return false
	return true

func _process_unit_defeated(data: Dictionary) -> bool:
	# Elimination-style task: completes when a target unit or faction unit is defeated
	if event_type != "eliminate":
		return false
	var u: Unit = data.get("unit")
	if u == null:
		return false
	# If target_id is set, match by unit name/id; otherwise accept any enemy defeat
	if not target_id.is_empty():
		if String(u.unit_name) != target_id and StringName(u.unit_name) != StringName(target_id):
			return false
	return true

func _process_round_changed(data: Dictionary) -> bool:
	# Countdown-style task: advances each round until reaching effort_required
	var progressed := false
	if event_type == "countdown":
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
		if duration_mode == &"cumulative" and elapsed_turns >= duration_turns:
			_complete_task(data.get("unit").faction if data.has("unit") and data.get("unit") else 0)
		elif duration_mode == &"consecutive" and streak_turns >= duration_turns:
			_complete_task(data.get("unit").faction if data.has("unit") and data.get("unit") else 0)
	return progressed

func _duration_condition_holds(data: Dictionary) -> bool:
	# Non-obvious: uses current task criteria to infer whether the ongoing condition still holds this round.
	# For protect/hold-type tasks, external systems should supply pertinent fields in data.
	# Fallback heuristics below avoid tight coupling.
	match event_type:
		"interact":
			# Treat presence at target location as holding condition if coords match.
			if target_coord != Vector2i(-999, -999) and data.has("coord"):
				return data.get("coord") == target_coord
			return false
		"pickup":
			# Expect data.holding: bool when item remains held by allowed holder
			return bool(data.get("holding", false))
		"explore_zone":
			# Presence in zone continues condition
			if data.has("coord"):
				var c: Vector2i = data.get("coord")
				return c in zone_coords
			return false
		"countdown":
			return true
		_:
			return false

func _process_move_explore(data: Dictionary) -> bool:
	if event_type != "explore_zone":
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
	if event_type != "pickup":
		return false
	if not target_id.is_empty():
		var item_id = data.get("id", "")
		if item_id != target_id:
			return false
	return true

func _process_ability_used(data: Dictionary) -> bool:
	if event_type != "ability_used":
		return false
	if not target_id.is_empty():
		var ability_id = data.get("id", "")
		if ability_id != target_id:
			return false
	return true

func _process_dialogue_started(data: Dictionary) -> bool:
	if event_type != "dialogue_started":
		return false
	if not target_id.is_empty():
		var d_id = data.get("id", "")
		if d_id != target_id and StringName(d_id) != dialogue_id:
			return false
	return true

func _complete_task(faction: int, target: Object = null) -> void:
	status = Status.COMPLETED
	winning_faction = faction

	if target and event_type == "explore":
		if target.has_method("mark_explored"):
			target.mark_explored()
		if target.has_method("disarm_trap"):
			target.disarm_trap()

	completed.emit(faction)

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

func can_be_worked_on_by(_unit: Unit) -> bool:
	if status != Status.ACTIVE:
		return false

	# For now, we assume if the unit is interacting, it's already in range.
	# Range checks are handled by callers like AIActionEvaluator or PlayerController.
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
