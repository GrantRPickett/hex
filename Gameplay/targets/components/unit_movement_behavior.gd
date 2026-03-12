class_name UnitMovementBehavior
extends RefCounted

## Component responsible for unit movement logic and pathfinding.
##
## This component handles:
## - Movement point management
## - Path calculation and validation
## - Movement range computation
## - Tentative move state tracking

var _unit: Unit
var _start_of_turn_grid_coord: Vector2i = Vector2i.MAX
var _tentative_grid_coord: Vector2i = Vector2i.MAX
var _tentative_path: Array[Vector2i] = []
var _tentative_cost: int = 0
var _free_roam_mode: bool = false

func _init(unit: Unit = null) -> void:
	if unit:
		setup(unit)

func setup(unit: Unit) -> void:
	_unit = unit

## Checks if the unit has movement available this turn
func has_move_available() -> bool:
	if _free_roam_mode:
		return true
	return _unit.res.has_move_available()

## Consumes movement points
func consume_move(cost: int = 1) -> void:
	if _free_roam_mode:
		return
	_unit.res.consume_move(cost)
	if _unit._movement_cache:
		_unit._movement_cache.invalidate()

## Adjusts remaining movement points by delta
func adjust_remaining_movement(delta: int) -> void:
	if _free_roam_mode:
		return
	_unit.res.adjust_remaining_movement(delta)
	if _unit._movement_cache:
		_unit._movement_cache.invalidate()

## Blocks movement for the remainder of this turn
func block_movement_this_turn() -> void:
	if _free_roam_mode:
		return
	_unit.res.block_movement_this_turn()
	if _unit._movement_cache:
		_unit._movement_cache.invalidate()

## Gets remaining movement points for this turn
func get_remaining_movement_points() -> int:
	if _free_roam_mode:
		return 999999 # Use constant if accessible, but hardcoded is safer for now
	return _unit.res.get_remaining_movement_points()

## Gets maximum movement points
func get_max_movement_points() -> int:
	return _unit.movement_points

## Computes the movement range from a starting coordinate
func compute_movement_range(start_coord: Vector2i, terrain_map, movement_budget: int = -1, pass_through_blockers: Dictionary = {}) -> Dictionary:
	if _unit._movement_cache == null:
		return {}

	return _unit._movement_cache.compute_range(start_coord, terrain_map, movement_budget, pass_through_blockers)

## Gets the path to a target coordinate
func get_path_to_coord(target_coord: Vector2i, terrain_map, start_coord: Vector2i = Vector2i.MAX, movement_budget: int = -1) -> Array[Vector2i]:
	if terrain_map.has_method("is_within_bounds") and not terrain_map.is_within_bounds(target_coord):
		return []

	var start_cell := start_coord
	if start_cell == Vector2i.MAX:
		start_cell = _unit.get_grid_location()

	var reachable := compute_movement_range(start_cell, terrain_map, movement_budget)
	var calculator := MovementRangeCalculator.new()
	var threatened_hexes: Dictionary = {}
	var blocked_hexes: Dictionary = {}

	if terrain_map and _unit and _unit._unit_manager:
		# find_path uses blocked_hexes to know where it CANNOT END or PASS.
		# Since reachable already accounts for pass-through blocks,
		# blocked_hexes here should ONLY include unoccupiable hexes.
		# Allies only block if they are the target_coord (cannot end on them).
		blocked_hexes = get_stop_blockers(_unit._unit_manager, target_coord)
		threatened_hexes = get_threatened_hexes(_unit._unit_manager, terrain_map)

	return calculator.find_path(target_coord, start_cell, reachable, terrain_map, movement_budget, threatened_hexes, blocked_hexes)

## Returns the best path to any unblocked neighbor of the target_pos.
func get_path_to_adjacent(target_pos: Vector2i, terrain_map, unit_manager: UnitManager) -> Array[Vector2i]:
	var best_path: Array[Vector2i] = []
	var best_score: int = 9999
	if not is_instance_valid(terrain_map) or not is_instance_valid(_unit) or not is_instance_valid(unit_manager):
		return best_path

	for neighbor in terrain_map.get_neighbors(target_pos):
		if unit_manager.is_occupied(neighbor):
			continue
		var path = get_path_to_coord(neighbor, terrain_map)
		if not path.is_empty():
			var score = path.size()
			if best_path.is_empty() or score < best_score:
				best_path = path
				best_score = score
	return best_path

func get_blocked_hexes(unit_manager: UnitManager, target_coord: Vector2i = Vector2i.MAX) -> Dictionary:
	var blocked_hexes: Dictionary = {}
	var units: Array[Unit] = unit_manager.get_all_units()
	var self_index := unit_manager.get_unit_index(_unit)

	for i in range(units.size()):
		var other = units[i]
		if other == null or not (other is Unit):
			continue

		var other_coord: Vector2i = unit_manager.get_coord(i)
		if other_coord != GameConstants.INVALID_COORD and i != self_index:
			# Units always block the path.
			# Exception: we don't block the target_coord if it's the destination we are checking path validity for,
			# because find_path needs the target to be "reachable" (but standard compute_range might already have excluded it).
			# Actually, standard behavior is that you cannot END on an ally or enemy.
			# But you also cannot PASS THROUGH them.
			blocked_hexes[other_coord] = true

	return blocked_hexes

