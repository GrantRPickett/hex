class_name CrystalTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName("Energized")
	blocks_action_after_move = false
	color = GameColors.TERRAIN_CRYSTAL
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Glass/Glass_01_1.png"
	description = "terrain.crystal.description"
