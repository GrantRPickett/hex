class_name PathTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 1
	status_effect = StringName()
	blocks_action_after_move = false
	color = Color.BURLYWOOD
	description = "A well-trodden path, speeding movement."