func get_threatened_hexes(unit_manager: UnitManager, terrain_map) -> Dictionary:
	var threatened_hexes: Dictionary = {}
	var units: Array[Unit] = unit_manager.get_all_units()
	var axis: int = terrain_map.get_offset_axis() if terrain_map.has_method("get_offset_axis") else TileSet.TILE_OFFSET_AXIS_VERTICAL

	for i in range(units.size()):
		var other = units[i]
		if other == null or not (other is Unit):
			continue
		if other == _unit or other.faction == _unit.faction:
			continue
		if other.faction == Unit.Faction.NEUTRAL:
			continue

		# If the enemy has no reactions left, they cannot threaten space (no Attack of Opportunity)
		if other.has_method("has_reaction_available") and not other.res.has_reaction_available():
			continue

		var enemy_coord: Vector2i = unit_manager.get_coord(i)
		if enemy_coord == GameConstants.INVALID_COORD:
			enemy_coord = other.get_grid_location()

		if not terrain_map.is_within_bounds(enemy_coord):
			continue

		for offset in HexNavigator.get_neighbor_offsets(enemy_coord, axis):
			var threatened_coord: Vector2i = enemy_coord + offset
			if terrain_map.is_within_bounds(threatened_coord):
				if not threatened_hexes.has(threatened_coord):
					threatened_hexes[threatened_coord] = []
				threatened_hexes[threatened_coord].append(other)
	return threatened_hexes

func process_path_for_opportunity_attacks(path: Array[Vector2i], terrain_map) -> Dictionary:
	var context = _get_opportunity_attack_context()
	if not context.valid or not terrain_map or path.is_empty():
		var dest = path[-1] if not path.is_empty() else get_start_of_turn_grid_coord()
		return {"destination": dest, "cost": _unit.movement.get_tentative_cost()}

	var combat_system = context.combat_system
	var unit_manager = context.unit_manager
	var start_coord = get_start_of_turn_grid_coord()
	if start_coord == Vector2i.MAX:
		start_coord = _unit.get_grid_location()

	var reachable = compute_movement_range(start_coord, terrain_map)
	var all_threatened_hexes = get_threatened_hexes(unit_manager, terrain_map)

	var current_pos = start_coord
	var my_index = unit_manager.get_unit_index(_unit)
	print_debug("[AoO] Processing path: ", path, " from start: ", start_coord)

	for next_pos in path:
		# Sync logical position to current step so if we die/retreat, we are at the right spot
		if my_index != -1:
			unit_manager.set_coord(my_index, next_pos)
			
		# Check if the unit is leaving a threatened hex
		if all_threatened_hexes.has(current_pos):
			print_debug("[AoO] Unit leaving threatened hex: ", current_pos)
			var attackers = all_threatened_hexes[current_pos]
			for attacker in attackers:
				if is_instance_valid(attacker) and attacker.res.has_reaction_available():
					var attacker_coord = unit_manager.get_coord(unit_manager.get_unit_index(attacker))
					var axis = terrain_map.get_offset_axis() if terrain_map.has_method("get_offset_axis") else TileSet.TILE_OFFSET_AXIS_VERTICAL

					# Ensure the attacker is actually adjacent to where the unit is leaving from
					if HexNavigator.get_hex_distance(attacker_coord, current_pos, axis) <= 1:
						print_debug("[AoO] Triggering attack from ", attacker.unit_name, " on ", _unit.unit_name)
						var pair_index = _select_best_attack_attribute(attacker)
						combat_system.execute_attack_of_opportunity(attacker, _unit, pair_index)

						# If the unit is defeated, stop movement at the current position
						if _unit.willpower <= 0:
							print_debug("[AoO] Unit ", _unit.unit_name, " defeated mid-move at ", next_pos)
							var cost_to_death_spot = int(reachable.get(next_pos, 0))
							return {"destination": next_pos, "cost": cost_to_death_spot}

		# Move to the next position for the next iteration
		current_pos = next_pos

	# If the loop completes, the unit reaches the final destination
	var final_destination = path[-1]
	var total_cost = int(reachable.get(final_destination, _unit.movement.get_tentative_cost()))
	return {"destination": final_destination, "cost": total_cost}

func _get_opportunity_attack_context() -> Dictionary:
	if not _unit or not _unit.has_method("get_combat_system"):
		return {"valid": false}
	var combat_system = _unit.get_combat_system()
	var unit_manager = _unit.get_unit_manager()
	if not combat_system or not unit_manager:
		return {"valid": false}
	return {"valid": true, "combat_system": combat_system, "unit_manager": unit_manager}

