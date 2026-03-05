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
	preload("res://Gameplay/commands/loot_command.gd"),
	preload("res://Gameplay/commands/confirm_move_command.gd"),
	preload("res://Gameplay/commands/cancel_move_command.gd"),
	preload("res://Gameplay/commands/visit_command.gd"),
	preload("res://Gameplay/commands/explore_command.gd"),
	preload("res://Gameplay/commands/trapped_command.gd"),
	preload("res://Gameplay/commands/undo_command.gd"),
	preload("res://Gameplay/commands/toggle_enemy_range_command.gd"),
	preload("res://Gameplay/commands/use_skill_command.gd"),
	preload("res://Gameplay/commands/trigger_dialogue_command.gd"),
]

static func _get_script_metadata(script: Script) -> Dictionary:
	var instance = script.new() as GameCommand
	var meta := {"name": "", "description": "", "instance": instance}

	if instance != null:
		if instance.has_method("get_command_name"):
			meta.name = instance.call("get_command_name")
		elif script.has_method("get_command_name"):
			meta.name = script.call("get_command_name")

		if instance.has_method("get_command_description"):
			meta.description = instance.call("get_command_description")
		elif script.has_method("get_command_description"):
			meta.description = script.call("get_command_description")

	return meta

## Creates the default command set
static func create_default_command_set() -> Dictionary:
	var command_set := {}
	for script in _command_classes:
		var meta = _get_script_metadata(script)
		if not meta.name.is_empty() and meta.instance != null:
			command_set[meta.name] = meta.instance
		elif meta.instance != null:
			meta.instance.call_deferred("free")
	return command_set

## Creates a command by class name or command logic name
static func create_command_by_name(cmd_name: String) -> GameCommand:
	for script in _command_classes:
		var meta = _get_script_metadata(script)
		if meta.instance != null:
			if meta.name == cmd_name or script.resource_path.get_file().trim_suffix(".gd").to_pascal_case() == cmd_name:
				return meta.instance
			meta.instance.call_deferred("free")
	return null

## Gets command metadata (name, required fields, description)
static func get_command_metadata() -> Dictionary:
	var meta := {}
	for script in _command_classes:
		var script_meta = _get_script_metadata(script)
		if not script_meta.name.is_empty() and script_meta.instance != null:
			meta[script_meta.name] = {
				"description": script_meta.description,
				"required_context": script_meta.instance.get_required_context_fields()
			}
		if script_meta.instance != null:
			script_meta.instance.call_deferred("free")
	return meta
