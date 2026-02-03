class_name TreeVillageTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = Color.DARK_GREEN
	description = "A village nestled among the trees."
