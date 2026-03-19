class_name LeafPlatformTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = Color.PALE_GREEN
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Foliage/Foliage_Leaves_01_Green_2.png"
	description = "A sturdy platform made of large leaves."
