class_name LevelLoader
extends RefCounted

static func load_level_data(level: Resource) -> Dictionary:
	var data = {
		"grid_width": 7,
		"grid_height": 7,
		"player_starts": [Vector2i(0, 0), Vector2i(0, 1)],
		"enemy_starts": [] as Array[Vector2i],
		"goal_coords": [Vector2i(3, 3), Vector2i(4, 3)],
		"terrain_rows": [],
		"require_all_units": false,
		"initial_rotation": 0.0,
		"hex_offset_axis": 1
	}

	if not level:
		return data

	if "grid_width" in level: data.grid_width = level.grid_width
	if "grid_height" in level: data.grid_height = level.grid_height
	if "player_starts" in level:
		var starts: Array[Vector2i] = []
		starts.assign(level.player_starts)
		data.player_starts = starts
	if "enemy_starts" in level:
		var enemies: Array[Vector2i] = []
		enemies.assign(level.enemy_starts)
		data.enemy_starts = enemies
	if "goal_coords" in level:
		var goals: Array[Vector2i] = []
		goals.assign(level.goal_coords)
		data.goal_coords = goals
	if "terrain_rows" in level: data.terrain_rows = level.terrain_rows
	if "require_all_units" in level: data.require_all_units = level.require_all_units
	if "initial_rotation" in level:
		data.initial_rotation = level.initial_rotation
	elif "initial_camera_rotation" in level:
		data.initial_rotation = level.initial_camera_rotation
	if "hex_offset_axis" in level: data.hex_offset_axis = level.hex_offset_axis

	if data.terrain_rows.is_empty():
		var default_row := "G".repeat(data.grid_width)
		for _i in range(data.grid_height):
			data.terrain_rows.append(default_row)

	return data
