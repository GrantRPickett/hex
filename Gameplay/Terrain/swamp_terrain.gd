class_name SwampTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = &"poisoned"
	blocks_action_after_move = false

