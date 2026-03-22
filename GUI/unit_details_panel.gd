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

	if DisplaySettings:
		DisplaySettings.display_settings_changed.connect(_on_display_settings_changed)

	_update_layout()

func _on_locale_changed() -> void:
	if visible and _last_unit:
		# Reset tracking variables to force an update even if state is technically same
		_last_unit_uid = GameConstants.INVALID_INDEX
		update_details(_last_unit, _last_terrain_map, _last_unit_manager)

var _last_unit_uid: int = GameConstants.INVALID_INDEX
var _last_willpower: int = GameConstants.INVALID_INDEX
var _last_stress: int = GameConstants.INVALID_INDEX
var _last_moves: int = GameConstants.INVALID_INDEX
var _last_can_act: bool = false
var _last_stuck: bool = false
var _last_inventory_hash: int = 0
var _last_attribute_hash: int = 0

func update_details(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager) -> void:
	if not is_node_ready():
		_pending_update = {"unit": unit, "terrain_map": terrain_map, "unit_manager": unit_manager}
		return

	if unit == null:
		_handle_null_unit()
		return

	if _last_unit != unit:
		if is_instance_valid(_last_unit):
			if _last_unit.attribute_modifiers_changed.is_connected(_on_unit_attributes_changed):
				_last_unit.attribute_modifiers_changed.disconnect(_on_unit_attributes_changed)
			if _last_unit.components_ready.is_connected(_on_unit_attributes_changed):
				_last_unit.components_ready.disconnect(_on_unit_attributes_changed)

		_last_unit = unit
		if is_instance_valid(_last_unit):
			if not _last_unit.attribute_modifiers_changed.is_connected(_on_unit_attributes_changed):
				_last_unit.attribute_modifiers_changed.connect(_on_unit_attributes_changed)
			if not _last_unit.components_ready.is_connected(_on_unit_attributes_changed):
				_last_unit.components_ready.connect(_on_unit_attributes_changed)

	var current_state = _capture_unit_state(unit, terrain_map, unit_manager)

	if visible and not _has_state_changed(current_state):
		return

	_apply_unit_details(unit, terrain_map, unit_manager, current_state)

func _on_unit_attributes_changed() -> void:
	if visible and is_instance_valid(_last_unit):
		# Force refresh by clearing a tracked state
		_last_attribute_hash = -1
		update_details(_last_unit, _last_terrain_map, _last_unit_manager)

func _handle_null_unit() -> void:
	if is_instance_valid(_last_unit):
		if _last_unit.attribute_modifiers_changed.is_connected(_on_unit_attributes_changed):
			_last_unit.attribute_modifiers_changed.disconnect(_on_unit_attributes_changed)
		if _last_unit.components_ready.is_connected(_on_unit_attributes_changed):
			_last_unit.components_ready.disconnect(_on_unit_attributes_changed)

	if visible:
		visible = false
		_last_unit_uid = -1

func _capture_unit_state(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager) -> Dictionary:
	var inv_hash: int = 0
	if unit.inv:
		var inv := unit.inv.get_inventory()
		if inv:
			# Simple hash: count + equipped status sum + IDs
			inv_hash = inv.get_items().size()
			for item in inv.get_items():
				inv_hash += (1 if item.equipped else 0)
				inv_hash += item.get_instance_id()

	var attr_hash: int = 0
	for idx in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		attr_hash += unit.get_attribute(idx)
		attr_hash += unit.get_base_attribute_from_target(idx)


	return {
		"uid": unit.get_instance_id(),
		"willpower": unit.get_attribute(GameConstants.AttributeIndex.WILLPOWER),
		"stress": unit.stress,
		"moves": unit.movement.get_remaining_movement_points() if unit.movement else 0,
		"can_act": unit.res.has_action_available() if unit.res else false,
		"stuck": ActionAvailabilityService.new().is_unit_stuck(unit, terrain_map, unit_manager) if terrain_map and unit_manager else false,
		"inv_hash": inv_hash,
		"attr_hash": attr_hash
	}

func _has_state_changed(state: Dictionary) -> bool:
	return state.uid != _last_unit_uid \
		or state.willpower != _last_willpower \
		or state.stress != _last_stress \
		or state.moves != _last_moves \
		or state.can_act != _last_can_act \
		or state.stuck != _last_stuck \
		or state.inv_hash != _last_inventory_hash \
		or state.attr_hash != _last_attribute_hash

func _apply_unit_details(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager, state: Dictionary) -> void:
	_last_unit = unit
	_last_terrain_map = terrain_map
	_last_unit_manager = unit_manager

	_last_unit_uid = state.uid
	_last_willpower = state.willpower
	_last_stress = state.stress
	_last_moves = state.moves
	_last_can_act = state.can_act
	_last_stuck = state.stuck
	_last_inventory_hash = state.inv_hash
	_last_attribute_hash = state.attr_hash
	visible = true

	_update_basic_info(unit)
	_update_stats_display(unit, state.willpower)
	_update_stress_display(state.stress)
	_update_movement_display(unit, state.moves, state.can_act)
	_update_status_display(state.stuck)
	_update_attributes_display(unit)
	_update_inventory_display(unit)

	force_fit_content()

