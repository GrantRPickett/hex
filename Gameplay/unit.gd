class_name Unit
extends Node2D

const _TerrainMapScript := preload("res://Gameplay/terrain_map.gd")
const _MovementRangeCalculatorScript := preload("res://Gameplay/movement_range_calculator.gd")

enum Faction {
	PLAYER,
	ENEMY,
	NEUTRAL
}

@export var unit_name: String = ""
@export var faction: Faction = Faction.PLAYER
@export var willpower: int = 10
@export var max_willpower: int = 10
@export var movement_points: int = 6
@export var action_range: float = 10.0
@export var attributes_path: NodePath
@export var inventory_path: NodePath

var skills: Array[StringName] = []
var _attributes: UnitAttributes
var _inventory: UnitInventory
var _item_modifier_ids: Dictionary = {}
var _turn_movement_points: int = 0
var _can_move_this_turn: bool = true
var _can_act_this_turn: bool = true
var _status_effects: Dictionary = {}
var _movement_range_cache: Dictionary = {}
static var _registered_units: Array[Unit] = []

func _ready() -> void:
	_attributes = _resolve_child(attributes_path, UnitAttributes)
	_inventory = _resolve_child(inventory_path, UnitInventory)
	if _inventory:
		_inventory.item_equipped.connect(_on_item_equipped)
		_inventory.item_unequipped.connect(_on_item_unequipped)
	if max_willpower < willpower:
		max_willpower = willpower
	refresh_turn()
	_registered_units.append(self)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_registered_units.erase(self)

func _exit_tree() -> void:
	_registered_units.erase(self)

func get_attributes() -> UnitAttributes:
	return _attributes

func get_inventory() -> UnitInventory:
	return _inventory

func get_faction_name() -> String:
	match faction:
		Faction.PLAYER:
			return "Player"
		Faction.ENEMY:
			return "Enemy"
		Faction.NEUTRAL:
			return "Neutral"
	return "Unknown"

func add_skill(skill: StringName) -> void:
	if not skills.has(skill):
		skills.append(skill)

func equip_item(item: InventoryItem) -> bool:
	if _inventory == null:
		return false
	return _inventory.equip_item(item)

func unequip_item(item: InventoryItem) -> bool:
	if _inventory == null:
		return false
	return _inventory.unequip_item(item)

func has_nearby_units(units: Array, detection_range: float) -> bool:
	return not get_units_in_range(units, detection_range).is_empty()

func get_units_in_range(units: Array, detection_range: float) -> Array:
	return _collect_units_in_range(units, detection_range)

func get_adjacent_units(units: Array, adjacency_range: float = 1.0) -> Array:
	return _collect_units_in_range(units, adjacency_range)

func get_units_in_range_by_faction(units: Array, detection_range: float, target_faction: Faction) -> Array:
	return _collect_units_in_range(
		units,
		detection_range,
		func(unit: Unit) -> bool:
			return unit.faction == target_faction
	)

func get_units_in_range_without_full_morale(units: Array, detection_range: float) -> Array:
	return _collect_units_in_range(
		units,
		detection_range,
		func(unit: Unit) -> bool:
			return not unit.is_at_full_morale()
	)

func list_goals_in_range(goals: Array, detection_range: float) -> Array:
	var result: Array = []
	for goal in goals:
		if goal == null:
			continue
		if not goal is Node2D:
			continue
		if global_position.distance_to(goal.global_position) <= detection_range:
			result.append(goal)
	return result

func act(target: Node2D) -> bool:
	if target == null:
		return false
	if not (target is Node2D):
		return false
	return global_position.distance_to(target.global_position) <= action_range

func is_at_full_morale() -> bool:
	if max_willpower <= 0:
		return true
	return willpower >= max_willpower

func refresh_turn() -> void:
	_turn_movement_points = movement_points
	_can_move_this_turn = _turn_movement_points > 0
	_can_act_this_turn = true
	_invalidate_movement_range_cache()

func has_move_available() -> bool:
	return _can_move_this_turn and _turn_movement_points > 0

func has_action_available() -> bool:
	return _can_act_this_turn

