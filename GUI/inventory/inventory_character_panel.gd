extends PanelContainer

signal item_dropped(item: InventoryItem, source_unit: Unit, target_unit: Unit)
signal action_requested(type: String, item: InventoryItem, unit: Unit)

@onready var _name_label: Label = %CharacterName
@onready var _stats_grid: GridContainer = %StatsGrid
@onready var _item_list: VBoxContainer = %ItemList
@onready var _capacity_label: Label = %CapacityLabel
@onready var _sprite_rect: TextureRect = %CharacterSprite
@onready var _header_box: BoxContainer = %HeaderHBox

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
		# Defer so that equip signal (and attribute modifier) can fire first.
		# item_equipped/unequipped connect directly to refresh() since they are the final step.
		call_deferred("refresh")


func _ready() -> void:
	get_viewport().size_changed.connect(_update_layout)
	if DisplaySettings:
		DisplaySettings.display_settings_changed.connect(func(_o, _r): _update_layout())
	refresh()
	_update_layout()

func refresh() -> void:
	if not unit or not is_node_ready() or _name_label == null:
		return
	
	_update_character_info()
	_update_capacity()
	_update_stats_grid()
	_update_item_list()

func _update_character_info() -> void:
	_update_name()
	_update_portrait()

func _update_name() -> void:
	_name_label.text = unit.unit_name if not unit.unit_name.is_empty() else tr("hud.unit_unknown")

func _update_portrait() -> void:
	if not _sprite_rect: return
		
	var tex: Texture2D = unit.master_texture
	if not tex:
		tex = _get_placeholder_texture()
	
	var region: Rect2 = _get_portrait_region()
	
	if tex and region.size != Vector2.ZERO:
		_apply_portrait_texture(tex, region)
	else:
		_sprite_rect.hide()

func _get_placeholder_texture() -> Texture2D:
	var tex_path := "res://Resources/art/placeholder/32rogues/rogues.png"
	if unit.faction == GameConstants.Faction.ENEMY:
		tex_path = "res://Resources/art/placeholder/32rogues/monsters.png"
	
	if ResourceLoader.exists(tex_path):
		return load(tex_path)
	return null

func _get_portrait_region() -> Rect2:
	var region: Rect2 = unit.region_rect
	if region == Rect2(0, 0, 32, 32) or region == Rect2(0, 0, 0, 0):
		return _calculate_default_region()
	return region

func _calculate_default_region() -> Rect2:
	var seed_val = unit.unit_name.hash() + unit.id.hash()
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	if unit.faction == GameConstants.Faction.ENEMY:
		var col_idx = rng.randi_range(0, 4)
		return Rect2(col_idx * 32, 160, 32, 32)
	elif unit.faction == GameConstants.Faction.NEUTRAL:
		var sprite_idx = rng.randi_range(0, 10)
		if sprite_idx < 6:
			return Rect2(sprite_idx * 32, 192, 32, 32)
		else:
			return Rect2((sprite_idx - 6) * 32, 224, 32, 32)
	return Rect2(0, 0, 32, 32)

func _apply_portrait_texture(tex: Texture2D, region: Rect2) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = region
	_sprite_rect.texture = atlas
	_sprite_rect.show()
	
	if unit.faction == GameConstants.Faction.NEUTRAL:
		if unit.loyalty_type == GameConstants.Faction.STATIC:
			_sprite_rect.modulate = Color.YELLOW
		elif is_instance_valid(unit.loyalty):
			if unit.loyalty.neutral_loyalty == GameConstants.Faction.NEUTRAL:
				_sprite_rect.modulate = Color.GREEN
			elif unit.loyalty.neutral_loyalty == GameConstants.Faction.ENEMY:
				_sprite_rect.modulate = Color.RED
			elif unit.loyalty.neutral_loyalty == GameConstants.Faction.PLAYER:
				_sprite_rect.modulate = Color.WHITE
	else:
		_sprite_rect.modulate = Color.WHITE

