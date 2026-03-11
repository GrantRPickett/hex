class_name UnitDetailsPanel
extends CustomResizablePanel

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)

@onready var _vbox: VBoxContainer = %VBoxContainer
@onready var _name_label: Label = %NameLabel
@onready var _stats_label: Label = %StatsLabel
@onready var _moves_label: Label = %MovesLabel

func _init() -> void:
	name = "UnitDetailsPanel"

var _pending_update = null

var _last_unit: Unit = null
var _last_terrain_map: TerrainMap = null
var _last_unit_manager: UnitManager = null

func _ready() -> void:
	hide()
	LocaleService.locale_changed.connect(_on_locale_changed)
	if _pending_update:
		update_details(_pending_update.unit, _pending_update.terrain_map, _pending_update.unit_manager)
		_pending_update = null

func _on_locale_changed() -> void:
	if visible and _last_unit:
		# Reset tracking variables to force an update even if state is technically same
		_last_unit_uid = -1
		update_details(_last_unit, _last_terrain_map, _last_unit_manager)

var _last_unit_uid: int = -1
var _last_willpower: int = -1
var _last_stress: int = -1
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

	_last_unit = unit
	_last_terrain_map = terrain_map
	_last_unit_manager = unit_manager

	var unit_uid = unit.get_instance_id()
	var current_willpower = unit.willpower
	var current_stress = unit.stress
	var current_moves = unit.movement.get_remaining_movement_points() if unit.movement else 0
	var current_can_act = unit.res.has_action_available() if unit.res else false
	var current_stuck = ActionAvailabilityService.new().is_unit_stuck(unit, terrain_map, unit_manager) if terrain_map and unit_manager else false

	if visible and unit_uid == _last_unit_uid \
		and current_willpower == _last_willpower \
		and current_stress == _last_stress \
		and current_moves == _last_moves \
		and current_can_act == _last_can_act \
		and current_stuck == _last_stuck:
		return

	_last_unit_uid = unit_uid
	_last_willpower = current_willpower
	_last_stress = current_stress
	_last_moves = current_moves
	_last_can_act = current_can_act
	_last_stuck = current_stuck

	visible = true

	_update_basic_info(unit)
	_update_stats_display(unit, current_willpower)
	_update_stress_display(current_stress)
	_update_movement_display(unit, current_moves, current_can_act)
	_update_status_display(current_stuck)
	_update_attributes_display(unit)
	_update_inventory_display(unit)
	
	force_fit_content()

func _update_basic_info(unit: Unit) -> void:
	if _name_label:
		_name_label.text = unit.unit_name if not unit.unit_name.is_empty() else LocalizationStrings.get_text("hud.unit_name_fallback")

func _update_stats_display(unit: Unit, current_willpower: int) -> void:
	if _stats_label:
		var faction_name = UnitPresenter.get_faction_name(unit)
		var base_text = tr("hud.unit_stats").format({
			"faction": faction_name,
			"current": current_willpower,
			"max": unit.max_willpower,
		})
		
		# Add stress to the same line to save vertical space
		_stats_label.text = base_text + " | Stress: %d" % unit.stress
		
		# Dynamic coloring based on health/stress
		if current_willpower < unit.max_willpower * 0.3:
			_stats_label.modulate = Color.ORANGE_RED
		elif unit.stress >= 6:
			_stats_label.modulate = Color.YELLOW
		else:
			_stats_label.modulate = Color.WHITE

func _update_stress_display(_current_stress: int) -> void:
	# No longer using a separate label
	pass

func _update_movement_display(unit: Unit, current_moves: int, current_can_act: bool) -> void:
	if _moves_label:
		var max_moves = unit.movement.get_max_movement_points() if unit.movement else 0
		var action_text = tr("hud.generic_yes") if current_can_act else tr("hud.generic_no")
		var summary = tr("hud.movement_summary").format({
			"moves": current_moves,
			"max_moves": max_moves,
			"action": action_text,
		})
		
		# Append stuck status here
		var terrain_map = _last_terrain_map
		var unit_manager = _last_unit_manager
		var is_stuck = ActionAvailabilityService.new().is_unit_stuck(unit, terrain_map, unit_manager) if terrain_map and unit_manager else false
		
		if is_stuck:
			summary += " [STUCK]"
			_moves_label.modulate = Color.RED
		else:
			_moves_label.modulate = Color.WHITE
			
		_moves_label.text = summary

func _update_status_display(_current_stuck: bool) -> void:
	# Consolidated into movement display
	pass

func _update_attributes_display(unit: Unit) -> void:
	var attributes_label = _vbox.get_node_or_null("AttributesLabel")
	if not attributes_label:
		attributes_label = RichTextLabel.new()
		attributes_label.name = "AttributesLabel"
		attributes_label.bbcode_enabled = true
		attributes_label.fit_content = true
		attributes_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_vbox.add_child(attributes_label)
	
	var attribute_lines: Array[String] = []
	var attrs = unit.inv.get_attributes() if unit.inv else null
	if attrs:
		# Use COMBAT_ATTRIBUTES to avoid duplicating Willpower
		for attr_name in GameConstants.Attributes.COMBAT_ATTRIBUTES:
			var display_name = tr("attr." + attr_name.to_lower())
			var value = attrs.get_attribute(attr_name)
			attribute_lines.append("%s: %d" % [display_name, value])
	
	if attribute_lines.is_empty():
		attributes_label.text = ""
		attributes_label.tooltip_text = ""
		attributes_label.hide()
	else:
		var raw_text = LocalizationStrings.get_text(LocalizationStrings.HUD_ATTRIBUTES).format({
			"attributes": ", ".join(attribute_lines)
		})
		attributes_label.text = GameConstants.Attributes.colorize_attributes(raw_text)
		# Flavor tooltips for stats
		attributes_label.tooltip_text = """Grit: Physical endurance and resilience
Focus: Careful restraint and precision
Flow: Agility and adaptability
Shade: Perception and insight
Gusto: Assertive push and momentum
Shine: Inspiration and morale"""
		attributes_label.show()

func _update_inventory_display(unit: Unit) -> void:
	var inventory_label = _vbox.get_node_or_null("InventoryLabel")
	if not inventory_label:
		inventory_label = Label.new()
		inventory_label.name = "InventoryLabel"
		inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_vbox.add_child(inventory_label)

	var items = []
	if unit.inv:
		var inv = unit.inv.get_inventory()
		if inv:
			for item in inv.get_items():
				items.append(item.item_name)

	if items.is_empty():
		inventory_label.text = ""
		inventory_label.hide()
	else:
		inventory_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_ITEMS).format({
			"items": ", ".join(items)
		})
		inventory_label.show()
