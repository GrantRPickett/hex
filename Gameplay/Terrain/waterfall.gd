class_name WaterfallTerrain
extends TerrainTile

func _init() -> void:
	passable = false
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName("Wet")
	blocks_action_after_move = true
	color = Color.DEEP_SKY_BLUE
	description = "A cascading waterfall, impassable and making units wet."
