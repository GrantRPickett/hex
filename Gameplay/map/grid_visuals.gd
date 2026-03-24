class_name GridVisuals
extends Node2D

# --- Overlay Color Constants (Accessibility Focused) ---
const COLOR_HOVER := GameConstants.Colors.GRID_HOVER
const COLOR_PATH_LINE := GameConstants.Colors.GRID_PATH_LINE
const COLOR_THREATENED_PATH := GameConstants.Colors.GRID_THREATENED_PATH
const COLOR_RANGE_PLAYER := GameConstants.Colors.GRID_RANGE_PLAYER
const COLOR_RANGE_ENEMY := GameConstants.Colors.GRID_RANGE_ENEMY
const COLOR_RANGE_TENTATIVE := GameConstants.Colors.GRID_RANGE_TENTATIVE
const COLOR_AOO_THREAT := GameConstants.Colors.GRID_AOO_THREAT
const COLOR_ENEMY_RANGE_FULL := GameConstants.Colors.GRID_ENEMY_RANGE_FULL
const COLOR_DIALOGUE_INDICATOR := GameConstants.Colors.GRID_DIALOGUE_INDICATOR
const COLOR_LOYALTY_PLAYER := GameConstants.Colors.GRID_LOYALTY_PLAYER
const COLOR_LOYALTY_ENEMY := GameConstants.Colors.GRID_LOYALTY_ENEMY
const COLOR_LOYALTY_NEUTRAL := GameConstants.Colors.GRID_LOYALTY_NEUTRAL

var _hover_indicator: Polygon2D
var _path_line: Line2D
var _range_indicator_root: Node2D
var _terrain_overlay_root: Node2D
var _enemy_range_root: Node2D
var _enemy_range_visible: bool = false
var _aoo_threat_root: Node2D
var _threatened_path_hex: Polygon2D
var _dialogue_indicator_root: Node2D
var _loyalty_indicator_root: Node2D
var _suppress_updates := false

var _texture_cache: Dictionary = {}

func _ready() -> void:
	_hover_indicator = Polygon2D.new()
	_hover_indicator.color = COLOR_HOVER
	_hover_indicator.visible = false
	add_child(_hover_indicator)

	_path_line = Line2D.new()
	_path_line.width = GameConstants.PATH_WIDTH
	_path_line.default_color = COLOR_PATH_LINE
	_path_line.z_index = GameConstants.ZIndex.PATH_LINE
	_path_line.visible = false
	add_child(_path_line)

	_range_indicator_root = Node2D.new()
	_range_indicator_root.name = "RangeIndicator"
	_range_indicator_root.z_index = GameConstants.ZIndex.RANGE_INDICATOR # ON TOP of terrain
	add_child(_range_indicator_root)

	_terrain_overlay_root = Node2D.new()
	_terrain_overlay_root.name = "TerrainOverlay"
	_terrain_overlay_root.z_index = GameConstants.ZIndex.TERRAIN # Just above base grid
	add_child(_terrain_overlay_root)

	_aoo_threat_root = Node2D.new()
	_aoo_threat_root.name = "AoOThreatOverlay"
	_aoo_threat_root.z_index = GameConstants.ZIndex.AOO_THREAT
	add_child(_aoo_threat_root)

	_dialogue_indicator_root = Node2D.new()
	_dialogue_indicator_root.name = "DialogueIndicatorOverlay"
	_dialogue_indicator_root.z_index = GameConstants.ZIndex.DIALOGUE_INDICATOR
	add_child(_dialogue_indicator_root)

	_loyalty_indicator_root = Node2D.new()
	_loyalty_indicator_root.name = "LoyaltyIndicatorOverlay"
	_loyalty_indicator_root.z_index = GameConstants.ZIndex.TERRAIN # Above terrain, below path/units
	add_child(_loyalty_indicator_root)

	_threatened_path_hex = Polygon2D.new()
	_threatened_path_hex.color = COLOR_THREATENED_PATH
	_threatened_path_hex.visible = false
	_threatened_path_hex.z_index = GameConstants.ZIndex.THREATENED_PATH
	add_child(_threatened_path_hex)

func set_suppress_updates(enabled: bool) -> void:
	if _suppress_updates == enabled:
		return
	_suppress_updates = enabled
	if _suppress_updates:
		if is_instance_valid(_range_indicator_root):
			_clear_children(_range_indicator_root)
		if is_instance_valid(_aoo_threat_root):
			_clear_children(_aoo_threat_root)
		if is_instance_valid(_loyalty_indicator_root):
			_clear_children(_loyalty_indicator_root)
		if is_instance_valid(_path_line):
			_path_line.visible = false
		if is_instance_valid(_threatened_path_hex):
			_threatened_path_hex.visible = false

