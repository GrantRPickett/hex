class_name InputCommandRouter
extends RefCounted

var _context: GameCommandContext
var _commands: Dictionary = {}
signal game_action(payload: Dictionary)

func _init(context: GameCommandContext = null, commands: Dictionary = {}) -> void:
	_context = context
	set_commands(commands)

func set_context(context: GameCommandContext) -> void:
	_context = context

func set_commands(commands: Dictionary) -> void:
	_commands = commands.duplicate(true)

func register_command(id: GameConstants.Commands.CommandID, command: GameCommand) -> void:
	if command == null:
		_commands.erase(id)
		return
	_commands[id] = command

func _get_command_name(id: GameConstants.Commands.CommandID) -> String:
	var keys = GameConstants.Commands.CommandID.keys()
	if id >= 0 and id < keys.size():
		return keys[id]
	return "UNKNOWN"

## Executes a command and returns the result
func execute(id: GameConstants.Commands.CommandID, payload = null) -> CommandResult:
	var command_name := _get_command_name(id)
	if _context == null:
		var result = CommandResult.invalid_context(["_context"], "Ensure InputCommandRouter is initialized with a valid GameCommandContext.")
		GameLogger.debug(GameLogger.Category.SYSTEM, "Command ID '%d' (%s) skipped: %s" % [id, command_name, result.get_description()])
		return result
	var command: GameCommand = _commands.get(id)
	if command == null:
		var result = CommandResult.failed("Command ID '%d' not registered" % id, "Check CommandFactory to ensure the command class is preloaded.")
		GameLogger.debug(GameLogger.Category.SYSTEM, "Command ID '%d' (%s) skipped: %s" % [id, command_name, result.get_description()])
		return result
	GameLogger.debug(GameLogger.Category.SYSTEM, "Command ID '%d' (%s) executing with payload=%s" % [id, command_name, str(payload)])
	var result: CommandResult = command.execute(_context, payload)
	var description := result.get_description()
	if result.is_failure():
		GameLogger.debug(GameLogger.Category.SYSTEM, "Command ID '%d' (%s) failed: %s" % [id, command_name, description])
	else:
		if description.is_empty():
			description = "OK"
		GameLogger.debug(GameLogger.Category.SYSTEM, "Command ID '%d' (%s) succeeded: %s" % [id, command_name, description])
		# Emit a normalized action payload for TaskManager/others to consume
		var action: Dictionary = {}
		action[GameConstants.Payload.COMMAND] = id
		action[GameConstants.Payload.PAYLOAD] = payload
		action[GameConstants.Payload.RESULT] = description
		game_action.emit(action)
	return result
