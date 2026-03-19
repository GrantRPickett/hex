class_name TreeVillageTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = Color.DARK_OLIVE_GREEN
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Wood/Wood_Branches_01.png"
	description = "A village nestled among the trees."
