class_name VisualOverlayBuilder
extends RefCounted

## Helper class for building complex grid overlays.
## Reduces the complexity of GridVisuals by centralizing polygon creation and hex math.

var _overlay_points: PackedVector2Array
var _grid: TileMapLayer

func _init(grid: TileMapLayer, scale_factor: float = 1.0) -> void:
	_grid = grid
	_overlay_points = _build_hex_points(Vector2(grid.tile_set.tile_size) * scale_factor, grid)

func create_polygon(coord: Vector2i, color: Color, texture: Texture2D = null) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = _overlay_points
	
	if texture:
		poly.texture = texture
		poly.texture_scale = Vector2.ONE
		poly.texture_offset = Vector2(texture.get_size()) / 2.0
	else:
		poly.color = color

	poly.position = _grid.map_to_local(coord)
	return poly

func _build_hex_points(tile_size: Vector2, grid: TileMapLayer) -> PackedVector2Array:
	var w := tile_size.x * 0.5
	var h := tile_size.y * 0.5
	var use_flat_top := (grid.tile_set.tile_offset_axis == TileSet.TILE_OFFSET_AXIS_VERTICAL)

	if use_flat_top:
		var q := tile_size.x * 0.25
		return PackedVector2Array([
			Vector2(q, -h), Vector2(w, 0), Vector2(q, h),
			Vector2(-q, h), Vector2(-w, 0), Vector2(-q, -h)
		])
	else:
		var q := tile_size.y * 0.25
		return PackedVector2Array([
			Vector2(w, -q), Vector2(0, -h), Vector2(-w, -q),
			Vector2(-w, q), Vector2(0, h), Vector2(w, q)
		])
