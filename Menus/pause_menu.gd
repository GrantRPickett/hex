extends Control

signal resume_requested
signal inventory_requested
signal journal_requested
signal settings_requested
signal feedback_requested
signal quit_requested

@onready var _panel: Panel = $CanvasLayer/Panel

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process_unhandled_input(true)

	_setup_feedback_button()

	if DisplaySettings:
		DisplaySettings.display_settings_changed.connect(_on_display_settings_changed)

	LocaleService.locale_changed.connect(_translate_labels)
	_translate_labels()
	_update_layout()
	_apply_focus_styles()

func _apply_focus_styles() -> void:
	var vbox = get_node_or_null("CanvasLayer/Panel/VBox")
	if vbox:
		for child in vbox.get_children():
			if child is Button:
				GUINavigationHelper.apply_focus_style(child)

func _translate_labels() -> void:
	if not is_inside_tree(): return
	var resume_btn = get_node_or_null("CanvasLayer/Panel/VBox/Resume")
	if resume_btn: resume_btn.text = tr("menu.pause.resume")
	var inv_btn = get_node_or_null("CanvasLayer/Panel/VBox/Inventory")
	if inv_btn: inv_btn.text = tr("menu.inventory.title")
	var jrnl_btn = get_node_or_null("CanvasLayer/Panel/VBox/Journal")
	if jrnl_btn: jrnl_btn.text = tr("menu.pause.journal")
	var config_btn = get_node_or_null("CanvasLayer/Panel/VBox/Settings")
	if config_btn: config_btn.text = tr("menu.pause.settings")
	var feedback_btn = get_node_or_null("CanvasLayer/Panel/VBox/Feedback")
	if feedback_btn: feedback_btn.text = tr("menu.pause.feedback")
	var quit_btn = get_node_or_null("CanvasLayer/Panel/VBox/Quit")
	if quit_btn: quit_btn.text = tr("menu.pause.quit")

func _setup_feedback_button() -> void:
	var vbox = get_node_or_null("CanvasLayer/Panel/VBox")
	if not vbox: return

	if vbox.has_node("Feedback"): return

	var feedback_btn = Button.new()
	feedback_btn.name = "Feedback"
	feedback_btn.text = tr("menu.pause.feedback")
	vbox.add_child(feedback_btn)
	# Insert before Quit button if it exists
	var quit_btn = vbox.get_node_or_null("Quit")
	if quit_btn:
		vbox.move_child(feedback_btn, quit_btn.get_index())

	feedback_btn.pressed.connect(_on_feedback_pressed)

func _on_feedback_pressed() -> void:
	var feedback_scene: String = FilePaths.Scenes.FEEDBACK_FORM
	if ResourceLoader.exists(feedback_scene):
		var packed: PackedScene = load(feedback_scene)
		var feedback_menu = packed.instantiate()
		feedback_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(feedback_menu)
		feedback_menu.close_requested.connect(_on_feedback_closed.bind(feedback_menu))
		hide_menu()
	else:
		GameLogger.error(GameLogger.Category.UI, "Feedback form scene not found!")


func _on_feedback_closed(menu: Node) -> void:
	if is_instance_valid(menu):
		menu.queue_free()
	show_menu()
	var feedback_btn = get_node_or_null("CanvasLayer/Panel/VBox/Feedback")
	if feedback_btn:
		feedback_btn.grab_focus()

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
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		GameLogger.info(GameLogger.Category.INPUT, "[PauseMenu] Action pressed: %s. Focus owner: %s" % [event.as_text(), get_viewport().gui_get_focus_owner()])

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


func _on_inventory_pressed() -> void:
	GameLogger.info(GameLogger.Category.UI, "[PauseMenu] Inventory button pressed, emitting inventory_requested")
	inventory_requested.emit()

func _on_journal_pressed() -> void:
	journal_requested.emit()

func _on_settings_pressed() -> void:
	settings_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()
