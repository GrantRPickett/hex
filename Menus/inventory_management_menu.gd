extends Control

@onready var _character_list: GridContainer = %CharacterList
@onready var _stash_list: VBoxContainer = %StashList
@onready var _auto_equip_button: Button = %AutoEquipButton
@onready var _back_button: Button = %BackButton

var _roster: PlayerRoster
var _loaded_units: Array[Unit] = []
var _char_panels: Array[PanelContainer] = []

# Move Mode state (Controller/Keyboard)
var _move_mode_active: bool = false
var _move_mode_item: InventoryItem = null
var _move_mode_target_idx: int = 0

func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_auto_equip_button.pressed.connect(_on_auto_equip_pressed)
	_load_roster_data()
	_refresh_ui()

func _exit_tree() -> void:
	for unit in _loaded_units:
		if is_instance_valid(unit):
			unit.queue_free()

func _load_roster_data() -> void:
	var save_manager = get_tree().root.get_node_or_null("SaveManager")
	if save_manager:
		_roster = save_manager.load_roster()
	
	if _roster:
		for u in _loaded_units: u.queue_free()
		_loaded_units.clear()
		
		for entry in _roster.roster_entries:
			var scene = RosterPersistence.entry_to_scene(entry)
			if scene:
				var unit = scene.instantiate() as Unit
				UnitSerializer.restore_from_memento(unit, entry.get("data", {}))
				# Unit needs to be in tree for components to work
				add_child(unit)
				unit.visible = false
				_loaded_units.append(unit)

func _refresh_ui() -> void:
	# Clear lists
	for child in _character_list.get_children(): child.queue_free()
	
	# Clear and setup stash list
	for child in _stash_list.get_children(): child.queue_free()
	var stash_drop_zone = StashPanel.new()
	stash_drop_zone.setup(self)
	_stash_list.add_child(stash_drop_zone)
	
	_char_panels.clear()
	
	# Populate characters
	for unit in _loaded_units:
		var char_panel = _create_character_panel(unit)
		_character_list.add_child(char_panel)
		_char_panels.append(char_panel)
	
	# Populate stash
	if _roster:
		for item in _roster.stash_items:
			var item_ui = _create_stash_item_ui(item)
			stash_drop_zone.add_item(item_ui)
	
	_update_move_mode_visuals()

func _create_character_panel(unit: Unit) -> PanelContainer:
	var panel = CharacterPanel.new()
	panel.setup(unit, self)
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(250, 0)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Name Header
	var name_label = Label.new()
	name_label.text = unit.unit_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)
	
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)
	
	# Stats Grid (4 columns: Stat, Base, Bonus, Total)
	var stats_grid = GridContainer.new()
	stats_grid.columns = 4
	stats_grid.add_theme_constant_override("h_separation", 10)
	vbox.add_child(stats_grid)
	
	# Headers for stats
	for h in ["Stat", "Base", "+", "Total"]:
		var hl = Label.new()
		hl.text = h
		hl.add_theme_font_size_override("font_size", 10)
		hl.modulate = Color.GRAY
		stats_grid.add_child(hl)
	
	var attrs = unit.inv.get_attributes() if unit.inv else null
	if attrs:
		for stat in GameConstants.Attributes.COMBAT_ATTRIBUTES:
			var base = attrs.get_base_attribute(stat)
			var total = attrs.get_attribute(stat)
			var bonus = total - base
			
			_create_stat_row(stats_grid, stat.capitalize(), base, bonus, total)
	
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	# Item List
	var item_list = VBoxContainer.new()
	item_list.name = "ItemList"
	item_list.theme_override_constants/separation = 2
	vbox.add_child(item_list)
	
	if unit.inv:
		var inv = unit.inv.get_inventory()
		if inv:
			for item in inv.get_items():
				var item_ui = _create_inv_item_ui(unit, item)
				item_list.add_child(item_ui)
	
	return panel

func _create_stat_row(grid: GridContainer, stat_name: String, base: int, bonus: int, total: int) -> void:
	var nl = Label.new()
	nl.text = stat_name
	nl.theme_override_font_sizes/font_size = 12
	grid.add_child(nl)
	
	var bl = Label.new()
	bl.text = str(base)
	bl.theme_override_font_sizes/font_size = 12
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grid.add_child(bl)
	
	var bonl = Label.new()
	bonl.text = "+%d" % bonus if bonus >= 0 else str(bonus)
	bonl.theme_override_font_sizes/font_size = 12
	bonl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonl.modulate = Color.GREEN if bonus > 0 else (Color.RED if bonus < 0 else Color.GRAY)
	grid.add_child(bonl)
	
	var tl = Label.new()
	tl.text = str(total)
	tl.theme_override_font_sizes/font_size = 12
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.modulate = Color.CYAN
	grid.add_child(tl)

