class_name GridVisuals
extends Node2D

const TERRAIN_DEBUG_COLORS := {
	"G": Color(0.4, 0.75, 0.3, 0.35),
	"R": Color(0.85, 0.65, 0.35, 0.35),
	"M": Color(0.5, 0.3, 0.1, 0.35),
	"S": Color(0.4, 0.2, 0.6, 0.35),
	"I": Color(0.3, 0.7, 0.9, 0.35),
	"W": Color(0.1, 0.1, 0.1, 0.5),
}

var _hover_indicator: Polygon2D
var _path_line: Line2D
var _range_indicator_root: Node2D
var _terrain_overlay_root: Node2D

func _ready() -> void:
	_hover_indicator = Polygon2D.new()
	_hover_indicator.color = Color(1, 1, 1, 0.2)
	_hover_indicator.visible = false
	add_child(_hover_indicator)

	_path_line = Line2D.new()
	_path_line.width = 4.0
	_path_line.default_color = Color(1, 1, 1, 0.6)
	_path_line.z_index = -1
	_path_line.visible = false
	add_child(_path_line)

	_range_indicator_root = Node2D.new()
	_range_indicator_root.name = "RangeIndicator"
	_range_indicator_root.z_index = -3
	add_child(_range_indicator_root)

	_terrain_overlay_root = Node2D.new()
	_terrain_overlay_root.name = "TerrainOverlay"
	_terrain_overlay_root.z_index = -5
	add_child(_terrain_overlay_root)

func setup_hex_shape(tile_size: Vector2, grid: Node2D = null) -> void:
	var hex_points = _build_hex_points(tile_size, grid)
	_hover_indicator.polygon = hex_points

func update_hover_indicator(mouse_pos: Vector2, grid: Node2D, _unit_manager: UnitManager, terrain_map = null) -> void:
	if not is_instance_valid(_hover_indicator):
		return

	var cell = grid.local_to_map(grid.to_local(mouse_pos))

	if terrain_map and not terrain_map.is_within_bounds(cell):
		_hover_indicator.visible = false
		return

	_hover_indicator.visible = true
	_hover_indicator.position = grid.map_to_local(cell)

func update_path_preview(mouse_pos: Vector2, grid: Node2D, unit_manager: UnitManager, terrain_map) -> void:
	if not is_instance_valid(_path_line):
		return
	_path_line.visible = false
	_path_line.points = PackedVector2Array() # Clear previous points

	var selected_idx = unit_manager.get_selected_index()
	if selected_idx == -1:
		return

	var unit = unit_manager.get_unit(selected_idx)
	if not (unit is Unit) or not unit_manager.is_player_controlled(selected_idx):
		return

	var path_points = []
	var movement_budget = unit.get_remaining_movement_points()

	if unit.has_tentative_move():
		var tentative_path = unit.get_tentative_path()
		if not tentative_path.is_empty():
			var start_cell = unit.get_start_of_turn_grid_coord()

			if start_cell == Vector2i.MAX:
				start_cell = unit.get_grid_location()

			if not terrain_map.is_within_bounds(start_cell):
				return

			for cell in tentative_path:
				path_points.append(grid.map_to_local(cell))

			path_points.insert(0, grid.map_to_local(start_cell))

			_path_line.points = PackedVector2Array(path_points)
			_path_line.visible = true
		return

	var current_cell = unit.get_grid_location()

	if not terrain_map.is_within_bounds(current_cell):
		return

	var target_cell = grid.local_to_map(grid.to_local(mouse_pos))
	if terrain_map and not terrain_map.is_within_bounds(target_cell):
		return

	if target_cell == current_cell:
		return

	if unit_manager.is_occupied(target_cell, selected_idx):
		return

	var path_cells = unit.get_path_to_coord(target_cell, terrain_map, current_cell, movement_budget)
	if path_cells.is_empty():
		return

	for cell in path_cells:
		path_points.append(grid.map_to_local(cell))

	path_points.insert(0, grid.map_to_local(current_cell))

	_path_line.points = PackedVector2Array(path_points)
	_path_line.visible = true

func update_range_indicator(grid: Node2D, unit_manager: UnitManager, terrain_map) -> void:
	if not is_instance_valid(_range_indicator_root):
		return
	for child in _range_indicator_root.get_children():
		child.queue_free()

	var selected_idx = unit_manager.get_selected_index()
	if selected_idx == -1:
		return

	var unit = unit_manager.get_unit(selected_idx)
	if not (unit is Unit):
		return

	var start_cell_for_range = unit.get_start_of_turn_grid_coord()

	if start_cell_for_range == Vector2i.MAX:
		start_cell_for_range = unit.get_grid_location()

	if not terrain_map.is_within_bounds(start_cell_for_range):
		return

	var movement_budget = unit.get_max_movement_points()
	var reachable = unit.compute_movement_range(start_cell_for_range, terrain_map, movement_budget)
	var hex_points = _build_hex_points(Vector2(grid.tile_set.tile_size) * 0.9, grid)
	var color = Color(0.2, 0.6, 1.0, 0.2) if unit_manager.is_player_controlled(selected_idx) else Color(1.0, 0.4, 0.4, 0.2)

	for coord in reachable:
		if unit.has_tentative_move() and coord == unit.get_tentative_grid_coord():
			var tentative_poly = Polygon2D.new()
			tentative_poly.polygon = hex_points
			tentative_poly.color = Color(1.0, 1.0, 0.0, 0.4) # Yellow for tentative
			tentative_poly.position = grid.map_to_local(coord)
			_range_indicator_root.add_child(tentative_poly)
			continue

		if coord == start_cell_for_range:
			continue
		var poly = Polygon2D.new()
		poly.polygon = hex_points
		poly.color = color
		poly.position = grid.map_to_local(coord)
		_range_indicator_root.add_child(poly)

