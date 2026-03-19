class_name IceTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName("Slippery")
	blocks_action_after_move = false
	color = Color.ALICE_BLUE
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Snow/Snow_01_White_1.png"
	description = "Slippery ice, making movement treacherous."
