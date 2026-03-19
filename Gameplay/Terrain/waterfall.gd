class_name WaterfallTerrain
extends TerrainTile

func _init() -> void:
	passable = false
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName("Wet")
	blocks_action_after_move = true
	color = Color.LIGHT_BLUE
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Water/Water_01_Blue_2.png"
	description = "A cascading waterfall, impassable and making units wet."
