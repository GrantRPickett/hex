class_name CrystalTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName("Energized")
	blocks_action_after_move = false
	color = Color.POWDER_BLUE
	description = "Shimmering crystals, providing an energized effect."
