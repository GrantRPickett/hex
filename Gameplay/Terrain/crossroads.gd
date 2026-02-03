class_name CrossroadsTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = Color.DIM_GRAY
	description = "Where paths converge, offering multiple directions."
