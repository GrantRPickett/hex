class_name MonasteryTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName("Sanctuary")
	blocks_action_after_move = false