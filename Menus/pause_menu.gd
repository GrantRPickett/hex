extends Control

signal resume_requested
signal controls_requested
signal journal_requested
signal settings_requested
signal quit_requested

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if $CanvasLayer.visible and event.is_action_pressed("ui_cancel"):
		resume_requested.emit()
		get_viewport().set_input_as_handled()

func show_menu() -> void:
	$CanvasLayer.visible = true

func hide_menu() -> void:
	$CanvasLayer.visible = false

func _on_resume_pressed() -> void:
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner:
		focus_owner.release_focus()
	resume_requested.emit()

func _on_controls_pressed() -> void:
	controls_requested.emit()

func _on_journal_pressed() -> void:
	journal_requested.emit()

func _on_settings_pressed() -> void:
	settings_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()
