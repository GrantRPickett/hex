class_name LevelSelect
extends Control

signal back_requested

@export var show_incomplete_only: bool = false

@onready var _list: VBoxContainer = %LevelList
@onready var _header: Label = %Header
@onready var _back_button: Button = %BackButton
@onready var _debug_reset_button: Button = %DebugResetButton

static var request_show_incomplete_only: bool = false

func _ready() -> void:
	if _debug_reset_button:
		_debug_reset_button.visible = OS.is_debug_build()
	if request_show_incomplete_only:
		show_incomplete_only = true
		request_show_incomplete_only = false

	if show_incomplete_only:
		_header.text = tr("menu.level_select.choose")
		_back_button.text = tr("menu.level_select.return")
	else:
		_header.text = tr("menu.level_select.select")
		_back_button.text = tr("menu.level_select.back")
	_populate_levels()

func _populate_levels() -> void:
	# Clear any existing buttons
	for child in _list.get_children():
		child.queue_free()

	var level_manager_instance = get_tree().root.get_node_or_null("LevelManager")
	if level_manager_instance == null:
		push_error("LevelManager not found! Cannot populate level select screen.")
		return

	var save_manager_instance = get_tree().root.get_node_or_null("SaveManager")
	var completed_levels = {}
	if save_manager_instance:
		completed_levels = save_manager_instance.get_value("completed_levels", {})

	var available_levels = level_manager_instance.get_available_levels()

	available_levels.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_home = a.get("is_hometown", false)
		var b_home = b.get("is_hometown", false)
		if a_home != b_home:
			return a_home
		var a_complete = completed_levels.has(a["id"])
		var b_complete = completed_levels.has(b["id"])
		if a_complete != b_complete:
			return not a_complete
		return String(a.get("display_name", "")).nocasecmp_to(String(b.get("display_name", ""))) < 0)

	var has_visible_levels := false

	for level_info: Dictionary in available_levels:
		var is_complete = completed_levels.has(level_info["id"])

		if show_incomplete_only and is_complete:
			continue

		has_visible_levels = true
		var b := Button.new()
		var display_name = tr(level_info.get("display_name", level_info["id"]))
		if is_complete:
			b.text = display_name + " ✓"
		else:
			b.text = display_name
		b.pressed.connect(_on_level_pressed.bind(level_info["id"]))
		_list.add_child(b)

	if show_incomplete_only and not has_visible_levels:
		var lbl = Label.new()
		lbl.text = tr("menu.level_select.no_levels")
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(lbl)

func _on_back_pressed() -> void:
	back_requested.emit()

	var level_manager = get_tree().root.get_node_or_null("LevelManager")
	var title_scene = FilePaths.Scenes.TITLE_SCREEN
	if level_manager and "TITLE_SCENE" in level_manager:
		title_scene = level_manager.TITLE_SCENE

	var transition = get_tree().root.get_node_or_null("SceneTransition")
	if transition:
		transition.change_scene(title_scene)
	else:
		get_tree().change_scene_to_file(title_scene)

func _on_level_pressed(level_id: String) -> void:
	var level_manager_instance = get_tree().root.get_node_or_null("LevelManager")
	if level_manager_instance != null:
		level_manager_instance.start_level_by_id(level_id)
	else:
		push_error("LevelManager not found! Cannot start level.")

func _on_debug_reset_pressed() -> void:
	var level_manager_instance = get_tree().root.get_node_or_null("LevelManager")
	if level_manager_instance != null:
		level_manager_instance.reset_completed_levels()
		_populate_levels()
		if has_node("/root/EventBus"):
			get_node("/root/EventBus").emit_event("show_feedback_message", "Debug: Completed levels reset to zero.")
