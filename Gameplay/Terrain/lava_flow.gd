class_name LavaFlowTerrain
extends TerrainTile

func _init() -> void:
	passable = false
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName("Burning")
	blocks_action_after_move = true
	color = Color.DARK_RED
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Water/Water_01_Red_2.png"
	description = "Molten rock, impassable and burning."