func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void:
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

	var font_size = 14 if is_portrait and viewport_size.x < 500 else 18
	var small_font_size = 12 if is_portrait and viewport_size.x < 500 else 14

	if _name_label:
		_name_label.add_theme_font_size_override("font_size", font_size + 4)
	if _stats_label:
		_stats_label.add_theme_font_size_override("font_size", font_size)
	if _moves_label:
		_moves_label.add_theme_font_size_override("font_size", font_size)

	var attr_label = _vbox.get_node_or_null("AttributesLabel")
	if attr_label:
		attr_label.add_theme_font_size_override("normal_font_size", small_font_size)

	var inv_label = _vbox.get_node_or_null("InventoryLabel")
	if inv_label:
		inv_label.add_theme_font_size_override("font_size", small_font_size)

	_vbox.add_theme_constant_override("separation", 2 if is_portrait else 5)


func _update_basic_info(unit: Unit) -> void:
	if _name_label:
		_name_label.text = unit.unit_name if not unit.unit_name.is_empty() else LocalizationStrings.get_text("hud.unit_name_fallback")

func _update_stats_display(unit: Unit, current_willpower: int) -> void:
	if _stats_label:
		var faction_name: String = GameConstants.get_faction_name(int(unit.faction))
		var base_text: String = tr("hud.unit_stats").format({
			"faction": faction_name,
			"current": current_willpower,
			"max": unit.max_willpower,
		})

		# Add stress to the same line to save vertical space
		_stats_label.text = base_text + " | Stress: %d" % unit.stress

		# Dynamic coloring based on health/stress
		if current_willpower < unit.max_willpower * 0.3:
			_stats_label.modulate = GameConstants.Colors.WILLPOWER_LOW
		elif unit.stress >= 6:
			_stats_label.modulate = GameConstants.Colors.WILLPOWER_MID
		else:
			_stats_label.modulate = GameConstants.Colors.WILLPOWER_NORMAL

func _update_stress_display(_current_stress: int) -> void:
	# No longer using a separate label
	pass

func _update_movement_display(unit: Unit, current_moves: int, current_can_act: bool) -> void:
	if _moves_label:
		var max_moves: int = unit.movement.get_max_movement_points() if unit.movement else 0
		var action_text: String = tr("hud.generic_yes") if current_can_act else tr("hud.generic_no")
		var summary: String = tr("hud.movement_summary").format({
			"moves": current_moves,
			"max_moves": max_moves,
			"action": action_text,
		})

		# Append stuck status here
		var terrain_map = _last_terrain_map
		var unit_manager = _last_unit_manager
		var is_stuck := ActionAvailabilityService.new().is_unit_stuck(unit, terrain_map, unit_manager) if terrain_map and unit_manager else false

		if is_stuck:
			summary += " [STUCK]"
			_moves_label.modulate = GameConstants.Colors.MOVES_DEPLETED
		else:
			_moves_label.modulate = GameConstants.Colors.MOVES_NORMAL

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

	# Use COMBAT_ATTRIBUTE_INDICES to avoid duplicating Willpower
	for idx in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var attr_name: String = GameConstants.get_attribute_name(idx)
		var display_name: String = tr("attr." + attr_name.to_lower())
		var total: int = unit.get_attribute(idx)
		var base = unit.get_base_attribute_from_target(idx)
		var bonus = total - base

		var stat_str: String = "%s: %d" % [display_name, total]
		if bonus > 0:
			stat_str += " [color=green](+%d)[/color]" % bonus
		elif bonus < 0:
			stat_str += " [color=red](%d)[/color]" % bonus

		attribute_lines.append(stat_str)

	if attribute_lines.is_empty():
		attributes_label.text = ""
		attributes_label.tooltip_text = ""
		attributes_label.hide()
	else:
		var raw_text: String = LocalizationStrings.get_text(LocalizationStrings.HUD_ATTRIBUTES).format({
			"attributes": ", ".join(attribute_lines)
		})
		attributes_label.text = GameConstants.colorize_attributes(raw_text)
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

	var items: Array = []
	if unit.inv:
		var inv := unit.inv.get_inventory()
		if inv:
			for item in inv.get_items():
				if item.has_method("get_item_name"):
					items.append(item.get_item_name())
				else:
					items.append(tr("hud.item_unknown"))

	if items.is_empty():
		inventory_label.text = ""
		inventory_label.hide()
	else:
		inventory_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_ITEMS).format({
			"items": ", ".join(items)
		})
		inventory_label.show()
