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

## Executes a command and returns the result
func execute(id: GameConstants.Commands.CommandID, payload = null) -> CommandResult:
	if _context == null:
		print_debug("Command ID '%d' skipped: missing context" % id)
		return CommandResult.invalid_context(["_context"])
	var command: GameCommand = _commands.get(id)
	if command == null:
		print_debug("Command ID '%d' skipped: not registered" % id)
		return CommandResult.failed("Command ID '%d' not registered" % id)
	print_debug("Command ID '%d' executing with payload=%s" % [id, str(payload)])
	var result = command.execute(_context, payload)
	var description := result.get_description()
	if result.is_failure():
		if description.is_empty():
			description = "Unknown error"
		print_debug("Command ID '%d' failed: %s" % [id, description])
	else:
		if description.is_empty():
			description = "OK"
		print_debug("Command ID '%d' succeeded: %s" % [id, description])
		# Emit a normalized action payload for TaskManager/others to consume
		var action: Dictionary = {}
		action[GameConstants.Payload.COMMAND] = id
		action[GameConstants.Payload.PAYLOAD] = payload
		action[GameConstants.Payload.RESULT] = description
		game_action.emit(action)
	return result
