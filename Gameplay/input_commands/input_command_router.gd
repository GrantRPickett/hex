class_name InputCommandRouter
extends RefCounted

const GameCommandContext := preload("res://Gameplay/input_commands/game_command_context.gd")
const GameCommand := preload("res://Gameplay/input_commands/game_command.gd")

var _context: GameCommandContext
var _commands: Dictionary = {}

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

func execute(name: String, payload = null) -> void:
	if _context == null:
		return
	var command: GameCommand = _commands.get(name)
	if command == null:
		return
	command.execute(_context, payload)
