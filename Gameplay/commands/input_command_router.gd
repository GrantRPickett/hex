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

func register_command(name: String, command: GameCommand) -> void:
	if command == null:
		_commands.erase(name)
		return
	_commands[name] = command

## Executes a command and returns the result
func execute(name: String, payload = null) -> CommandResult:
	if _context == null:
		print_debug("Command '%s' skipped: missing context" % name)
		return CommandResult.invalid_context(["_context"])
	var command: GameCommand = _commands.get(name)
	if command == null:
		print_debug("Command '%s' skipped: not registered" % name)
		return CommandResult.failed("Command '%s' not registered" % name)
	print_debug("Command '%s' executing with payload=%s" % [name, str(payload)])
	var result = command.execute(_context, payload)
	var description := result.get_description()
	if result.is_failure():
		if description.is_empty():
			description = "Unknown error"
		print_debug("Command '%s' failed: %s" % [name, description])
	else:
		if description.is_empty():
			description = "OK"
		print_debug("Command '%s' succeeded: %s" % [name, description])
		# Emit a normalized action payload for TaskManager/others to consume
		var action: Dictionary = {}
		action[GameConstants.Payload.COMMAND] = name
		action[GameConstants.Payload.PAYLOAD] = payload
		action[GameConstants.Payload.RESULT] = description
		game_action.emit(action)
	return result
