class_name QuagmireTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 3
	movement_bonus = 0
	status_effect = StringName("Stuck")
	blocks_action_after_move = true
	color = GameColors.TERRAIN_QUAGMIRE
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Dirt/Dirt_Silt_01_Brown_2.png"
	description = "terrain.quagmire.description"
