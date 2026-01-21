class_name Unit
extends Target

const InventoryComponentResource := preload("res://Gameplay/components/inventory_component.gd")
const ActionPointsComponentResource := preload("res://Gameplay/components/action_points_component.gd")
const MovementRangeCacheResource := preload("res://Gameplay/components/movement_range_cache.gd")
const UnitCombatBehaviorScript := preload("res://Gameplay/components/unit_combat_behavior.gd")
const UnitMovementBehaviorScript := preload("res://Gameplay/components/unit_movement_behavior.gd")
const UnitInteractionHandlerScript := preload("res://Gameplay/components/unit_interaction_handler.gd")
const UnitDeathHandlerScript := preload("res://Gameplay/components/unit_death_handler.gd")
const UnitQueryServiceScript := preload("res://Gameplay/components/unit_query_service.gd")

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

var skills: Array[Skill]
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
var morale: int = 10
var consumables_active: Dictionary

# Behavior components
var combat_behavior
var movement_behavior
var interaction_handler
var death_handler
var query_service

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
	skills = [] # of Skill
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

	# Initialize behavior components
	combat_behavior = UnitCombatBehaviorScript.new(self)
	movement_behavior = UnitMovementBehaviorScript.new(self)
	interaction_handler = UnitInteractionHandlerScript.new(self)
	death_handler = UnitDeathHandlerScript.new(self)
	query_service = UnitQueryServiceScript.new(self)

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

	for skill in skills:
		skill.on_equip(self)

	refresh_turn()

func _exit_tree() -> void:
	if _inventory_component:
		_inventory_component.cleanup()
	if _movement_cache:
		_movement_cache.cleanup()

func set_unit_manager(unit_manager: UnitManager) -> void:
	_unit_manager = unit_manager
	if _movement_cache:
		_movement_cache.set_unit_manager(unit_manager)
	if death_handler:
		death_handler.set_unit_manager(unit_manager)

func set_loot_manager(manager: LootManager) -> void:
	_loot_manager = manager
	if interaction_handler:
		interaction_handler.set_loot_manager(manager)
	if death_handler:
		death_handler.set_loot_manager(manager)

func set_goal_manager(manager: GoalManager) -> void:
	_goal_manager = manager
	if interaction_handler:
		interaction_handler.set_goal_manager(manager)

func set_combat_system(system: CombatSystem) -> void:
	_combat_system = system
	if combat_behavior:
		combat_behavior.set_combat_system(system)

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

func add_skill(skill: Skill) -> void:
	if skill == null:
		return
	if not skills.has(skill):
		skills.append(skill)
		skill.on_equip(self)

func remove_skill(skill: Skill) -> void:
	skills.erase(skill)
	skill.on_unequip(self)

func equip_item(item: InventoryItem) -> bool:
	if _inventory_component == null:
		return false
	return _inventory_component.equip_item(item)

func unequip_item(item: InventoryItem) -> bool:
	if _inventory_component == null:
		return false
	return _inventory_component.unequip_item(item)

func has_nearby_units(units: Array, detection_range: float) -> bool:
	return query_service.has_nearby_units(units, detection_range)

func get_units_in_range(units: Array, detection_range: float) -> Array:
	return query_service.get_units_in_range(units, detection_range)

func get_adjacent_units(units: Array, adjacency_range: float = 1.5) -> Array:
	return query_service.get_adjacent_units(units, adjacency_range)

func get_units_in_range_by_faction(units: Array, detection_range: float, target_faction: Faction) -> Array:
	return query_service.get_units_in_range_by_faction(units, detection_range, target_faction)

func get_units_in_range_without_full_morale(units: Array, detection_range: float) -> Array:
	return query_service.get_units_in_range_without_full_morale(units, detection_range)

func list_goals_in_range(goals: Array, detection_range: float) -> Array:
	return query_service.list_goals_in_range(goals, detection_range)

