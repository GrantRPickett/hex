class_name DesertOasisTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 1
	status_effect = StringName("Refreshed")
	blocks_action_after_move = false
	color = Color.PEACH_PUFF
	description = "A lush oasis in the desert, refreshing units."
