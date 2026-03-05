class_name GridVisuals
extends Node2D


var _hover_indicator: Polygon2D
var _path_line: Line2D
var _range_indicator_root: Node2D
var _terrain_overlay_root: Node2D
var _enemy_range_root: Node2D
var _enemy_range_visible: bool = false
var _aoo_threat_root: Node2D
var _threatened_path_hex: Polygon2D = null
var _dialogue_indicator_root: Node2D

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

	_aoo_threat_root = Node2D.new()
	_aoo_threat_root.name = "AoOThreatOverlay"
	_aoo_threat_root.z_index = -2
	add_child(_aoo_threat_root)

	_dialogue_indicator_root = Node2D.new()
	_dialogue_indicator_root.name = "DialogueIndicatorOverlay"
	_dialogue_indicator_root.z_index = -2
	add_child(_dialogue_indicator_root)

	_threatened_path_hex = Polygon2D.new()
	_threatened_path_hex.color = Color(1.0, 0.0, 0.0, 0.75)
	_threatened_path_hex.visible = false
	_threatened_path_hex.z_index = -1
	add_child(_threatened_path_hex)

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
		_threatened_path_hex.visible = false
		return
	_path_line.visible = false
	_path_line.clear_points()

	var selected_idx = unit_manager.get_selected_index()
	if selected_idx == -1:
		return

	var unit = unit_manager.get_unit(selected_idx)
	if not (unit is Unit) or not unit_manager.is_player_controlled(selected_idx):
		return

	if _try_draw_tentative_path_preview(unit, grid, terrain_map):
		_threatened_path_hex.visible = false
		return

	_draw_hover_path_preview(unit, mouse_pos, grid, unit_manager, terrain_map)

func update_range_indicator(grid: Node2D, unit_manager: UnitManager, terrain_map) -> void:
	if not is_instance_valid(_range_indicator_root):
		return
	_clear_children(_range_indicator_root)
	if is_instance_valid(_aoo_threat_root):
		_clear_children(_aoo_threat_root)

	var selected_idx = unit_manager.get_selected_index()
	if selected_idx == -1:
		return

	var unit = unit_manager.get_unit(selected_idx)
	if not (unit is Unit):
		return

	var start_cell = unit.movement.get_start_of_turn_grid_coord()
	if start_cell == Vector2i.MAX:
		start_cell = unit.get_grid_location()

	if not terrain_map.is_within_bounds(start_cell):
		return

	var movement_budget = unit.movement.get_remaining_movement_points()
	var reachable = unit.movement.compute_movement_range(start_cell, terrain_map, movement_budget)
	_draw_range_indicators(grid, unit, unit_manager, reachable, start_cell)
	_draw_aoo_threats(grid, unit, unit_manager, terrain_map)

func update_terrain_overlay(grid: Node2D, terrain_map) -> void:
	if not is_instance_valid(_terrain_overlay_root):
		return
	_clear_children(_terrain_overlay_root)
	if terrain_map == null or grid == null:
		return

	var tile_size := Vector2(grid.tile_set.tile_size)
	var hex_points := _build_hex_points(tile_size, grid)
	for y in range(terrain_map.grid_height):
		for x in range(terrain_map.grid_width):
			var coord := Vector2i(x, y)
			if not terrain_map.is_within_bounds(coord):
				continue
			var code: String = terrain_map.get_code(coord)
			var color: Color = terrain_map.get_color_for_code(code)
			color.a = 0.35
			var poly := _create_overlay_polygon(coord, color, hex_points, grid)
			_terrain_overlay_root.add_child(poly)

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
	if not is_instance_valid(_enemy_range_root) or not _enemy_range_visible:
		return
	_clear_children(_enemy_range_root)
	if unit_manager == null or terrain_map == null or grid == null:
		return

	var threatened_hexes = _get_threatened_hexes(unit_manager, terrain_map)
	_draw_threatened_hexes_overlay(threatened_hexes, grid)

func update_dialogue_indicators(grid: Node2D, unit_manager: UnitManager, dialogue_service: DialogueActionService) -> void:
	if not is_instance_valid(_dialogue_indicator_root):
		return
	_clear_children(_dialogue_indicator_root)

	if unit_manager == null or dialogue_service == null or grid == null:
		return

	var selected_unit = unit_manager.get_selected_unit()
	if not is_instance_valid(selected_unit) or not unit_manager.is_player_controlled(unit_manager.get_selected_index()):
		return

	var units: Array[Unit] = unit_manager.get_all_units()
	var tile_size := Vector2(grid.tile_set.tile_size)
	var hex_points := _build_hex_points(tile_size * 0.95, grid) # Match range indicator size
	var color := Color(1.0, 0.85, 0.0, 0.5) # Gold/Yellow for quest/talk

	for target_unit in units:
		if target_unit == selected_unit:
			continue

		if dialogue_service.has_active_dialogue_with(selected_unit, target_unit):
			print_debug("GridVisuals: Drawing dialogue indicator for %s" % target_unit.unit_name)
			var coord = target_unit.get_grid_location()
			var poly := _create_overlay_polygon(coord, color, hex_points, grid)
			_dialogue_indicator_root.add_child(poly)

