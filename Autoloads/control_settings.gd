extends Node

var _defaults: Dictionary = {}

@export var start_keycodes: PackedInt32Array = PackedInt32Array([KEY_ENTER, KEY_SPACE])
@export var quit_keycodes: PackedInt32Array = PackedInt32Array([KEY_ESCAPE])
@export var start_joypad_buttons: PackedInt32Array = PackedInt32Array([JOY_BUTTON_START, JOY_BUTTON_A])
@export var quit_joypad_buttons: PackedInt32Array = PackedInt32Array([JOY_BUTTON_BACK, JOY_BUTTON_B])
@export var allow_any_non_quit_key_to_start := true
@export var allow_any_joy_button_to_start := true
@export var move_actions: Array = [
    {"action": "move_q", "keys": [KEY_Q], "joy_buttons": []},
    {"action": "move_w", "keys": [KEY_W], "joy_buttons": []},
    {"action": "move_e", "keys": [KEY_E], "joy_buttons": []},
    {"action": "move_a", "keys": [KEY_A], "joy_buttons": []},
    {"action": "move_s", "keys": [KEY_S], "joy_buttons": []},
    {"action": "move_d", "keys": [KEY_D], "joy_buttons": []},
]

# Camera controls configuration (used by gameplay scene)
# Defaults:
# - Rotate: keyboard Z/X, controller left/right triggers
# - Zoom: keyboard C/V, controller plus/start and minus/back
@export var camera_actions: Array = [
    {"action": "camera_rotate_left", "keys": [KEY_Z], "joy_buttons": []},
    {"action": "camera_rotate_right", "keys": [KEY_X], "joy_buttons": []},
    {"action": "camera_zoom_in", "keys": [KEY_C], "joy_buttons": [JOY_BUTTON_START]},
    {"action": "camera_zoom_out", "keys": [KEY_V], "joy_buttons": [JOY_BUTTON_BACK]},
    {"action": "toggle_free_cam", "keys": [KEY_QUOTELEFT], "joy_buttons": [JOY_BUTTON_LEFT_STICK]},
]

# Selection actions configuration
# Defaults:
# - Keyboard 1 selects unit 1, 2 selects unit 2
# - Controller mappings left empty by default to avoid conflicts with movement
@export var selection_actions: Array = [
    {"action": "select_unit_1", "keys": [KEY_1], "joy_buttons": [JOY_BUTTON_LEFT_SHOULDER]},
    {"action": "select_unit_2", "keys": [KEY_2], "joy_buttons": [JOY_BUTTON_RIGHT_SHOULDER]},
    {"action": "select_next", "keys": [], "joy_buttons": []},
]

@export var require_all_units_to_goal := false

# Pause actions (gameplay)
@export var pause_actions: Array = [
    {"action": "pause_game", "keys": [KEY_ESCAPE], "joy_buttons": [JOY_BUTTON_START]},
]

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
        "pause_actions": pause_actions.duplicate(true),
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
    pause_actions = _defaults["pause_actions"].duplicate(true)
    require_all_units_to_goal = _defaults["require_all_units_to_goal"]
