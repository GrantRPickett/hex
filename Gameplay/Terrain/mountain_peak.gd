class_name MountainPeakTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 2
	movement_bonus = 0
	status_effect = StringName("HeightAdvantage")
	blocks_action_after_move = false
	color = Color.GHOST_WHITE
	description = "The summit of a mountain, difficult to traverse but offers advantage."
