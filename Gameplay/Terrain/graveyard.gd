class_name GraveyardTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName("Cursed")
	blocks_action_after_move = false
