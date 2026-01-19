class_name GameCommand
extends RefCounted

const GameCommandContext := preload("res://Gameplay/input_commands/game_command_context.gd")
const CommandResult := preload("res://Gameplay/input_commands/command_result.gd")
const CommandValidator := preload("res://Gameplay/input_commands/command_validator.gd")

## Executes the command and returns a result indicating success or failure
## Override in subclasses to implement specific behavior
func execute(_context: GameCommandContext, _payload = null) -> CommandResult:
	return CommandResult.success()

## Validates the context has required dependencies
## Subclasses should override to specify their specific requirements
func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray()

## Helper to validate context
func validate_context(context: GameCommandContext) -> CommandResult:
	var required = get_required_context_fields()
	return CommandValidator.validate_context(context, required)
