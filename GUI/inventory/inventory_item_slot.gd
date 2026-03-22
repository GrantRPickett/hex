extends PanelContainer

signal action_triggered(type: String, item: InventoryItem, unit: Unit)

@onready var _name_label: RichTextLabel = %ItemName
@onready var _equip_btn: Button = %EquipButton
@onready var _minus_btn: Button = %MinusButton
@onready var _hand_btn: Button = %HandButton

var item: InventoryItem
var owner_unit: Unit

func setup(p_item: InventoryItem, p_unit: Unit) -> void:
	item = p_item
	owner_unit = p_unit
	custom_minimum_size = Vector2(0, 30)
	
	if is_node_ready():
		_update_ui()

func _ready() -> void:
	_update_ui()
	_equip_btn.pressed.connect(func(): action_triggered.emit(GameConstants.Inventory.ACTION_EQUIP, item, owner_unit))
	_minus_btn.pressed.connect(func(): action_triggered.emit(GameConstants.Inventory.ACTION_MINUS, item, owner_unit))
	_hand_btn.pressed.connect(func(): action_triggered.emit(GameConstants.Inventory.ACTION_HAND, item, owner_unit))

func _update_ui() -> void:
	if not item:
		return
	
	var base_name = item.get_item_name()
	var mods_text: String = ""
	var item_modifiers := item.get_modifiers()
	
	if not item_modifiers.is_empty():
		var mods: Array = []
		for attr in item_modifiers:
			var val = item_modifiers[attr]
			var sign_str: String = "+" if val > 0 else ""
			var idx = GameConstants.get_attribute_index(attr)
			var attr_name: String = tr("attr." + GameConstants.get_attribute_name(idx).to_lower())
			var color:Color = GameConstants.get_attribute_color(idx)
			var hex = color.to_html(false)
			mods.append("%s%d [color=#%s]%s[/color]" % [sign_str, val, hex, attr_name])
		mods_text = " (%s)" % ", ".join(mods)
	
	_name_label.text = base_name + mods_text
	
	# Equip Button setup
	if owner_unit != null:
		_equip_btn.visible = not item.is_quest_item()
		if item.equipped:
			_equip_btn.modulate = GameConstants.Colors.INV_ITEM_EQUIPPED
			_equip_btn.tooltip_text = tr("inv.tooltip.unequip")
		else:
			_equip_btn.modulate = GameConstants.Colors.INV_ITEM_UNEQUIPPED
			_equip_btn.tooltip_text = tr("inv.tooltip.equip")
	else:
		_equip_btn.visible = false
	
	# Show minus for character items, hand for stash items
	_minus_btn.visible = owner_unit != null
	var unit_name = owner_unit.unit_name if owner_unit else tr("inv.generic_unit")
	_minus_btn.tooltip_text = tr("inv.tooltip.move_to_stash").format({"unit": unit_name})
	
	_hand_btn.visible = owner_unit == null
	_hand_btn.tooltip_text = tr("inv.tooltip.pick_up")

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not item: return null
	var preview: Label = Label.new()
	preview.text = item.get_item_name()
	set_drag_preview(preview)
	return {"item": item, "source_unit": owner_unit}

func set_highlight(active: bool) -> void:
	if active:
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = GameConstants.Colors.INV_SLOT_BG
		sb.border_width_left = 2; sb.border_width_right = 2; sb.border_width_top = 2; sb.border_width_bottom = 2
		sb.border_color = GameConstants.Colors.UI_WHITE
		add_theme_stylebox_override("panel", sb)
	else:
		remove_theme_stylebox_override("panel")

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary and data.has("item"):
		return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Find the inventory menu to handle the swap
	var p = get_parent()
	while p:
		if p.has_method("handle_swap"):
			p.handle_swap(data["item"], data.get("source_unit"), item, owner_unit)
			return
		p = p.get_parent()