func setup_hex_shape(tile_size: Vector2, grid: TileMapLayer = null) -> void:
	var hex_points: PackedVector2Array = _build_hex_points(tile_size, grid)
	_hover_indicator.polygon = hex_points

func update_hover_indicator(mouse_pos: Vector2, grid: TileMapLayer, _unit_manager: UnitManager, terrain_map: TerrainMap = null) -> void:
	if not is_instance_valid(_hover_indicator):
		return

	var cell: Vector2i = grid.local_to_map(grid.to_local(mouse_pos))

	if terrain_map and not terrain_map.is_within_bounds(cell):
		_hover_indicator.visible = false
		return

	_hover_indicator.visible = true
	_hover_indicator.position = grid.map_to_local(cell)

func update_path_preview(grid: TileMapLayer, path: Array[Vector2i], is_tentative: bool = false) -> void:
	if not is_instance_valid(_path_line):
		_threatened_path_hex.visible = false
		return
	_path_line.visible = false
	_path_line.clear_points()

	if path.is_empty():
		_threatened_path_hex.visible = false
		return

	var path_points: Array[Vector2] = []
	for cell: Vector2i in path:
		path_points.append(grid.map_to_local(cell))

	_path_line.points = PackedVector2Array(path_points)
	_path_line.visible = true
	
	if not is_tentative:
		_threatened_path_hex.visible = false

func update_range_indicator(grid: TileMapLayer, reachable: ReachableState) -> void:
	if _suppress_updates or not is_instance_valid(_range_indicator_root):
		return
	_clear_children(_range_indicator_root)
	_range_indicator_root.scale = Vector2(1.0, 1.0)
	if is_instance_valid(_aoo_threat_root):
		_clear_children(_aoo_threat_root)

	if reachable == null or reachable.coords.is_empty():
		return

	_draw_range_indicators(grid, reachable)

func update_terrain_overlay(grid: TileMapLayer, terrain_map: TerrainMap) -> void:
	if not is_instance_valid(_terrain_overlay_root):
		return
	_clear_children(_terrain_overlay_root)
	if terrain_map == null or grid == null:
		return

	# ENFORCE: GridVisuals should be a child of Grid to inherit transforms perfectly
	if get_parent() != grid:
		if get_parent():
			get_parent().remove_child(self)
		grid.add_child(self)

	var tile_size := Vector2(grid.tile_set.tile_size)
	var hex_points := _build_hex_points(tile_size, grid)

	for y in range(terrain_map.grid_height):
		for x in range(terrain_map.grid_width):
			var coord := Vector2i(x, y)
			if not terrain_map.is_within_bounds(coord):
				continue

			var code: String = terrain_map.get_code(coord)
			var color: Color = terrain_map.get_color_for_code(code)
			# We keep alpha high for texturing
			color.a = 1.0

			var terrain := terrain_map.get_terrain(coord)
			var texture: Texture2D = null
			if terrain and not terrain.texture_path.is_empty():
				texture = _get_cached_texture(terrain.texture_path)

			var poly := _create_overlay_polygon(coord, color, hex_points, grid, texture)
			_terrain_overlay_root.add_child(poly)


# update_terrain_overlay was removed (native TileSet texturing is now used)

func toggle_enemy_range_view() -> void:
	if not is_instance_valid(_enemy_range_root):
		_enemy_range_root = Node2D.new()
		_enemy_range_root.name = "EnemyRangeOverlay"
		_enemy_range_root.z_index = GameConstants.ZIndex.ENEMY_RANGE
		add_child(_enemy_range_root)
	_enemy_range_visible = not _enemy_range_visible
	_enemy_range_root.visible = _enemy_range_visible

func is_enemy_range_visible() -> bool:
	return _enemy_range_visible

func update_enemy_range_overlay(grid: TileMapLayer, threatened_hexes: Dictionary) -> void:
	if _suppress_updates or not is_instance_valid(_enemy_range_root) or not _enemy_range_visible:
		return
	_clear_children(_enemy_range_root)
	if grid == null or threatened_hexes.is_empty():
		return

	_draw_threatened_hexes_overlay(threatened_hexes, grid)

