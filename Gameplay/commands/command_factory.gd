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
	preload("res://Gameplay/commands/talk_to_unit_command.gd"),
]

static func _get_script_metadata(script: Script) -> Dictionary:
	var instance: GameCommand = script.new() as GameCommand
	var meta := {"id": GameConstants.Commands.CommandID.NONE, "name": "", "description": "", "instance": instance}

	if instance != null:
		if script.has_method("_get_command_id"):
			meta.id = script.call("_get_command_id")
		
		if script.has_method("get_command_name"):
			meta.name = script.call("get_command_name")

		if script.has_method("get_command_description"):
			meta.description = script.call("get_command_description")

	return meta

## Creates the default command set
static func create_default_command_set() -> Dictionary:
	var command_set := {}
	for script in _command_classes:
		var meta: Dictionary = _get_script_metadata(script)
		if meta.id != GameConstants.Commands.CommandID.NONE and meta.instance != null:
			command_set[meta.id] = meta.instance
		elif meta.instance != null:
			meta.instance.call_deferred("free")
	return command_set

## Creates a command by CommandID
static func create_command_by_id(cmd_id: GameConstants.Commands.CommandID) -> GameCommand:
	for script in _command_classes:
		if script.has_method("_get_command_id") and script.call("_get_command_id") == cmd_id:
			return script.new() as GameCommand
	return null

## Gets command metadata (id, name, required fields, description)
static func get_command_metadata() -> Dictionary:
	var meta := {}
	for script in _command_classes:
		var script_meta: Dictionary = _get_script_metadata(script)
		if script_meta.id != GameConstants.Commands.CommandID.NONE and script_meta.instance != null:
			meta[script_meta.id] = {
				"name": script_meta.name,
				"description": script_meta.description,
				"required_context": script_meta.instance.get_required_context_fields()
			}
		if script_meta.instance != null:
			script_meta.instance.call_deferred("free")
	return meta
