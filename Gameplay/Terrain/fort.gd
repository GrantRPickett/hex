class_name FortTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName("Fortified")
	blocks_action_after_move = false
	color = Color.FIREBRICK
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Bricks/Bricks/Bricks_01_Orange_1.png"
	description = "A defensive structure, providing fortification."