func update_dialogue_indicators(grid: TileMapLayer, unit_manager: UnitManager, dialogue_service: DialogueActionService) -> void:
	if not is_instance_valid(_dialogue_indicator_root):
		return
	_clear_children(_dialogue_indicator_root)

	if unit_manager == null or dialogue_service == null or grid == null:
		return

	var selected_unit: Unit = unit_manager.get_selected_unit()
	if not is_instance_valid(selected_unit) or not unit_manager.is_player_controlled(unit_manager.get_selected_index()):
		return

	var units: Array[Unit] = unit_manager.get_all_units()
	var tile_size := Vector2(grid.tile_set.tile_size)
	var hex_points := _build_hex_points(tile_size * GameConstants.OverlayScale.DIALOGUE, grid) # Match range indicator size
	var _color := GameConstants.Colors.GRID_DIALOGUE_INDICATOR # Gold/Yellow for quest/talk

	for target_unit in units:
		if target_unit == selected_unit:
			continue

		if dialogue_service.has_active_dialogue_with(selected_unit, target_unit):
			GameLogger.debug(GameLogger.Category.MAP, "GridVisuals: Drawing dialogue indicator for %s" % target_unit.unit_name)
			var coord: Vector2i = target_unit.get_grid_location()
			var poly := _create_overlay_polygon(coord, Color.YELLOW, hex_points, grid)
			_dialogue_indicator_root.add_child(poly)

# Private Helpers

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _try_draw_tentative_path_preview(unit: Unit, grid: TileMapLayer, terrain_map: TerrainMap) -> bool:
	if not unit.movement.has_tentative_move():
		return false


	var tentative_path: Array = unit.movement.get_tentative_path()
	if tentative_path.is_empty():
		return true

	var start_cell: Vector2i = unit.movement.get_start_of_turn_grid_coord()
	if start_cell == Vector2i.MAX:
		start_cell = unit.get_grid_location()

	if not terrain_map.is_within_bounds(start_cell):
		return true

	var path_points: Array = []
	for cell: Vector2i in tentative_path:
		path_points.append(grid.map_to_local(cell))
	path_points.insert(0, grid.map_to_local(start_cell))


	_path_line.points = PackedVector2Array(path_points)
	_path_line.visible = true
	return true

func _draw_hover_path_preview(unit: Unit, mouse_pos: Vector2, grid: TileMapLayer, unit_manager: UnitManager, terrain_map: TerrainMap) -> void:
	var current_cell: Vector2i = unit.get_grid_location()
	if not terrain_map.is_within_bounds(current_cell):
		return

	var target_cell: Vector2i = grid.local_to_map(grid.to_local(mouse_pos))
	if not terrain_map.is_within_bounds(target_cell) or target_cell == current_cell:
		return

	var selected_idx: int = unit_manager.get_selected_index()
	if unit_manager.is_occupied(target_cell, selected_idx):
		return

	var movement_budget: int = unit.movement.get_remaining_movement_points()
	var path_cells: Array[Vector2i] = unit.movement.get_path_to_coord(target_cell, terrain_map, current_cell, movement_budget)
	if path_cells.is_empty():
		return

	var path_points: Array[Vector2] = []
	for cell: Vector2i in path_cells:
		path_points.append(grid.map_to_local(cell))
	path_points.insert(0, grid.map_to_local(current_cell))

	_path_line.points = PackedVector2Array(path_points)
	_path_line.visible = true

func _draw_range_indicators(grid: TileMapLayer, reachable: ReachableState) -> void:
	var hex_points: PackedVector2Array = _build_hex_points(Vector2(grid.tile_set.tile_size) * GameConstants.OverlayScale.RANGE, grid)
	var color = COLOR_RANGE_PLAYER if reachable.unit_index >= 0 and reachable.lookup.get("player_controlled", true) else COLOR_RANGE_ENEMY # Note: we might need to pass faction info in ReachableState

	for coord in reachable.coords:
		if coord == reachable.movement_origin:
			continue

		var poly_color = color
		var metadata = reachable.lookup.get(coord, {})
		if metadata.get("is_tentative", false):
			poly_color = COLOR_RANGE_TENTATIVE

		var poly = _create_overlay_polygon(coord, poly_color, hex_points, grid)
		_range_indicator_root.add_child(poly)

func draw_aoo_threats(grid: TileMapLayer, threatened_hexes: Dictionary) -> void:
	if not is_instance_valid(_aoo_threat_root):
		return

	var tile_size := Vector2(grid.tile_set.tile_size)
	var hex_points := _build_hex_points(tile_size * GameConstants.OverlayScale.THREAT, grid)
	var color := COLOR_AOO_THREAT

	for coord in threatened_hexes.keys():
		var poly := _create_overlay_polygon(coord, color, hex_points, grid)
		_aoo_threat_root.add_child(poly)

