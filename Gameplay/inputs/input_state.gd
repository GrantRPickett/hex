## Base class for contextual input handling.
class_name InputState
extends RefCounted

var _manager: Node # ContextualInputManager
var _context: GameCommandContext
var _router: InputCommandRouter

func _init(manager: Node, context: GameCommandContext, router: InputCommandRouter) -> void:
	_manager = manager
	_context = context
	_router = router

## Called when this state becomes active.
func enter() -> void:
	pass

## Called when this state is no longer active.
func exit() -> void:
	pass

## Handle an input action.
func handle_action(command_id: GameConstants.Commands.CommandID, payload: Dictionary = {}) -> CommandResult:
	return _router.execute(command_id, payload)

## Handle unhandled input events.
func handle_input(_event: InputEvent) -> void:
	pass
