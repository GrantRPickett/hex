class_name Task
extends Resource

signal progress_changed(current: int, required: int, faction_id: int)
signal completed(faction_id: int, unit: Unit, task_id: StringName)
signal failed()
signal dialogue_requested(dialogue_id: StringName, unit_index: int)

enum Status {PENDING, ACTIVE, COMPLETED, FAILED, CANCELLED}

@export_group("Identity")
@export var id: StringName
@export var title: String = "New Task"
@export_multiline var description: String = "A new task."
@export var icon: Texture2D
@export var owning_faction: int = GameConstants.Faction.PLAYER

@export_group("Criteria")
@export var event_type: String = GameConstants.Activity.INTERACT
@export var target_coord: Vector2i = GameConstants.INVALID_COORD
@export var target_id: String = ""
# Optional target kind hint for validation/routing: "unit"|"location"|"item"|"none"
@export var target_kind: StringName = GameConstants.Activity.KIND_NONE
@export var target_faction: int = GameConstants.Faction.PLAYER
@export var target_filters: Array = []
@export var completion_condition: CompletionCondition
## Optional: If this task points to a specific target, the spawn entry for that target.
@export var target_spawn: Resource

@export_group("Requirements")
@export var effort_required: int = 0
@export var is_optional: bool = false
@export var carryover_to_next_stage: bool = false

@export_group("Duration")
# If > 0, task supports turn-based completion in addition to effort.
@export var duration_turns: int = 0
@export var duration_mode: StringName = GameConstants.Tasks.DURATION_CUMULATIVE
var elapsed_turns: int = 0
var streak_turns: int = 0

@export_group("Opposition")
@export var is_opposed: bool = false

@export_group("Rewards")
@export var journal_entry_id: String = ""
@export var reward_id: String = ""
@export var reward_resource: TaskReward

@export_group("Dialogue & Zones")
@export var dialogue_id: StringName = &""
@export var start_dialogue_resource: String
@export var exit_dialogue_resource: String
@export var enter_dialogue_id: StringName = &""
@export var exit_dialogue_id: StringName = &""

@export var enter_journal_id: String = ""
@export var exit_journal_id: String = ""
@export var zone_coords: Array[Vector2i] = []

## Runtime State
var status: Status = Status.PENDING
var current_effort: int = 0
var winning_faction: int = -1
var _skip_exit_logic: bool = false

## True when the task tracks cumulative effort toward completion (e.g. convince).
## False = completion is world-driven (target willpower hits 0, unit defeated, etc.).
var has_effort_tracking: bool:
	get: return effort_required > 0

func initialize() -> void:
	status = Status.ACTIVE
	current_effort = 0
	winning_faction = -1
	elapsed_turns = 0
	streak_turns = 0

func handle_event(type: String, data: Dictionary) -> void:
	if status != Status.ACTIVE:
		return

	if not TaskProcessor.is_event_type_supported(self, type):
		return

	var actor: Unit = data.get("attacker") as Unit if type == GameConstants.Activity.UNIT_DEFEATED else data.get("unit") as Unit
	if actor:
		var effective_faction = actor.get_effective_faction()
		if effective_faction != owning_faction:
			return

	if not TaskProcessor.is_event_processed(self, type, data):
		return

	var progress = TaskProcessor.calculate_event_progress(self, actor, data, type)
	_apply_progress(progress, actor, data, type)

func _apply_progress(progress: int, actor: Unit, data: Dictionary, type: String) -> void:
	var faction := actor.faction if actor else owning_faction

	# For convince tasks: lazily derive effort_required from the target's max willpower
	# so the task resource never needs to be manually kept in sync with unit stats.
	if not has_effort_tracking and type == GameConstants.Activity.CONVINCE:
		var target: Target = data.get("target")
		if target and target.has_method("get_max_willpower"):
			effort_required = target.get_max_willpower() >> 1  # half, integer shift

	if has_effort_tracking:
		current_effort = min(effort_required, current_effort + progress)
		progress_changed.emit(current_effort, effort_required, faction)
		if current_effort >= effort_required:
			_complete_task(faction, data.get("target"))
	elif duration_turns > 0:
		_apply_duration_progress(data, progress)
	# else: world-driven — task_manager emits task_updated via interacted signal


func _apply_duration_progress(data: Dictionary, progress: int = 1) -> void:
	var holds = TaskProcessor.duration_condition_holds(self, data)
	if holds:
		elapsed_turns += progress
		streak_turns += 1
	else:
		streak_turns = 0

	progress_changed.emit(elapsed_turns, duration_turns, owning_faction)

	var winner = owning_faction # TODO Linked Task winners and losers conditions

	if duration_mode == GameConstants.Tasks.DURATION_CUMULATIVE and elapsed_turns >= duration_turns:
		_complete_task(winner)
	elif duration_mode == GameConstants.Tasks.DURATION_CONSECUTIVE and streak_turns >= duration_turns:
		_complete_task(winner)

func _complete_task(faction: int, target: Target = null) -> void:
	if not exit_dialogue_resource.is_empty():
		EventBus.dialogue_requested.emit(exit_dialogue_resource, exit_dialogue_id)
	status = Status.COMPLETED
	winning_faction = faction
	completed.emit(faction, target, id)


func force_complete(faction: int = -1) -> void:
	if status == Status.ACTIVE:
		if has_effort_tracking:
			current_effort = effort_required
		_complete_task(faction, null)

func _fail_task() -> void:
	status = Status.FAILED
	failed.emit()

func cancel() -> void:
	if status == Status.ACTIVE: status = Status.CANCELLED

func suppress_exit_logic() -> void:
	_skip_exit_logic = true

func get_progress_ratio() -> float:
	if duration_turns > 0: return float(elapsed_turns) / float(duration_turns)
	if has_effort_tracking: return float(current_effort) / float(effort_required)
	return 1.0 # world-driven; HUDTaskPresenter reads target willpower directly

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
	if status != Status.ACTIVE: return false
	if not target_filters.is_empty(): return _can_work_filters(unit, from_coord)

	# If no filters, and no coord/ID, it's an abstract task (like eliminate)
	# and shouldn't provide a context action at a specific hex.
	if target_coord == GameConstants.INVALID_COORD and target_id.is_empty():
		return false

	if target_coord != GameConstants.INVALID_COORD:
		return _coord_matches_requirement(unit, from_coord, target_coord, target_kind)
	return true

func _can_work_filters(unit: Unit, from_coord: Vector2i) -> bool:
	var has_coord_filter := false
	for filter in target_filters:
		if filter is Dictionary and filter.has("target_coord"):
			has_coord_filter = true
			var coord: Vector2i = TaskProcessor.to_vector2i(filter.get("target_coord", GameConstants.INVALID_COORD))
			if _coord_matches_requirement(unit, from_coord, coord, filter.get("target_kind", target_kind)):
				return true
	return not has_coord_filter

func _coord_matches_requirement(unit: Unit, from_coord: Vector2i, coord: Vector2i, kind) -> bool:
	var check_coord: Vector2i = from_coord if from_coord != GameConstants.INVALID_COORD else unit.get_grid_location()
	var dist: int = 0
	if unit.grid_map and unit.grid_map.tile_set:
		dist = HexLib.get_distance(check_coord, coord, unit.grid_map.tile_set.tile_offset_axis)
	else:
		dist = int(Vector2(check_coord).distance_to(Vector2(coord)))

	match str(kind):
		GameConstants.Activity.KIND_UNIT: return dist == 1
		GameConstants.Activity.KIND_LOCATION, GameConstants.Activity.KIND_ITEM: return dist == 0
		_: return dist <= 1
