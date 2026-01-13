extends Control

signal back_requested

@onready var _list: VBoxContainer = $Panel/VBox/List

func _ready() -> void:
	set_process_unhandled_input(true)
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
		var a_complete = completed_levels.has(a["id"])
		var b_complete = completed_levels.has(b["id"])
		if a_complete != b_complete:
			return not a_complete
		return String(a.get("display_name", "")).nocasecmp_to(String(b.get("display_name", ""))) < 0)

	for level_info: Dictionary in available_levels:
		var b := Button.new()
		var is_complete = completed_levels.has(level_info["id"])
		if is_complete:
			b.text = level_info["display_name"] + " ✓"
			b.disabled = true
		else:
			b.text = level_info["display_name"]
		b.pressed.connect(_on_level_pressed.bind(level_info["id"]))
		_list.add_child(b)

func _on_back_pressed() -> void:
	back_requested.emit()
	get_tree().change_scene_to_file("res://Menus/title_screen.tscn")

func _on_level_pressed(level_id: String) -> void:
	var level_manager_instance = get_tree().root.get_node_or_null("LevelManager")
	if level_manager_instance != null:
		level_manager_instance.start_level_by_id(level_id)
	else:
		push_error("LevelManager not found! Cannot start level.")
