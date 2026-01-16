extends Control

@onready var _level_buttons_container: VBoxContainer = %LevelButtonsContainer
@onready var _return_to_title_button: Button = %ReturnToTitleButton

func _ready() -> void:
	_return_to_title_button.pressed.connect(_on_return_to_title_pressed)
	_populate_level_buttons()

func _populate_level_buttons() -> void:


	var level_manager_instance = get_tree().root.get_node_or_null("LevelManager")
	if level_manager_instance == null:
		push_error("LevelManager Autoload not found!")
		return

	# Clear existing buttons
	for child in _level_buttons_container.get_children():
		child.queue_free()

	var available_levels = level_manager_instance.get_available_levels()
	var has_incomplete_levels := false

	for level_info in available_levels:
		if not level_manager_instance.is_level_completed(level_info["id"]):
			has_incomplete_levels = true
			var level_button = Button.new()
			level_button.text = level_info["display_name"]
			level_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			level_button.pressed.connect(_on_level_button_pressed.bind(level_info["id"]))
			_level_buttons_container.add_child(level_button)
	
	if not has_incomplete_levels:
		var no_levels_label = Label.new()
		no_levels_label.text = "No more incomplete levels available!"
		no_levels_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_level_buttons_container.add_child(no_levels_label)


func _on_level_button_pressed(level_id: String) -> void:


	var level_manager_instance = get_tree().root.get_node_or_null("LevelManager")


	if level_manager_instance != null:


		level_manager_instance.start_level_by_id(level_id)


	else:


		push_error("LevelManager Autoload not found!")

func _on_return_to_title_pressed() -> void:

	var level_manager_instance = get_tree().root.get_node_or_null("LevelManager")
	var title_scene_path: String = "res://Menus/title_screen.tscn"
	if level_manager_instance != null:
		title_scene_path = level_manager_instance.TITLE_SCENE
	var transition := get_tree().root.get_node_or_null("SceneTransition")
	if transition:
		transition.change_scene(title_scene_path)
	else:
		get_tree().change_scene_to_file(title_scene_path)
