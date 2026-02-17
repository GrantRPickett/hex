class_name Stage
extends Resource

const StageSpawnEntry := preload("res://Resources/task/stage_spawn_entry.gd")

signal stage_completed(next_stage: Stage)
signal stage_ready_to_advance
signal stage_failed

enum CompletionMode {ALL_REQUIRED, ANY_REQUIRED, ANY_WITH_BRANCHING}

@export var id: StringName
@export var tasks: Array[Task]
@export var completion_mode: CompletionMode = CompletionMode.ALL_REQUIRED
@export var auto_advance: bool = true ## If false, stage waits for advance() call after requirements are met.
@export var start_dialogue_resource: String
@export var exit_dialogue_id: StringName
@export var enter_journal_id: String
@export var exit_journal_id: String
@export var spawns: Array[StageSpawnEntry] = []
@export var enemy_spawns: Array[LevelUnitSpawnEntry] = []
@export var neutral_spawns: Array[LevelUnitSpawnEntry] = []
@export var loot_spawns: Array[LevelLootEntry] = []
@export var location_spawns: Array[LevelTaskEntry] = []

@export_group("Transitions")
@export var default_next_stage: Stage
## Maps a Task ID (StringName) to a Stage Resource. Used if mode is ANY_WITH_BRANCHING.
@export var branching_transitions: Dictionary = {}

# Runtime State
var active_tasks: Array[Task] = []
var _pending_next_stage: Stage = null

func start_stage(context_target: Unit = null) -> void:
	_pending_next_stage = null
	active_tasks.clear()
	for task_res in tasks:
		# Duplicate task to ensure unique state for this run
		var task = task_res.duplicate(true)
		task.initialize(context_target)
		task.completed.connect(_on_task_completed.bind(task))
		task.failed.connect(_on_task_failed)
		active_tasks.append(task)

func handle_event(type: String, data: Dictionary) -> void:
	for task in active_tasks:
		task.handle_event(type, data)

func _on_task_completed(faction: int, task: Task) -> void:
	var next_stage: Stage = null
	var is_ready: bool = false

	match completion_mode:
		CompletionMode.ANY_WITH_BRANCHING:
			next_stage = branching_transitions.get(task.id, default_next_stage)
			is_ready = true

		CompletionMode.ANY_REQUIRED:
			next_stage = default_next_stage
			is_ready = true

		CompletionMode.ALL_REQUIRED:
			if _are_all_required_tasks_complete():
				next_stage = default_next_stage
				is_ready = true

	if is_ready:
		_pending_next_stage = next_stage
		if auto_advance:
			stage_completed.emit(next_stage)
		else:
			stage_ready_to_advance.emit()

func advance() -> void:
	if _pending_next_stage:
		stage_completed.emit(_pending_next_stage)
	elif completion_mode == CompletionMode.ALL_REQUIRED and _are_all_required_tasks_complete():
		# Fallback if advance is called manually without a specific pending stage (e.g. forced)
		stage_completed.emit(default_next_stage)

func _on_task_failed() -> void:
	# Logic for stage failure could go here (e.g. if a critical task fails)
	pass

func _are_all_required_tasks_complete() -> bool:
	for t in active_tasks:
		if not t.is_optional and t.status != Task.Status.COMPLETED:
			return false
	return true

func end_stage() -> void:
	for t in active_tasks:
		if t.status == Task.Status.ACTIVE:
			t.cancel()