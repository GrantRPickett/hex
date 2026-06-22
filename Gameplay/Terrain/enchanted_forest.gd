class_name EnchantedForestTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName("Mystified")
	blocks_action_after_move = false
	color = GameColors.TERRAIN_ENCHANTED_FOREST
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Foliage/Foliage_Leaves_01_Green_1.png"
	description = "terrain.enchanted_forest.description"
