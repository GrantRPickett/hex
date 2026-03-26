class_name KeepTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName("Guarded")
	blocks_action_after_move = false
	color = GameColors.TERRAIN_KEEP
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Bricks/Bricks/Bricks_03_Grey_1.png"
	description = "A fortified keep, providing a guarded status."
