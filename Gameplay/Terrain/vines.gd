class_name VinesTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName("Entangled")
	blocks_action_after_move = true
	color = GameColors.TERRAIN_VINES
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Foliage/Foliage_Roots_1.png"
	description = "Thick vines, entangling units and blocking actions."
