#class_name ControlSettings
extends Node

var _defaults: Dictionary = {}

@export var start_keycodes: PackedInt32Array = PackedInt32Array([KEY_ENTER, KEY_SPACE])
@export var quit_keycodes: PackedInt32Array = PackedInt32Array([KEY_ESCAPE])
@export var start_joypad_buttons: PackedInt32Array = PackedInt32Array([JOY_BUTTON_START, JOY_BUTTON_A])
@export var quit_joypad_buttons: PackedInt32Array = PackedInt32Array([JOY_BUTTON_BACK, JOY_BUTTON_B])
@export var allow_any_non_quit_key_to_start := true
@export var allow_any_joy_button_to_start := true
@export var move_actions: Array = InputActions.MOVEMENT_DEFAULTS.duplicate(true)

# Camera controls configuration (used by gameplay scene)
@export var camera_actions: Array = InputActions.CAMERA_DEFAULTS.duplicate(true)

# Selection actions configuration
@export var selection_actions: Array = InputActions.SELECTION_DEFAULTS.duplicate(true)

@export var interaction_actions: Array = InputActions.INTERACTION_DEFAULTS.duplicate(true)

# Pause actions (gameplay)
@export var pause_actions: Array = InputActions.PAUSE_DEFAULTS.duplicate(true)

# Visual toggles and overlays
@export var visual_actions: Array = InputActions.VISUAL_DEFAULTS.duplicate(true)

func _ready() -> void:
	# Capture deep copies of default-config values for reset
	_defaults = {
		"start_keycodes": start_keycodes.duplicate(),
		"quit_keycodes": quit_keycodes.duplicate(),
		"start_joypad_buttons": start_joypad_buttons.duplicate(),
		"quit_joypad_buttons": quit_joypad_buttons.duplicate(),
		"allow_any_non_quit_key_to_start": allow_any_non_quit_key_to_start,
		"allow_any_joy_button_to_start": allow_any_joy_button_to_start,
		"move_actions": move_actions.duplicate(true),
		"camera_actions": camera_actions.duplicate(true),
		"selection_actions": selection_actions.duplicate(true),
		"interaction_actions": interaction_actions.duplicate(true),
		"pause_actions": pause_actions.duplicate(true),
		"visual_actions": visual_actions.duplicate(true),
	}

	_initialize_input_map()

func _initialize_input_map() -> void:
	var binding_service := InputBindingService.new()
	var input_mapper = get_tree().root.get_node_or_null("InputMapper")
	if not input_mapper and has_node("/root/InputMapper"):
		input_mapper = get_node("/root/InputMapper")

	if input_mapper:
		binding_service.apply_bindings(self, input_mapper as Node)
	else:
		# Fallback if InputMapper is not yet ready or available
		binding_service.apply_bindings(null, null)

func reset_inputs_to_defaults() -> void:
	var sk: Variant = _defaults.get("start_keycodes")
	if sk is PackedInt32Array:
		var sk_typed: PackedInt32Array = sk
		start_keycodes = sk_typed.duplicate()
		
	var qk: Variant = _defaults.get("quit_keycodes")
	if qk is PackedInt32Array:
		var qk_typed: PackedInt32Array = qk
		quit_keycodes = qk_typed.duplicate()
		
	var sjb: Variant = _defaults.get("start_joypad_buttons")
	if sjb is PackedInt32Array:
		var sjb_typed: PackedInt32Array = sjb
		start_joypad_buttons = sjb_typed.duplicate()
		
	var qjb: Variant = _defaults.get("quit_joypad_buttons")
	if qjb is PackedInt32Array:
		var qjb_typed: PackedInt32Array = qjb
		quit_joypad_buttons = qjb_typed.duplicate()
		
	var allow_key: Variant = _defaults.get("allow_any_non_quit_key_to_start", true)
	if allow_key is bool:
		allow_any_non_quit_key_to_start = allow_key
	
	var allow_joy: Variant = _defaults.get("allow_any_joy_button_to_start", true)
	if allow_joy is bool:
		allow_any_joy_button_to_start = allow_joy
	
	var m_actions: Variant = _defaults.get("move_actions")
	if m_actions is Array:
		var m_array: Array = m_actions
		move_actions = m_array.duplicate(true)
		
	var c_actions: Variant = _defaults.get("camera_actions")
	if c_actions is Array:
		var c_array: Array = c_actions
		camera_actions = c_array.duplicate(true)
	
	var sel_actions: Variant = _defaults.get("selection_actions", [])
	if sel_actions is Array:
		var sel_array: Array = sel_actions
		selection_actions = sel_array.duplicate(true)
		
	var int_actions: Variant = _defaults.get("interaction_actions", [])
	if int_actions is Array:
		var int_array: Array = int_actions
		interaction_actions = int_array.duplicate(true)
		
	var p_actions: Variant = _defaults.get("pause_actions", [])
	if p_actions is Array:
		var p_array: Array = p_actions
		pause_actions = p_array.duplicate(true)
		
	var v_actions: Variant = _defaults.get("visual_actions", [])
	if v_actions is Array:
		var v_array: Array = v_actions
		visual_actions = v_array.duplicate(true)
