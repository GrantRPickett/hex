class_name Target
extends Node2D

signal interacted(unit: Unit, context: Dictionary)

const COMBAT_ATTRIBUTE_NAMES := GameConstants.Attributes.COMBAT_ATTRIBUTES
const ATTRIBUTE_NAMES := GameConstants.Attributes.ALL_ATTRIBUTES

@export var sprite: Sprite2D
@export var grid_map: TileMapLayer

@export_group("Core Attributes")
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
	interacted.emit(unit, context)


func get_attribute(attr_name: String) -> int:
	var normalized_name = attr_name.to_lower()
	if normalized_name == "willpower" and not ("willpower" in self ):
		return base_willpower
	if normalized_name in ATTRIBUTE_NAMES:
		return int(get(normalized_name))
	return 0

func get_grid_location() -> Vector2i:
	return MapDiscovery.get_grid_location(self, grid_map, _external_grid_coord if _has_external_grid_coord else GameConstants.INVALID_COORD)

func snap_to_grid() -> void:
	var coord = MapDiscovery.snap_to_grid(self, grid_map)
	if coord != GameConstants.INVALID_COORD:
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
	return MapDiscovery.get_distance(self, other)

func is_pixel_inside(world_pos: Vector2) -> bool:
	return MapDiscovery.is_pixel_inside(self, world_pos, sprite)
