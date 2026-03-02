class_name Unit
extends Target

signal willpower_changed(unit: Unit)
signal components_ready

const FREE_ROAM_MOVEMENT_POINTS := 999999


enum Faction {
	PLAYER,
	ENEMY,
	NEUTRAL
}


@export var unit_name: String = ""
@export var faction: Faction = Faction.PLAYER
@export var action_range: float = 1.5 # Changed to grid units (1.5 covers adjacent hexes)
@export var inventory_component_template: Resource = InventoryComponent.new()
@export var action_points_template: Resource = ActionPointsComponent.new()
@export var movement_range_cache_template: Resource = MovementRangeCache.new()
@export var saved_items: Array[InventoryItem] = []
@export var neutral_can_be_persuaded: bool = false
@export var neutral_can_rally_allies: bool = false
@export var stress: int = 0
@export var is_dead: bool = false
@export var combat_priority_profile: CombatPriorityProfile


var skills: Array[Skill] = []
var _inventory_component
var _action_points: ActionPointsComponent
var _movement_cache: MovementRangeCache
var _unit_manager: UnitManager
var _loot_manager: LootManager
var _task_manager: TaskManager
var _combat_system: CombatSystem
var _animation_service: AnimationRequestService
var consumables_active: Dictionary
var _free_roam_mode : bool = false
var _leader_faction: int = -1
var _setup_finalized: bool = false


# Behavior components
var combat_behavior
var movement_behavior
var interaction_handler
var death_handler
var query_service
var loyalty_component
var status_component


func _init() -> void:
	if action_points_template == null:
		action_points_template = ActionPointsComponent.new()
	_action_points = action_points_template.duplicate(true)
	if _action_points == null:
		_action_points = ActionPointsComponent.new()


var willpower: int:
	get:
		return _action_points.get_willpower()

	set(value):
		_action_points.set_willpower(value)
		if _action_points.get_willpower() <= 0:
			_die()


var max_willpower: int:
	get:
		return _action_points.get_max_willpower()

	set(value):
		_action_points.set_max_willpower(value)


var movement_points: int:
	get:
		if _free_roam_mode:
			return FREE_ROAM_MOVEMENT_POINTS
		return _action_points.get_movement_points()

	set(value):
		_action_points.set_movement_points(value)
		if _movement_cache:
			_movement_cache.invalidate()


func _ready() -> void:
	UnitComponentFactory.create_components(self )

	skills = [] # of Skill
	consumables_active = {}

	if _animation_service and death_handler:
		death_handler.set_animation_service(_animation_service)

	if _action_points:
		_action_points.willpower_changed.connect(_on_action_points_willpower_changed)

	if not saved_items.is_empty():
		for item in saved_items:
			if item == null:
				continue
			var regenerate_uuid := not item.resource_path.is_empty()
			var item_instance := item.duplicate_instance(regenerate_uuid)
			if item_instance == null:
				continue
			if item_instance.equipped:
				equip_item(item_instance)
			else:
				add_item_to_inventory(item_instance)

		saved_items.clear()

	refresh_for_new_round()

	if not _setup_finalized:
		finalize_setup()

func _on_action_points_willpower_changed() -> void:
	willpower_changed.emit(self )


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


func get_unit_manager() -> UnitManager:
	return _unit_manager

func set_animation_service(service) -> void:
	_animation_service = service
	if death_handler:
		death_handler.set_animation_service(service)


func set_loot_manager(manager: LootManager) -> void:
	_loot_manager = manager

	if interaction_handler:
		interaction_handler.set_loot_manager(manager)

	if death_handler:
		death_handler.set_loot_manager(manager)


func set_task_manager(manager: TaskManager) -> void:
	_task_manager = manager

	if interaction_handler:
		interaction_handler.set_task_manager(manager)


func get_task_manager() -> TaskManager:
	return _task_manager


func get_loot_manager() -> LootManager:
	return _loot_manager


func set_combat_system(system: CombatSystem) -> void:
	_combat_system = system

	if combat_behavior:
		combat_behavior.set_combat_system(system)


func get_combat_system() -> CombatSystem:
	return _combat_system


func get_attributes() -> UnitAttributes:
	if _inventory_component == null:
		return null

	return _inventory_component.get_attributes()

func get_attribute(attr_name: String) -> int:
	var attrs = get_attributes()
	if attrs:
		return attrs.get_attribute(attr_name)
	return super.get_attribute(attr_name)


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


func remove_skill(skill: Skill) -> void:
	skills.erase(skill)

	skill.on_unequip(self )


func equip_item(item: InventoryItem) -> bool:
	if _inventory_component == null:
		return false

	return _inventory_component.equip_item(item)


func unequip_item(item: InventoryItem) -> bool:
	if _inventory_component == null:
		return false

	return _inventory_component.unequip_item(item)


