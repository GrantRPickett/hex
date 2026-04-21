class_name Target
extends Node2D

signal interacted(unit: Unit, context: CombatResult, target: Target)


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
@export var base_willpower: int = 10:
	set(v):
		base_willpower = v
		if not is_inside_tree():
			willpower = v
		else:
			# If already in tree, we might want to preserve current willpower
			# but usually base_willpower is set during setup.
			# Let's keep it simple for now and sync if it's a fresh setup.
			if willpower == 0: willpower = v

var willpower: int = 10:
	set(v):
		if willpower != v:
			willpower = v
			willpower_changed.emit()

signal willpower_changed(target: Target)
@export var is_opposed: bool = false

var _wiggle_tween: Tween

const WIGGLE_DURATION := 0.4
const WIGGLE_ROTATION := 0.1 # Radians

func trigger_wiggle() -> void:
	if not is_instance_valid(sprite):
		return
	
	if _wiggle_tween and _wiggle_tween.is_valid():
		return # Already wiggling
	
	_wiggle_tween = create_tween().set_loops(3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Wiggle rotation
	_wiggle_tween.tween_property(sprite, "rotation", WIGGLE_ROTATION, WIGGLE_DURATION * 0.25)
	_wiggle_tween.tween_property(sprite, "rotation", -WIGGLE_ROTATION, WIGGLE_DURATION * 0.5)
	_wiggle_tween.tween_property(sprite, "rotation", 0.0, WIGGLE_DURATION * 0.25)
	
	_wiggle_tween.finished.connect(func(): _wiggle_tween = null)

func stop_wiggle() -> void:
	if _wiggle_tween and _wiggle_tween.is_valid():
		_wiggle_tween.kill()
	_wiggle_tween = null
	if is_instance_valid(sprite):
		sprite.rotation = 0.0

func get_interaction_type() -> String:
	return GameConstants.Activity.INTERACT

var _has_external_grid_coord := false
var _external_grid_coord := GameConstants.INVALID_COORD

func _ready() -> void:
	willpower = base_willpower
	TargetDiscoveryService.register_target(self)
	z_index = GameConstants.ZIndex.LOCATION # Use LOOT as baseline for non-unit targets

func _exit_tree() -> void:
	TargetDiscoveryService.unregister_target(self)

func get_current_willpower() -> int:
	return willpower

func get_max_willpower() -> int:
	return base_willpower

func set_willpower(value: int) -> void:
	willpower = value

func get_target_name() -> String:
	return name

func get_target_id() -> String:
	return id

func get_subtype_prefix() -> String:
	return get_script().get_global_name().to_lower()


## Called by Unit / InteractionHandler / Item or other sources when this target is manipulated.
func interact(unit: Unit, context: CombatResult) -> void:
	GameLogger.debug(GameLogger.Category.COMBAT, "[Target] interact: unit=%s, context=%s, target=%s" % [unit.unit_name if unit else "null", context, name])
	interacted.emit(unit, context, self )


func get_attribute(idx: GameConstants.AttributeIndex) -> int:
	match idx:
		GameConstants.AttributeIndex.GRIT: return grit
		GameConstants.AttributeIndex.FLOW: return flow
		GameConstants.AttributeIndex.GUSTO: return gusto
		GameConstants.AttributeIndex.FOCUS: return focus
		GameConstants.AttributeIndex.SHINE: return shine
		GameConstants.AttributeIndex.SHADE: return shade
	return 0

func get_best_attribute_index() -> int:
	var best_idx: int = 0
	var best_val: int = -999
	for i in range(6):
		var val = get_attribute(i as GameConstants.AttributeIndex)
		if val > best_val:
			best_val = val
			best_idx = i
	return best_idx

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
	var default_radius: float = GameConstants.TARGET_RADIUS
	return world_pos.distance_to(global_position) <= default_radius
