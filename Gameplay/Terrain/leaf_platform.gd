class_name LeafPlatformTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = Color.MEDIUM_SEA_GREEN
	description = "A sturdy platform made of large leaves."
