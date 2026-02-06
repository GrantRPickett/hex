class_name InputActions
extends Resource

const MOVEMENT_PREFIX := "move_"
const DIRECT_SELECTION_PREFIX := "select_unit_"
const PRIMARY_ACTION := "ui_select"
const SECONDARY_ACTION := "secondary_action"
const WAIT_ACTION := "wait_turn"
const CAMERA_ZOOM_IN := "camera_zoom_in"
const CAMERA_ZOOM_OUT := "camera_zoom_out"
const FREE_CAM_TOGGLE := "toggle_free_cam"
const SELECTION_CYCLE_NEXT := "cycle_next"
const SELECTION_CYCLE_PREV := "cycle_prev"
const TOGGLE_ENEMY_RANGE := "toggle_enemy_range"
const UI_NAV_TOGGLE := "toggle_ui_nav"
const CONFIRM_MOVE := "confirm_move"
const CANCEL_MOVE := "cancel_move"
const DIALOGIC_DEFAULT_ACTION := "dialogic_default_action"
const AUTO_BATTLE_TOGGLE := "toggle_auto_battle"

const MOVEMENT_ACTIONS := [
	"move_q",
	"move_w",
	"move_e",
	"move_a",
	"move_s",
	"move_d",
]

const MOVEMENT_DEFAULTS := [
	{"action": "move_q", "keys": [KEY_Q], "joy_buttons": [JOY_BUTTON_DPAD_LEFT]},
	{"action": "move_w", "keys": [KEY_W], "joy_buttons": [JOY_BUTTON_DPAD_UP]},
	{"action": "move_e", "keys": [KEY_E], "joy_buttons": [JOY_BUTTON_DPAD_RIGHT]},
	{"action": "move_a", "keys": [KEY_A], "joy_buttons": [JOY_AXIS_TRIGGER_LEFT]},
	{"action": "move_s", "keys": [KEY_S], "joy_buttons": [JOY_BUTTON_DPAD_DOWN]},
	{"action": "move_d", "keys": [KEY_D], "joy_buttons": [JOY_AXIS_TRIGGER_RIGHT]},
]

const INTERACTION_DEFAULTS := [
	{"action": PRIMARY_ACTION, "mouse_buttons": [MOUSE_BUTTON_LEFT], "joy_buttons": [JOY_BUTTON_A]},
	{"action": SECONDARY_ACTION, "mouse_buttons": [MOUSE_BUTTON_RIGHT], "keys": [KEY_BACKSPACE], "joy_buttons": [JOY_BUTTON_B]},
	{"action": WAIT_ACTION, "keys": [KEY_SPACE], "joy_buttons": [JOY_BUTTON_Y]},
	{"action": CONFIRM_MOVE, "keys": [KEY_ENTER], "joy_buttons": [JOY_BUTTON_A]}, # Added space as secondary confirm for convenience
	{"action": CANCEL_MOVE, "keys": [KEY_BACKSPACE], "joy_buttons": [JOY_BUTTON_B]},
]

const CAMERA_DEFAULTS := [
	{"action": "camera_rotate_left", "keys": [KEY_Z, KEY_DELETE], "joy_buttons": []},
	{"action": "camera_rotate_right", "keys": [KEY_X, KEY_PAGEDOWN], "joy_buttons": []},
	{"action": CAMERA_ZOOM_IN, "keys": [KEY_C, KEY_EQUAL], "joy_buttons": [JOY_BUTTON_X]},
	{"action": CAMERA_ZOOM_OUT, "keys": [KEY_V, KEY_MINUS], "joy_buttons": [JOY_BUTTON_B]},
	{"action": FREE_CAM_TOGGLE, "keys": [KEY_QUOTELEFT], "joy_buttons": [JOY_BUTTON_LEFT_STICK]},
]

const SELECTION_DEFAULTS := [
	{"action": DIRECT_SELECTION_PREFIX + "1", "keys": [KEY_1, KEY_KP_1], "joy_buttons": []},
	{"action": DIRECT_SELECTION_PREFIX + "2", "keys": [KEY_2, KEY_KP_2], "joy_buttons": []},
	{"action": SELECTION_CYCLE_NEXT, "keys": [KEY_TAB], "joy_buttons": [JOY_BUTTON_RIGHT_SHOULDER]},
	{"action": SELECTION_CYCLE_PREV, "keys": [KEY_BACKTAB], "joy_buttons": [JOY_BUTTON_LEFT_SHOULDER]},
]

const PAUSE_DEFAULTS := [
	{"action": "pause_game", "keys": [KEY_ESCAPE, KEY_P], "joy_buttons": [JOY_BUTTON_START]},
]

const VISUAL_DEFAULTS := [
	{"action": TOGGLE_ENEMY_RANGE, "keys": [KEY_R], "joy_buttons": [JOY_BUTTON_BACK]},
	{"action": UI_NAV_TOGGLE, "keys": [KEY_F1], "joy_buttons": [JOY_BUTTON_RIGHT_STICK]},
	{"action": AUTO_BATTLE_TOGGLE, "keys": [KEY_F5], "joy_buttons": []},
]