func _select_best_attack_attribute(unit: Unit) -> int:
	var attrs = unit.inv.get_attributes() if unit.inv else null
	if attrs == null:
		return 0
	var best_index := 0
	var best_value := -INF
	var combat_system = unit.get_combat_system()
	if not combat_system:
		return 0

	for i in range(combat_system.PAIRS.size()):
		var pair = combat_system.PAIRS[i]
		var val_a = attrs.get_attribute(pair[0])
		var val_b = attrs.get_attribute(pair[1])
		var stat = max(val_a, val_b)
		if stat > best_value:
			best_value = stat
			best_index = i
	return best_index

func set_free_roam_mode(enabled: bool) -> void:
	_free_roam_mode = enabled

func is_free_roam_mode() -> bool:
	return _free_roam_mode

## Refreshes movement state at the start of a turn
func refresh_for_new_round() -> void:
	var current_coord = _unit.get_grid_location()
	if current_coord != GameConstants.INVALID_COORD:
		_start_of_turn_grid_coord = current_coord
	else:
		_start_of_turn_grid_coord = Vector2i.MAX
	_tentative_grid_coord = Vector2i.MAX
	_tentative_path = []
	_tentative_cost = 0

## Gets the unit's position at the start of its turn
func get_start_of_turn_grid_coord() -> Vector2i:
	if _start_of_turn_grid_coord == Vector2i.MAX:
		return _unit.get_grid_location()
	return _start_of_turn_grid_coord

func set_start_of_turn_grid_coord(coord: Vector2i) -> void:
	_start_of_turn_grid_coord = coord

## Sets a tentative move for preview purposes
func set_tentative_move(coord: Vector2i, path: Array[Vector2i], cost: int) -> void:
	_tentative_grid_coord = coord
	_tentative_path = path
	_tentative_cost = cost

## Clears the tentative move
func clear_tentative_move() -> void:
	_tentative_grid_coord = Vector2i.MAX
	_tentative_path = []
	_tentative_cost = 0

## Gets the tentative grid coordinate
func get_tentative_grid_coord() -> Vector2i:
	return _tentative_grid_coord

## Checks if there's a tentative move set
func has_tentative_move() -> bool:
	return _tentative_grid_coord != Vector2i.MAX

## Gets the tentative path
func get_tentative_path() -> Array[Vector2i]:
	return _tentative_path

## Gets the tentative move cost
func get_tentative_cost() -> int:
	return _tentative_cost

## Moves the unit along a path step by step (animated)
func move_along_path(path: Array) -> void:
	var unit_manager = _unit.get_unit_manager()
	if unit_manager == null:
		return

	var my_index = unit_manager.get_unit_index(_unit)
	if my_index == -1:
		return

	# Path usually excludes start, but includes end.
	for step in path:
		# Update logical position
		unit_manager.set_coord(my_index, step)

		# Consume resource
		var cost = 1 # Assuming 1 for now, or could query terrain cost if available
		consume_move(cost)

		# Wait for animation (assumed 0.2s from Gameplay.gd tween)
		await _unit.get_tree().create_timer(0.25).timeout

func on_enter_terrain(terrain: Variant) -> void:
	if terrain == null:
		return

	if "movement_penalty" in terrain:
		consume_move(terrain.movement_penalty)

	if "blocks_action_after_move" in terrain and terrain.blocks_action_after_move:
		_unit.block_action_this_turn()

	if "status_effect" in terrain and not str(terrain.status_effect).is_empty():
		if _unit.status:
			_unit.status.apply_status_effect(terrain.status_effect)

	if "passable" in terrain and not terrain.passable:
		block_movement_this_turn()

func get_pass_through_blockers(unit_manager: UnitManager) -> Dictionary:
	var blockers: Dictionary = {}
	if not unit_manager: return blockers
	var units = unit_manager.get_all_units()
	for i in range(units.size()):
		var other = units[i]
		if not is_instance_valid(other) or other == _unit: continue
		# Enemies block passing through.
		if other.faction != _unit.faction:
			blockers[unit_manager.get_coord(i)] = true
	return blockers

func get_stop_blockers(unit_manager: UnitManager, target_coord: Vector2i = Vector2i.MAX) -> Dictionary:
	var blockers: Dictionary = {}
	if not unit_manager: return blockers
	var units = unit_manager.get_all_units()
	var self_index = unit_manager.get_unit_index(_unit)
	for i in range(units.size()):
		var other = units[i]
		if not is_instance_valid(other) or i == self_index: continue

		var coord = unit_manager.get_coord(i)
		# We cannot end on ANY other unit.
		# If this is the target_coord we want to move to, it's blocked.
		if coord == target_coord:
			blockers[coord] = true
	return blockers
