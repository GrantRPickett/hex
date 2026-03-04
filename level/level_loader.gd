class_name LevelLoader
extends RefCounted

static func load_level_data(level: Level) -> Dictionary:
	var data = {
		"grid_width": 7,
		"grid_height": 7,
		"player_starts": [Vector2i(0, 0), Vector2i(0, 1)],
		"enemy_starts": [] as Array[Vector2i],
		"location_coords": [Vector2i(2, 2), Vector2i(3, 2)],
		"loot_coords": [] as Array[Vector2i],
		"loot_items": [] as Array[InventoryItem],
		"terrain_rows": [],
		"initial_rotation": 0.0,
		"hex_offset_axis": 1
	}

	if not level:
		_validate_data(data)
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
	if "locations" in level:
		var locations: Array[Vector2i] = []
		for loc in level.locations:
			if loc: locations.append(loc.coord)
		data.location_coords = locations
	if "loot_coords" in level:
		var loots: Array[Vector2i] = []
		loots.assign(level.loot_coords)
		data.loot_coords = loots
	if "loot_items" in level:
		data.loot_items = level.loot_items
	if "terrain_rows" in level: data.terrain_rows = level.terrain_rows
	if "initial_rotation" in level:
		data.initial_rotation = level.initial_rotation
	elif "initial_camera_rotation" in level:
		data.initial_rotation = level.initial_camera_rotation
	if "hex_offset_axis" in level: data.hex_offset_axis = level.hex_offset_axis

	if data.terrain_rows.is_empty():
		var default_row := "G".repeat(data.grid_width)
		for _i in range(data.grid_height):
			data.terrain_rows.append(default_row)

	_validate_data(data)
	return data

static func _validate_data(data: Dictionary) -> void:
	# Delegate to shared validator to avoid duplication
	LevelDataValidator.validate_data(data)
