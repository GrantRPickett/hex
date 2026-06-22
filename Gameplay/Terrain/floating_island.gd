class_name FloatingIslandTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = GameColors.TERRAIN_FLOATING_ISLAND
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Grass/Grass_01_Green_2.png"
	description = "terrain.floating_island.description"
