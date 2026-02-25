# journal_manager.gd
extends Node

var journal_data: JournalData
var _task_manager: TaskManager
var _level: Level

signal entry_unlocked(entry_id: String)

func setup(task_manager: TaskManager) -> void:
	print_debug("JournalManager: setup() called.")

	if is_instance_valid(_task_manager):
		if _task_manager.objective_updated.is_connected(_on_objective_updated):
			_task_manager.objective_updated.disconnect(_on_objective_updated)
		if _task_manager.objective_completed.is_connected(_on_objective_completed):
			_task_manager.objective_completed.disconnect(_on_objective_completed)

	_task_manager = task_manager
	if _task_manager:
		if not _task_manager.objective_updated.is_connected(_on_objective_updated):
			_task_manager.objective_updated.connect(_on_objective_updated)
		if not _task_manager.objective_completed.is_connected(_on_objective_completed):
			_task_manager.objective_completed.connect(_on_objective_completed)
	print_debug("JournalManager: TaskManager setup complete.")

func _ready():
	print_debug("JournalManager: _ready() called.")

func set_level(level: Level) -> void:
	print_debug("JournalManager: set_level() called for level ID: %s" % (level.level_id if is_instance_valid(level) else "NULL"))
	_level = level
	_ensure_initialized()
	_initialize_default_content()

	# Add level-specific journal entries
	if is_instance_valid(_level) and _level.journal_entries:
		for entry in _level.journal_entries:
			if is_instance_valid(entry):
				if not journal_data.has_entry(entry.id):
					journal_data.add_entry(entry)
				else:
					push_warning("JournalManager: Duplicate journal entry ID found: %s. Overwriting with level's entry." % entry.id)
					journal_data.replace_entry(entry)

func _ensure_initialized() -> void:
	print_debug("JournalManager: _ensure_initialized() called.")
	if journal_data != null:
		return

	journal_data = JournalData.new() # Always create a new instance

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


func _collect_resources_recursive(path: String) -> Array[Resource]:
	print_debug("JournalManager: _collect_resources_recursive() called for path: %s" % path)
	var resources: Array[Resource] = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path := FilePaths.join_path(path, file_name)
			if dir.current_is_dir():
				if not file_name.begins_with("."):
					resources.append_array(_collect_resources_recursive(full_path))
			elif file_name.ends_with(".tres"):
				var res = load(full_path)
				if res:
					print_debug("JournalManager: _collect_resources_recursive() loaded: %s. Is LevelJournalEntry: %s" % [full_path, res is LevelJournalEntry])
					resources.append(res)
				else:
					push_warning("JournalManager: _collect_resources_recursive() failed to load resource at: %s" % full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_warning("JournalManager: Could not open directory at: %s" % path)
	return resources

func unlock_entry(entry_id: String) -> bool:
	print_debug("JournalManager: unlock_entry() called for ID: %s" % entry_id)
	_ensure_initialized()
	var entry: LevelJournalEntry = journal_data.get_entry(entry_id)
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
	var entry: LevelJournalEntry = journal_data.get_entry(entry_id)
	if entry == null:
		# Create a new dynamic entry
		entry = LevelJournalEntry.new(
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

func get_entry(entry_id: String) -> LevelJournalEntry:
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
		var entry: LevelJournalEntry = journal_data.entries[entry_id]
		if entry.unlocked:
			savable_entries[entry_id] = true # Store only unlocked status
	return {"unlocked_journal_entries": savable_entries}

# Method to load saved data
func load_savable_data(data: Dictionary):
	_ensure_initialized()
	if data.has("unlocked_journal_entries"):
		var unlocked_entries_map = data["unlocked_journal_entries"]
		for entry_id in unlocked_entries_map:
			var entry: LevelJournalEntry = journal_data.get_entry(entry_id)
			if entry:
				entry.unlocked = true
			else:
				push_warning("JournalManager: Saved data refers to non-existent entry ID: %s" % entry_id)

func _on_objective_updated(objective: Objective) -> void:
	print_debug("JournalManager: _on_objective_updated() called for objective ID: %s" % objective.objective_id)
	if objective == null:
		return

	_add_or_update_objective_entry(objective)
	_add_or_update_stage_entry(objective.current_stage, objective)

	# Connect to current stage's tasks
	if objective.current_stage:
		for task in objective.current_stage.active_tasks:
			if task == null:
				continue
			_add_or_update_task_entry(task, _task_status_to_string(task.status), objective)
			# Connect for future updates.
			var completed_callable = _on_task_status_changed.bind(task, "completed", objective)
			if not task.completed.is_connected(completed_callable):
				task.completed.connect(completed_callable)

			var failed_callable = _on_task_status_changed.bind(task, "failed", objective)
			if not task.failed.is_connected(failed_callable):
				task.failed.connect(failed_callable)


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

	if not is_instance_valid(_level):
		push_warning("JournalManager: Cannot add objective entry because level is not set.")
		return

	var obj_id = _generate_entry_id("objective", _level.level_prefix + "_" + objective.objective_id)
	var objective_entry = journal_data.get_entry(obj_id)
	var objective_section = _get_objective_section()

	if objective_entry == null:
		objective_entry = LevelJournalEntry.new(
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

	if not is_instance_valid(_level):
		push_warning("JournalManager: Cannot add stage entry because level is not set.")
		return

	var stage_id = _generate_entry_id("stage", _level.level_prefix + objective.objective_id + "_" + stage.id)
	var stage_entry = journal_data.get_entry(stage_id)
	var objective_section = _get_objective_section() # Stages are sub-entries of objectives

	var content_text = ""
	if stage.start_dialogue_resource:
		content_text += "\n(Dialogue: %s)" % stage.start_dialogue_resource.get_file().get_basename()

	if stage_entry == null:
		stage_entry = LevelJournalEntry.new(
			stage_id,
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

	var task_full_id = task.id
	if objective:
		task_full_id = objective.objective_id + "_" + task.id

	if not is_instance_valid(_level):
		push_warning("JournalManager: Cannot add task entry because level is not set.")
		return

	var task_entry_id = _generate_entry_id("task", _level.level_prefix + "_" + task_full_id)
	var task_entry = journal_data.get_entry(task_entry_id)
	var objective_section = _get_objective_section()

	var content_text = task.description

	if task_entry == null:
		task_entry = LevelJournalEntry.new(
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
	return prefix + "_" + game_object_id.replace("res://", "").replace("/", "_").replace("\\", "_").replace(".tres", "")

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
