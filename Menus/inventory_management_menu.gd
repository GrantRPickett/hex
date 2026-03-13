extends Control

signal back_requested

var is_submenu: bool = false

@onready var _character_list: GridContainer = %CharacterList
@onready var _stash_list: BoxContainer = %StashList
@onready var _auto_equip_button: Button = %AutoEquipButton
@onready var _debug_reset_button: Button = %DebugResetButton
@onready var _back_button: Button = %BackButton
@onready var _help_label: Label = %HelpLabel
@onready var _hbox: BoxContainer = $CanvasLayer/MainPanel/VBox/HBox
@onready var _character_scroll: ScrollContainer = $CanvasLayer/MainPanel/VBox/HBox/CharactersScroll
@onready var _stash_panel: VBoxContainer = $CanvasLayer/MainPanel/VBox/HBox/StashPanel
@onready var _stash_scroll: ScrollContainer = $CanvasLayer/MainPanel/VBox/HBox/StashPanel/StashScroll
@onready var _controls: BoxContainer = $CanvasLayer/MainPanel/VBox/Controls
@onready var _pause_handler: PauseHandler = $PauseHandler
@onready var _pause_button: Button = %PauseButton

# Scenes
var _character_panel_scene: PackedScene = preload("res://GUI/inventory/inventory_character_panel.tscn")
var _item_slot_scene: PackedScene = preload("res://GUI/inventory/inventory_item_slot.tscn")

# Move Mode state (Controller/Keyboard)
var _move_mode_active: bool = false
var _move_mode_item: InventoryItem = null
var _move_mode_target_idx: int = 0

func _ready() -> void:
	if is_submenu:
		if is_instance_valid(_pause_button):
			_pause_button.hide()
		if is_instance_valid(_pause_handler):
			_pause_handler.set_process_unhandled_input(false)
			_pause_handler.queue_free()
			
	_back_button.pressed.connect(_on_back_pressed)
	_auto_equip_button.pressed.connect(_on_auto_equip_pressed)
	
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	if _debug_reset_button:
		_debug_reset_button.visible = OS.is_debug_build()
		_debug_reset_button.pressed.connect(_on_debug_reset_pressed)
		
		# Give debug button a distinct style
		var debug_sb = StyleBoxFlat.new()
		debug_sb.bg_color = GameConstants.Colors.INV_DEBUG_BG
		debug_sb.corner_radius_top_left = 4; debug_sb.corner_radius_top_right = 4; debug_sb.corner_radius_bottom_right = 4; debug_sb.corner_radius_bottom_left = 4
		_debug_reset_button.add_theme_stylebox_override("normal", debug_sb)

	# Design polish: Give Auto-Equip a distinct style
	var sb = StyleBoxFlat.new()
	sb.bg_color = GameConstants.Colors.INV_BG
	sb.corner_radius_top_left = 4; sb.corner_radius_top_right = 4; sb.corner_radius_bottom_right = 4; sb.corner_radius_bottom_left = 4
	_auto_equip_button.add_theme_stylebox_override("normal", sb)
	_auto_equip_button.add_theme_color_override("font_color", GameConstants.Colors.UI_WHITE)

	_refresh_ui()
	_update_help_text()
	
	if DisplaySettings:
		DisplaySettings.display_settings_changed.connect(_on_display_settings_changed)
		
	_update_layout()

