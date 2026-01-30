extends Node

const InputActions := preload("res://Resources/input_actions.gd")

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

@export var require_all_units_to_goal := false

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
		"require_all_units_to_goal": require_all_units_to_goal,
	}

func reset_inputs_to_defaults() -> void:
	start_keycodes = _defaults["start_keycodes"].duplicate()
	quit_keycodes = _defaults["quit_keycodes"].duplicate()
	start_joypad_buttons = _defaults["start_joypad_buttons"].duplicate()
	quit_joypad_buttons = _defaults["quit_joypad_buttons"].duplicate()
	allow_any_non_quit_key_to_start = _defaults["allow_any_non_quit_key_to_start"]
	allow_any_joy_button_to_start = _defaults["allow_any_joy_button_to_start"]
	move_actions = _defaults["move_actions"].duplicate(true)
	camera_actions = _defaults["camera_actions"].duplicate(true)
	selection_actions = _defaults["selection_actions"].duplicate(true)
	interaction_actions = _defaults["interaction_actions"].duplicate(true)
	pause_actions = _defaults["pause_actions"].duplicate(true)
	visual_actions = _defaults["visual_actions"].duplicate(true)
	require_all_units_to_goal = _defaults["require_all_units_to_goal"]
