class_name ActionsPanel
extends CustomResizablePanel

signal action_selected(action: Dictionary)
signal attribute_hovered(attribute_index: int) # -1 if exited

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")
const BUTTON_MIN_SIZE := Vector2(160, 30)
const HINT_TEXT_COLOR := Color(1, 1, 0.8)

@onready var actions_container: VBoxContainer = %ActionsContainer
@onready var hint_label: Label = %HintLabel

# State cache for Back button
var _cached_unit: Unit
var _cached_terrain_map
var _cached_unit_manager: UnitManager

func _ready() -> void:
	print_debug("ActionsPanel._ready() called - Panel is initializing")
	# ... (keep existing debugs if desired, skipping for brevity in replacement) ...

	min_width = 220
	min_height = 50
	super._ready()

	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	if hint_label:
		hint_label.text = LocalizationStrings.get_text("hud.actions_hint")
		hint_label.visible = false
		hint_label.modulate = Color(1, 1, 1, 0)
		hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_label.add_theme_color_override("font_color", HINT_TEXT_COLOR)
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hint_label.custom_minimum_size = Vector2(0, 18)

	queue_redraw()

func update_actions(unit: Unit, terrain_map, unit_manager: UnitManager) -> void:
	_cached_unit = unit
	_cached_terrain_map = terrain_map
	_cached_unit_manager = unit_manager

	_clear_actions()

	if not is_instance_valid(unit):
		_show_hint("No unit selected")
		return

	var unit_index = unit_manager.get_unit_index(unit)
	if not unit_manager.is_player_controlled(unit_index):
		_show_hint("Enemy unit selected")
		return

	var available_actions = UnitActionManager.get_available_actions(unit, terrain_map, unit_manager)
	if available_actions.is_empty():
		_show_hint("No actions available")
		return

	_show_actions_hint()

	for action in available_actions:
		var btn := Button.new()
		btn.text = action.label
		btn.custom_minimum_size = BUTTON_MIN_SIZE
		btn.disabled = not action.available
		if action.has("hint"):
			btn.tooltip_text = str(action.hint)
		btn.pressed.connect(func(): action_selected.emit(action))
		actions_container.add_child(btn)

	force_fit_content()

func show_attack_menu(attacker: Unit, target: Unit) -> void:
	print_debug("ActionsPanel: show_attack_menu called, attacker=", attacker.unit_name if attacker else "null", " target=", target.unit_name if target else "null")
	_clear_actions()
	print_debug("ActionsPanel: Actions cleared, setting hint")
	hint_label.text = "Select Attribute"
	hint_label.visible = true
	hint_label.modulate = Color(1, 1, 1, 1) # Ensure visible

	if not attacker:
		print_debug("ActionsPanel: No attacker, returning early")
		return

	var attrs = attacker.get_attributes()
	if not attrs:
		print_debug("ActionsPanel: No attributes, returning early")
		return

	print_debug("ActionsPanel: Creating ", UnitAttributes.ATTRIBUTE_NAMES.size(), " attribute buttons")

	for i in range(UnitAttributes.ATTRIBUTE_NAMES.size()):
		var attr_name = UnitAttributes.ATTRIBUTE_NAMES[i]
		var val = attrs.get_attribute(attr_name)
		var btn := Button.new()
		btn.text = "%s (%d)" % [attr_name.capitalize(), val]
		btn.custom_minimum_size = BUTTON_MIN_SIZE

		# Action: Attack with this attribute
		btn.pressed.connect(func():
			action_selected.emit({
				"type": "attack",
				"target": target,
				"attribute_index": i
			})
		)

		# Hover: Update preview
		btn.mouse_entered.connect(func(): attribute_hovered.emit(i))
		# btn.focus_entered.connect(...) # Support controller focus logic here if needed

		actions_container.add_child(btn)

	# Back Button
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = BUTTON_MIN_SIZE
	back_btn.pressed.connect(_on_back_pressed)
	# Clear preview on back hover?
	back_btn.mouse_entered.connect(func(): attribute_hovered.emit(-1))
	actions_container.add_child(back_btn)

	force_fit_content()

func _on_back_pressed() -> void:
	if is_instance_valid(_cached_unit):
		update_actions(_cached_unit, _cached_terrain_map, _cached_unit_manager)

func _clear_actions() -> void:
	if not is_instance_valid(actions_container): return
	for child in actions_container.get_children():
		if child != hint_label:
			child.queue_free()

func _show_hint(msg: String) -> void:
	if is_instance_valid(hint_label):
		hint_label.visible = true
		hint_label.text = msg

func _show_actions_hint() -> void:
	if is_instance_valid(hint_label):
		hint_label.visible = true
		hint_label.modulate = Color(1, 1, 1, 1)
