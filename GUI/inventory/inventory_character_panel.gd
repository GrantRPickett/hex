extends PanelContainer

signal item_dropped(item: InventoryItem, source_unit: Unit, target_unit: Unit)
signal action_requested(type: String, item: InventoryItem, unit: Unit)

@onready var _name_label: Label = %CharacterName
@onready var _stats_grid: GridContainer = %StatsGrid
@onready var _item_list: VBoxContainer = %ItemList
@onready var _capacity_label: Label = %CapacityLabel

var unit: Unit
var item_slot_scene: PackedScene = preload("res://GUI/inventory/inventory_item_slot.tscn")

func setup(p_unit: Unit) -> void:
	unit = p_unit
	if is_node_ready():
		refresh()
	
	if not EventBus.item_equipped.is_connected(_on_item_changed):
		EventBus.item_equipped.connect(_on_item_changed)
	if not EventBus.item_unequipped.is_connected(_on_item_changed):
		EventBus.item_unequipped.connect(_on_item_changed)
	if not EventBus.item_added.is_connected(_on_item_changed):
		EventBus.item_added.connect(_on_item_changed)
	if not EventBus.item_removed.is_connected(_on_item_changed):
		EventBus.item_removed.connect(_on_item_changed)
	
	if not unit.attribute_modifiers_changed.is_connected(refresh):
		unit.attribute_modifiers_changed.connect(refresh)

func _on_item_changed(u: Node, _item: Resource) -> void:
	if u == unit:
		refresh()

func _ready() -> void:
	refresh()

func refresh() -> void:
	if not unit:
		return
	
	if not is_node_ready() or _name_label == null:
		return
	
	_name_label.text = unit.unit_name if not unit.unit_name.is_empty() else "Unnamed Unit"
	
	# Update Capacity Label
	if _capacity_label:
		if SaveManager and SaveManager.is_easy_difficulty():
			_capacity_label.text = ""
			_capacity_label.hide()
		elif unit.inv and unit.inv.get_inventory():
			var inv = unit.inv.get_inventory()
			var count = inv.get_non_quest_items().size()
			var max_cap = inv.slot_capacity
			_capacity_label.text = "%d/%d Full" % [count, max_cap]
			_capacity_label.show()
			# Change color if full
			if count >= max_cap:
				_capacity_label.modulate = GameConstants.Colors.INV_CAPACITY_FULL
			else:
				_capacity_label.modulate = GameConstants.Colors.INV_CAPACITY_NORMAL
		else:
			_capacity_label.text = ""
			_capacity_label.hide()
	
	# Clear dynamic stat values (skip first 8 labels which are headers)
	var children = _stats_grid.get_children()
	for i in range(8, children.size()):
		var child = children[i]
		_stats_grid.remove_child(child)
		child.queue_free()
	
	for stat in GameConstants.Attributes.COMBAT_ATTRIBUTES:
		var idx = GameConstants.Attributes.get_attribute_index(stat)
		var base = unit.get_base_attribute_from_target(idx)
		var total = unit.get_attribute(idx)
		var bonus = total - base
		var stat_color = GameConstants.Attributes.ATTRIBUTE_COLORS.get(stat, GameConstants.Colors.UI_WHITE)
		_add_stat_row(stat.capitalize(), base, bonus, total, stat_color)
			
	# Clear and rebuild items
	for child in _item_list.get_children():
		_item_list.remove_child(child)
		child.queue_free()
	if unit.inv:
		var inv = unit.inv.get_inventory()
		if inv:
			for item in inv.get_items():
				var slot = item_slot_scene.instantiate()
				_item_list.add_child(slot)
				slot.setup(item, unit)
				slot.action_triggered.connect(func(type, itm, u): action_requested.emit(type, itm, u))

func _add_stat_row(stat_name: String, base: int, bonus: int, total: int, stat_color: Color = GameConstants.Colors.UI_WHITE) -> void:
	var nl = Label.new(); nl.text = stat_name; nl.add_theme_font_size_override("font_size", 12)
	nl.modulate = stat_color
	_stats_grid.add_child(nl)
	
	var bl = Label.new(); bl.text = str(base); bl.add_theme_font_size_override("font_size", 12)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_grid.add_child(bl)
	
	var bonl = Label.new(); bonl.text = "+%d" % bonus if bonus >= 0 else str(bonus)
	bonl.add_theme_font_size_override("font_size", 12)
	bonl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonl.modulate = GameConstants.Colors.FACTION_PLAYER if bonus > 0 else (GameConstants.Colors.FACTION_ENEMY if bonus < 0 else GameConstants.Colors.UI_GRAY)
	_stats_grid.add_child(bonl)
	
	var tl = RichTextLabel.new(); tl.bbcode_enabled = true; tl.fit_content = true; tl.autowrap_mode = 0
	tl.text = "[center][color=#%s]%d[/color][/center]" % [stat_color.to_html(false), total]
	tl.add_theme_font_size_override("normal_font_size", 12)
	_stats_grid.add_child(tl)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("item")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	item_dropped.emit(data["item"], data.get("source_unit"), unit)

func set_highlight(active: bool) -> void:
	if active:
		var sb = StyleBoxFlat.new()
		sb.bg_color = GameConstants.Colors.INV_CHAR_PANEL_BG
		sb.border_width_left = 2; sb.border_width_right = 2; sb.border_width_top = 2; sb.border_width_bottom = 2
		sb.border_color = GameConstants.Colors.UI_CYAN
		add_theme_stylebox_override("panel", sb)
	else:
		remove_theme_stylebox_override("panel")
