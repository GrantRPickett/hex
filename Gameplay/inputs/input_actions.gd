class_name InputActions
extends Resource

const MOVEMENT_PREFIX := GameConstants.Inputs.MOVEMENT_PREFIX
const DIRECT_SELECTION_PREFIX := GameConstants.Inputs.DIRECT_SELECTION_PREFIX
const PRIMARY_ACTION := GameConstants.Inputs.PRIMARY_ACTION
const SECONDARY_ACTION := GameConstants.Inputs.SECONDARY_ACTION
const WAIT_ACTION := GameConstants.Inputs.WAIT_ACTION
const CAMERA_ZOOM_IN := GameConstants.Inputs.CAMERA_ZOOM_IN
const CAMERA_ZOOM_OUT := GameConstants.Inputs.CAMERA_ZOOM_OUT
const FREE_CAM_TOGGLE := GameConstants.Inputs.FREE_CAM_TOGGLE
const SELECTION_CYCLE_NEXT := GameConstants.Inputs.SELECTION_CYCLE_NEXT
const SELECTION_CYCLE_PREV := GameConstants.Inputs.SELECTION_CYCLE_PREV
const TOGGLE_ENEMY_RANGE := GameConstants.Inputs.TOGGLE_ENEMY_RANGE
const UI_NAV_TOGGLE := GameConstants.Inputs.UI_NAV_TOGGLE
const CONFIRM_MOVE := GameConstants.Inputs.CONFIRM_MOVE
const CANCEL_MOVE := GameConstants.Inputs.CANCEL_MOVE
const DIALOGIC_DEFAULT_ACTION := GameConstants.Inputs.DIALOGIC_DEFAULT_ACTION
const AUTO_BATTLE_TOGGLE := GameConstants.Inputs.AUTO_BATTLE_TOGGLE
const CAMERA_PAN_UP := GameConstants.Inputs.CAMERA_PAN_UP
const CAMERA_PAN_DOWN := GameConstants.Inputs.CAMERA_PAN_DOWN
const CAMERA_PAN_LEFT := GameConstants.Inputs.CAMERA_PAN_LEFT
const CAMERA_PAN_RIGHT := GameConstants.Inputs.CAMERA_PAN_RIGHT
const DIALOGUE_SKIP_ACTION := GameConstants.Inputs.DIALOGUE_SKIP_ACTION
const DIALOGUE_ADVANCE_ACTION := GameConstants.Inputs.DIALOGUE_ADVANCE_ACTION

const MOVEMENT_ACTIONS: Array[String] = [
	"move_q",
	"move_w",
	"move_e",
	"move_a",
	"move_s",
	"move_d",
]

const MOVEMENT_DEFAULTS: Array[Dictionary] = [
	{"action": "move_q", "keys": [KEY_Q], "joy_buttons": [JOY_BUTTON_DPAD_LEFT]},
	{"action": "move_w", "keys": [KEY_W], "joy_buttons": [JOY_BUTTON_DPAD_UP]},
	{"action": "move_e", "keys": [KEY_E], "joy_buttons": [JOY_BUTTON_DPAD_RIGHT]},
	{"action": "move_a", "keys": [KEY_A], "joy_buttons": [JOY_AXIS_TRIGGER_LEFT]},
	{"action": "move_s", "keys": [KEY_S], "joy_buttons": [JOY_BUTTON_DPAD_DOWN]},
	{"action": "move_d", "keys": [KEY_D], "joy_buttons": [JOY_AXIS_TRIGGER_RIGHT]},
]

const INTERACTION_DEFAULTS: Array[Dictionary] = [
	{"action": PRIMARY_ACTION, "mouse_buttons": [MOUSE_BUTTON_LEFT], "joy_buttons": [JOY_BUTTON_A]},
	{"action": SECONDARY_ACTION, "mouse_buttons": [MOUSE_BUTTON_RIGHT], "keys": [KEY_BACKSPACE], "joy_buttons": [JOY_BUTTON_B]},
	{"action": WAIT_ACTION, "keys": [KEY_SPACE], "joy_buttons": [JOY_BUTTON_Y]},
	{"action": CONFIRM_MOVE, "keys": [KEY_ENTER], "joy_buttons": [JOY_BUTTON_A]},
	{"action": CANCEL_MOVE, "keys": [KEY_BACKSPACE], "joy_buttons": [JOY_BUTTON_B]},
]



const CAMERA_DEFAULTS: Array[Dictionary] = [
	{"action": GameConstants.Inputs.CAMERA_ROTATE_LEFT, "keys": [KEY_Z, KEY_DELETE], "joy_buttons": [JOY_BUTTON_LEFT_SHOULDER]},
	{"action": GameConstants.Inputs.CAMERA_ROTATE_RIGHT, "keys": [KEY_X, KEY_PAGEDOWN], "joy_buttons": [JOY_BUTTON_RIGHT_SHOULDER]},
	{"action": CAMERA_ZOOM_IN, "keys": [KEY_C, KEY_EQUAL], "joy_buttons": [JOY_BUTTON_DPAD_UP]},
	{"action": CAMERA_ZOOM_OUT, "keys": [KEY_V, KEY_MINUS], "joy_buttons": [JOY_BUTTON_DPAD_DOWN]},
	{"action": FREE_CAM_TOGGLE, "keys": [KEY_QUOTELEFT], "joy_buttons": [JOY_BUTTON_LEFT_STICK]},
	{"action": CAMERA_PAN_UP, "keys": [KEY_UP], "joy_buttons": []}, # Panning handled via axis in InputHandler
	{"action": CAMERA_PAN_DOWN, "keys": [KEY_DOWN], "joy_buttons": []},
	{"action": CAMERA_PAN_LEFT, "keys": [KEY_LEFT], "joy_buttons": []},
	{"action": CAMERA_PAN_RIGHT, "keys": [KEY_RIGHT], "joy_buttons": []},
]

const SELECTION_DEFAULTS: Array[Dictionary] = [
	{"action": DIRECT_SELECTION_PREFIX + "1", "keys": [KEY_1, KEY_KP_1], "joy_buttons": []},
	{"action": DIRECT_SELECTION_PREFIX + "2", "keys": [KEY_2, KEY_KP_2], "joy_buttons": []},
	{"action": SELECTION_CYCLE_NEXT, "keys": [KEY_TAB], "joy_buttons": [JOY_BUTTON_RIGHT_SHOULDER]},
	{"action": SELECTION_CYCLE_PREV, "keys": [KEY_BACKTAB], "joy_buttons": [JOY_BUTTON_LEFT_SHOULDER]},
]

const PAUSE_DEFAULTS: Array[Dictionary] = [
	{"action": GameConstants.Inputs.PAUSE_GAME, "keys": [KEY_ESCAPE, KEY_P], "joy_buttons": [JOY_BUTTON_START]},
	{"action": DIALOGUE_SKIP_ACTION, "keys": [KEY_ESCAPE], "joy_buttons": [JOY_BUTTON_B]}, # New default for dialogue skip
]

const VISUAL_DEFAULTS: Array[Dictionary] = [
	{"action": TOGGLE_ENEMY_RANGE, "keys": [KEY_R], "joy_buttons": [JOY_BUTTON_BACK]},
	{"action": UI_NAV_TOGGLE, "keys": [KEY_F1], "joy_buttons": [JOY_BUTTON_RIGHT_STICK]},
	{"action": AUTO_BATTLE_TOGGLE, "keys": [KEY_F5], "joy_buttons": []},
]