func add_item_to_inventory(item: InventoryItem) -> bool:
	if _inventory_component == null:
		return false
	# Quest items: route to appropriate roster stash based on unit faction; do not occupy unit inventory
	if item and item.quest:
		var roster: UnitRoster = null
		# Prefer GameState services when available; avoid traversing the scene tree
		if _unit_manager and _unit_manager.has_method("get_roster_for_faction"):
			roster = _unit_manager.get_roster_for_faction(faction)
		elif _task_manager and _task_manager._state:
			if faction == Faction.PLAYER and _task_manager._state.player_roster:
				roster = _task_manager._state.player_roster
		if roster and roster.has_method("add_to_stash"):
			roster.add_to_stash([item])
			return true
		# Fallback: add to inventory if no roster found
	return _inventory_component.add_item_to_inventory(item)


func get_equipped_items() -> Array[InventoryItem]:
	if _inventory_component == null:
		return []
	return _inventory_component.get_equipped_items()

func get_combat_profile() -> CombatPriorityProfile:
	if combat_priority_profile == null:
		if not Unit._default_combat_profile:
			Unit._default_combat_profile = CombatPriorityProfile.new()
		return Unit._default_combat_profile
	return combat_priority_profile

static var _default_combat_profile: CombatPriorityProfile


func has_nearby_units(units: Array, detection_range: float) -> bool:
	return query_service.has_nearby_units(units, detection_range)


func get_units_in_range(units: Array, detection_range: float) -> Array:
	return query_service.get_units_in_range(units, detection_range)


func get_adjacent_units(units: Array, adjacency_range: float = 1.5) -> Array:
	return query_service.get_adjacent_units(units, adjacency_range)


func get_units_in_range_by_faction(units: Array, detection_range: float, target_faction: Faction) -> Array:
	return query_service.get_units_in_range_by_faction(units, detection_range, target_faction)


func get_units_in_range_without_full_willpower(units: Array, detection_range: float) -> Array:
	return query_service.get_units_in_range_without_full_willpower(units, detection_range)


func list_locations_in_range(locations: Array, detection_range: float) -> Array:
	return query_service.list_locations_in_range(locations, detection_range)


func get_hostile_units() -> Array[Unit]:
	return query_service.get_hostile_units()


func get_friendly_units() -> Array[Unit]:
	return query_service.get_friendly_units()


func get_neutral_units() -> Array[Unit]:
	return query_service.get_neutral_units()


func get_closest_unit(units: Array) -> Unit:
	return query_service.get_closest_unit(units)


func act(target: Target) -> bool:
	if target == null:
		return false

	if not (target is Target):
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


func attack_unit(target: Unit, attribute_index: int = 0) -> bool:
	return combat_behavior.attack(target, attribute_index)


func work_on_task(target_task: Task) -> bool:
	return interaction_handler.work_on_task(target_task)


func aid_ally(ally: Unit) -> bool:
	return combat_behavior.aid_ally(ally)


func is_at_full_willpower() -> bool:
	if max_willpower <= 0:
		return true

	return willpower >= max_willpower


func refresh_for_new_round() -> void:
	if _action_points:
		_action_points.refresh_for_new_round()

	if _movement_cache:
		_movement_cache.invalidate()

	if movement_behavior:
		movement_behavior.refresh_for_new_round()

	if query_service:
		query_service.invalidate_cache()


func set_free_roam_mode(enabled: bool) -> void:
	if _free_roam_mode == enabled:
		return
	_free_roam_mode = enabled
	if movement_behavior:
		movement_behavior.refresh_for_new_round()
	if _action_points:
		_action_points.refresh_for_new_round()
	if _movement_cache:
		_movement_cache.invalidate()

func is_in_free_roam_mode() -> bool:
	return _free_roam_mode


func is_faction_leader(p_faction: int) -> bool:
	return _leader_faction == p_faction and p_faction >= 0


func set_faction_leader(p_faction: int, enabled: bool) -> void:
	if p_faction < 0:
		return
	if enabled:
		_leader_faction = p_faction
	else:
		if _leader_faction == p_faction:
			_leader_faction = -1


func is_player_leader() -> bool:
	return is_faction_leader(Unit.Faction.PLAYER)


func set_player_leader(enabled: bool) -> void:
	set_faction_leader(Unit.Faction.PLAYER, enabled)


func has_move_available() -> bool:
	if _free_roam_mode:
		return true
	return movement_behavior.has_move_available()


func has_action_available() -> bool:
	if _free_roam_mode:
		return true
	return _action_points.has_action_available()


func has_reaction_available() -> bool:
	if _free_roam_mode:
		return true
	return _action_points.has_reaction_available()


func consume_reaction() -> void:
	if _free_roam_mode:
		return
	_action_points.consume_reaction()


func consume_move(cost: int = 1) -> void:
	if _free_roam_mode:
		return
	movement_behavior.consume_move(cost)


func consume_action() -> void:
	if _action_points == null:
		return
	if _free_roam_mode:
		return

	_action_points.consume_action()


