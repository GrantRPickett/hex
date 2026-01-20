class_name Unit
extends Target

const InventoryComponentResource := preload("res://Gameplay/components/inventory_component.gd")
const ActionPointsComponentResource := preload("res://Gameplay/components/action_points_component.gd")
const MovementRangeCacheResource := preload("res://Gameplay/components/movement_range_cache.gd")

enum Faction {
	PLAYER,
	ENEMY,
	NEUTRAL
}

@export var unit_name: String = ""
@export var faction: Faction = Faction.PLAYER
@export var action_range: float = 1.5 # Changed to grid units (1.5 covers adjacent hexes)
@export var inventory_component_template: Resource = InventoryComponentResource.new()
@export var action_points_template: Resource = ActionPointsComponentResource.new()
@export var movement_range_cache_template: Resource = MovementRangeCacheResource.new()
@export var unit_manager_path: NodePath
@export var loot_manager_path: NodePath
@export var goal_manager_path: NodePath
@export var combat_system_path: NodePath
@export var saved_items: Array[InventoryItem] = []

var skills: Array[StringName]
var _status_effects: Dictionary
var _inventory_component
var _action_points
var _movement_cache
var _unit_manager: UnitManager
var _loot_manager: LootManager
var _goal_manager: GoalManager
var _combat_system: CombatSystem
var _pending_willpower: int = -1
var _pending_max_willpower: int = -1
var _pending_movement_points: int = -1
var _is_dying: bool = false
var morale: int = 10
var consumables_active: Dictionary
var _start_of_turn_grid_coord: Vector2i = Vector2i.MAX # Stores the unit's position at the start of its turn
var _tentative_grid_coord: Vector2i = Vector2i.MAX    # Stores the unit's tentative movement position
var _tentative_path: Array[Vector2i] = []            # Stores the path for the tentative move
var _tentative_cost: int = 0                          # Stores the cost of the tentative move

var willpower: int:
	get:
		if _action_points:
			return _action_points.get_willpower()
		if _pending_willpower >= 0:
			return _pending_willpower
		if action_points_template:
			return action_points_template.get_willpower()
		return 0
	set(value):
		if _action_points:
			_action_points.set_willpower(value)
			if _action_points.get_willpower() <= 0:
				_die()
			return
		var clamp_max := _pending_max_willpower
		if clamp_max < 0 and action_points_template:
			clamp_max = action_points_template.get_max_willpower()
		if clamp_max >= 0:
			_pending_willpower = clamp(value, 0, clamp_max)
		else:
			_pending_willpower = max(0, value)

var max_willpower: int:
	get:
		if _action_points:
			return _action_points.get_max_willpower()
		if _pending_max_willpower >= 0:
			return _pending_max_willpower
		if action_points_template:
			return action_points_template.get_max_willpower()
		return 0
	set(value):
		var normalized: int = max(0, value)
		if _action_points:
			_action_points.set_max_willpower(normalized)
			return
		_pending_max_willpower = normalized
		if _pending_willpower >= 0 and _pending_willpower > _pending_max_willpower:
			_pending_willpower = _pending_max_willpower

var movement_points: int:
	get:
		if _action_points:
			return _action_points.get_movement_points()
		if _pending_movement_points >= 0:
			return _pending_movement_points
		if action_points_template:
			return action_points_template.get_movement_points()
		return 0
	set(value):
		var normalized: int = max(0, value)
		if _action_points:
			_action_points.set_movement_points(normalized)
			if _movement_cache:
				_movement_cache.invalidate()
			return
		_pending_movement_points = normalized