func _refresh_ui() -> void:
	if not _character_list or not _stash_list: return

	# Clear lists
	for child in _character_list.get_children(): child.queue_free()

	# Clear stash
	for child in _stash_list.get_children(): child.queue_free()

	var viewport_size = get_viewport().get_visible_rect().size
	var is_portrait = viewport_size.y > viewport_size.x

	var stash_drop_zone = StashPanelNode.new()
	if is_portrait:
		# In portrait, stash is horizontal at top.
		stash_drop_zone.setup(self, false)
		# Set a large width to allow horizontal scrolling if many items
		stash_drop_zone.custom_minimum_size = GameConstants.Inventory.STASH_SIZE_PORTRAIT
	else:
		# In landscape, stash is vertical on right.
		stash_drop_zone.setup(self, true)
		# Set a large height to allow vertical scrolling
		stash_drop_zone.custom_minimum_size = GameConstants.Inventory.STASH_SIZE_LANDSCAPE
		
	_stash_list.add_child(stash_drop_zone)

	var units = RosterManager.get_units()
	var roster = RosterManager.get_roster()

	# Populate characters
	for unit in units:
		if not is_instance_valid(unit):
			continue
		var char_panel = _character_panel_scene.instantiate()
		char_panel.setup(unit)
		_character_list.add_child(char_panel)
		char_panel.item_dropped.connect(handle_item_drop)
		char_panel.action_requested.connect(_on_action_requested)

	# Populate stash
	if roster:
		for item in roster.stash_items:
			var item_ui = _item_slot_scene.instantiate()
			stash_drop_zone.add_item(item_ui)
			item_ui.setup(item, null)
			item_ui.action_triggered.connect(_on_action_requested)

	_update_move_mode_visuals()

func _update_help_text() -> void:
	if not _help_label: return
	if _move_mode_active:
		_help_label.text = "MOVE MODE: Up/Down/Left/Right to target. SPACE/ENTER to Confirm, ESC to Cancel."
		_help_label.modulate = GameConstants.Colors.UI_CYAN
	else:
		_help_label.text = "Equip [E], Un-assign [-], or Move [✋]. Drag & Drop also supported."
		_help_label.modulate = GameConstants.Colors.INV_HELP_TEXT

func _on_action_requested(type: String, item: InventoryItem, unit: Unit) -> void:
	match type:
		GameConstants.Inventory.ACTION_MINUS: _on_minus_pressed(unit, item)
		GameConstants.Inventory.ACTION_HAND: _on_hand_pressed(item)
		GameConstants.Inventory.ACTION_EQUIP: _on_equip_pressed(unit, item)

func _on_minus_pressed(unit: Unit, item: InventoryItem) -> void:
	RosterManager.transfer_item(item, unit, null)
	_refresh_ui()

func _on_equip_pressed(unit: Unit, item: InventoryItem) -> void:
	RosterManager.toggle_item_equip(item, unit)
	_refresh_ui()

func _on_hand_pressed(item: InventoryItem) -> void:
	_enter_move_mode(item)

func handle_item_drop(item: InventoryItem, source_unit: Unit, target_unit: Unit) -> void:
	if source_unit == target_unit: return
	
	# If target unit is full, we can't just add it (it will bounce back)
	if target_unit != null and not item.is_quest_item():
		var inv = target_unit.inv.get_inventory()
		if inv and inv.get_non_quest_items().size() >= inv.slot_capacity:
			print_debug("[InventoryMenu] Target unit %s is full. Item %s bounced back." % [target_unit.unit_name, item.get_item_name()])
			return

	RosterManager.transfer_item(item, source_unit, target_unit)
	_refresh_ui()

func handle_swap(item_a: InventoryItem, unit_a: Unit, item_b: InventoryItem, unit_b: Unit) -> void:
	if item_a == item_b: return
	RosterManager.swap_items(item_a, unit_a, item_b, unit_b)
	_refresh_ui()

func _on_auto_equip_pressed() -> void:
	RosterManager.auto_equip()
	_refresh_ui()

func _on_debug_reset_pressed() -> void:
	RosterManager.debug_reset_roster()
	_refresh_ui()
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").show_feedback_message.emit("Debug: Roster reset to defaults.")

func _on_viewport_size_changed() -> void:
	_update_layout()

