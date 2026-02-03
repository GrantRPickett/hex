class_name FortTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName("Fortified")
	blocks_action_after_move = false
	color = Color.SADDLE_BROWN
	description = "A defensive structure, providing fortification."