func _update_capacity() -> void:
	if not _capacity_label:
		return
		
	if SaveManager and SaveManager.is_easy_difficulty():
		_capacity_label.text = ""
		_capacity_label.hide()
	elif unit.inv and unit.inv.get_inventory():
		var inv: UnitInventory = unit.inv.get_inventory()
		var count: int = inv.get_non_quest_items().size()
		var max_cap = inv.slot_capacity
		_capacity_label.text = tr("hud.inventory_capacity").format({"current": count, "max": max_cap})
		_capacity_label.show()
		if count >= max_cap:
			_capacity_label.modulate = GameConstants.Colors.INV_CAPACITY_FULL
		else:
			_capacity_label.modulate = GameConstants.Colors.INV_CAPACITY_NORMAL
	else:
		_capacity_label.text = ""
		_capacity_label.hide()

func _update_stats_grid() -> void:
	_clear_stats_grid()
	_setup_stats_header()
	_add_attribute_rows()

func _clear_stats_grid() -> void:
	var children = _stats_grid.get_children()
	for i in range(8, children.size()):
		var child = children[i]
		_stats_grid.remove_child(child)
		child.queue_free()

func _setup_stats_header() -> void:
	var children = _stats_grid.get_children()
	if children.size() >= 4:
		children[0].text = tr("inv.header.attribute")
		children[1].text = tr("inv.header.base")
		children[2].text = tr("inv.header.bonus")
		children[3].text = tr("inv.header.total")

func _add_attribute_rows() -> void:
	for idx in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var base = unit.get_base_attribute_from_target(idx)
		var total: int = unit.get_attribute(idx)
		var bonus = total - base
		var stat_color = GameConstants.get_attribute_color(idx)
		var stat_name: String = GameConstants.get_attribute_name(idx)
		_add_stat_row(tr("attr." + stat_name.to_lower()), base, bonus, total, stat_color)

func _update_item_list() -> void:
	for child in _item_list.get_children():
		_item_list.remove_child(child)
		child.queue_free()
		
	if unit.inv:
		var inv: UnitInventory = unit.inv.get_inventory()
		if inv:
			for item in inv.get_items():
				var slot: Node = item_slot_scene.instantiate()
				_item_list.add_child(slot)
				slot.setup(item, unit)
				slot.action_triggered.connect(func(type, itm, u): action_requested.emit(type, itm, u))

func _update_layout() -> void:
	if not is_node_ready() or not _header_box: return
	
	var is_portrait = false
	if DisplaySettings:
		is_portrait = DisplaySettings.get_current_orientation() == DisplayOrientation.Orientation.PORTRAIT
	else:
		var viewport_size = get_viewport().get_visible_rect().size
		is_portrait = viewport_size.y > viewport_size.x
		
	if is_portrait:
		_header_box.vertical = true
		_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		_header_box.vertical = false
		_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _add_stat_row(stat_name: String, base: int, bonus: int, total: int, stat_color: Color = GameConstants.Colors.UI_WHITE) -> void:
	var nl: Label = Label.new(); nl.text = stat_name; nl.add_theme_font_size_override("font_size", 12)
	nl.modulate = stat_color
	_stats_grid.add_child(nl)
	
	var bl: Label = Label.new(); bl.text = str(base); bl.add_theme_font_size_override("font_size", 12)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_grid.add_child(bl)
	
	var bonl: Label = Label.new(); bonl.text = "+%d" % bonus if bonus >= 0 else str(bonus)
	bonl.add_theme_font_size_override("font_size", 12)
	bonl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonl.modulate = GameConstants.Colors.FACTION_PLAYER if bonus > 0 else (GameConstants.Colors.FACTION_ENEMY if bonus < 0 else GameConstants.Colors.UI_GRAY)
	_stats_grid.add_child(bonl)
	
	var tl: RichTextLabel = RichTextLabel.new(); tl.bbcode_enabled = true; tl.fit_content = true; tl.autowrap_mode = TextServer.AUTOWRAP_OFF
	tl.text = "[center][color=#%s]%d[/color][/center]" % [stat_color.to_html(false), total]
	tl.add_theme_font_size_override("normal_font_size", 12)
	_stats_grid.add_child(tl)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("item")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	item_dropped.emit(data["item"], data.get("source_unit"), unit)

func set_highlight(active: bool) -> void:
	if active:
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = GameConstants.Colors.INV_CHAR_PANEL_BG
		sb.border_width_left = 2; sb.border_width_right = 2; sb.border_width_top = 2; sb.border_width_bottom = 2
		sb.border_color = GameConstants.Colors.UI_CYAN
		add_theme_stylebox_override("panel", sb)
	else:
		remove_theme_stylebox_override("panel")
