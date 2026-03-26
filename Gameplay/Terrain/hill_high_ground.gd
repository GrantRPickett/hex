class_name HillHighGroundTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName("HeightAdvantage")
	blocks_action_after_move = false
	color = GameColors.TERRAIN_HILL_HIGH_GROUND
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Grass/Grass_01_Green_2.png"
	description = "terrain.hill_high_ground.description"
