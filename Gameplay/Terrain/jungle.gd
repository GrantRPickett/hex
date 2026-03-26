class_name JungleTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = GameColors.TERRAIN_JUNGLE
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Foliage/Foliage_Roots_1.png"
	description = "Dense jungle, slowing passage."