func update_terrain_overlay(grid: Node2D, terrain_map) -> void:
	if not is_instance_valid(_terrain_overlay_root):
		return
	for child in _terrain_overlay_root.get_children():
		child.queue_free()
	if terrain_map == null or grid == null:
		return
	var tile_size := Vector2(grid.tile_set.tile_size)
	var hex_points := _build_hex_points(tile_size, grid)
	for y in range(1, terrain_map.grid_height + 1):
		for x in range(1, terrain_map.grid_width + 1):
			var coord := Vector2i(x, y)
			if not terrain_map.is_within_bounds(coord):
				continue
			var code: String = terrain_map.get_code(coord)
			var color: Color = TERRAIN_DEBUG_COLORS.get(code, Color(0.7, 0.7, 0.7, 0.35))
			var poly := Polygon2D.new()
			poly.polygon = hex_points
			poly.color = color
			poly.position = grid.map_to_local(coord)
			_terrain_overlay_root.add_child(poly)

func _build_hex_points(tile_size: Vector2, grid: Node2D = null) -> PackedVector2Array:
	var w := tile_size.x * 0.5
	var h := tile_size.y * 0.5
	var use_flat_top := false
	if grid and grid.tile_set:
		use_flat_top = (grid.tile_set.tile_offset_axis == TileSet.TILE_OFFSET_AXIS_VERTICAL)
	var sqrt3 := sqrt(3.0)
	if use_flat_top:
		var r := w
		return PackedVector2Array([
			Vector2(r, 0),
			Vector2(r * 0.5, r * sqrt3 * 0.5),
			Vector2(-r * 0.5, r * sqrt3 * 0.5),
			Vector2(-r, 0),
			Vector2(-r * 0.5, -r * sqrt3 * 0.5),
			Vector2(r * 0.5, -r * sqrt3 * 0.5),
		])
	else:
		var r := h
		return PackedVector2Array([
			Vector2(r * sqrt3 * 0.5, r * 0.5),
			Vector2(0, r),
			Vector2(-r * sqrt3 * 0.5, r * 0.5),
			Vector2(-r * sqrt3 * 0.5, -r * 0.5),
			Vector2(0, -r),
			Vector2(r * sqrt3 * 0.5, -r * 0.5),
		])

var _enemy_range_root: Node2D
var _enemy_range_visible: bool = false

func toggle_enemy_range_view() -> void:
	if not is_instance_valid(_enemy_range_root):
		_enemy_range_root = Node2D.new()
		_enemy_range_root.name = "EnemyRangeOverlay"
		_enemy_range_root.z_index = -4
		add_child(_enemy_range_root)
	_enemy_range_visible = not _enemy_range_visible
	_enemy_range_root.visible = _enemy_range_visible

func is_enemy_range_visible() -> bool:
	return _enemy_range_visible

func update_enemy_range_overlay(unit_manager: UnitManager, terrain_map, grid: Node2D) -> void:
	if not is_instance_valid(_enemy_range_root):
		return
	if not _enemy_range_visible:
		return
	for child in _enemy_range_root.get_children():
		child.queue_free()
	if unit_manager == null or terrain_map == null or grid == null:
		return
	var threatened_hexes = {}
	var units = unit_manager.get_units()
	var tile_size := Vector2(grid.tile_set.tile_size)
	var hex_points := _build_hex_points(tile_size * 0.8, grid)
	var color := Color(1.0, 0.0, 0.0, 0.15)
	for i in range(units.size()):
		var unit = units[i]
		if not (unit is Unit):
			continue
		if unit_manager.is_player_controlled(i):
			continue
		var start_coord = unit.get_grid_location()
		if not terrain_map.is_within_bounds(start_coord):
			continue
		var movement_budget = unit.get_max_movement_points()
		var reachable = unit.compute_movement_range(start_coord, terrain_map, movement_budget)
		for coord in reachable:
			threatened_hexes[coord] = true
	for coord in threatened_hexes:
		var poly := Polygon2D.new()
		poly.polygon = hex_points
		poly.color = color
		poly.position = grid.map_to_local(coord)
		poly.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_enemy_range_root.add_child(poly)
