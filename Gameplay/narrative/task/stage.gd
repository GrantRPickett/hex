class_name Stage
extends Resource

signal stage_completed(next_stage: Stage)
signal stage_failed
signal stage_ready_to_advance

signal task_completed(task: Task, faction: int, unit: Unit)
signal task_failed(task: Task)
signal task_updated(task: Task, faction: int)
signal dialogue_requested(dialogue_resource_path: String, dialogue_id: StringName)

enum CompletionMode {ALL_REQUIRED, ANY_REQUIRED, SOME_REQUIRED, ANY_WITH_BRANCHING}

@export var id: StringName
@export var tasks: Array[Task]
@export var completion_mode: CompletionMode = CompletionMode.ALL_REQUIRED
@export var auto_advance: bool = true ## If false, stage waits for advance() call after requirements are met.
@export var start_dialogue_resource: String
@export var exit_dialogue_resource: String
@export var enter_dialogue_id: StringName
@export var exit_dialogue_id: StringName
@export var enter_journal_id: String
@export var exit_journal_id: String
@export var spawns: Array = [] # Deprecated: use enemy_spawns/neutral_spawns
@export var enemy_spawns: Array[LevelUnitSpawnEntry] = []
@export var neutral_spawns: Array[LevelUnitSpawnEntry] = []
@export var loot_spawns: Array[LevelLootEntry] = []
@export var location_spawns: Array[LevelTaskEntry] = []
@export var dialogue_entries: Array[LevelDialogueEntry] = []
@export var journal_entries: Array[JournalEntry] = []
@export var dialogue_journal_entries: Array[LevelDialogueJournalEntry] = []


@export_group("Transitions")
@export var default_next_stage: Stage
## Maps a Task ID (StringName) to a Stage Resource. Used if mode is ANY_WITH_BRANCHING.
@export var branching_transitions: Dictionary = {}

# Runtime State
var active_tasks: Array[Task] = []
var _pending_next_stage: Stage = null

func start_stage(p_carryover_tasks: Array[Task] = []) -> void:
	_pending_next_stage = null
	active_tasks.clear()

	var consumed_carryovers: Array[Task] = []
	var has_mandatory : bool = false

	for task_res in tasks:
		var carryover: Task = null
		for ct in p_carryover_tasks:
			if ct.id == task_res.id:
				carryover = ct
				break

		var task: Task
		if carryover:
			task = carryover
			consumed_carryovers.append(carryover)
			# Do NOT initialize, keep existing progress
		else:
			# Duplicate task to ensure unique state for this run
			task = task_res.duplicate(true)
			task.initialize()

		_connect_task_signals(task)
		active_tasks.append(task)
		if not task.is_optional:
			has_mandatory = true

	# Add any carryover tasks that weren't in the new stage's explicit tasks list
	for ct in p_carryover_tasks:
		if ct not in consumed_carryovers:
			_connect_task_signals(ct)
			active_tasks.append(ct)
			if not ct.is_optional:
				has_mandatory = true

	if not has_mandatory and completion_mode == CompletionMode.ALL_REQUIRED:
		GameLogger.warning(GameLogger.Category.SYSTEM, "Stage '%s' has no mandatory tasks in ALL_REQUIRED mode. It may never advance automatically." % id)

	if not start_dialogue_resource.is_empty():
		if EventBus:
			EventBus.dialogue_requested.emit(start_dialogue_resource, enter_dialogue_id)
		else:
			dialogue_requested.emit(start_dialogue_resource, enter_dialogue_id)

	# Log task expectations
	GameLogger.debug(GameLogger.Category.SYSTEM, "[Stage] Starting stage: '%s'. Task target expectations:" % id)
	for task in active_tasks:
		var target_info = ""
		if not task.target_id.is_empty():
			target_info += "ID: '%s'" % task.target_id
		if task.target_coord != GameConstants.INVALID_COORD:
			if not target_info.is_empty(): target_info += ", "
			target_info += "Coord: %s" % task.target_coord
		
		if target_info.is_empty():
			target_info = "None (Abstract Task)"
			
		GameLogger.debug(GameLogger.Category.SYSTEM, "[Stage]   Task '%s' expects target: %s" % [task.id, target_info])

func _connect_task_signals(task: Task) -> void:
	# Ensure we don't double-connect if it was already connected (though usually we start fresh)
	if not task.completed.is_connected(_on_task_completed):
		task.completed.connect(_on_task_completed.bind(task))
	if not task.failed.is_connected(_on_task_failed):
		task.failed.connect(_on_task_failed.bind(task))
	if not task.progress_changed.is_connected(_on_task_progress_changed):
		task.progress_changed.connect(_on_task_progress_changed.bind(task))
	if not task.dialogue_requested.is_connected(_on_task_dialogue_requested):
		task.dialogue_requested.connect(_on_task_dialogue_requested)

