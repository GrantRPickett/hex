extends PanelContainer

signal action_triggered(type: String, item: InventoryItem, unit: Unit)

@onready var _name_label: RichTextLabel = %ItemName
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
	_minus_btn.pressed.connect(func(): action_triggered.emit("minus", item, owner_unit))
	_hand_btn.pressed.connect(func(): action_triggered.emit("hand", item, owner_unit))

func _update_ui() -> void:
	if not item:
		print_debug("[ItemSlot] NO ITEM assigned")
		return
	
	var base_name = item.item_name if not item.item_name.is_empty() else "Unnamed Item"
	var mods_text = ""
	
	if not item.attribute_modifiers.is_empty():
		var mods = []
		for attr in item.attribute_modifiers:
			var val = item.attribute_modifiers[attr]
			var sign_str = "+" if val > 0 else ""
			var attr_name = attr.capitalize()
			var color = GameConstants.Attributes.ATTRIBUTE_COLORS.get(attr, Color.WHITE)
			var hex = color.to_html(false)
			mods.append("%s%d [color=#%s]%s[/color]" % [sign_str, val, hex, attr_name])
		mods_text = " (%s)" % ", ".join(mods)
	
	_name_label.text = base_name + mods_text
	print_debug("[ItemSlot] Updating UI for: ", _name_label.text)
	
	# Show minus for character items, hand for stash items
	_minus_btn.visible = owner_unit != null
	_hand_btn.visible = owner_unit == null

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not item: return null
	var preview = Label.new()
	preview.text = item.item_name
	set_drag_preview(preview)
	return {"item": item, "source_unit": owner_unit}

func set_highlight(active: bool) -> void:
	if active:
		var sb = StyleBoxFlat.new()
		sb.bg_color = GameConstants.Colors.INV_SLOT_BG
		sb.border_width_left = 2; sb.border_width_right = 2; sb.border_width_top = 2; sb.border_width_bottom = 2
		sb.border_color = Color.WHITE
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