func _ready() -> void:
	skills = []
	_status_effects = {}
	consumables_active = {}

	if action_points_template == null:
		action_points_template = ActionPointsComponentResource.new()
	_action_points = action_points_template.duplicate(true)
	if _action_points == null:
		_action_points = ActionPointsComponentResource.new()
	if _pending_max_willpower >= 0:
		_action_points.set_max_willpower(_pending_max_willpower)
	if _pending_willpower >= 0:
		_action_points.set_willpower(_pending_willpower)
	if _pending_movement_points >= 0:
		_action_points.set_movement_points(_pending_movement_points)
	_pending_willpower = -1
	_pending_max_willpower = -1
	_pending_movement_points = -1
	if max_willpower < willpower:
		max_willpower = willpower
	_action_points.refresh_turn()

	if inventory_component_template == null:
		inventory_component_template = InventoryComponentResource.new()
	_inventory_component = inventory_component_template.duplicate(true)
	if _inventory_component == null:
		_inventory_component = InventoryComponentResource.new()
	_inventory_component.setup(self)

	var movement_callable := func() -> int:
		return movement_points
	if movement_range_cache_template == null:
		movement_range_cache_template = MovementRangeCacheResource.new()
	_movement_cache = movement_range_cache_template.duplicate(true)
	if _movement_cache == null:
		_movement_cache = MovementRangeCacheResource.new()
	_movement_cache.setup(movement_callable)

	if not unit_manager_path.is_empty() and has_node(unit_manager_path):
		var manager_node := get_node(unit_manager_path)
		if manager_node is UnitManager:
			set_unit_manager(manager_node)

	if not loot_manager_path.is_empty() and has_node(loot_manager_path):
		var loot_mgr := get_node(loot_manager_path)
		if loot_mgr is LootManager:
			set_loot_manager(loot_mgr)

	if not goal_manager_path.is_empty() and has_node(goal_manager_path):
		var goal_mgr := get_node(goal_manager_path)
		if goal_mgr is GoalManager:
			set_goal_manager(goal_mgr)

	if not combat_system_path.is_empty() and has_node(combat_system_path):
		var combat_sys := get_node(combat_system_path)
		if combat_sys is CombatSystem:
			set_combat_system(combat_sys)

	if not saved_items.is_empty():
		for item in saved_items:
			equip_item(item)
		saved_items.clear()

	refresh_turn()
	if _start_of_turn_grid_coord == Vector2i.ZERO:
		_start_of_turn_grid_coord = Vector2i.MAX

func _exit_tree() -> void:
	if _inventory_component:
		_inventory_component.cleanup()
	if _movement_cache:
		_movement_cache.cleanup()

func set_unit_manager(unit_manager: UnitManager) -> void:
	_unit_manager = unit_manager
	if _movement_cache:
		_movement_cache.set_unit_manager(unit_manager)

func set_loot_manager(manager: LootManager) -> void:
	_loot_manager = manager

func set_goal_manager(manager: GoalManager) -> void:
	_goal_manager = manager

func set_combat_system(system: CombatSystem) -> void:
	_combat_system = system

func get_attributes() -> UnitAttributes:
	if _inventory_component == null:
		return null
	return _inventory_component.get_attributes()

func get_inventory() -> UnitInventory:
	if _inventory_component == null:
		return null
	return _inventory_component.get_inventory()

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
	if _inventory_component == null:
		return false
	return _inventory_component.equip_item(item)

func unequip_item(item: InventoryItem) -> bool:
	if _inventory_component == null:
		return false
	return _inventory_component.unequip_item(item)

func has_nearby_units(units: Array, detection_range: float) -> bool:
	return not get_units_in_range(units, detection_range).is_empty()

func get_units_in_range(units: Array, detection_range: float) -> Array:
	return _collect_units_in_range(units, detection_range)

func get_adjacent_units(units: Array, adjacency_range: float = 1.5) -> Array:
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

	# Prefer grid distance if available
	if grid_map:
		var my_coord = get_grid_location()
		var target_coord = Vector2i.ZERO
		if target is Target:
			target_coord = target.get_grid_location()
		elif target.get_parent() is TileMapLayer:
			target_coord = target.get_parent().local_to_map(target.position)
		else:
			# Fallback for non-Target nodes
			target_coord = grid_map.local_to_map(grid_map.to_local(target.global_position))

		var axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
		if grid_map.tile_set:
			axis = grid_map.tile_set.tile_offset_axis
		return HexNavigator.get_hex_distance(my_coord, target_coord, axis) <= action_range

	return global_position.distance_to(target.global_position) <= (action_range * 64.0) # Fallback pixel conversion

