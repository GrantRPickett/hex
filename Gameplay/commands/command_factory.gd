class_name CommandFactory
extends RefCounted

## Factory for creating and registering commands with consistent initialization

static var _command_classes: Array[Script] = [
	preload("res://Gameplay/commands/move_action_command.gd"),
	preload("res://Gameplay/commands/joy_move_command.gd"),
	preload("res://Gameplay/commands/selection_cycle_command.gd"),
	preload("res://Gameplay/commands/select_index_command.gd"),
	preload("res://Gameplay/commands/primary_action_command.gd"),
	preload("res://Gameplay/commands/move_to_coord_command.gd"),
	preload("res://Gameplay/commands/toggle_free_cam_command.gd"),
	preload("res://Gameplay/commands/zoom_camera_command.gd"),
	preload("res://Gameplay/commands/wait_command.gd"),
	preload("res://Gameplay/commands/attack_unit_command.gd"),
	preload("res://Gameplay/commands/aid_ally_command.gd"),
	preload("res://Gameplay/commands/work_on_task_command.gd"),
	preload("res://Gameplay/commands/loot_command.gd"),
	preload("res://Gameplay/commands/confirm_move_command.gd"),
	preload("res://Gameplay/commands/cancel_move_command.gd"),
	preload("res://Gameplay/commands/interact_command.gd"),
	preload("res://Gameplay/commands/undo_command.gd"),
	preload("res://Gameplay/commands/toggle_enemy_range_command.gd"),
	preload("res://Gameplay/commands/use_skill_command.gd"),
	preload("res://Gameplay/commands/talk_to_unit_command.gd"),
	preload("res://Gameplay/commands/trigger_dialogue_command.gd"),
]

## Creates the default command set
static func create_default_command_set() -> Dictionary:
	var command_set := {}
	for script in _command_classes:
		var instance = script.new() as GameCommand
		if instance != null:
			var actual_name = ""
			if instance.has_method("get_command_name"):
				actual_name = instance.call("get_command_name")
			elif script.has_method("get_command_name"):
				actual_name = script.call("get_command_name")

			if not actual_name.is_empty():
				command_set[actual_name] = instance
	return command_set

## Creates a command by class name or command logic name
static func create_command_by_name(cmd_name: String) -> GameCommand:
	for script in _command_classes:
		var instance = script.new() as GameCommand
		if instance != null:
			var actual_name = ""
			if instance.has_method("get_command_name"):
				actual_name = instance.call("get_command_name")
			elif script.has_method("get_command_name"):
				actual_name = script.call("get_command_name")

			if actual_name == cmd_name or script.resource_path.get_file().trim_suffix(".gd").to_pascal_case() == cmd_name:
				return instance
			instance.call_deferred("free") # Free if not the one we want
	return null

## Gets command metadata (name, required fields, description)
static func get_command_metadata() -> Dictionary:
	var meta := {}

	for script in _command_classes:
		var instance = script.new() as GameCommand
		if instance != null:
			var actual_name = ""
			if instance.has_method("get_command_name"):
				actual_name = instance.call("get_command_name")
			elif script.has_method("get_command_name"):
				actual_name = script.call("get_command_name")

			if not actual_name.is_empty():
				var desc = ""
				if instance.has_method("get_command_description"):
					desc = instance.call("get_command_description")
				elif script.has_method("get_command_description"):
					desc = script.call("get_command_description")

				meta[actual_name] = {
					"description": desc,
					"required_context": instance.get_required_context_fields()
				}
			instance.call_deferred("free")

	return meta
