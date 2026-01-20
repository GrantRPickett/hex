class_name GridController
extends Node

var _grid: Node2D

func setup(grid: Node2D) -> void:
	_grid = grid

func configure_tileset() -> void:
	if not is_instance_valid(_grid):
		return

	if _grid.tile_set == null or _grid.tile_set.tile_shape != TileSet.TILE_SHAPE_HEXAGON:
		var new_ts: TileSet
		if _grid.tile_set:
			new_ts = _grid.tile_set.duplicate(true)
		else:
			new_ts = TileSet.new()
			new_ts.tile_size = Vector2i(64, 64)

		new_ts.tile_shape = TileSet.TILE_SHAPE_HEXAGON
		new_ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
		if new_ts.tile_size == Vector2i.ZERO:
			new_ts.tile_size = Vector2i(96, 96)
		_grid.tile_set = new_ts

func build_grid(width: int, height: int) -> void:
	if not is_instance_valid(_grid):
		return
	_grid.clear()
	for q in width:
		for r in height:
			_grid.set_cell(Vector2i(q, r), 0, Vector2i.ZERO)