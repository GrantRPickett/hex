class_name GameCommand
extends RefCounted

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

## Returns the globally unique registry name for this command type
static func get_command_name() -> String:
	return LocalizationStrings.get_command_name(_get_command_id())

## Returns a description of what this command does
static func get_command_description() -> String:
	return LocalizationStrings.get_command_description(_get_command_id())

## Internal ID used for identification
static func _get_command_id() -> GameConstants.ActionType:
	return GameConstants.ActionType.NONE

## Executes the command and returns a result indicating success or failure
## Override in subclasses to implement specific behavior
func execute(_context: GameCommandContext, _payload: Dictionary = {}) -> CommandResult:
	return CommandResult.success()

## Validates the context has required dependencies
## Subclasses should override to specify their specific requirements
func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray()

## Helper to validate context
func validate_context(context: GameCommandContext) -> CommandResult:
	var required = get_required_context_fields()
	return CommandValidator.validate_context(context, required)
