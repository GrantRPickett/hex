class_name RoadTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = ""
	blocks_action_after_move = false
