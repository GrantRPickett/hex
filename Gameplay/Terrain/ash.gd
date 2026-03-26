class_name AshTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName("Soot")
	blocks_action_after_move = false
	color = GameColors.TERRAIN_ASH
	description = "Fine volcanic ash, slowing movement."
