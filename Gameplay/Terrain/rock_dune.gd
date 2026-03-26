class_name RockDuneTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 2
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = GameColors.TERRAIN_ROCK_DUNE
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Sand/Sand_01_Rocks_1.png"
	description = "terrain.rock_dune.description"
