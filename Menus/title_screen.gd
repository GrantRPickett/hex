extends Control

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

signal start_pressed
signal quit_requested

@onready var _title_label: Label = $Center/VBox/TitleLabel
@onready var _start_button: Button = $Center/VBox/StartButton
@onready var _quit_button: Button = $Center/VBox/QuitButton
@onready var _level_button: Button = $Center/VBox/LevelSelectButton

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const DEFAULT_TUTORIAL_LEVEL := "res://Resources/levels/level_1.tres"
const DEFAULT_START_KEYS := [KEY_ENTER, KEY_SPACE]
const DEFAULT_QUIT_KEYS := [KEY_ESCAPE]
const DEFAULT_START_BUTTONS := [JOY_BUTTON_START, JOY_BUTTON_A]
const DEFAULT_QUIT_BUTTONS := [JOY_BUTTON_BACK, JOY_BUTTON_B]

var _quit_callback: Callable
var _controls: Node = null

func _ready() -> void:
	if is_instance_valid(_title_label):
		_title_label.text = LocalizationStrings.get_text("menus.title.heading")
	_start_button.text = LocalizationStrings.get_text("menus.title.play")
	_level_button.text = LocalizationStrings.get_text("menus.title.level_select")
	_quit_button.text = LocalizationStrings.get_text("menus.title.quit")
	_controls = get_tree().root.get_node_or_null("ControlSettings")
	if _controls == null:
		push_error("ControlSettings autoload not found in TitleScreen.gd!")
		# Optionally, handle gracefully or disable features relying on it
		return
	if _quit_callback.is_null():
		_quit_callback = get_tree().quit
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_level_button.pressed.connect(_on_level_select)

func set_quit_callback(callback: Callable) -> void:
	_quit_callback = callback

func _on_start_pressed() -> void:
	start_pressed.emit()
	var level_manager_instance = get_tree().root.get_node_or_null("LevelManager")
	if level_manager_instance != null:
		if level_manager_instance.has_method("start_first_level"):
			level_manager_instance.start_first_level()
		else:
			level_manager_instance.set("_current_level_path", DEFAULT_TUTORIAL_LEVEL)
			var transition := _scene_transition()
			if transition:
				await transition.change_scene(GAMEPLAY_SCENE_PATH)
			else:
				get_tree().change_scene_to_file(GAMEPLAY_SCENE_PATH)

func _on_quit_pressed() -> void:
	quit_requested.emit()
	_quit_callback.call()

func _on_level_select() -> void:
	var transition := _scene_transition()
	if transition:
		await transition.change_scene("res://Menus/level_select.tscn")
	else:
		get_tree().change_scene_to_file("res://Menus/level_select.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if not _is_relevant_press(event):
		return
	if _is_quit_event(event):
		_quit_via_shortcut()
		_mark_input_handled()
		return
	if _is_start_event(event):
		_start_via_shortcut()
		_mark_input_handled()

func _is_relevant_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton:
		return event.pressed
	return false

func _is_quit_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return _contains(_quit_keys(), event.keycode)
	if event is InputEventJoypadButton:
		return _contains(_quit_buttons(), event.button_index)
	return false

func _is_start_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return _contains(_start_keys(), event.keycode) or (_allow_any_non_quit_key() and not _is_quit_event(event))
	if event is InputEventJoypadButton:
		return _contains(_start_buttons(), event.button_index) or (_allow_any_joy_button() and not _is_quit_event(event))
	return false

func _contains(values: PackedInt32Array, value: int) -> bool:
	return values.has(value)

func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport:
		viewport.set_input_as_handled()

func _start_keys() -> PackedInt32Array:
	return _controls.start_keycodes if _controls else PackedInt32Array(DEFAULT_START_KEYS)

func _quit_keys() -> PackedInt32Array:
	return _controls.quit_keycodes if _controls else PackedInt32Array(DEFAULT_QUIT_KEYS)

func _start_buttons() -> PackedInt32Array:
	return _controls.start_joypad_buttons if _controls else PackedInt32Array(DEFAULT_START_BUTTONS)

func _quit_buttons() -> PackedInt32Array:
	return _controls.quit_joypad_buttons if _controls else PackedInt32Array(DEFAULT_QUIT_BUTTONS)

func _allow_any_non_quit_key() -> bool:
	return _controls.allow_any_non_quit_key_to_start if _controls else true

func _allow_any_joy_button() -> bool:
	return _controls.allow_any_joy_button_to_start if _controls else true

func _start_via_shortcut() -> void:
	_on_start_pressed()

func _quit_via_shortcut() -> void:
	_on_quit_pressed()

func _scene_transition() -> Node:
	return get_tree().root.get_node_or_null("SceneTransition")