func _disconnect_task_signals(task: Task) -> void:
	if task.completed.is_connected(_on_task_completed):
		task.completed.disconnect(_on_task_completed)
	if task.failed.is_connected(_on_task_failed):
		task.failed.disconnect(_on_task_failed)
	if task.progress_changed.is_connected(_on_task_progress_changed):
		task.progress_changed.disconnect(_on_task_progress_changed)
	if task.dialogue_requested.is_connected(_on_task_dialogue_requested):
		task.dialogue_requested.disconnect(_on_task_dialogue_requested)

func _on_task_dialogue_requested(res_path: String, d_id: StringName) -> void:
	dialogue_requested.emit(res_path, d_id)

func handle_event(type: String, data: Dictionary) -> void:
	for task in active_tasks:
		task.handle_event(type, data)

func _on_task_completed(faction: int, unit: Unit, task: Task) -> void:
	task_completed.emit(task, faction, unit)
	var next_stage: Stage = null
	var is_ready: bool = false

	match completion_mode:
		CompletionMode.ANY_WITH_BRANCHING:
			next_stage = branching_transitions.get(task.id, default_next_stage)
			is_ready = true
		CompletionMode.SOME_REQUIRED:
			# Spec change: If the faction that just completed a task now has
			# all of THEIR required tasks complete, the stage advances.
			if _are_faction_required_tasks_complete(faction):
				next_stage = default_next_stage
				is_ready = true
		CompletionMode.ANY_REQUIRED:
			next_stage = default_next_stage
			is_ready = true

		CompletionMode.ALL_REQUIRED:
			# Spec change: If the faction that just completed a task now has
			# all of THEIR required tasks complete, the stage advances.
			if _are_faction_required_tasks_complete(faction):
				next_stage = default_next_stage
				is_ready = true

	if is_ready:
		if task:
			task.suppress_exit_logic()
		_pending_next_stage = next_stage
		if auto_advance:
			stage_completed.emit(next_stage)
		else:
			stage_ready_to_advance.emit()

func advance() -> void:
	if _pending_next_stage:
		stage_completed.emit(_pending_next_stage)
	elif completion_mode == CompletionMode.ALL_REQUIRED:
		# Fallback if advance is called manually: check if ANY faction has completed their requirements
		var factions = [GameConstants.Faction.PLAYER, GameConstants.Faction.ENEMY, GameConstants.Faction.NEUTRAL]
		for faction in factions:
			if _are_faction_required_tasks_complete(faction):
				stage_completed.emit(default_next_stage)
				return

func _on_task_failed(task: Task) -> void:
	task_failed.emit(task)
	if not task.is_optional:
		stage_failed.emit()

func _on_task_progress_changed(_current: int, _required: int, faction: int, task: Task) -> void:
	task_updated.emit(task, faction)

func _are_faction_required_tasks_complete(faction: int) -> bool:
	var faction_tasks: Array = active_tasks.filter(func(t): return t.owning_faction == faction)
	if faction_tasks.is_empty():
		return false

	var mandatory_tasks: Array = faction_tasks.filter(func(t): return not t.is_optional)
	if mandatory_tasks.is_empty():
		# Factions with no mandatory tasks cannot trigger stage completion via this mode
		return false

	for t in mandatory_tasks:
		if t.status != Task.Status.COMPLETED:
			return false
	return true

func _are_all_required_tasks_complete() -> bool:
	for t in active_tasks:
		if not t.is_optional and t.status != Task.Status.COMPLETED:
			return false
	return true

func end_stage() -> void:
	# Play Stage Exit Logic (Dialogue / Journal)
	if not exit_dialogue_resource.is_empty():
		if EventBus:
			EventBus.dialogue_requested.emit(exit_dialogue_resource, exit_dialogue_id)
		else:
			dialogue_requested.emit(exit_dialogue_resource, exit_dialogue_id)

	for t in active_tasks:
		if t.status == Task.Status.ACTIVE:
			if not t.carryover_to_next_stage:
				t.cancel()
		_disconnect_task_signals(t)

func create_memento() -> Dictionary:
	var task_mementos: Array[Dictionary] = []
	for task in active_tasks:
		task_mementos.append(task.create_memento())

	return {
		"id": id,
		"active_tasks": task_mementos
	}

func restore_from_memento(memento: Dictionary) -> void:
	var task_mementos = memento.get("active_tasks", [])
	# We expect active_tasks to already be populated by start_stage (duplicated from resources)
	# We just need to apply the runtime state to the matching tasks.
	for task_data in task_mementos:
		var task_id = task_data.get("id")
		for active_task in active_tasks:
			if active_task.id == task_id:
				active_task.restore_from_memento(task_data)
				break
