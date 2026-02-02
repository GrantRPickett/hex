class_name LavaFlowTerrain
extends TerrainTile

func _init() -> void:
	passable = false
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName("Burning")
	blocks_action_after_move = true
