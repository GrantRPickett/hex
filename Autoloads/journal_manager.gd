# journal_manager.gd
extends Node

const JournalSection := preload("res://Gameplay/Journal/journal_section.gd")
const JournalTopic := preload("res://Gameplay/Journal/journal_topic.gd")
const JournalEntry := preload("res://Gameplay/Journal/journal_entry.gd")

@export var journal_data_resource: Resource = preload("res://Resources/journal_data.tres")

var journal_data: JournalData
var _task_manager: TaskManager
var _connected_tasks: Array[Task] = [] # New member variable # New member variable

signal entry_unlocked(entry_id: String)

func setup(task_manager: TaskManager) -> void: # New setup method
	_task_manager = task_manager
	if _task_manager:
		_task_manager.objective_updated.connect(_on_objective_updated)
		_task_manager.objective_completed.connect(_on_objective_completed)
	print_debug("JournalManager: TaskManager setup complete.")

func _ready():
	_ensure_initialized()

func _ensure_initialized() -> void:
	if journal_data != null:
		return

	if journal_data_resource:
		journal_data = journal_data_resource.duplicate() # Create an editable instance
		if not journal_data is JournalData:
			push_error("JournalManager: 'journal_data_resource' is not a JournalData resource.")
			journal_data = JournalData.new() # Fallback to empty data
	else:
		journal_data = JournalData.new()

	_initialize_default_content()

func _initialize_default_content():
	# Create default sections in the specified order
	var default_sections = [
		{"id": "objectives", "title": "Objectives"},
		{"id": "people", "title": "People"},
		{"id": "places", "title": "Places"},
		{"id": "rules", "title": "Rules"},
		{"id": "achievements", "title": "Achievements"},
	]

	for section_data in default_sections:
		if not journal_data.get_section(section_data.id):
			var section = JournalSection.new(section_data.id, section_data.title)
			journal_data.add_section(section)

	# Load topics and entries from Resources/journal/
	var all_resources = _collect_resources_recursive("res://Resources/journal/")

	# Add topics first
	for res in all_resources:
		if res is JournalTopic:
			journal_data.add_topic(res)

	# Then add entries
	for res in all_resources:
		if res is JournalEntry:
			journal_data.add_entry(res)