func attack_unit(target: Unit) -> bool:
	if not has_action_available():
		return false

	if target == null:
		return false

	if not get_adjacent_units([target]).has(target):
		return false

	if _combat_system == null:
		return false

	# TODO: Allow choosing which stat pair to use
	_combat_system.execute_combat(self, target, 0)
	consume_action()
	return true

func work_on_goal(goal: Goal) -> bool:
	if not has_action_available():
		return false

	if goal == null:
		return false

	if get_grid_location() != goal.coord:
		return false

	if _goal_manager == null:
		return false

	var goal_index = -1
	for i in range(_goal_manager.get_goal_count()):
		if _goal_manager.get_target(i) == goal.coord:
			goal_index = i
			break

	if goal_index == -1:
		return false

	_goal_manager.apply_progress(goal_index, self)
	consume_action()
	return true

func aid_ally(ally: Unit) -> bool:
	if not has_action_available():
		return false

	if ally == null or ally == self:
		return false

	if not get_adjacent_units([ally]).has(ally):
		return false

	# For now, aid restores 1 willpower. This can be expanded later.
	ally.willpower += 1

	consume_action()
	return true

func is_at_full_morale() -> bool:
	if max_willpower <= 0:
		return true
	return willpower >= max_willpower

func refresh_turn() -> void:
	if _action_points:
		_action_points.refresh_turn()
	if _movement_cache:
		_movement_cache.invalidate()
	_start_of_turn_grid_coord = get_grid_location()
	_tentative_grid_coord = Vector2i.MAX
	_tentative_path = []
	_tentative_cost = 0

func has_move_available() -> bool:
	if _action_points == null:
		return false
	return _action_points.has_move_available()

func has_action_available() -> bool:
	if _action_points == null:
		return false
	return _action_points.has_action_available()

func consume_move(cost: int = 1) -> void:
	if _action_points == null:
		return
	_action_points.consume_move(cost)
	if _movement_cache:
		_movement_cache.invalidate()

func consume_action() -> void:
	if _action_points == null:
		return
	_action_points.consume_action()

func adjust_remaining_movement(delta: int) -> void:
	if _action_points == null:
		return
	_action_points.adjust_remaining_movement(delta)
	if _movement_cache:
		_movement_cache.invalidate()

func block_movement_this_turn() -> void:
	if _action_points == null:
		return
	_action_points.block_movement_this_turn()
	if _movement_cache:
		_movement_cache.invalidate()

func block_action_this_turn() -> void:
	if _action_points == null:
		return
	_action_points.block_action_this_turn()
	if _movement_cache:
		_movement_cache.invalidate()

func get_remaining_movement_points() -> int:
	if _action_points == null:
		return 0
	return _action_points.get_remaining_movement_points()

func get_max_movement_points() -> int:
	return movement_points

func compute_movement_range(start_coord: Vector2i, terrain_map, movement_budget: int = -1) -> Dictionary:
	if _movement_cache == null:
		return {}
	return _movement_cache.compute_range(start_coord, terrain_map, movement_budget)

