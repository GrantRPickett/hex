class_name WallTerrain
extends TerrainTile

func _init() -> void:
	passable = false
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = true
	color = GameColors.TERRAIN_WALL
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Bricks/Bricks/Bricks_01_Grey_1.png"
	description = "An impassable wall, blocking movement and actions."