func act(target: Node2D) -> bool:
	if target == null:
		return false
	if not (target is Node2D):
		return false

	# Prefer grid distance if available
	if grid_map:
		var my_coord = get_grid_location()
		var target_coord = Vector2i.ZERO
		if target.get_parent() is TileMapLayer:
			target_coord = target.get_parent().local_to_map(target.position)
		else:
			# Fallback for non-Target nodes
			target_coord = grid_map.local_to_map(grid_map.to_local(target.global_position))

		var axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
		if grid_map.tile_set:
			axis = grid_map.tile_set.tile_offset_axis
		return HexNavigator.get_hex_distance(my_coord, target_coord, axis) <= action_range

	return global_position.distance_to(target.global_position) <= (action_range * 64.0) # Fallback pixel conversion

func interact(target: Target) -> bool:
	return interaction_handler.interact(target)

func attack_unit(target: Unit) -> bool:
	return combat_behavior.attack(target)

func work_on_goal(goal: Goal) -> bool:
	return interaction_handler.work_on_goal(goal)

func aid_ally(ally: Unit) -> bool:
	return combat_behavior.aid_ally(ally)

func is_at_full_morale() -> bool:
	if max_willpower <= 0:
		return true
	return willpower >= max_willpower

func refresh_turn() -> void:
	if _action_points:
		_action_points.refresh_turn()
	if _movement_cache:
		_movement_cache.invalidate()
	if movement_behavior:
		movement_behavior.refresh_turn()

func has_move_available() -> bool:
	return movement_behavior.has_move_available()

func has_action_available() -> bool:
	if _action_points == null:
		return false
	return _action_points.has_action_available()

func consume_move(cost: int = 1) -> void:
	movement_behavior.consume_move(cost)

func consume_action() -> void:
	if _action_points == null:
		return
	_action_points.consume_action()

func adjust_remaining_movement(delta: int) -> void:
	movement_behavior.adjust_remaining_movement(delta)

func block_movement_this_turn() -> void:
	movement_behavior.block_movement_this_turn()

func block_action_this_turn() -> void:
	if _action_points == null:
		return
	_action_points.block_action_this_turn()
	if _movement_cache:
		_movement_cache.invalidate()

func get_remaining_movement_points() -> int:
	return movement_behavior.get_remaining_movement_points()

func get_max_movement_points() -> int:
	return movement_behavior.get_max_movement_points()

func compute_movement_range(start_coord: Vector2i, terrain_map, movement_budget: int = -1) -> Dictionary:
	return movement_behavior.compute_movement_range(start_coord, terrain_map, movement_budget)

func get_path_to_coord(target_coord: Vector2i, terrain_map, start_coord: Vector2i = Vector2i.MAX, movement_budget: int = -1) -> Array[Vector2i]:
	return movement_behavior.get_path_to_coord(target_coord, terrain_map, start_coord, movement_budget)

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

func _collect_targets_in_range(targets: Array, detection_range: float, filter: Callable = Callable()) -> Array:
	return query_service._collect_targets_in_range(targets, detection_range, filter)

func loot(loot_coord: Vector2i) -> bool:
	return interaction_handler.loot(loot_coord)


func _die() -> void:
	death_handler.die()

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
	return movement_behavior.get_start_of_turn_grid_coord()

func set_tentative_move(coord: Vector2i, path: Array[Vector2i], cost: int) -> void:
	movement_behavior.set_tentative_move(coord, path, cost)

func clear_tentative_move() -> void:
	movement_behavior.clear_tentative_move()

func get_tentative_grid_coord() -> Vector2i:
	return movement_behavior.get_tentative_grid_coord()

func has_tentative_move() -> bool:
	return movement_behavior.has_tentative_move()

func get_tentative_path() -> Array[Vector2i]:
	return movement_behavior.get_tentative_path()

func get_tentative_cost() -> int:
	return movement_behavior.get_tentative_cost()
