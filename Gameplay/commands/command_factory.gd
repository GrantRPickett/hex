class_name CommandFactory
extends RefCounted

## Factory for creating and registering commands with consistent initialization

## Creates the default command set
static func create_default_command_set() -> Dictionary:
	return {
		"move_action": MoveActionCommand.new(),
		"joy_move": JoyMoveCommand.new(),
		"selection_cycle": SelectionCycleCommand.new(),
		"select_index": SelectIndexCommand.new(),
		"primary_action": PrimaryActionCommand.new(),
		"move_to_coord": MoveToCoordCommand.new(),
		"toggle_free_cam": ToggleFreeCamCommand.new(),
		"zoom_camera": ZoomCameraCommand.new(),
		"wait": WaitCommand.new(),
		"attack_unit": AttackUnitCommand.new(),
		"aid_ally": AidAllyCommand.new(),
		"work_on_task": WorkOnTaskCommand.new(),
		"loot": LootCommand.new(),
		"confirm_move": ConfirmMoveCommand.new(),
		"cancel_move": CancelMoveCommand.new(),
		"interact": InteractCommand.new(),
		"undo": UndoCommand.new(),
		"toggle_enemy_range": ToggleEnemyRangeCommand.new(),
		"use_skill": UseSkillCommand.new(),
		"talk_to_unit": TalkToUnitCommand.new(),
		"trigger_dialogue": TriggerDialogueCommand.new(),
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
		"WorkOnTaskCommand": return WorkOnTaskCommand.new()
		"LootCommand": return LootCommand.new()
		"ConfirmMoveCommand": return ConfirmMoveCommand.new()
		"CancelMoveCommand": return CancelMoveCommand.new()
		"InteractCommand": return InteractCommand.new()
		"UndoCommand": return UndoCommand.new()
		"UseSkillCommand": return UseSkillCommand.new()
		"TalkToUnitCommand": return TalkToUnitCommand.new()
		"MoveToCoordCommand": return MoveToCoordCommand.new()
		"TriggerDialogueCommand": return TriggerDialogueCommand.new()
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
		"move_to_coord": {
			"description": "Move the selected unit to a specific coordinate",
			"required_context": ["move_controller"],
			"payload_type": "Vector2i",
			"payload_description": "{ coord: Vector2i }"
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
			"required_context": ["task_controller", "move_controller", "unit_manager", "turn_controller"],
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
			"description": "Encouragement through a shared affinity. Restores willpower based on highest shared attribute.",
			"required_context": ["unit_manager", "turn_controller"],
			"payload_type": "Dictionary",
			"payload_description": "{ helper_index: int, target_index: int }"
		},
		"work_on_task": {
			"description": "Work on a location at current position",
			"required_context": ["unit_manager", "task_controller", "turn_controller"],
			"payload_type": "Dictionary",
			"payload_description": "{ worker_index: int, location_index: int }"
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
			"description": "Interact with a target (Loot, location, Unit)",
			"required_context": ["unit_manager"],
			"payload_type": "Target",
			"payload_description": "The Target object to interact with"
		},
		"undo": {
			"description": "Undo the last interaction",
			"required_context": ["unit_manager"],
			"payload_type": "null",
			"payload_description": "No payload needed"
		},
		"toggle_enemy_range": {
			"description": "Toggle enemy threat range overlay",
			"required_context": ["grid_visuals", "unit_manager", "terrain_map"],
			"payload_type": "null",
			"payload_description": "No payload needed"
		},
		"use_skill": {
			"description": "Use a unit skill",
			"required_context": ["unit_manager"],
			"payload_type": "Dictionary",
			"payload_description": "{ unit_index: int, skill: Skill }"
		},
		"talk_to_unit": {
			"description": "Initiate a dialogue with an adjacent unit",
			"required_context": ["unit_manager", "dialogue_action_service"],
			"payload_type": "Dictionary",
			"payload_description": "{ initiator_index: int, target_index: int, dialogue_id: String }"
		},
		"trigger_dialogue": {
			"description": "Trigger a custom DialogueManager dialogue at a specific location",
			"required_context": [],
			"payload_type": "Dictionary",
			"payload_description": "{ dialogue_resource_path: String, start_title: String }"
		}
	}
