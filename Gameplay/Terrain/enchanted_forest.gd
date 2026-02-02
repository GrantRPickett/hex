class_name EnchantedForestTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName("Mystified")
	blocks_action_after_move = false
