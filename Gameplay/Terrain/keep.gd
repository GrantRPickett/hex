class_name KeepTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName("Guarded")
	blocks_action_after_move = false
	color = Color.WEB_MAROON
	description = "A fortified keep, providing a guarded status."