func _create_inv_item_ui(unit: Unit, item: InventoryItem) -> PanelContainer:
	var item_ui = InventoryItemUI.new()
	item_ui.setup(item, unit, self)
	
	var hbox = HBoxContainer.new()
	item_ui.add_child(hbox)
	
	var label = Label.new()
	label.text = item.item_name
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.theme_override_font_sizes/font_size = 14
	hbox.add_child(label)
	
	var minus_btn = Button.new()
	minus_btn.text = "-"
	minus_btn.tooltip_text = "Move to Stash"
	minus_btn.custom_minimum_size = Vector2(25, 25)
	minus_btn.pressed.connect(_on_minus_pressed.bind(unit, item))
	hbox.add_child(minus_btn)
	
	return item_ui

func _create_stash_item_ui(item: InventoryItem) -> PanelContainer:
	var item_ui = InventoryItemUI.new()
	item_ui.setup(item, null, self)
	
	var hbox = HBoxContainer.new()
	item_ui.add_child(hbox)
	
	var label = Label.new()
	label.text = item.item_name
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	var hand_btn = Button.new()
	hand_btn.text = "✋"
	hand_btn.tooltip_text = "Pick up to Move"
	hand_btn.custom_minimum_size = Vector2(30, 30)
	hand_btn.pressed.connect(_on_hand_pressed.bind(item))
	hbox.add_child(hand_btn)
	
	return item_ui

func _get_highest_stat(unit: Unit) -> String:
	var best_stat = ""
	var best_val = -1
	var attributes_component = unit.inv.get_attributes() if unit.inv else null
	if attributes_component:
		for stat in GameConstants.Attributes.COMBAT_ATTRIBUTES:
			var val = attributes_component.get_attribute(stat)
			if val > best_val:
				best_val = val
				best_stat = stat
	return best_stat

# Action Handlers

func _on_minus_pressed(unit: Unit, item: InventoryItem) -> void:
	if unit.inv.remove_item_from_inventory(item):
		_roster.stash_items.append(item)
		_save_changes()
		_refresh_ui()

func _on_hand_pressed(item: InventoryItem) -> void:
	_enter_move_mode(item)

func _on_auto_equip_pressed() -> void:
	var all_items: Array[InventoryItem] = []
	all_items.append_array(_roster.stash_items)
	_roster.stash_items.clear()
	
	for unit in _loaded_units:
		if unit.inv:
			var inv = unit.inv.get_inventory()
			if inv:
				var items = inv.get_items().duplicate()
				for item in items:
					unit.inv.remove_item_from_inventory(item)
				all_items.append_array(items)
	
	if all_items.is_empty(): return

	all_items.sort_custom(func(a, b):
		var max_a = 0
		for v in a.attribute_modifiers.values(): max_a = max(max_a, v)
		var max_b = 0
		for v in b.attribute_modifiers.values(): max_b = max(max_b, v)
		return max_a > max_b
	)

	var target_count = ceil(float(all_items.size()) / _loaded_units.size())
	target_count = min(target_count, 6) 
	var items_to_process = all_items.duplicate()
	
	for unit in _loaded_units:
		var best_stat = _get_highest_stat(unit)
		var i = 0
		while i < items_to_process.size():
			var item = items_to_process[i]
			if item.attribute_modifiers.get(best_stat, 0) > 0:
				if _get_unit_item_count(unit) < target_count:
					unit.inv.add_item_to_inventory(item)
					unit.inv.equip_item(item)
					items_to_process.remove_at(i)
					continue
			i += 1

	for unit in _loaded_units:
		while _get_unit_item_count(unit) < target_count and not items_to_process.is_empty():
			var item = items_to_process.pop_front()
			unit.inv.add_item_to_inventory(item)
			unit.inv.equip_item(item)
			
	_roster.stash_items = items_to_process
	_save_changes()
	_refresh_ui()

