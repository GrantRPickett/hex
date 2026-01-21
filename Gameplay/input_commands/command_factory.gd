class_name CommandFactory
extends RefCounted

const MoveActionCommand := preload("res://Gameplay/input_commands/move_action_command.gd")
const JoyMoveCommand := preload("res://Gameplay/input_commands/joy_move_command.gd")
const SelectionCycleCommand := preload("res://Gameplay/input_commands/selection_cycle_command.gd")
const SelectIndexCommand := preload("res://Gameplay/input_commands/select_index_command.gd")
const PrimaryActionCommand := preload("res://Gameplay/input_commands/primary_action_command.gd")
const ToggleFreeCamCommand := preload("res://Gameplay/input_commands/toggle_free_cam_command.gd")
const ZoomCameraCommand := preload("res://Gameplay/input_commands/zoom_camera_command.gd")
const WaitCommand := preload("res://Gameplay/input_commands/wait_command.gd")
const AttackUnitCommand := preload("res://Gameplay/input_commands/attack_unit_command.gd")
const AidAllyCommand := preload("res://Gameplay/input_commands/aid_ally_command.gd")
const WorkOnGoalCommand := preload("res://Gameplay/input_commands/work_on_goal_command.gd")
const LootCommand := preload("res://Gameplay/input_commands/loot_command.gd")
const ConfirmMoveCommand := preload("res://Gameplay/input_commands/confirm_move_command.gd")
const CancelMoveCommand := preload("res://Gameplay/input_commands/cancel_move_command.gd")
const InteractCommand := preload("res://Gameplay/input_commands/interact_command.gd")
const UndoCommand := preload("res://Gameplay/input_commands/undo_command.gd") as GDScript
## Factory for creating and registering commands with consistent initialization

## Creates the default command set
static func create_default_command_set() -> Dictionary:
	return {
		"move_action": MoveActionCommand.new(),
		"joy_move": JoyMoveCommand.new(),
		"selection_cycle": SelectionCycleCommand.new(),
		"select_index": SelectIndexCommand.new(),
		"primary_action": PrimaryActionCommand.new(),
		"toggle_free_cam": ToggleFreeCamCommand.new(),
		"zoom_camera": ZoomCameraCommand.new(),
		"wait": WaitCommand.new(),
		"attack_unit": AttackUnitCommand.new(),
		"aid_ally": AidAllyCommand.new(),
		"work_on_goal": WorkOnGoalCommand.new(),
		"loot": LootCommand.new(),
		"confirm_move": ConfirmMoveCommand.new(),
		"cancel_move": CancelMoveCommand.new(),
		"interact": InteractCommand.new(),
		"undo": UndoCommand.new(),
	}

## Creates a command by class name
static func create_command_by_name(cmd_name: String) -> GameCommand:
	match cmd_name:
		"MoveActionCommand": return MoveActionCommand.new()
		"JoyMoveCommand": return JoyMoveCommand.new()
		"SelectionCycleCommand": return SelectionCycleCommand.new()
		"SelectIndexCommand": return SelectIndexCommand.new()
		"PrimaryActionCommand": return PrimaryActionCommand.new()
		"ToggleFreeCamCommand": return ToggleFreeCamCommand.new()
		"ZoomCameraCommand": return ZoomCameraCommand.new()
		"WaitCommand": return WaitCommand.new()
		"AttackUnitCommand": return AttackUnitCommand.new()
		"AidAllyCommand": return AidAllyCommand.new()
		"WorkOnGoalCommand": return WorkOnGoalCommand.new()
		"LootCommand": return LootCommand.new()
		"ConfirmMoveCommand": return ConfirmMoveCommand.new()
		"CancelMoveCommand": return CancelMoveCommand.new()
		"InteractCommand": return InteractCommand.new()
		"UndoCommand": return UndoCommand.new()
		_: return null

## Gets command metadata (name, required fields, description)
static func get_command_metadata() -> Dictionary:
	return {
		"move_action": {
			"description": "Request movement in a cardinal direction",
			"required_context": ["unit_manager", "hex_navigator", "camera_controller", "move_controller", "grid"],
			"payload_type": "String",
			"payload_description": "Direction action (e.g., 'north', 'southeast')"
		},
		"joy_move": {
			"description": "Request movement from joystick axis",
			"required_context": ["unit_manager", "hex_navigator", "camera_controller", "move_controller", "grid"],
			"payload_type": "Dictionary",
			"payload_description": "Dictionary with 'axis' key containing Vector2"
		},
		"selection_cycle": {
			"description": "Cycle through selectable units",
			"required_context": ["unit_manager", "turn_controller"],
			"payload_type": "int",
			"payload_description": "Direction: 1 for next, -1 for previous"
		},
		"select_index": {
			"description": "Select a specific unit by index",
			"required_context": ["unit_manager", "turn_controller"],
			"payload_type": "int",
			"payload_description": "Unit index to select"
		},
		"primary_action": {
			"description": "Primary action at screen coordinates (click or tap)",
			"required_context": ["grid", "unit_manager", "move_controller", "turn_controller"],
			"payload_type": "Vector2",
			"payload_description": "Screen position"
		},
		"toggle_free_cam": {
			"description": "Toggle free camera mode",
			"required_context": ["camera_controller"],
			"payload_type": "null",
			"payload_description": "No payload needed"
		},
		"zoom_camera": {
			"description": "Zoom camera in or out",
			"required_context": ["camera_controller"],
			"payload_type": "int",
			"payload_description": "Zoom direction: 1 for in, -1 for out"
		},
		"wait": {
			"description": "End turn for current unit",
			"required_context": ["goal_controller", "move_controller", "unit_manager", "turn_controller"],
			"payload_type": "null",
			"payload_description": "No payload needed"
		},
		"attack_unit": {
			"description": "Attack an adjacent enemy unit",
			"required_context": ["unit_manager", "turn_controller"],
			"payload_type": "Dictionary",
			"payload_description": "{ attacker_index: int, target_index: int }"
		},
		"aid_ally": {
			"description": "Aid an adjacent ally, restoring willpower",
			"required_context": ["unit_manager", "turn_controller"],
			"payload_type": "Dictionary",
			"payload_description": "{ helper_index: int, target_index: int }"
		},
		"work_on_goal": {
			"description": "Work on a goal at current position",
			"required_context": ["unit_manager", "goal_controller", "turn_controller"],
			"payload_type": "Dictionary",
			"payload_description": "{ worker_index: int, goal_index: int }"
		},
		"loot": {
			"description": "Pick up loot at current position",
			"required_context": ["unit_manager", "turn_controller"],
			"payload_type": "Dictionary",
			"payload_description": "{ looter_index: int, loot_coord: Vector2i }"
		},
		"confirm_move": {
			"description": "Confirm the current tentative move of the selected unit",
			"required_context": ["move_controller"],
			"payload_type": "null",
			"payload_description": "No payload needed"
		},
		"cancel_move": {
			"description": "Cancel the current tentative move of the selected unit",
			"required_context": ["move_controller"],
			"payload_type": "null",
			"payload_description": "No payload needed"
		},
		"interact": {
			"description": "Interact with a target (Loot, Goal, Unit)",
			"required_context": ["unit_manager"],
			"payload_type": "Target",
			"payload_description": "The Target object to interact with"
		},
		"undo": {
			"description": "Undo the last interaction",
			"required_context": ["unit_manager"],
			"payload_type": "null",
			"payload_description": "No payload needed"
		}
	}
