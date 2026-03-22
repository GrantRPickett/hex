extends Control

signal resume_requested
signal controls_requested
signal inventory_requested
signal journal_requested
signal settings_requested
signal quit_requested

@onready var _panel: Panel = $CanvasLayer/Panel

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process_unhandled_input(true)
	
	$CanvasLayer/Panel/VBox/Resume.text = tr("menu.pause.resume")
	$CanvasLayer/Panel/VBox/Controls.text = tr("menu.controls.title")
	$CanvasLayer/Panel/VBox/Inventory.text = tr("menu.inventory.title")
	$CanvasLayer/Panel/VBox/Journal.text = tr("menu.pause.journal")
	$CanvasLayer/Panel/VBox/Settings.text = tr("menu.pause.settings")
	$CanvasLayer/Panel/VBox/Quit.text = tr("menu.pause.quit")
	
	if DisplaySettings:
		DisplaySettings.display_settings_changed.connect(_on_display_settings_changed)
	
	_update_layout()

func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void:
	_update_layout()

func _update_layout() -> void:
	if not is_instance_valid(_panel):
		return
		
	var viewport_size = get_viewport().get_visible_rect().size
	var is_portrait = viewport_size.y > viewport_size.x
	
	if is_portrait:
		_panel.anchor_left = GameConstants.UI.PAUSE_ANCHOR_PORTRAIT_LEFT
		_panel.anchor_right = GameConstants.UI.PAUSE_ANCHOR_PORTRAIT_RIGHT
		_panel.anchor_top = GameConstants.UI.PAUSE_ANCHOR_PORTRAIT_TOP
		_panel.anchor_bottom = GameConstants.UI.PAUSE_ANCHOR_PORTRAIT_BOTTOM
	else:
		_panel.anchor_left = GameConstants.UI.PAUSE_ANCHOR_LANDSCAPE_LEFT
		_panel.anchor_right = GameConstants.UI.PAUSE_ANCHOR_LANDSCAPE_RIGHT
		_panel.anchor_top = GameConstants.UI.PAUSE_ANCHOR_LANDSCAPE_TOP
		_panel.anchor_bottom = GameConstants.UI.PAUSE_ANCHOR_LANDSCAPE_BOTTOM

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

func _on_inventory_pressed() -> void:
	GameLogger.info(GameLogger.Category.UI, "[PauseMenu] Inventory button pressed, emitting inventory_requested")
	inventory_requested.emit()

func _on_journal_pressed() -> void:
	journal_requested.emit()

func _on_settings_pressed() -> void:
	settings_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()
