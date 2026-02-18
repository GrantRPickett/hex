# journal_manager.gd
extends Node

const JournalSection := preload("res://Gameplay/journal/journal_section.gd")
const JournalTopic := preload("res://Gameplay/journal/journal_topic.gd")
const JournalEntry := preload("res://Gameplay/journal/journal_entry.gd")

var journal_data: JournalData
var _task_manager: TaskManager
var _connected_tasks: Array[Task] = [] # New member variable # New member variable

signal entry_unlocked(entry_id: String)

func setup(task_manager: TaskManager) -> void: # New setup method
	print_debug("JournalManager: setup() called.")
	_task_manager = task_manager
	if _task_manager:
		_task_manager.objective_updated.connect(_on_objective_updated)
		_task_manager.objective_completed.connect(_on_objective_completed)
	print_debug("JournalManager: TaskManager setup complete.")

func _ready():
	print_debug("JournalManager: _ready() called.")
	_ensure_initialized()

func _ensure_initialized() -> void:
	print_debug("JournalManager: _ensure_initialized() called.")
	if journal_data != null:
		return

	journal_data = JournalData.new() # Always create a new instance
	_initialize_default_content()

func _initialize_default_content():
	print_debug("JournalManager: _initialize_default_content() called.")
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

	# Ensure default topic for objectives exists for dynamically added entries
	var objectives_section_id = "objectives"
	if not journal_data.get_topic(objectives_section_id):
		var objectives_topic = JournalTopic.new(objectives_section_id, "Objectives", objectives_section_id)
		journal_data.add_topic(objectives_topic)

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
	print_debug("JournalManager: _collect_resources_recursive() called for path: %s" % path)
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
				var full_path = path + file_name
				var res = load(full_path)
				if res:
					print_debug("JournalManager: _collect_resources_recursive() loaded: %s. Is JournalEntry: %s" % [full_path, res is JournalEntry])
					resources.append(res)
				else:
					print_debug("JournalManager: _collect_resources_recursive() failed to load: %s" % full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("JournalManager: Could not open directory at %s" % path)
	return resources

func unlock_entry(entry_id: String) -> bool:
	print_debug("JournalManager: unlock_entry() called for ID: %s" % entry_id)
	_ensure_initialized()
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

func unlock_coupled_entry(entry_id: String, section_id: String, topic_id: String, notes: String, _flag_name: StringName) -> void:
	print_debug("JournalManager: unlock_coupled_entry() called for ID: %s" % entry_id)
	_ensure_initialized()
	var entry: JournalEntry = journal_data.get_entry(entry_id)
	if entry == null:
		# Create a new dynamic entry
		entry = JournalEntry.new(
			entry_id,
			entry_id.capitalize(), # Title placeholder
			notes,
			topic_id if not topic_id.is_empty() else "objectives",
			section_id if not section_id.is_empty() else "objectives",
			"dialogue",
			"completed",
			entry_id
		)
		journal_data.add_entry(entry)

	if not entry.unlocked:
		entry.unlocked = true
		entry_unlocked.emit(entry_id)
		print("JournalManager: Unlocked coupled entry: %s" % entry_id)

func get_journal_data() -> JournalData:
	print_debug("JournalManager: get_journal_data() called.")
	return journal_data

func get_entry(entry_id: String) -> JournalEntry:
	print_debug("JournalManager: get_entry() called for ID: %s" % entry_id)
	return journal_data.get_entry(entry_id)

func get_section(section_id: String) -> JournalSection:
	print_debug("JournalManager: get_section() called for ID: %s" % section_id)
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
	print_debug("JournalManager: _on_objective_updated() called for objective ID: %s" % objective.objective_id)
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
	print_debug("JournalManager: _on_objective_completed() called for objective ID: %s" % objective.objective_id)
	if objective == null:
		return
	_add_or_update_objective_entry(objective, "completed")
	_add_or_update_stage_entry(objective.current_stage, objective, "completed")


func _add_or_update_objective_entry(objective: Objective, status: String = "active") -> void:
	print_debug("JournalManager: _add_or_update_objective_entry() called for objective ID: %s, status: %s" % [objective.objective_id if is_instance_valid(objective) else "NULL", status])
	if not is_instance_valid(objective):
		push_error("JournalManager: _add_or_update_objective_entry() received invalid objective.")
		return

	var obj_id = _generate_entry_id("objective", objective.objective_id)
	var objective_entry = journal_data.get_entry(obj_id)
	var objective_section = _get_objective_section()

	if objective_entry == null:
		if JournalEntry == null: # NEW: Check if JournalEntry script is null
			push_error("[JournalManager] JournalEntry script failed to load. Cannot create new entry.")
			return # Exit to prevent error

		objective_entry = JournalEntry.new(
			obj_id,
			"Objective: " + objective.title,
			objective.description,
			"objectives", # Topic ID, can be the same as section if no sub-topics
			"objective",
			status,
			objective.objective_id
		)
		journal_data.add_entry(objective_entry)
		unlock_entry(obj_id) # Unlock it when first added
	else:
		objective_entry.title = "Objective: " + objective.title
		objective_entry.content = objective.description
		objective_entry.status = status
	print_debug("[JournalManager] Objective Entry '%s' status: %s" % [objective_entry.title, objective_entry.status])


func _add_or_update_stage_entry(stage: Stage, objective: Objective, status: String = "active") -> void:
	print_debug("JournalManager: _add_or_update_stage_entry() called for stage ID: %s, objective ID: %s, status: %s" % [stage.id if is_instance_valid(stage) else "NULL", objective.objective_id if is_instance_valid(objective) else "NULL", status])
	if not is_instance_valid(stage) or not is_instance_valid(objective):
		push_error("JournalManager: _add_or_update_stage_entry() received invalid stage or objective.")
		return

	var stage_id = _generate_entry_id("stage", objective.objective_id + "_" + stage.id)
	var stage_entry = journal_data.get_entry(stage_id)
	var objective_section = _get_objective_section() # Stages are sub-entries of objectives

	var content_text = ""
	if stage.start_dialogue_resource:
		content_text += "\n(Dialogue: %s)" % stage.start_dialogue_resource.get_file().get_basename()

	if stage_entry == null:
		stage_entry = JournalEntry.new(
			stage.id,
			"Stage: " + String(stage.id),
			content_text,
			"objectives",
			"stage",
			status,
			stage.id
		)
		journal_data.add_entry(stage_entry)
		unlock_entry(stage_id)
	else:
		stage_entry.title = "Stage: " + String(stage.id)
		stage_entry.content = content_text
		stage_entry.status = status
	print_debug("[JournalManager] Stage Entry '%s' status: %s" % [stage_entry.title, stage_entry.status])


func _add_or_update_task_entry(task: Task, status: String = "active", objective: Objective = null) -> void:
	print_debug("JournalManager: _add_or_update_task_entry() called for task ID: %s, objective ID: %s, status: %s" % [task.id if is_instance_valid(task) else "NULL", objective.objective_id if is_instance_valid(objective) else "N/A", status])
	if not is_instance_valid(task):
		push_error("JournalManager: _add_or_update_task_entry() received invalid task.")
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
			"Task: " + task.title,
			content_text,
			"objectives",
			"task",
			status,
			task_full_id
		)
		journal_data.add_entry(task_entry)
		unlock_entry(task_entry_id)
	else:
		task_entry.title = "Task: " + task.title
		task_entry.content = content_text
		task_entry.status = status
	print_debug("[JournalManager] Task Entry '%s' status: %s" % [task_entry.title, task_entry.status])


