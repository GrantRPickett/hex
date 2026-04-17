extends Control

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

signal start_pressed
signal quit_requested

@onready var _title_label: Label = $Center/VBox/TitleLabel
@onready var _start_button: Button = $Center/VBox/StartButton
@onready var _quit_button: Button = $Center/VBox/QuitButton
@onready var _level_button: Button = $Center/VBox/LevelSelectButton

var _continue_button: Button
var _recovery_button: Button

const DEFAULT_START_KEYS := [KEY_ENTER, KEY_SPACE]
const DEFAULT_QUIT_KEYS := [KEY_ESCAPE]
const DEFAULT_START_BUTTONS := [JOY_BUTTON_START, JOY_BUTTON_A]
const DEFAULT_QUIT_BUTTONS := [JOY_BUTTON_BACK, JOY_BUTTON_B]

var _quit_callback: Callable
var _controls: Node = null

func _ready() -> void:
	if is_instance_valid(_title_label):
		_title_label.text = LocalizationStrings.get_text(LocalizationStrings.MENU_TITLE_HEADING)
	_start_button.text = LocalizationStrings.get_text(LocalizationStrings.MENU_TITLE_START)
	_level_button.text = LocalizationStrings.get_text(LocalizationStrings.MENU_TITLE_LEVEL_SELECT)
	_quit_button.text = LocalizationStrings.get_text(LocalizationStrings.MENU_TITLE_QUIT)

	var feedback_btn = Button.new()
	feedback_btn.text = LocalizationStrings.get_text(LocalizationStrings.MENU_TITLE_FEEDBACK)
	$Center/VBox.add_child(feedback_btn)
	$Center/VBox.move_child(feedback_btn, $Center/VBox.get_children().find(_quit_button))
	feedback_btn.pressed.connect(_on_feedback_pressed)

	_add_store_button()

	_controls = ControlSettings
	if _controls == null:
		GameLogger.error(GameLogger.Category.UI, "ControlSettings autoload not found in TitleScreen.gd!")
		# Optionally, handle gracefully or disable features relying on it
		return
	if _quit_callback.is_null():
		_quit_callback = get_tree().quit
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_level_button.pressed.connect(_on_level_select)

	_setup_additional_buttons()

	var all_buttons = [_start_button, _quit_button, _level_button]
	if is_instance_valid(_continue_button): all_buttons.append(_continue_button)
	if is_instance_valid(_recovery_button): all_buttons.append(_recovery_button)

	for btn in all_buttons:
		btn.pressed.connect(func(): if EventBus: EventBus.ui_button_pressed.emit())
		btn.mouse_entered.connect(func(): if EventBus: EventBus.ui_hover_triggered.emit())

func _setup_additional_buttons() -> void:
	if not is_instance_valid(SaveManager): return

	var vbox = $Center/VBox

	# Continue Button
	if SaveManager.has_resumable_session():
		_continue_button = Button.new()
		_continue_button.text = LocalizationStrings.get_text(LocalizationStrings.MENU_TITLE_CONTINUE)
		vbox.add_child(_continue_button)
		vbox.move_child(_continue_button, 0) # At the top
		_continue_button.pressed.connect(_on_continue_pressed)

	# Recovery Button (Hard-Saves)
	var hard_saves = SaveManager.get_hard_save_metadata()
	if not hard_saves.is_empty():
		_recovery_button = Button.new()
		_recovery_button.text = LocalizationStrings.get_text(LocalizationStrings.MENU_TITLE_RECOVERY)
		vbox.add_child(_recovery_button)
		vbox.move_child(_recovery_button, vbox.get_children().find(_level_button) + 1)
		_recovery_button.pressed.connect(_on_recovery_pressed)

func _on_recovery_pressed() -> void:
	# Prototype: just show a simple list for now, or prepare for new menu
	var recovery_scene: String = "res://Menus/recovery_menu.tscn"
	if ResourceLoader.exists(recovery_scene):
		var transition := _scene_transition()
		if transition:
			await transition.change_scene(recovery_scene)
		else:
			get_tree().change_scene_to_file(recovery_scene)
	else:
		GameLogger.error(GameLogger.Category.UI, "Recovery menu scene not found!")

func _on_continue_pressed() -> void:
	if is_instance_valid(SaveManager):
		# The memento is already loaded into SaveManager._game_data by setup()
		# We just need to transition to the scene it specifies.
		var level_id = SaveManager.get_value("current_level_id", "")
		if not level_id.is_empty() and is_instance_valid(LevelManager):
			LevelManager.start_level_by_id(level_id)

func _add_store_button() -> void:
	if BuildConfig.get_build_type() == BuildConfig.BuildType.PAID_BUILD:
		return

	var store_btn = Button.new()
	store_btn.text = LocalizationStrings.get_text(LocalizationStrings.MENU_TITLE_STORE)
	$Center/VBox.add_child(store_btn)
	$Center/VBox.move_child(store_btn, $Center/VBox.get_children().find(_quit_button))
	store_btn.pressed.connect(_on_store_pressed)

func _on_store_pressed() -> void:
	OS.shell_open("https://store.steampowered.com/")

func _on_feedback_pressed() -> void:
	var feedback_scene: String = FilePaths.Scenes.FEEDBACK_FORM
	if ResourceLoader.exists(feedback_scene):
		var packed: PackedScene = load(feedback_scene)
		var feedback_menu = packed.instantiate()
		feedback_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(feedback_menu)
		feedback_menu.close_requested.connect(_on_feedback_close.bind(feedback_menu))
	else:
		GameLogger.error(GameLogger.Category.UI, "Feedback form scene not found!")

func _on_feedback_close(menu: Node) -> void:
	if is_instance_valid(menu):
		menu.queue_free()


func set_quit_callback(callback: Callable) -> void:
	_quit_callback = callback

func _on_start_pressed() -> void:
	start_pressed.emit()
	var level_manager_instance = LevelManager
	if level_manager_instance != null:
		if level_manager_instance.has_method("start_first_level"):
			level_manager_instance.start_first_level()
		else:
			# Fallback for older manager versions
			var gameplay_scene = FilePaths.Scenes.GAMEPLAY
			var transition := _scene_transition()
			if transition:
				await transition.change_scene(gameplay_scene)
			else:
				get_tree().change_scene_to_file(gameplay_scene)

func _on_quit_pressed() -> void:
	quit_requested.emit()
	_quit_callback.call()

func _on_level_select() -> void:
	var level_select_scene = FilePaths.Scenes.LEVEL_SELECT
	var transition := _scene_transition()
	if transition:
		await transition.change_scene(level_select_scene)
	else:
		get_tree().change_scene_to_file(level_select_scene)

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
	return SceneTransition