# Private Helpers

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _try_draw_tentative_path_preview(unit: Unit, grid: Node2D, terrain_map) -> bool:
	if not unit.movement.has_tentative_move():
		return false


	var tentative_path = unit.movement.get_tentative_path()
	if tentative_path.is_empty():
		return true

	var start_cell = unit.movement.get_start_of_turn_grid_coord()
	if start_cell == Vector2i.MAX:
		start_cell = unit.get_grid_location()

	if not terrain_map.is_within_bounds(start_cell):
		return true

	var path_points = []
	for cell in tentative_path:
		path_points.append(grid.map_to_local(cell))
	path_points.insert(0, grid.map_to_local(start_cell))


	_path_line.points = PackedVector2Array(path_points)
	_path_line.visible = true
	return true

func _draw_hover_path_preview(unit: Unit, mouse_pos: Vector2, grid: Node2D, unit_manager: UnitManager, terrain_map) -> void:
	var current_cell = unit.get_grid_location()
	if not terrain_map.is_within_bounds(current_cell):
		return

	var target_cell = grid.local_to_map(grid.to_local(mouse_pos))
	if not terrain_map.is_within_bounds(target_cell) or target_cell == current_cell:
		return

	var selected_idx = unit_manager.get_selected_index()
	if unit_manager.is_occupied(target_cell, selected_idx):
		return

	var movement_budget = unit.movement.get_remaining_movement_points()
	var path_cells = unit.movement.get_path_to_coord(target_cell, terrain_map, current_cell, movement_budget)
	if path_cells.is_empty():
		return

	var path_points = []
	for cell in path_cells:
		path_points.append(grid.map_to_local(cell))
	path_points.insert(0, grid.map_to_local(current_cell))

	_path_line.points = PackedVector2Array(path_points)
	_path_line.visible = true

func _draw_range_indicators(grid: Node2D, unit: Unit, unit_manager: UnitManager, reachable: Dictionary, start_cell: Vector2i) -> void:
	var hex_points = _build_hex_points(Vector2(grid.tile_set.tile_size) * 0.9, grid)
	var selected_idx = unit_manager.get_unit_index(unit)
	var color = Color(0.2, 0.6, 1.0, 0.2) if unit_manager.is_player_controlled(selected_idx) else Color(1.0, 0.4, 0.4, 0.2)
	var tentative_color = Color(1.0, 1.0, 0.0, 0.4)

	for coord in reachable:
		if coord == start_cell:
			continue

		var poly_color = color
		if unit.movement.has_tentative_move() and coord == unit.movement.get_tentative_grid_coord():
			poly_color = tentative_color

		var poly = _create_overlay_polygon(coord, poly_color, hex_points, grid)
		_range_indicator_root.add_child(poly)

func _draw_aoo_threats(grid: Node2D, unit: Unit, unit_manager: UnitManager, terrain_map) -> void:
	if not is_instance_valid(_aoo_threat_root) or not unit.movement:
		return

	var threatened_hexes = unit.movement.get_threatened_hexes(unit_manager, terrain_map)
	var tile_size := Vector2(grid.tile_set.tile_size)
	var hex_points := _build_hex_points(tile_size * 0.8, grid)
	var color := Color(1.0, 0.4, 0.0, 0.4) # Orange for threat

	for coord in threatened_hexes:
		var poly := _create_overlay_polygon(coord, color, hex_points, grid)
		_aoo_threat_root.add_child(poly)

func _get_threatened_hexes(unit_manager: UnitManager, terrain_map) -> Dictionary:
	var threatened_hexes := {}
	var units: Array[Unit] = unit_manager.get_all_units()
	for i in range(units.size()):
		var unit = units[i]
		if not (unit is Unit) or unit_manager.is_player_controlled(i):
			continue

		var start_coord = unit.get_grid_location()
		if not terrain_map.is_within_bounds(start_coord):
			continue

		var movement_budget = unit.movement.get_max_movement_points() if unit.movement else 0
		var reachable = unit.movement.compute_movement_range(start_coord, terrain_map, movement_budget)
		for coord in reachable:
			threatened_hexes[coord] = true
	return threatened_hexes

func _draw_threatened_hexes_overlay(threatened_hexes: Dictionary, grid: Node2D) -> void:
	var tile_size := Vector2(grid.tile_set.tile_size)
	var hex_points := _build_hex_points(tile_size * 0.8, grid)
	var color := Color(1.0, 0.0, 0.0, 0.15)
	for coord in threatened_hexes:
		var poly := _create_overlay_polygon(coord, color, hex_points, grid)
		_enemy_range_root.add_child(poly)

func _create_overlay_polygon(coord: Vector2i, color: Color, hex_points: PackedVector2Array, grid: Node2D) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = hex_points
	poly.color = color
	poly.position = grid.map_to_local(coord)
	return poly

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

func show_threatened_path_hex(coord: Vector2i, grid: Node2D) -> void:
	_threatened_path_hex.polygon = _build_hex_points(Vector2(grid.tile_set.tile_size) * 0.9, grid)
	_threatened_path_hex.position = grid.map_to_local(coord)
	_threatened_path_hex.visible = true
