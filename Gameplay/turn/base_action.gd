class_name BaseAction
extends RefCounted

## Shared base for all game actions (AI or Player).
## Consolidates core "what to do" properties via Command composition.

var type: GameConstants.ActionType = GameConstants.ActionType.UNKNOWN

# Composition: The command to execute and its parameters
var command_id: GameConstants.Commands.CommandID = GameConstants.Commands.CommandID.NONE
var command_payload: Dictionary = {}

# Movement: Pathing information if this action involves a move
var path: Array[Vector2i] = []
var move_cost: int = 0
var action_cost: int = 1

# Optional: Reference to the primary object being interacted with
var target_object: Object = null

func _init(p_type: GameConstants.ActionType = GameConstants.ActionType.UNKNOWN) -> void:
	type = p_type
