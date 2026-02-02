class_name QuagmireTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 3
	movement_bonus = 0
	status_effect = StringName("Stuck")
	blocks_action_after_move = true
