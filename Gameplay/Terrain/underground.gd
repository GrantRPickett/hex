class_name UndergroundTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = GameColors.BLACK
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Dirt/Dirt_Rocks_01_Black_1.png"
	description = "Subterranean passages and caverns."
