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

func setup_hex_shape(tile_size: Vector2) -> void:
	var hex_points = _build_hex_points(tile_size)
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

	var selected_idx = unit_manager.get_selected_index()
	if selected_idx == -1:
		return

	var unit = unit_manager.get_unit(selected_idx)
	if not (unit is Unit) or not unit_manager.is_player_controlled(selected_idx):
		return

	var target_cell = grid.local_to_map(grid.to_local(mouse_pos))
	if terrain_map and not terrain_map.is_within_bounds(target_cell):
		return

	var start_cell = unit_manager.get_coord(selected_idx)

	if target_cell == start_cell:
		return

	if unit_manager.is_occupied(target_cell, selected_idx):
		return

	var path_cells = unit.get_path_to_coord(target_cell, terrain_map, start_cell)
	if path_cells.is_empty():
		return

	var path_points = []
	for cell in path_cells:
		path_points.append(grid.map_to_local(cell))

	# Prepend start position for visual continuity
	path_points.insert(0, grid.map_to_local(start_cell))

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

	var start_cell = unit_manager.get_coord(selected_idx)
	var reachable = unit.compute_movement_range(start_cell, terrain_map)
	var hex_points = _build_hex_points(Vector2(grid.tile_set.tile_size) * 0.9)
	var color = Color(0.2, 0.6, 1.0, 0.2) if unit_manager.is_player_controlled(selected_idx) else Color(1.0, 0.4, 0.4, 0.2)

	for coord in reachable:
		if coord == start_cell:
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
	var hex_points := _build_hex_points(tile_size)
	for y in range(terrain_map.grid_height):
		for x in range(terrain_map.grid_width):
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

func _build_hex_points(tile_size: Vector2) -> PackedVector2Array:
	var w := tile_size.x * 0.5
	var h := tile_size.y * 0.5
	return PackedVector2Array([
		Vector2(0, -h),
		Vector2(w, -h * 0.33),
		Vector2(w, h * 0.33),
		Vector2(0, h),
		Vector2(-w, h * 0.33),
		Vector2(-w, -h * 0.33),
	])
