class_name PauseHandler
extends Node

signal resume_requested
signal controls_requested
signal quit_requested

const PAUSE_MENU_SCENE_PATH := "res://Menus/pause_menu.tscn"
const CONTROLS_MENU_SCENE_PATH := "res://Menus/controls_menu.tscn"
const JOURNAL_MENU_SCENE_PATH := "res://GUI/JournalUI.tscn"
const SETTINGS_MENU_SCENE_PATH := "res://Menus/settings_menu.tscn"

var _paused := false
var _pause_menu: Control
var _controls_menu: Control
var _journal_menu: Control
var _settings_menu: Control


func _unhandled_input(event: InputEvent) -> void:
	if _handle_pause_input(event):
		get_viewport().set_input_as_handled()

func _handle_pause_input(event: InputEvent) -> bool:
	if not event.is_action_pressed("pause_game"):
		return false

	var dialogue_service := UnitActionManager.get_dialogue_service()
	if dialogue_service and dialogue_service.is_dialogue_active():
		print_debug("PauseHandler: Pause blocked, dialogue is active.")
		return true

	if _paused:
		_hide_pause_menu()
	else:
		show_pause_menu()

	return true

func show_pause_menu() -> void:
	if _paused:
		return
	_paused = true
	var packed: PackedScene = load(PAUSE_MENU_SCENE_PATH)
	_pause_menu = packed.instantiate() as Control
	_pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_menu)
	_pause_menu.resume_requested.connect(_on_pause_resume)
	_pause_menu.controls_requested.connect(_on_pause_controls)
	_pause_menu.journal_requested.connect(_on_pause_journal)
	_pause_menu.settings_requested.connect(_on_pause_settings)
	_pause_menu.quit_requested.connect(_on_pause_quit)
	get_tree().paused = true

func _hide_pause_menu() -> void:
	if not _paused:
		return
	if is_instance_valid(_controls_menu):
		_controls_menu.queue_free()
		_controls_menu = null
	if is_instance_valid(_journal_menu):
		_journal_menu.queue_free()
		_journal_menu = null
	if is_instance_valid(_settings_menu):
		_settings_menu.queue_free()
		_settings_menu = null
	if is_instance_valid(_pause_menu):
		_pause_menu.queue_free()
		_pause_menu = null
	_paused = false
	get_tree().paused = false

func _on_pause_resume() -> void:
	_hide_pause_menu()
	resume_requested.emit()

func _on_pause_controls() -> void:
	if not is_instance_valid(_pause_menu):
		return
	if is_instance_valid(_controls_menu):
		_controls_menu.queue_free()

	_pause_menu.hide_menu()

	var packed: PackedScene = load(CONTROLS_MENU_SCENE_PATH)
	_controls_menu = packed.instantiate() as Control
	_controls_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_controls_menu)
	_controls_menu.back_requested.connect(_on_controls_back)
	controls_requested.emit()

func _on_pause_journal() -> void:
	if not is_instance_valid(_pause_menu):
		return
	if is_instance_valid(_journal_menu):
		_journal_menu.queue_free()

	_pause_menu.hide_menu()

	var packed: PackedScene = load(JOURNAL_MENU_SCENE_PATH)
	_journal_menu = packed.instantiate() as Control
	_journal_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_journal_menu)
	_journal_menu.back_requested.connect(_on_journal_back)

func _on_pause_settings() -> void:
	if not is_instance_valid(_pause_menu):
		return
	if is_instance_valid(_settings_menu):
		_settings_menu.queue_free()

	_pause_menu.hide_menu()

	var packed: PackedScene = load(SETTINGS_MENU_SCENE_PATH)
	_settings_menu = packed.instantiate() as Control
	_settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_settings_menu)
	_settings_menu.back_requested.connect(_on_settings_back)

func _on_controls_back() -> void:
	if is_instance_valid(_controls_menu):
		_controls_menu.queue_free()
		_controls_menu = null
	if is_instance_valid(_pause_menu):
		_pause_menu.show_menu()
		_pause_menu.grab_focus()

func _on_journal_back() -> void:
	if is_instance_valid(_journal_menu):
		_journal_menu.queue_free()
		_journal_menu = null
	if is_instance_valid(_pause_menu):
		_pause_menu.show_menu()
		_pause_menu.grab_focus()

func _on_settings_back() -> void:
	if is_instance_valid(_settings_menu):
		_settings_menu.queue_free()
		_settings_menu = null
	if is_instance_valid(_pause_menu):
		_pause_menu.show_menu()
		_pause_menu.grab_focus()

func _on_pause_quit() -> void:
	_hide_pause_menu()
	quit_requested.emit()

func is_paused() -> bool:
	return _paused
