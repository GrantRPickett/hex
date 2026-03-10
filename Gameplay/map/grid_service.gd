class_name GridService
extends RefCounted

## Service to abstract coordinate systems and grid validations.
## It isolates the rest of the codebase from knowing whether the grid 
## is 0-based or 1-based internally.
##
## All systems should pass "Virtual Coordinates" to this service, which
## translates them to Godot's internal coordinates if necessary.

# If the internal engine uses 0-based (TileMapLayer native)
# but level designers use 1-based (JSON maps), we handle that here.
# Currently assuming internal Godot coords are 0-based.
const IS_INTERNAL_0_BASED := true

static func is_in_bounds(coord: Vector2i, width: int, height: int) -> bool:
	if IS_INTERNAL_0_BASED:
		return coord.x >= 0 and coord.y >= 0 and coord.x < width and coord.y < height
	else:
		return coord.x >= 1 and coord.y >= 1 and coord.x <= width and coord.y <= height

static func key_of(coord: Vector2i) -> String:
	return "%s,%s" % [coord.x, coord.y]

static func to_virtual(engine_coord: Vector2i) -> Vector2i:
	# Convert from Godot internal to designer/virtual coordinates
	if IS_INTERNAL_0_BASED:
		# If designer uses 1-based but engine uses 0-based
		# return engine_coord + Vector2i(1, 1) if that was the convention
		return engine_coord
	return engine_coord

static func to_engine(virtual_coord: Vector2i) -> Vector2i:
	# Convert from virtual/designer coordinate to Godot internal
	if IS_INTERNAL_0_BASED:
		return virtual_coord
	return virtual_coord
