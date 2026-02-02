class_name HillHighGroundTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName("HeightAdvantage")
	blocks_action_after_move = false