func _collect_resources_recursive(path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if not file_name.begins_with("."):
					resources.append_array(_collect_resources_recursive(path + file_name + "/"))
			elif file_name.ends_with(".tres"):
				var res = load(path + file_name)
				if res:
					resources.append(res)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("JournalManager: Could not open directory at %s" % path)
	return resources

func unlock_entry(entry_id: String) -> bool:
	var entry: JournalEntry = journal_data.get_entry(entry_id)
	if entry and not entry.unlocked:
		entry.unlocked = true
		entry_unlocked.emit(entry_id)
		print("JournalManager: Unlocked entry: %s" % entry_id)
		return true
	elif entry and entry.unlocked:
		print("JournalManager: Entry '%s' already unlocked." % entry_id)
	else:
		push_warning("JournalManager: Attempted to unlock non-existent entry: %s" % entry_id)
	return false

func get_journal_data() -> JournalData:
	return journal_data

func get_entry(entry_id: String) -> JournalEntry:
	return journal_data.get_entry(entry_id)

func get_section(section_id: String) -> JournalSection:
	return journal_data.get_section(section_id)

# Method to prepare data for saving
func get_savable_data() -> Dictionary:
	_ensure_initialized()
	var savable_entries = {}
	for entry_id in journal_data.entries:
		var entry: JournalEntry = journal_data.entries[entry_id]
		if entry.unlocked:
			savable_entries[entry_id] = true # Store only unlocked status
	return {"unlocked_journal_entries": savable_entries}

# Method to load saved data
func load_savable_data(data: Dictionary):
	_ensure_initialized()
	if data.has("unlocked_journal_entries"):
		var unlocked_entries_map = data["unlocked_journal_entries"]
		for entry_id in unlocked_entries_map:
			var entry: JournalEntry = journal_data.get_entry(entry_id)
			if entry:
				entry.unlocked = true
			else:
				push_warning("JournalManager: Saved data refers to non-existent entry ID: %s" % entry_id)

func _on_objective_updated(objective: Objective) -> void:
	if objective == null:
		return

	# Disconnect from previously connected tasks to avoid duplicate signals
	for task in _connected_tasks:
		if is_instance_valid(task):
			if task.completed.is_connected(_on_task_status_changed):
				task.completed.disconnect(_on_task_status_changed)
			if task.failed.is_connected(_on_task_status_changed):
				task.failed.disconnect(_on_task_status_changed)
	_connected_tasks.clear()

	_add_or_update_objective_entry(objective)
	_add_or_update_stage_entry(objective.current_stage, objective)

	# Connect to current stage's tasks
	if objective.current_stage:
		for task in objective.current_stage.active_tasks:
			if task == null:
				continue
			_add_or_update_task_entry(task, _task_status_to_string(task.status), objective)
			# Connect for future updates
			if not task.completed.is_connected(_on_task_status_changed):
				task.completed.connect(_on_task_status_changed.bind(task, "completed", objective))
			if not task.failed.is_connected(_on_task_status_changed):
				task.failed.connect(_on_task_status_changed.bind(task, "failed", objective))
			_connected_tasks.append(task)


func _on_objective_completed(objective: Objective) -> void:
	if objective == null:
		return
	_add_or_update_objective_entry(objective, "completed")
	_add_or_update_stage_entry(objective.current_stage, objective, "completed")




func _add_or_update_objective_entry(objective: Objective, status: String = "active") -> void:
	if objective == null:
		return

	var obj_id = _generate_entry_id("objective", objective.objective_id)
	var objective_entry = journal_data.get_entry(obj_id)
	var objective_section = _get_objective_section()

	if objective_entry == null:
		objective_entry = JournalEntry.new(
			obj_id,
			"Objective: " + objective.display_name,
			objective.description,
			"objectives", # Topic ID, can be the same as section if no sub-topics
			"objective",
			status,
			objective.objective_id
		)
		journal_data.add_entry(objective_entry)
		objective_section.add_entry(objective_entry)
		unlock_entry(obj_id) # Unlock it when first added
	else:
		objective_entry.title = "Objective: " + objective.display_name
		objective_entry.content = objective.description
		objective_entry.status = status
	print_debug("[JournalManager] Objective Entry '%s' status: %s" % [objective_entry.title, objective_entry.status])


func _add_or_update_stage_entry(stage: Stage, objective: Objective, status: String = "active") -> void:
	if stage == null or objective == null:
		return

	var stage_id = _generate_entry_id("stage", objective.objective_id + "_" + stage.stage_id)
	var stage_entry = journal_data.get_entry(stage_id)
	var objective_section = _get_objective_section() # Stages are sub-entries of objectives

	var content_text = stage.description
	if stage.start_dialogue_timeline:
		content_text += "\n(Dialogue: %s)" % stage.start_dialogue_timeline.resource_path.get_file().get_basename()

	if stage_entry == null:
		stage_entry = JournalEntry.new(
			stage_id,
			"Stage: " + stage.display_name,
			content_text,
			"objectives",
			"stage",
			status,
			stage.stage_id
		)
		journal_data.add_entry(stage_entry)
		objective_section.add_entry(stage_entry)
		unlock_entry(stage_id)
	else:
		stage_entry.title = "Stage: " + stage.display_name
		stage_entry.content = content_text
		stage_entry.status = status
	print_debug("[JournalManager] Stage Entry '%s' status: %s" % [stage_entry.title, stage_entry.status])


func _add_or_update_task_entry(task: Task, status: String = "active", objective: Objective = null) -> void:
	if task == null:
		return

	var task_full_id = task.task_id
	if objective:
		task_full_id = objective.objective_id + "_" + task.task_id

	var task_entry_id = _generate_entry_id("task", task_full_id)
	var task_entry = journal_data.get_entry(task_entry_id)
	var objective_section = _get_objective_section()

	var content_text = task.description

	if task_entry == null:
		task_entry = JournalEntry.new(
			task_entry_id,
			"Task: " + task.display_name,
			content_text,
			"objectives",
			"task",
			status,
			task_full_id
		)
		journal_data.add_entry(task_entry)
		objective_section.add_entry(task_entry)
		unlock_entry(task_entry_id)
	else:
		task_entry.title = "Task: " + task.display_name
		task_entry.content = content_text
		task_entry.status = status
	print_debug("[JournalManager] Task Entry '%s' status: %s" % [task_entry.title, task_entry.status])


func _generate_entry_id(prefix: String, game_object_id: String) -> String:
	return prefix + "_" + game_object_id.replace("res://", "").replace("/", "_").replace(".tres", "")

func _get_objective_section() -> JournalSection:
	var section = journal_data.get_section("objectives")
	if section == null:
		section = JournalSection.new("objectives", "Objectives")
		journal_data.add_section(section)
	return section

func _on_task_status_changed(task: Task, new_status_str: String, objective: Objective) -> void:
	if task == null:
		return
	_add_or_update_task_entry(task, new_status_str, objective)

func _task_status_to_string(status_enum: Task.Status) -> String:
	match status_enum:
		Task.Status.PENDING: return "pending"
		Task.Status.ACTIVE: return "active"
		Task.Status.COMPLETED: return "completed"
		Task.Status.FAILED: return "failed"
		Task.Status.CANCELLED: return "cancelled"
	return "unknown"