func _get_unit_item_count(unit: Unit) -> int:
	if unit.inv and unit.inv.get_inventory():
		return unit.inv.get_inventory().get_items().size()
	return 0

# Drag and Drop & Move Mode Logic

func handle_item_drop(item: InventoryItem, source_unit: Unit, target_unit: Unit) -> void:
	if source_unit == target_unit: return
	
	# Remove from source
	if source_unit == null: # From stash
		_roster.stash_items.erase(item)
	else:
		source_unit.inv.remove_item_from_inventory(item)
	
	# Add to target
	if target_unit == null: # To stash
		_roster.stash_items.append(item)
	else:
		target_unit.inv.add_item_to_inventory(item)
		target_unit.inv.equip_item(item)
	
	_save_changes()
	_refresh_ui()

func _enter_move_mode(item: InventoryItem) -> void:
	_move_mode_active = true
	_move_mode_item = item
	_move_mode_target_idx = 0
	_update_move_mode_visuals()

func _exit_move_mode() -> void:
	_move_mode_active = false
	_move_mode_item = null
	_update_move_mode_visuals()

func _update_move_mode_visuals() -> void:
	for i in range(_char_panels.size()):
		var panel = _char_panels[i]
		if _move_mode_active and i == _move_mode_target_idx:
			panel.add_theme_stylebox_override("panel", _get_highlight_style())
		else:
			panel.remove_theme_stylebox_override("panel")

func _get_highlight_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.4, 0.6, 0.5)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = Color.CYAN
	return sb

func _input(event: InputEvent) -> void:
	if not _move_mode_active: return
	
	if event.is_action_pressed("ui_left"):
		_move_mode_target_idx = posmod(_move_mode_target_idx - 1, _loaded_units.size())
		_update_move_mode_visuals()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_move_mode_target_idx = posmod(_move_mode_target_idx + 1, _loaded_units.size())
		_update_move_mode_visuals()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move_mode_target_idx = posmod(_move_mode_target_idx - 3, _loaded_units.size())
		_update_move_mode_visuals()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_mode_target_idx = posmod(_move_mode_target_idx + 3, _loaded_units.size())
		_update_move_mode_visuals()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		handle_item_drop(_move_mode_item, null, _loaded_units[_move_mode_target_idx])
		_exit_move_mode()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_exit_move_mode()
		get_viewport().set_input_as_handled()

func _save_changes() -> void:
	if not _roster: return
	var new_entries: Array[Dictionary] = []
	for unit in _loaded_units:
		new_entries.append(RosterPersistence.unit_to_entry(unit))
	_roster.roster_entries = new_entries
	var save_manager = get_tree().root.get_node_or_null("SaveManager")
	if save_manager:
		save_manager.save_roster(_roster)

func _on_back_pressed() -> void:
	_save_changes()
	var transition = get_tree().root.get_node_or_null("SceneTransition")
	if transition:
		transition.change_scene(FilePaths.Scenes.LEVEL_SELECT)
	else:
		get_tree().change_scene_to_file(FilePaths.Scenes.LEVEL_SELECT)

# Helper Classes for Drag and Drop

class InventoryItemUI extends PanelContainer:
	var item: InventoryItem
	var owner_unit: Unit
	var menu: Control
	
	func setup(p_item: InventoryItem, p_unit: Unit, p_menu: Control) -> void:
		item = p_item
		owner_unit = p_unit
		menu = p_menu
		custom_minimum_size = Vector2(0, 30)
	
	func _get_drag_data(_at_position: Vector2) -> Variant:
		var preview = Label.new()
		preview.text = item.item_name
		set_drag_preview(preview)
		return {"item": item, "source_unit": owner_unit}

class CharacterPanel extends PanelContainer:
	var unit: Unit
	var menu: Control
	
	func setup(p_unit: Unit, p_menu: Control) -> void:
		unit = p_unit
		menu = p_menu
	
	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("item")
	
	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		menu.handle_item_drop(data["item"], data.get("source_unit"), unit)

class StashPanel extends VBoxContainer:
	var menu: Control
	
	func setup(p_menu: Control) -> void:
		menu = p_menu
		size_flags_horizontal = SIZE_EXPAND_FILL
		size_flags_vertical = SIZE_EXPAND_FILL
	
	func add_item(node: Node) -> void:
		add_child(node)
	
	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("item")
	
	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		menu.handle_item_drop(data["item"], data.get("source_unit"), null)