func _generate_entry_id(prefix: String, game_object_id: String) -> String:
	print_debug("JournalManager: _generate_entry_id() called with prefix: %s, object ID: %s" % [prefix, game_object_id])
	return prefix + "_" + game_object_id.replace("res://", "").replace("/", "_").replace(".tres", "")

func _get_objective_section() -> JournalSection:
	print_debug("JournalManager: _get_objective_section() called.")
	var section = journal_data.get_section("objectives")
	if section == null:
		section = JournalSection.new("objectives", "Objectives")
		journal_data.add_section(section)
	return section

func _on_task_status_changed(task: Task, new_status_str: String, objective: Objective) -> void:
	print_debug("JournalManager: _on_task_status_changed() called for task ID: %s, new status: %s, objective ID: %s" % [task.id, new_status_str, objective.objective_id])
	if task == null:
		return
	_add_or_update_task_entry(task, new_status_str, objective)

func _task_status_to_string(status_enum: Task.Status) -> String:
	print_debug("JournalManager: _task_status_to_string() called for status: %s" % status_enum)
	match status_enum:
		Task.Status.PENDING: return "pending"
		Task.Status.ACTIVE: return "active"
		Task.Status.COMPLETED: return "completed"
		Task.Status.FAILED: return "failed"
		Task.Status.CANCELLED: return "cancelled"
	return "unknown"
