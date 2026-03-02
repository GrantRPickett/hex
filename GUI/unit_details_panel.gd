class_name UnitDetailsPanel
extends CustomResizablePanel

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

@onready var _vbox: VBoxContainer = %VBoxContainer
@onready var _name_label: Label = %NameLabel
@onready var _stats_label: Label = %StatsLabel
@onready var _moves_label: Label = %MovesLabel
@onready var _stuck_label: Label = %StuckLabel

func _init() -> void:
	name = "UnitDetailsPanel"

var _pending_update = null

func _ready() -> void:
	if _pending_update:
		update_details(_pending_update.unit, _pending_update.terrain_map, _pending_update.unit_manager)
		_pending_update = null

var _last_unit_uid: int = -1
var _last_willpower: int = -1
var _last_moves: int = -1
var _last_can_act: bool = false
var _last_stuck: bool = false

func update_details(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager) -> void:
	if not is_node_ready():
		_pending_update = {"unit": unit, "terrain_map": terrain_map, "unit_manager": unit_manager}
		return
	if unit == null:
		if visible:
			visible = false
			_last_unit_uid = -1
		return

	var unit_uid = unit.get_instance_id()
	var current_willpower = unit.willpower
	var current_moves = unit.get_remaining_movement_points()
	var current_can_act = unit.has_action_available()
	var current_stuck = UnitActionManager.is_unit_stuck(unit, terrain_map, unit_manager) if terrain_map and unit_manager else false

	if visible and unit_uid == _last_unit_uid \
		and current_willpower == _last_willpower \
		and current_moves == _last_moves \
		and current_can_act == _last_can_act \
		and current_stuck == _last_stuck:
		return

	_last_unit_uid = unit_uid
	_last_willpower = current_willpower
	_last_moves = current_moves
	_last_can_act = current_can_act
	_last_stuck = current_stuck

	visible = true

	if _name_label:
		_name_label.text = unit.unit_name if not unit.unit_name.is_empty() else LocalizationStrings.get_text("hud.unit_name_fallback")

	if _stats_label:
		_stats_label.text = LocalizationStrings.get_text("hud.unit_stats").format({
			"faction": unit.get_faction_name(),
			"current": current_willpower,
			"max": unit.max_willpower,
		})

	if _moves_label:
		var max_moves = unit.get_max_movement_points()
		var action_text = LocalizationStrings.get_text("hud.generic_yes") if current_can_act else LocalizationStrings.get_text("hud.generic_no")
		_moves_label.text = LocalizationStrings.get_text("hud.movement_summary").format({
			"moves": current_moves,
			"max_moves": max_moves,
			"action": action_text,
		})

	if _stuck_label:
		var status_text = LocalizationStrings.get_text("hud.status_stuck") if current_stuck else LocalizationStrings.get_text("hud.status_ok")
		_stuck_label.text = status_text
		_stuck_label.modulate = Color.RED if current_stuck else Color.GREEN

	var attributes_label = _vbox.get_node_or_null("AttributesLabel")
	if not attributes_label:
		attributes_label = Label.new()
		attributes_label.name = "AttributesLabel"
		attributes_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_vbox.add_child(attributes_label)
	var attribute_lines: Array[String] = []
	var attrs = unit.get_attributes() if unit.has_method("get_attributes") else null
	if attrs:
		for attr_name in UnitAttributes.ATTRIBUTE_NAMES:
			var display_name = attr_name.capitalize()
			var value = attrs.get_attribute(attr_name)
			attribute_lines.append("%s: %d" % [display_name, value])
	if attribute_lines.is_empty():
		attributes_label.text = ""
		attributes_label.hide()
	else:
		attributes_label.text = "Attributes: " + ", ".join(attribute_lines)
		attributes_label.show()

	_update_inventory_display(unit)
	force_fit_content()

func _update_inventory_display(unit: Unit) -> void:
	var inventory_label = _vbox.get_node_or_null("InventoryLabel")
	if not inventory_label:
		inventory_label = Label.new()
		inventory_label.name = "InventoryLabel"
		inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_vbox.add_child(inventory_label)

	var items = []
	var inv = unit.get_inventory()
	if inv:
		for item in inv.get_items():
			items.append(item.item_name)

	if items.is_empty():
		inventory_label.text = ""
		inventory_label.hide()
	else:
		inventory_label.text = "Items: " + ", ".join(items)
		inventory_label.show()