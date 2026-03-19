class_name HillHighGroundTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName("HeightAdvantage")
	blocks_action_after_move = false
	color = Color.YELLOW_GREEN
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Grass/Grass_01_Green_2.png"
	description = "Elevated terrain, offering a height advantage."
