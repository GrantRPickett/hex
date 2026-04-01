import os
import re

commands = {
	'move_action': {'file': 'move_action_command.gd', 'class': 'MoveActionCommand', 'desc': 'Request movement in a cardinal direction'},
	'joy_move': {'file': 'joy_move_command.gd', 'class': 'JoyMoveCommand', 'desc': 'Request movement from joystick axis'},
	'move_to_coord': {'file': 'move_to_coord_command.gd', 'class': 'MoveToCoordCommand', 'desc': 'Move the selected unit to a specific coordinate'},
	'confirm_move': {'file': 'confirm_move_command.gd', 'class': 'ConfirmMoveCommand', 'desc': 'Confirm the current tentative move of the selected unit'},
	'cancel_move': {'file': 'cancel_move_command.gd', 'class': 'CancelMoveCommand', 'desc': 'Cancel the current tentative move of the selected unit'},
	'wait': {'file': 'wait_command.gd', 'class': 'WaitCommand', 'desc': 'End turn for current unit'},
	'attack_unit': {'file': 'attack_unit_command.gd', 'class': 'AttackUnitCommand', 'desc': 'Attack an near enemy unit'},
	'aid_ally': {'file': 'aid_ally_command.gd', 'class': 'AidAllyCommand', 'desc': 'Encouragement through a shared affinity. Restores willpower based on highest shared attribute.'},
	'loot': {'file': 'loot_command.gd', 'class': 'LootCommand', 'desc': 'Pick up loot at current position'},
	'SKILL': {'file': 'SKILL_command.gd', 'class': 'UseSkillCommand', 'desc': 'Use a unit skill'},
	'talk_to_unit': {'file': 'talk_to_unit_command.gd', 'class': 'TalkToUnitCommand', 'desc': 'Initiate a dialogue with an near unit'},
	'selection_cycle': {'file': 'selection_cycle_command.gd', 'class': 'SelectionCycleCommand', 'desc': 'Cycle through selectable units'},
	'select_index': {'file': 'select_index_command.gd', 'class': 'SelectIndexCommand', 'desc': 'Select a specific unit by index'},
	'primary_action': {'file': 'primary_action_command.gd', 'class': 'PrimaryActionCommand', 'desc': 'Primary action at screen coordinates (click or tap)'},
	'interact': {'file': 'interact_command.gd', 'class': 'InteractCommand', 'desc': 'Interact with a target (Loot, location, Unit)'},
	'toggle_free_cam': {'file': 'toggle_free_cam_command.gd', 'class': 'ToggleFreeCamCommand', 'desc': 'Toggle free camera mode'},
	'zoom_camera': {'file': 'zoom_camera_command.gd', 'class': 'ZoomCameraCommand', 'desc': 'Zoom camera in or out'},
	'undo': {'file': 'undo_command.gd', 'class': 'UndoCommand', 'desc': 'Undo the last interaction'},
	'toggle_enemy_range': {'file': 'toggle_enemy_range_command.gd', 'class': 'ToggleEnemyRangeCommand', 'desc': 'Toggle enemy threat range overlay'},
	'trigger_dialogue': {'file': 'trigger_dialogue_command.gd', 'class': 'TriggerDialogueCommand', 'desc': 'Trigger a custom DialogueManager dialogue at a specific location'}
}

dir_path = r'c:\Users\grant\Documents\github\hex\Gameplay\commands'

for key, info in commands.items():
	file_path = os.path.join(dir_path, info['file'])
	if os.path.exists(file_path):
		with open(file_path, 'r', encoding='utf-8') as f:
			content = f.read()

		if 'static func get_command_name' not in content:
			lines = content.split('\n')
			new_lines = []

			for line in lines:
				new_lines.append(line)
				if line.startswith('extends'):
					new_lines.append('')
					new_lines.append('\treturn "{}"'.format(key))
					new_lines.insert(-1, 'static func get_command_name() -> String:')
					new_lines.append('')
					new_lines.append('\treturn "{}"'.format(info['desc']))
					new_lines.insert(-1, 'static func get_command_description() -> String:')

			with open(file_path, 'w', encoding='utf-8') as f:
				f.write('\n'.join(new_lines))
			print(f"Updated {info['file']}")
