class_name PauseHandler
extends Node

signal resume_requested
signal inventory_requested
signal quit_requested
signal pause_state_changed(paused: bool)
signal hud_toggle_requested(visible: bool)

var _paused := false
var _pause_menu: Control
var _inventory_menu: Control
var _journal_menu: Control
var _settings_menu: Control
var _journal_manager: Node
var _unit_manager: UnitManager

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		GameLogger.info(GameLogger.Category.UI, "[PauseHandler] Detected pause_game action")
	if _handle_pause_input(event):
		get_viewport().set_input_as_handled()

func _handle_pause_input(event: InputEvent) -> bool:
	if not event.is_action_pressed("pause_game"):
		return false

	var dialogue_service := PlayerActionManager.get_dialogue_service()
	if dialogue_service and dialogue_service.is_dialogue_active():
		GameLogger.debug(GameLogger.Category.UI, "PauseHandler: Pause blocked, dialogue is active.")
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
	var packed: PackedScene = load(FilePaths.Scenes.PAUSE_MENU)
	_pause_menu = packed.instantiate() as Control
	_pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_menu)
	_pause_menu.resume_requested.connect(_on_pause_resume)
	_pause_menu.inventory_requested.connect(_on_pause_inventory)
	_pause_menu.journal_requested.connect(_on_pause_journal)
	_pause_menu.settings_requested.connect(_on_pause_settings)
	_pause_menu.quit_requested.connect(_on_pause_quit)
	get_tree().paused = true
	pause_state_changed.emit(true)
	hud_toggle_requested.emit(false)
	
	# Focus the first button for keyboard/controller navigation
	var resume_btn = _pause_menu.get_node_or_null("CanvasLayer/Panel/VBox/Resume")
	if resume_btn:
		resume_btn.grab_focus()

func _hide_pause_menu() -> void:
	if not _paused:
		return
	if is_instance_valid(_inventory_menu):
		_inventory_menu.queue_free()
		_inventory_menu = null
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
	pause_state_changed.emit(false)
	hud_toggle_requested.emit(true)

func _on_pause_resume() -> void:
	_hide_pause_menu()
	resume_requested.emit()


func _on_pause_inventory() -> void:
	if not is_instance_valid(_pause_menu):
		return
	if is_instance_valid(_inventory_menu):
		_inventory_menu.queue_free()

	# Sync from combat units to RosterManager BEFORE showing menu
	if RosterManager:
		if is_instance_valid(_unit_manager):
			GameLogger.info(GameLogger.Category.UI, "[PauseHandler] Using stored UnitManager, triggering sync_from_combat")
			RosterManager.sync_from_combat(_unit_manager, [])
		else:
			# Fallback if not explicitly set
			var unit_manager = get_tree().root.find_child("UnitManager", true, false)
			if is_instance_valid(unit_manager):
				GameLogger.info(GameLogger.Category.UI, "[PauseHandler] Found UnitManager via fallback, triggering sync_from_combat")
				RosterManager.sync_from_combat(unit_manager, [])
			else:
				GameLogger.info(GameLogger.Category.UI, "[PauseHandler] WARNING: UnitManager NOT FOUND for sync_from_combat")

	_pause_menu.hide_menu()

	var packed: PackedScene = load(FilePaths.Scenes.INVENTORY_MANAGEMENT_MENU)
	_inventory_menu = packed.instantiate() as Control
	_inventory_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	if "is_submenu" in _inventory_menu:
		_inventory_menu.is_submenu = true
	add_child(_inventory_menu)
	_inventory_menu.back_requested.connect(_on_inventory_back)
	
	# Focus back button
	var back_btn = _inventory_menu.find_child("BackButton", true, false)
	if back_btn:
		back_btn.grab_focus()
		
	inventory_requested.emit()

func _on_pause_journal() -> void:
	if not is_instance_valid(_pause_menu):
		return
	if is_instance_valid(_journal_menu):
		_journal_menu.queue_free()

	_pause_menu.hide_menu()

	var packed: PackedScene = load(FilePaths.Scenes.JOURNAL_UI)
	if packed == null:
		GameLogger.error(GameLogger.Category.UI, "PauseHandler: Failed to load journal menu scene")
		return
	_journal_menu = packed.instantiate() as Control
	_journal_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	if _journal_menu.has_method("setup"):
		_journal_menu.setup(_journal_manager)
	add_child(_journal_menu)
	_journal_menu.back_requested.connect(_on_journal_back)
	
	# Focus back button
	var back_btn = _journal_menu.find_child("BackButton", true, false)
	if back_btn:
		back_btn.grab_focus()

func _on_pause_settings() -> void:
	if not is_instance_valid(_pause_menu):
		return
	if is_instance_valid(_settings_menu):
		_settings_menu.queue_free()

	_pause_menu.hide_menu()

	var packed: PackedScene = load(FilePaths.Scenes.SETTINGS_MENU)
	_settings_menu = packed.instantiate() as Control
	_settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_settings_menu)
	_settings_menu.back_requested.connect(_on_settings_back)
	
	# Focus back button
	var back_btn = _settings_menu.find_child("Back", true, false)
	if back_btn:
		back_btn.grab_focus()


func _on_inventory_back() -> void:
	if is_instance_valid(_inventory_menu):
		# Sync from RosterManager back to combat units AFTER closing menu
		if RosterManager:
			if is_instance_valid(_unit_manager):
				GameLogger.info(GameLogger.Category.UI, "[PauseHandler] Syncing back to stored UnitManager")
				RosterManager.sync_to_combat(_unit_manager)
			else:
				var unit_manager = get_tree().root.find_child("UnitManager", true, false)
				if is_instance_valid(unit_manager):
					GameLogger.info(GameLogger.Category.UI, "[PauseHandler] Syncing back to UnitManager via fallback")
					RosterManager.sync_to_combat(unit_manager)
		
		_inventory_menu.queue_free()
		_inventory_menu = null
	
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
	
	# Sync roster before quitting to ensure no progress is lost
	if RosterManager:
		# We need a reference to the UnitManager. Since PauseHandler is often 
		# used in Gameplay, we can try to find it via the owner or a global search.
		var unit_manager = get_tree().root.find_child("UnitManager", true, false)
		if is_instance_valid(unit_manager):
			RosterManager.sync_from_combat(unit_manager, [])
	
	quit_requested.emit()

	var level_select_scene = FilePaths.Scenes.LEVEL_SELECT
	var transition = SceneTransition
	if transition:
		transition.change_scene(level_select_scene)
	else:
		get_tree().change_scene_to_file(level_select_scene)

func is_paused() -> bool:
	return _paused

func set_journal_manager(p_journal_manager: Node) -> void:
	_journal_manager = p_journal_manager

func set_unit_manager(p_unit_manager: UnitManager) -> void:
	_unit_manager = p_unit_manager
