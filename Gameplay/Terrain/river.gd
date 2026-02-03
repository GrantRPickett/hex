class_name RiverTerrain
extends TerrainTile

func _init() -> void:
	passable = false
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName("Wet")
	blocks_action_after_move = true
	color = Color.CYAN
	description = "A flowing river, impassable and making units wet."
