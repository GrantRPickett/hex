class_name PathTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 1
	status_effect = StringName()
	blocks_action_after_move = false
	color = GameColors.TERRAIN_PATH
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Dirt/Dirt_Pebbles_01_Brown_1.png"
	description = "terrain.path.description"
