# journal_manager.gd
extends Node

var journal_data: JournalData
var _task_manager: TaskManager
var _level: Level

signal entry_unlocked(entry_id: String)
signal journal_cleared

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
	if journal_data != null:
		return

	journal_data = JournalData.new() # Always create a new instance

func _initialize_default_content():
	print_debug("JournalManager: _initialize_default_content() called.")
	# Create default sections in the specified order
	var default_sections: Array[Dictionary] = [
		{"id": "objectives", "title": tr("journal.section.objectives")},
		{"id": "people", "title": tr("journal.section.people")},
		{"id": "places", "title": tr("journal.section.places")},
		{"id": "rules", "title": tr("journal.section.rules")},
		{"id": "achievements", "title": tr("journal.section.achievements")},
	]

	for section_data in default_sections:
		if not journal_data.get_section(section_data.id):
			var section: JournalSection = JournalSection.new(section_data.id, section_data.title)
			journal_data.add_section(section)

	# Ensure default topic for objectives exists for dynamically added entries
	var objectives_section_id: String = "objectives"
	if not journal_data.get_topic(objectives_section_id):
		var objectives_topic: JournalTopic = JournalTopic.new(objectives_section_id, tr("journal.section.objectives"), objectives_section_id)
		journal_data.add_topic(objectives_topic)


	# Load static entries from res://Resources/level_data/ (optional, if levels have pre-defined journal entries)
	# This part is dynamic now, but we can still scan if needed
	var all_static_entries: Array = ResourceLoaderService.collect_resources_recursive("res://Resources/level_data/")
	for res: Resource in all_static_entries:
		if res is JournalEntry:
			journal_data.add_entry(res as JournalEntry)


func unlock_entry(entry_id: String) -> bool:
	_ensure_initialized()
	var entry: JournalEntry = journal_data.get_entry(entry_id)
	if entry and not entry.unlocked:
		entry.unlocked = true
		entry_unlocked.emit(entry_id)
		if EventBus: EventBus.audio_trigger_requested.emit("journal_unlock")
		print("JournalManager: Unlocked entry: %s" % entry_id)
		return true
	return false

func clear_journal() -> void:
	print_debug("JournalManager: clear_journal() called.")
	_ensure_initialized()
	journal_data.entries.clear()
	# Re-initialize default content so the UI doesn't crash on missing sections.
	_initialize_default_content()
	journal_cleared.emit()
	entry_unlocked.emit("") # Signal a major change

func unlock_coupled_entry(entry_id: String, section_id: String, topic_id: String, notes: String, _flag_name: StringName) -> void:
	print_debug("JournalManager: unlock_coupled_entry() called for ID: %s" % entry_id)
	_ensure_initialized()
	var entry: JournalEntry = journal_data.get_entry(entry_id)
	if entry == null:
		# Create a new dynamic entry
		# p_id, p_title, p_content, p_topic_id, p_section_id, p_entry_type, p_status, p_related_id
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
		if EventBus: EventBus.audio_trigger_requested.emit("journal_unlock")
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
	var savable_entries: Dictionary = {}
	for entry_id: String in journal_data.entries:
		var entry_val: Variant = journal_data.entries[entry_id]
		if entry_val is JournalEntry:
			var entry: JournalEntry = entry_val
			if entry.unlocked:
				savable_entries[entry_id] = true # Store only unlocked status
	return {"unlocked_journal_entries": savable_entries}

# Method to load saved data
func load_savable_data(data: Dictionary) -> void:
	_ensure_initialized()
	if data.has("unlocked_journal_entries"):
		var unlocked_entries_map: Dictionary = data["unlocked_journal_entries"]
		for entry_id: String in unlocked_entries_map:
			var entry: JournalEntry = journal_data.get_entry(entry_id) as JournalEntry
			if entry:
				entry.unlocked = true
			else:
				push_warning("JournalManager: Saved data refers to non-existent entry ID: %s" % entry_id)

func _on_objective_updated(objective: Objective) -> void:
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

			# Using TaskManager's task signals is better but for now we'll just fix the duplicate connection check.
			# To handle bound callables correctly in Godot 4:
			# disconnect EVERYTHING first if we can't find the specific one, or just trust the disconnect.
			# But we only want to connect once per task.
			var completed_callable: Callable = _on_task_completed_signal.bind(task, objective)
			var failed_callable: Callable = _on_task_failed_signal.bind(task, objective)

			if not task.completed.is_connected(completed_callable):
				task.completed.connect(completed_callable)

			if not task.failed.is_connected(failed_callable):
				task.failed.connect(failed_callable)


