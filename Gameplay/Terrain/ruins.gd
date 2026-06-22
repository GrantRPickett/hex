class_name RuinsTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = GameColors.TERRAIN_RUINS
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Bricks/Brick Plaster/Brick_Plaster_01_Hole_1.png"
	description = "terrain.ruins.description"
