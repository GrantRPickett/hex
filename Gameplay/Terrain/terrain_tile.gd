class_name TerrainTile
extends Node2D

@export var passable: bool = true
@export var movement_penalty: int = 0
@export var movement_bonus: int = 0
@export var status_effect: StringName = StringName()
@export var blocks_action_after_move: bool = false

func get_movement_adjustment() -> int:
	return movement_bonus - movement_penalty

func apply_to_unit(unit: Unit) -> void:
	if unit == null:
		return
	if not passable:
		unit.block_movement_this_turn()
		return
	var adjustment := get_movement_adjustment()
	if adjustment != 0:
		unit.adjust_remaining_movement(adjustment)
	if blocks_action_after_move:
		unit.block_action_this_turn()
	if not status_effect.is_empty():
		unit.apply_status_effect(status_effect)

## Null Object implementation for TerrainTile
class NullTerrain extends TerrainTile:
	func _init() -> void:
		passable = false
		movement_penalty = 999
		movement_bonus = 0
		status_effect = ""
		blocks_action_after_move = false
