class_name ReachableState
extends RefCounted

## Typed data structure for unit reachability results.

var movement_origin: Vector2i = GameConstants.INVALID_COORD
var action_origin: Vector2i = GameConstants.INVALID_COORD
var coords: Array[Vector2i] = []
var lookup: Dictionary = {} # coord -> {"remaining": int, "cost": int}
var move_spaces: int = 0
var unit_index: int = -1

static func create_empty() -> ReachableState:
	var state = ReachableState.new()
	state.movement_origin = Vector2i(-999, -999)
	state.action_origin = Vector2i(-999, -999)
	return state
