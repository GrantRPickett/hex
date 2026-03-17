class_name Target
extends Node2D

signal interacted(unit: Unit, context: Dictionary, target: Target)


@export var sprite: Sprite2D
@export var grid_map: TileMapLayer

@export_group("Core Attributes")
## Unlocalized ID used for task matching and persistent identification.
@export var id: String = ""
@export var grit: int = 6
@export var flow: int = 6
@export var gusto: int = 6
@export var focus: int = 6
@export var shine: int = 6
@export var shade: int = 6
@export var base_willpower: int = 1

var _has_external_grid_coord := false
var _external_grid_coord := GameConstants.INVALID_COORD

func interact(unit: Unit, context: Dictionary = {}) -> void:
	print_debug("[Target] interact: unit=%s, context=%s, target=%s" % [unit.unit_name if unit else "null", context, name])
	interacted.emit(unit, context, self )


func get_attribute(idx: GameConstants.AttributeIndex) -> int:
	match idx:
		GameConstants.AttributeIndex.GRIT: return grit
		GameConstants.AttributeIndex.FLOW: return flow
		GameConstants.AttributeIndex.GUSTO: return gusto
		GameConstants.AttributeIndex.FOCUS: return focus
		GameConstants.AttributeIndex.SHINE: return shine
		GameConstants.AttributeIndex.SHADE: return shade
		GameConstants.AttributeIndex.WILLPOWER: return base_willpower
	return 0

## Convenience method for string-based attribute lookup
func get_attribute_by_name(attr_name: String) -> int:
	var idx = GameConstants.get_attribute_index(attr_name)
	return get_attribute(idx)

func get_attribute_by_index(idx: GameConstants.AttributeIndex) -> int:
	if idx < 0 or idx > 6:
		return 0
	return get_attribute(idx as GameConstants.AttributeIndex)


func get_grid_location() -> Vector2i:
	if _has_external_grid_coord:
		return _external_grid_coord

	if is_instance_valid(grid_map):
		return grid_map.local_to_map(position)

	var parent = get_parent()
	if parent is TileMapLayer:
		return parent.local_to_map(position)

	return GameConstants.INVALID_COORD

func snap_to_grid() -> void:
	var grid: TileMapLayer = grid_map
	if not is_instance_valid(grid) and get_parent() is TileMapLayer:
		grid = get_parent()

	if is_instance_valid(grid) and grid.tile_set:
		var coord := grid.local_to_map(position)
		position = grid.map_to_local(coord)
		set_external_grid_coord(coord)

func set_external_grid_coord(coord: Vector2i) -> void:
	if coord == GameConstants.INVALID_COORD:
		clear_external_grid_coord()
		return
	_has_external_grid_coord = true
	_external_grid_coord = coord

func clear_external_grid_coord() -> void:
	_has_external_grid_coord = false
	_external_grid_coord = GameConstants.INVALID_COORD

func has_external_grid_coord() -> bool:
	return _has_external_grid_coord

func distance_to_target(other: Target) -> int:
	if not is_instance_valid(other):
		return GameConstants.INFINITY_DISTANCE

	var axis := TileSet.TILE_OFFSET_AXIS_VERTICAL
	if is_instance_valid(grid_map) and grid_map.tile_set:
		axis = grid_map.tile_set.tile_offset_axis

	return HexLib.get_distance(get_grid_location(), other.get_grid_location(), axis)

func is_pixel_inside(world_pos: Vector2) -> bool:
	if is_instance_valid(sprite):
		var rect = sprite.get_global_rect()
		return rect.has_point(world_pos)
	var default_radius: float = 32.0
	return world_pos.distance_to(global_position) <= default_radius
