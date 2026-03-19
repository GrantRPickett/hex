class_name SwampTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 2
	movement_bonus = 0
	status_effect = StringName("Bogged")
	blocks_action_after_move = false
	color = Color.OLIVE_DRAB
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Grass/Grass_01_Green_2.png"
	description = "Murky swamp, bogging down units."
