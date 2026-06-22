class_name PlazaTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = GameColors.TERRAIN_PLAZA
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Concrete/Concrete_01_Grey_1.png"
	description = "terrain.plaza.description"