func consume_move(cost: int = 1) -> void:
	if not _can_move_this_turn:
		return
	_turn_movement_points = max(0, _turn_movement_points - cost)
	if _turn_movement_points <= 0:
		_can_move_this_turn = false
	_invalidate_movement_range_cache()

func consume_action() -> void:
	_can_act_this_turn = false

func adjust_remaining_movement(delta: int) -> void:
	_turn_movement_points = max(0, _turn_movement_points + delta)
	_can_move_this_turn = _turn_movement_points > 0
	_invalidate_movement_range_cache()

func block_movement_this_turn() -> void:
	_turn_movement_points = 0
	_can_move_this_turn = false
	_invalidate_movement_range_cache()

func block_action_this_turn() -> void:
	_can_act_this_turn = false
	_invalidate_movement_range_cache()

func get_remaining_movement_points() -> int:
	return _turn_movement_points

func get_max_movement_points() -> int:
	return movement_points

func compute_movement_range(start_coord: Vector2i, terrain_map) -> Dictionary:
	if terrain_map == null:
		return {}
	var map_version := 0
	if terrain_map.has_method("get_version"):
		map_version = terrain_map.get_version()
	var cached_coord: Vector2i = _movement_range_cache.get("coord", Vector2i(-999, -999))
	var cached_points: int = _movement_range_cache.get("points", -1)
	var cached_version: int = _movement_range_cache.get("version", -1)
	if cached_coord == start_coord and cached_points == movement_points and cached_version == map_version:
		return _movement_range_cache.get("result", {})
	var calculator := _MovementRangeCalculatorScript.new()
	var result := calculator.compute(start_coord, movement_points, terrain_map)
	_movement_range_cache = {
		"coord": start_coord,
		"points": movement_points,
		"version": map_version,
		"result": result,
	}
	return result

func apply_status_effect(effect: StringName) -> void:
	if effect.is_empty():
		return
	_status_effects[effect] = true

func has_status_effect(effect: StringName) -> bool:
	return _status_effects.get(effect, false)

func clear_status_effect(effect: StringName) -> void:
	_status_effects.erase(effect)

func on_enter_terrain(terrain: TerrainTile) -> void:
	if terrain == null:
		return
	terrain.apply_to_unit(self)

func _collect_units_in_range(units: Array, detection_range: float, filter: Callable = Callable()) -> Array:
	var result: Array = []
	for other in units:
		if other == null or other == self:
			continue
		if not (other is Unit):
			continue
		if global_position.distance_to(other.global_position) > detection_range:
			continue
		var other_unit: Unit = other
		if not filter.is_null() and not filter.call(other_unit):
			continue
		result.append(other_unit)
	return result

func _resolve_child(path: NodePath, type_class) -> Node:
	var node: Node = null
	if not path.is_empty() and has_node(path):
		node = get_node(path)
	if node == null:
		node = type_class.new()
		add_child(node)
	return node

func _on_item_equipped(item: InventoryItem) -> void:
	if _attributes == null or item == null:
		return
	var id := str(item.get_instance_id())
	_item_modifier_ids[item] = id
	_attributes.apply_modifier(id, item.attribute_modifiers)

func _on_item_unequipped(item: InventoryItem) -> void:
	if _attributes == null or item == null:
		return
	if not _item_modifier_ids.has(item):
		return
	var id = _item_modifier_ids[item]
	_attributes.remove_modifier(id)
	_item_modifier_ids.erase(item)

func _invalidate_movement_range_cache() -> void:
	_movement_range_cache.clear()

static func notify_unit_moved(coord: Vector2i) -> void:
	for index in range(_registered_units.size() - 1, -1, -1):
		var unit := _registered_units[index]
		if not is_instance_valid(unit):
			_registered_units.remove_at(index)
			continue
		unit._invalidate_cache_if_close(coord)

func _invalidate_cache_if_close(coord: Vector2i) -> void:
	if _movement_range_cache.is_empty():
		return
	var cached_coord: Vector2i = _movement_range_cache.get("coord", Vector2i(-999, -999))
	if cached_coord == Vector2i(-999, -999):
		return
	if cached_coord.distance_to(coord) <= 10:
		_invalidate_movement_range_cache()