func _on_task_completed_signal(_faction_id: int, _unit: Unit, task: Task, objective: Objective) -> void:
	_on_task_status_changed(task, "completed", objective)

func _on_task_failed_signal(task: Task, objective: Objective) -> void:
	_on_task_status_changed(task, "failed", objective)


func _on_objective_completed(objective: Objective) -> void:
	if objective == null:
		return
	_add_or_update_objective_entry(objective, "completed")
	_add_or_update_stage_entry(objective.current_stage, objective, "completed")


func _add_or_update_objective_entry(objective: Objective, status: String = "active") -> void:
	if not is_instance_valid(objective):
		push_error("JournalManager: _add_or_update_objective_entry() received invalid objective.")
		return

	if not is_instance_valid(_level):
		push_warning("JournalManager: Cannot add objective entry because level is not set.")
		return

	var obj_id = _generate_entry_id("objective", _level.level_prefix + "_" + objective.objective_id)
	var objective_entry: JournalEntry = journal_data.get_entry(obj_id)

	if objective_entry == null:
		# p_id, p_title, p_content, p_topic_id, p_section_id, p_entry_type, p_status, p_related_id
		objective_entry = JournalEntry.new(
			obj_id,
			tr("journal.entry.objective_prefix").format({"title": objective.title}),
			objective.description,
			"objectives", # Topic ID
			"objectives", # Section ID
			"objective",  # Entry Type
			status,	   # Status
			objective.objective_id # Related ID
		)
		journal_data.add_entry(objective_entry)
		unlock_entry(obj_id) # Unlock it when first added
	else:
		objective_entry.title = tr("journal.entry.objective_prefix").format({"title": objective.title})
		objective_entry.content = objective.description
		objective_entry.status = status


func _add_or_update_stage_entry(stage: Stage, objective: Objective, status: String = "active") -> void:
	if not is_instance_valid(stage) or not is_instance_valid(objective):
		push_error("JournalManager: _add_or_update_stage_entry() received invalid stage or objective.")
		return

	if not is_instance_valid(_level):
		push_warning("JournalManager: Cannot add stage entry because level is not set.")
		return

	var stage_id = _generate_entry_id("stage", _level.level_prefix + objective.objective_id + "_" + stage.id)
	var stage_entry: JournalEntry = journal_data.get_entry(stage_id)

	var content_text: String = ""
	if stage.start_dialogue_resource:
		content_text += "\n" + tr("journal.entry.dialogue_hint").format({"name": stage.start_dialogue_resource.get_file().get_basename()})

	if stage_entry == null:
		# p_id, p_title, p_content, p_topic_id, p_section_id, p_entry_type, p_status, p_related_id
		stage_entry = JournalEntry.new(
			stage_id,
			tr("journal.entry.stage_prefix").format({"id": stage.id}),
			content_text,
			"objectives", # Topic ID
			"objectives", # Section ID
			"stage",	  # Entry Type
			status,	   # Status
			stage.id	  # Related ID
		)
		journal_data.add_entry(stage_entry)
		unlock_entry(stage_id)
	else:
		stage_entry.title = tr("journal.entry.stage_prefix").format({"id": stage.id})
		stage_entry.content = content_text
		stage_entry.status = status


func _add_or_update_task_entry(task: Task, status: String = "active", objective: Objective = null) -> void:
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
	var task_entry: JournalEntry = journal_data.get_entry(task_entry_id)

	var content_text = task.description

	if task_entry == null:
		# p_id, p_title, p_content, p_topic_id, p_section_id, p_entry_type, p_status, p_related_id
		task_entry = JournalEntry.new(
			task_entry_id,
			tr("journal.entry.task_prefix").format({"title": task.title}),
			content_text,
			"objectives", # Topic ID
			"objectives", # Section ID
			"task",	   # Entry Type
			status,	   # Status
			task_full_id  # Related ID
		)
		journal_data.add_entry(task_entry)
		unlock_entry(task_entry_id)
	else:
		task_entry.title = tr("journal.entry.task_prefix").format({"title": task.title})
		task_entry.content = content_text
		task_entry.status = status


func _generate_entry_id(prefix: String, game_object_id: String) -> String:
	return prefix + "_" + game_object_id.replace("res://", "").replace("/", "_").replace("\\", "_").replace(".tres", "")

func _get_objective_section() -> JournalSection:
	var section: JournalSection = journal_data.get_section("objectives")
	if section == null:
		section = JournalSection.new("objectives", "Objectives")
		journal_data.add_section(section)
	return section

func _on_task_status_changed(task: Task, new_status_str: String, objective: Objective, _args = null) -> void:
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
