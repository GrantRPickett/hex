class_name MonasteryTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName("Sanctuary")
	blocks_action_after_move = false
	color = GameColors.TERRAIN_MONASTERY
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Bricks/Bricks/Bricks_01_Grey_1.png"
	description = "A peaceful monastery, offering sanctuary."