func _update_layout() -> void:
	var is_portrait := false
	var viewport_size := Vector2.ZERO
	
	if DisplaySettings:
		is_portrait = DisplaySettings.get_current_orientation() == DisplayOrientation.Orientation.PORTRAIT
		viewport_size = Vector2(DisplaySettings.get_current_resolution())
	elif is_inside_tree():
		viewport_size = get_viewport().get_visible_rect().size
		is_portrait = viewport_size.y > viewport_size.x
	else:
		return
	
	# Adjust HBox orientation (stacking in portrait)
	if is_portrait:
		_hbox.vertical = true
		_character_list.columns = 1 if viewport_size.x < 500 else 2
		_stash_panel.custom_minimum_size = Vector2(0, 80) # Minimal height
		_stash_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stash_panel.size_flags_vertical = Control.SIZE_SHRINK_END # Push to bottom
		
		# Make stash list horizontal
		_stash_list.vertical = false
		_stash_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_stash_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_stash_list.custom_minimum_size.y = 0
		
		# Move Stash to BOTTOM in portrait
		if _hbox.get_child(0) == _stash_panel:
			_hbox.move_child(_stash_panel, 1)
			
		_character_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_character_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		_hbox.vertical = false
		_character_list.columns = 3
		_stash_panel.custom_minimum_size = Vector2(GameConstants.Inventory.STASH_ITEM_WIDTH_LANDSCAPE + 50, 0) # Width-constrained in landscape
		_stash_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_stash_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# Make stash list vertical
		_stash_list.vertical = true
		_stash_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_stash_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_stash_list.custom_minimum_size.y = 400
		
		# Move Stash to RIGHT in landscape
		if _hbox.get_child(1) == _character_scroll:
			_hbox.move_child(_character_scroll, 0)
			
		_character_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_character_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Adjust controls spacing
	if viewport_size.x < 400:
		_controls.vertical = true
		_controls.alignment = BoxContainer.ALIGNMENT_CENTER
	else:
		_controls.vertical = false
		_controls.alignment = BoxContainer.ALIGNMENT_CENTER

func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void:
	_update_layout()

func _input(event: InputEvent) -> void:
	if not _move_mode_active: return
	
	var units = RosterManager.get_units()
	if units.is_empty(): return

	if event.is_action_pressed("ui_left"):
		_move_mode_target_idx = posmod(_move_mode_target_idx - 1, units.size())
		_update_move_mode_visuals()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_move_mode_target_idx = posmod(_move_mode_target_idx + 1, units.size())
		_update_move_mode_visuals()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move_mode_target_idx = posmod(_move_mode_target_idx - 3, units.size())
		_update_move_mode_visuals()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_mode_target_idx = posmod(_move_mode_target_idx + 3, units.size())
		_update_move_mode_visuals()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		handle_item_drop(_move_mode_item, null, units[_move_mode_target_idx])
		_exit_move_mode()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_exit_move_mode()
		get_viewport().set_input_as_handled()

func _on_back_pressed() -> void:
	back_requested.emit()
	# Only change scene if we are the current main scene (not a child of pause menu)
	if get_tree().current_scene == self:
		if is_instance_valid(SceneTransition):
			SceneTransition.change_scene(FilePaths.Scenes.LEVEL_SELECT)
		else:
			get_tree().change_scene_to_file(FilePaths.Scenes.LEVEL_SELECT)

func _update_move_mode_visuals() -> void:
	# Note: Visuals implementation remains unchanged, just using RosterManager.get_units()
	var panels = _character_list.get_children()
	for i in range(panels.size()):
		if panels[i] is Control:
			if _move_mode_active and i == _move_mode_target_idx:
				panels[i].modulate = GameConstants.Colors.UI_CYAN
			else:
				panels[i].modulate = GameConstants.Colors.UI_WHITE

func _enter_move_mode(item: InventoryItem) -> void:
	_move_mode_active = true
	_move_mode_item = item
	_move_mode_target_idx = 0
	_update_help_text()
	_update_move_mode_visuals()

func _exit_move_mode() -> void:
	_move_mode_active = false
	_move_mode_item = null
	_update_help_text()
	_update_move_mode_visuals()

# Stash drop zone helper
class StashPanelNode extends BoxContainer:
	var menu: Control
	func setup(p_menu: Control, is_vertical: bool = true) -> void:
		menu = p_menu
		vertical = is_vertical
		size_flags_horizontal = SIZE_EXPAND_FILL
		size_flags_vertical = SIZE_EXPAND_FILL
	func add_item(node: Node) -> void: add_child(node)
	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("item")
	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		menu.handle_item_drop(data["item"], data.get("source_unit"), null)

func _on_pause_pressed() -> void:
	print("[InventoryMenu] Pause button pressed")
	if is_instance_valid(_pause_handler):
		_pause_handler.show_pause_menu()
