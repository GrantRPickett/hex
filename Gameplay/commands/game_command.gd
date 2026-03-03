class_name GameCommand
extends RefCounted

## Returns the globally unique registry name for this command type
static func get_command_name() -> String:
	return ""

## Returns a description of what this command does
static func get_command_description() -> String:
	return ""

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
