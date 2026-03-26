class_name DesertOasisTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 1
	status_effect = StringName("Refreshed")
	blocks_action_after_move = false
	color = GameColors.TERRAIN_DESERT_OASIS
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Water/Water_01_Blue_1.png"
	description = "A lush oasis in the desert, refreshing units."
