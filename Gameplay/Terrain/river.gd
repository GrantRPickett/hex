class_name RiverTerrain
extends TerrainTile

func _init() -> void:
	passable = false
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName("Wet")
	blocks_action_after_move = true
	color = Color.CORNFLOWER_BLUE
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Water/Water_01_Blue_3.png"
	description = "A flowing river, impassable and making units wet."
