import re
import os

def refactor_hud_action_executor():
	path = "GUI/hud_action_executor.gd"
	if not os.path.exists(path):
		print(f"File not found: {path}")
		return

	with open(path, 'r') as f:
		content = f.read()

	# 1. Update _run_input_command signature
	content = re.sub(
		r"func _run_input_command\(command_name:\s*String,\s*payload\s*=\s*null\)\s*->\s*CommandResult:",
		"func _run_input_command(command_id: GameConstants.Commands.CommandID, payload = null) -> CommandResult:",
		content
	)

	# Update body of _run_input_command
	content = content.replace(
		"_input_controller._execute_command(command_name,",
		"_input_controller._execute_command(command_id,"
	)

	# 2. Map GameConstants.Commands.X to GameConstants.Commands.CommandID.X
	# We want to match GameConstants.Commands.WAIT, GameConstants.Commands.VISIT, etc.
	# but NOT GameConstants.Commands.CommandID.WAIT
	# and NOT GameConstants.Commands.MOVE_AND_INTERACT_TYPE which needs special handling
	content = re.sub(
		r"GameConstants\.Commands\.(?!(CommandID\.)|MOVE_AND_INTERACT_TYPE)([A-Z_]+)",
		r"GameConstants.Commands.CommandID.\2",
		content
	)

	# Special case for MOVE_AND_INTERACT_TYPE if it was used
	content = content.replace("GameConstants.Commands.MOVE_AND_INTERACT_TYPE", "GameConstants.Commands.CommandID.MOVE_AND_INTERACT")

	# 3. Map GameConstants.Interactions.X to GameConstants.Commands.CommandID.X
	content = re.sub(
		r"GameConstants\.Interactions\.([A-Z_]+)",
		r"GameConstants.Commands.CommandID.\1",
		content
	)

	with open(path, 'w') as f:
		f.write(content)
	print(f"Refactored {path}")

def refactor_input_controller():
	path = "Gameplay/inputs/input_controller.gd"
	if not os.path.exists(path):
		print(f"File not found: {path}")
		return

	with open(path, 'r') as f:
		content = f.read()

	# 1. Fix string calls to _execute_command
	# _execute_command("select_index", unit_idx) -> _execute_command(GameConstants.Commands.CommandID.SELECT_INDEX, unit_idx)
	def to_command_id(match):
		cmd_str = match.group(1).upper()
		# Handle cases where the string name doesn't match the enum name exactly if any
		if cmd_str == "ATTACK_UNIT": cmd_str = "ATTACK"
		if cmd_str == "AID_ALLY": cmd_str = "AID"
		if cmd_str == "CONVINCE_UNIT": cmd_str = "CONVINCE"
		if cmd_str == "TALK_TO_UNIT": cmd_str = "TALK"

		return f"_execute_command(GameConstants.Commands.CommandID.{cmd_str}"

	content = re.sub(r'_execute_command\("([^"]+)"', to_command_id, content)

	with open(path, 'w') as f:
		f.write(content)
	print(f"Refactored {path}")

def refactor_combat_input_state():
	path = "Gameplay/inputs/combat_input_state.gd"
	if not os.path.exists(path):
		print(f"File not found: {path}")
		return

	# Check if any strings are still used in the lists
	with open(path, 'r') as f:
		content = f.read()

	# If passthrough or locking_commands have strings, convert them.
	# Currently they seem to use CommandID already.

	with open(path, 'w') as f:
		f.write(content)
	print(f"Refactored {path}")

if __name__ == "__main__":
	refactor_hud_action_executor()
	refactor_input_controller()
	refactor_combat_input_state()