# _get_threatened_hexes was removed (logic moved to services)

func _draw_threatened_hexes_overlay(threatened_hexes: Dictionary, grid: TileMapLayer) -> void:
	var tile_size := Vector2(grid.tile_set.tile_size)
	var hex_points := _build_hex_points(tile_size * GameConstants.OverlayScale.THREAT, grid)
	var color := COLOR_ENEMY_RANGE_FULL
	for coord in threatened_hexes:
		var poly := _create_overlay_polygon(coord, color, hex_points, grid)
		_enemy_range_root.add_child(poly)

func _create_overlay_polygon(coord: Vector2i, color: Color, hex_points: PackedVector2Array, grid: TileMapLayer, texture: Texture2D = null) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = hex_points
	
	if texture:
		# The user insists on NO UV arrays and NO default colors for textured hexes.
		poly.texture = texture
		
		# Centering the 1:1 pixel mapping to the actual tile center.
		# This ensures we don't see the "seams" of the texture wrapping at (0,0).
		poly.texture_scale = Vector2.ONE
		poly.texture_offset = Vector2(texture.get_size()) / 2.0
	else:
		poly.color = color
		
	poly.position = grid.map_to_local(coord)
	return poly

func _get_cached_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path]
	if ResourceLoader.exists(path):
		var tex = ResourceLoader.load(path) as Texture2D
		_texture_cache[path] = tex
		return tex
	return null

func _build_hex_points(tile_size: Vector2, grid: TileMapLayer = null) -> PackedVector2Array:
	var w := tile_size.x * 0.5
	var h := tile_size.y * 0.5
	var use_flat_top := false
	if grid and grid.tile_set:
		use_flat_top = (grid.tile_set.tile_offset_axis == TileSet.TILE_OFFSET_AXIS_VERTICAL)

	if use_flat_top:
		var q := tile_size.x * 0.25
		return PackedVector2Array([
			Vector2(q, -h),
			Vector2(w, 0),
			Vector2(q, h),
			Vector2(-q, h),
			Vector2(-w, 0),
			Vector2(-q, -h),
		])
	else:
		var q := tile_size.y * 0.25
		return PackedVector2Array([
			Vector2(w, -q),
			Vector2(0, -h),
			Vector2(-w, -q),
			Vector2(-w, q),
			Vector2(0, h),
			Vector2(w, q),
		])

func refresh_visuals(unit_manager: UnitManager, terrain_map: TerrainMap, grid: TileMapLayer) -> void:
	if _suppress_updates:
		return
	update_loyalty_indicators(unit_manager, terrain_map, grid)
	# Add other general updates here if they don't require external services (like dialogue)
	# or if those services are available as globals/autoloads.

func update_loyalty_indicators(unit_manager: UnitManager, terrain_map: TerrainMap, grid: TileMapLayer) -> void:
	if _suppress_updates or not is_instance_valid(_loyalty_indicator_root):
		return
	_clear_children(_loyalty_indicator_root)

	if unit_manager == null or terrain_map == null or grid == null:
		return

	var units: Array[Unit] = unit_manager.get_all_units()
	var tile_size := Vector2(grid.tile_set.tile_size)
	var hex_points := _build_hex_points(tile_size * GameConstants.OverlayScale.THREAT, grid)

	for unit in units:
		if not is_instance_valid(unit) or unit.faction != GameConstants.Faction.NEUTRAL:
			continue

		if not is_instance_valid(unit.loyalty):
			continue

		# Check if unit is convincable (NEUTRAL and not STATIC/unpersuatable)
		var is_convincable: bool = unit.faction == GameConstants.Faction.NEUTRAL and \
			unit.neutral_can_be_persuaded and \
			unit.loyalty_type != GameConstants.Faction.STATIC

		if not is_convincable:
			continue

		var leaning: int = unit.loyalty.neutral_loyalty
		var color: Color = Color.TRANSPARENT

		match leaning:
			GameConstants.Faction.PLAYER:
				color = COLOR_LOYALTY_PLAYER
			GameConstants.Faction.ENEMY:
				color = COLOR_LOYALTY_ENEMY
			GameConstants.Faction.NEUTRAL:
				color = COLOR_LOYALTY_NEUTRAL
			_:
				continue

		if color != Color.TRANSPARENT:
			var coord: Vector2i = unit.get_grid_location()
			var poly := _create_overlay_polygon(coord, color, hex_points, grid)
			_loyalty_indicator_root.add_child(poly)