func get_path_to_coord(target_coord: Vector2i, terrain_map, start_coord: Vector2i = Vector2i.MAX, movement_budget: int = -1) -> Array[Vector2i]:
	if terrain_map.has_method("is_within_bounds") and not terrain_map.is_within_bounds(target_coord):
		return []

	var start_cell := start_coord
	if start_cell == Vector2i.MAX:
		start_cell = get_grid_location()

	var reachable := compute_movement_range(start_cell, terrain_map, movement_budget)
	var calculator := MovementRangeCalculator.new()
	return calculator.find_path(target_coord, start_cell, reachable, terrain_map)

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

		var dist := 0.0
		if grid_map and other.grid_map:
			# Use grid coordinate distance
			var axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
			if grid_map.tile_set:
				axis = grid_map.tile_set.tile_offset_axis
			dist = float(HexNavigator.get_hex_distance(get_grid_location(), other.get_grid_location(), axis))
		else:
			# Fallback to pixels, assuming detection_range is meant for grid units, scale it up
			# or assume the caller passed pixel range.
			# Given the context, we'll assume the inputs are grid units and scale pixel check.
			dist = global_position.distance_to(other.global_position) / 64.0

		if dist > detection_range:
			continue

		var other_unit: Unit = other
		if not filter.is_null() and not filter.call(other_unit):
			continue
		result.append(other_unit)
	return result

func loot(loot_coord: Vector2i) -> bool:
	if not has_action_available():
		return false

	if get_grid_location() != loot_coord:
		return false

	if _loot_manager == null:
		return false

	var loot_item = _loot_manager.get_loot_at(loot_coord)
	if loot_item == null:
		return false

	for item in loot_item.inventory.duplicate():
		if equip_item(item):
			loot_item.inventory.erase(item)

	if loot_item.inventory.is_empty():
		_loot_manager.remove_loot(loot_item)

	consume_action()
	return true

func _die() -> void:
	if _is_dying:
		return
	_is_dying = true
	_drop_loot()

	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "rotation_degrees", 180.0, 0.5)
		tween.tween_callback(func():
			if _unit_manager:
				_unit_manager.remove_unit(self)
			else:
				queue_free()
		)
	elif _unit_manager:
		_unit_manager.remove_unit(self)
	else:
		queue_free()

func _drop_loot() -> void:
	if _loot_manager == null:
		return

	var inventory_ref := get_inventory()
	if inventory_ref == null:
		return

	var items := inventory_ref.get_items()
	if not items.is_empty():
		_loot_manager.spawn_loot(get_grid_location(), items)
		inventory_ref.clear()

func apply_consumable(pair_index: int, bonus: int) -> void:
	consumables_active[pair_index] = bonus

func prepare_for_save() -> void:
	if _action_points:
		action_points_template = _action_points.duplicate(true)

	var inv := get_inventory()
	if inv:
		saved_items = inv.get_items()

func create_memento() -> Dictionary:
	var items = []
	var inv = get_inventory()
	if inv:
		items = inv.get_items()

	return {
		"willpower": willpower,
		"max_willpower": max_willpower,
		"movement_points": movement_points,
		"faction": faction,
		"items": items
	}

func restore_from_memento(data: Dictionary) -> void:
	max_willpower = data.get("max_willpower", max_willpower)
	willpower = data.get("willpower", willpower)
	movement_points = data.get("movement_points", movement_points)
	faction = data.get("faction", faction)
	saved_items = data.get("items", [])
	# Items will be equipped in _ready or need manual re-equip if unit is already ready
	if is_node_ready() and not saved_items.is_empty():
		for item in saved_items:
			equip_item(item)
		saved_items.clear()

func get_start_of_turn_grid_coord() -> Vector2i:
	if _start_of_turn_grid_coord == Vector2i.MAX:
		return get_grid_location()
	return _start_of_turn_grid_coord

func set_tentative_move(coord: Vector2i, path: Array[Vector2i], cost: int) -> void:
	_tentative_grid_coord = coord
	_tentative_path = path
	_tentative_cost = cost

func clear_tentative_move() -> void:
	_tentative_grid_coord = Vector2i.MAX
	_tentative_path = []
	_tentative_cost = 0

func get_tentative_grid_coord() -> Vector2i:
	return _tentative_grid_coord

func has_tentative_move() -> bool:
	return _tentative_grid_coord != Vector2i.MAX

func get_tentative_path() -> Array[Vector2i]:
	return _tentative_path

func get_tentative_cost() -> int:
	return _tentative_cost
