extends Control

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

@onready var _list: VBoxContainer = %SaveList
@onready var _back_button: Button = %BackButton

func _ready() -> void:
	if _back_button:
		_back_button.text = LocalizationStrings.get_text(LocalizationStrings.HUD_ACTION_BACK)
		_back_button.pressed.connect(_on_back_pressed)
	
	var title = $Center/VBox/Title
	if title:
		title.text = LocalizationStrings.get_text(LocalizationStrings.MENU_TITLE_RECOVERY)
		
	_populate_saves()

func _populate_saves() -> void:
	if not is_instance_valid(SaveManager):
		return
		
	# Clear existing
	for child in _list.get_children():
		child.queue_free()
		
	var metadata = SaveManager.get_hard_save_metadata()
	# Sort by timestamp (newest first)
	metadata.sort_custom(func(a, b): return _is_newer(a.timestamp, b.timestamp))
	
	for data in metadata:
		var btn: Button = Button.new()
		var ts = data.timestamp
		var time_str: String = "%04d-%02d-%02d %02d:%02d" % [ts.year, ts.month, ts.day, ts.hour, ts.minute]
		
		# Metadata labeling: Level ID, completion count, last completed
		btn.text = "[%s] Level: %s (Cleared: %d) | Last: %s" % [
			time_str,
			data.level_id,
			data.completed_count,
			data.last_completed
		]
		
		btn.pressed.connect(_on_save_selected.bind(data.slot_index))
		_list.add_child(btn)

func _is_newer(ts_a: Dictionary, ts_b: Dictionary) -> bool:
	# Simple dictionary comparison for Godot Time dicts
	if ts_a.year != ts_b.year: return ts_a.year > ts_b.year
	if ts_a.month != ts_b.month: return ts_a.month > ts_b.month
	if ts_a.day != ts_b.day: return ts_a.day > ts_b.day
	if ts_a.hour != ts_b.hour: return ts_a.hour > ts_b.hour
	return ts_a.minute > ts_b.minute

func _on_save_selected(slot_index: int) -> void:
	if SaveManager.load_hard_save(slot_index):
		var level_id = SaveManager.get_value("current_level_id", "")
		if not level_id.is_empty() and is_instance_valid(LevelManager):
			LevelManager.start_level_by_id(level_id)
		else:
			# If no active level in save, go to level select
			_on_back_pressed()
	else:
		push_error("Failed to load hard-save from slot: ", slot_index)

func _on_back_pressed() -> void:
	var title_scene: String = "res://Menus/title_screen.tscn"
	if is_instance_valid(SceneTransition):
		SceneTransition.change_scene(title_scene)
	else:
		get_tree().change_scene_to_file(title_scene)
