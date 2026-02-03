class_name SwampTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 2
	movement_bonus = 0
	status_effect = StringName("Bogged")
	blocks_action_after_move = false
	color = Color.DARK_OLIVE_GREEN
	description = "Murky swamp, bogging down units."