func adjust_remaining_movement(delta: int) -> void:
	if _free_roam_mode:
		return
	movement_behavior.adjust_remaining_movement(delta)


func block_movement_this_turn() -> void:
	if _free_roam_mode:
		return
	movement_behavior.block_movement_this_turn()


func block_action_this_turn() -> void:
	if _action_points == null:
		return
	if _free_roam_mode:
		return

	_action_points.block_action_this_turn()

	if _movement_cache:
		_movement_cache.invalidate()


func get_remaining_movement_points() -> int:
	if _free_roam_mode:
		return FREE_ROAM_MOVEMENT_POINTS
	return movement_behavior.get_remaining_movement_points()


func get_max_movement_points() -> int:
	return movement_behavior.get_max_movement_points()


func compute_movement_range(start_coord: Vector2i, terrain_map, movement_budget: int = -1) -> Dictionary:
	return movement_behavior.compute_movement_range(start_coord, terrain_map, movement_budget)


func get_path_to_coord(target_coord: Vector2i, terrain_map, start_coord: Vector2i = Vector2i.MAX, movement_budget: int = -1) -> Array[Vector2i]:
	return movement_behavior.get_path_to_coord(target_coord, terrain_map, start_coord, movement_budget)


func apply_status_effect(effect: StringName) -> void:
	status_component.apply_status_effect(effect)


func has_status_effect(effect: StringName) -> bool:
	return status_component.has_status_effect(effect)


func clear_status_effect(effect: StringName) -> void:
	status_component.clear_status_effect(effect)


func on_enter_terrain(terrain: TerrainTile) -> void:
	if terrain == null:
		return

	terrain.apply_to_unit(self )


func move_along_path(path: Array) -> void:
	if _unit_manager == null:
		return

	var my_index = _unit_manager.get_unit_index(self )
	if my_index == -1:
		return

	# Path usually excludes start, but includes end.
	# We iterate and move one by one.
	for step in path:
		# Update logical position
		_unit_manager.set_coord(my_index, step)

		# Consume resource
		var cost = 1 # Assuming 1 for now, or could query terrain cost if available
		consume_move(cost)

		# Wait for animation (assumed 0.2s from Gameplay.gd tween)
		await get_tree().create_timer(0.25).timeout


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
	return UnitSerializer.create_memento(self )


func restore_from_memento(data: Dictionary) -> void:
	UnitSerializer.restore_from_memento(self , data)


func get_start_of_turn_grid_coord() -> Vector2i:
	return movement_behavior.get_start_of_turn_grid_coord()


func set_tentative_move(coord: Vector2i, path: Array[Vector2i], cost: int) -> void:
	movement_behavior.set_tentative_move(coord, path, cost)


func clear_tentative_move() -> void:
	movement_behavior.clear_tentative_move()


func get_tentative_grid_coord() -> Vector2i:
	return movement_behavior.get_tentative_grid_coord()


func has_tentative_move() -> bool:
	if movement_behavior == null:
		# Temporarily return false if movement_behavior is not initialized
		# This indicates an issue with unit initialization timing.
		return false
	return movement_behavior.has_tentative_move()


func get_tentative_path() -> Array[Vector2i]:
	return movement_behavior.get_tentative_path()


func get_tentative_cost() -> int:
	return movement_behavior.get_tentative_cost()

func get_hover_info() -> String:
	var info_text = "Name: " + unit_name
	info_text += "\nFaction: " + get_faction_name()
	info_text += "\nWP: %d/%d" % [willpower, max_willpower]
	if _action_points:
		info_text += "\nReactions: %d/%d" % [_action_points.get_reactions_available(), _action_points.get_max_reactions()]
	if faction == Faction.NEUTRAL:
		var loyalty_text := "Neutral"
		var loyalty = get_neutral_loyalty()
		if loyalty == Faction.PLAYER:
			loyalty_text = "Player"
		elif loyalty == Faction.ENEMY:
			loyalty_text = "Enemy"
		info_text += "\nLoyalty: " + loyalty_text

	var effects = status_component.get_status_effects()
	info_text += "\nStatus: " + ", ".join(effects.map(func(e): return str(e)))

	return info_text

func get_neutral_loyalty() -> int:
	return loyalty_component.neutral_loyalty


func reset_neutral_loyalty() -> void:
	loyalty_component.reset_neutral_loyalty()


func set_neutral_loyalty(target_faction: int, allow_rally: bool = true, rally_targets: Array = []) -> void:
	loyalty_component.set_neutral_loyalty(target_faction, allow_rally, rally_targets)


func apply_persuasion(target_faction: int) -> void:
	loyalty_component.apply_persuasion(target_faction)


func handle_attack_from(attacker: Unit) -> void:
	loyalty_component.handle_attack_from(attacker)


func finalize_setup() -> void:
	if _setup_finalized:
		return
	_setup_finalized = true
	components_ready.emit()
