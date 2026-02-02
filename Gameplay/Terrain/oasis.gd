class_name OasisTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 1
	status_effect = StringName("Refreshed") # Updated as per plan
	blocks_action_after_move = false