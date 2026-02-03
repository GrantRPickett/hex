class_name PlazaTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = Color.LIGHT_GOLDENROD
	description = "An open public square."
