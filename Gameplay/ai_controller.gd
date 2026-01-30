class_name AIController
extends Node

var _unit_manager: UnitManager
var _map_controller: MapController
var _combat_system: CombatSystem
var _unit_controller: UnitController
var _goal_manager: GoalManager
var _loot_manager: LootManager

# Helper class to store potential AI actions
class AIAction:
	var type: String
	var target: Variant
	var path: Array
	var score: float

	func _init(p_type: String, p_target: Variant, p_path: Array, p_score: float):
		type = p_type
		target = p_target
		path = p_path
		score = p_score

@onready var weather_manager = get_node("/root/WeatherManager") # Added WeatherManager reference

var _current_ai_modifier: float = 0.0 # New member variable for AI modifier

func _ready(): # Added _ready function
	if weather_manager:
		weather_manager.weather_effect_applied.connect(_on_weather_effect_applied)

func setup(
	unit_manager: UnitManager,
	map_controller: MapController,
	combat_system: CombatSystem,
	unit_controller: UnitController,
	goal_manager: GoalManager,
	loot_manager: LootManager
) -> void:
	_unit_manager = unit_manager
	_map_controller = map_controller
	_combat_system = combat_system
	_unit_controller = unit_controller
	_goal_manager = goal_manager
	_loot_manager = loot_manager

func execute_turn(ai_unit: Unit) -> void:
	if not is_instance_valid(ai_unit) or ai_unit.willpower <= 0:
		return

	var terrain_map = _map_controller.get_terrain_map()
	var potential_actions = _gather_potential_actions(ai_unit, terrain_map)

	if potential_actions.is_empty():
		return

	potential_actions.sort_custom(func(a, b): return a.score > b.score)
	var best_action = potential_actions[0]

	await _execute_action(ai_unit, best_action, terrain_map)

func _gather_potential_actions(ai_unit: Unit, terrain_map) -> Array[AIAction]:
	var potential_actions: Array[AIAction] = []
	var start_pos = ai_unit.get_grid_location()

	var threatened_hexes: Dictionary = {}
	if ai_unit.movement_behavior:
		threatened_hexes = ai_unit.movement_behavior.get_threatened_hexes(_unit_manager, terrain_map)

	_find_aid_ally_actions(ai_unit, start_pos, potential_actions)
	_find_loot_actions(ai_unit, start_pos, potential_actions)
	_find_work_on_goal_actions(ai_unit, start_pos, potential_actions)
	_find_enemy_actions(ai_unit, start_pos, terrain_map, potential_actions, threatened_hexes)
	_find_move_to_loot_actions(ai_unit, start_pos, terrain_map, potential_actions, threatened_hexes)
	_find_goal_actions(ai_unit, start_pos, terrain_map, potential_actions, threatened_hexes)

	# Apply _current_ai_modifier to all action scores
	for action in potential_actions:
		action.score += _current_ai_modifier * 10.0 # Multiply by an arbitrary factor to make the effect noticeable

	# TODO: Refine AI behavior based on specific weather attributes (humidity, temperature, wind).
	# Example: If very wet, AI might avoid open areas or prioritize ranged attacks.
	# If windy, AI might use cover more effectively or move with the wind.

	return potential_actions

func _execute_movement(ai_unit: Unit, path: Array, _terrain_map) -> void:
	if not path.is_empty():
		await ai_unit.move_along_path(path)

func _execute_action(ai_unit: Unit, best_action: AIAction, terrain_map) -> void:
	if not best_action.path.is_empty() and terrain_map:
		await _execute_movement(ai_unit, best_action.path, terrain_map)

	if ai_unit.has_action_available():
		_execute_unit_interaction(ai_unit, best_action)

func _execute_unit_interaction(ai_unit: Unit, best_action: AIAction) -> void:
		if best_action.type == "attack":
			var enemy_target: Unit = best_action.target
			ai_unit.attack_unit(enemy_target)
		elif best_action.type == "work_on_goal":
			var goal_target: Goal = best_action.target
			ai_unit.work_on_goal(goal_target)
			# work_on_goal consumes the action, so no need to call it here
		elif best_action.type == "loot":
			var loot_coord = best_action.target as Vector2i
			ai_unit.loot(loot_coord)
		elif best_action.type == "aid_ally":
			var ally_target: Unit = best_action.target
			ai_unit.aid_ally(ally_target)

# Finds the best path to an unoccupied tile adjacent to the target
func _find_path_to_adjacent(ai_unit: Unit, target_pos: Vector2i, terrain_map, threatened_hexes: Dictionary = {}) -> Array:
	var best_path: Array = []
	var best_score: int = 9999

	if terrain_map == null:
		return best_path

	for neighbor in terrain_map.get_neighbors(target_pos):
		if not _unit_manager.is_occupied(neighbor):
			var path = ai_unit.get_path_to_coord(neighbor, terrain_map)
			if not path.is_empty():
				var is_threatened = threatened_hexes.has(neighbor)
				var score = path.size() + (2 if is_threatened else 0)
				if best_path.is_empty() or score < best_score:
					best_path = path
					best_score = score

	return best_path

func _find_work_on_goal_actions(ai_unit: Unit, start_pos: Vector2i, actions: Array[AIAction]) -> void:
	if _goal_manager == null or not ai_unit.has_action_available():
		return

	var goal = _goal_manager.get_goal_at_cell(start_pos)
	if goal and goal.can_be_worked_on_by(ai_unit):
		actions.append(AIAction.new("work_on_goal", goal, [], 80.0))

func _find_loot_actions(ai_unit: Unit, start_pos: Vector2i, actions: Array[AIAction]) -> void:
	if _loot_manager == null or not ai_unit.has_action_available():
		return

	if _loot_manager.has_loot_at(start_pos):
		actions.append(AIAction.new("loot", start_pos, [], 70.0))

func _find_aid_ally_actions(ai_unit: Unit, _start_pos: Vector2i, actions: Array[AIAction]) -> void:
	if not ai_unit.has_action_available():
		return

	var potential_allies = ai_unit.get_friendly_units()
	var adjacent_allies = ai_unit.get_units_in_range_without_full_willpower(potential_allies, 1.5)

	for ally in adjacent_allies:
		# Score based on how much health is missing
		var score = 60.0 + (ally.max_willpower - ally.willpower)
		actions.append(AIAction.new("aid_ally", ally, [], score))

func _find_enemy_actions(ai_unit: Unit, _start_pos: Vector2i, terrain_map, actions: Array[AIAction], threatened_hexes: Dictionary = {}) -> void:
	var targets = ai_unit.get_hostile_units()
	var adjacent_enemies = ai_unit.get_units_in_range(targets, 1.5)

	# Action: Attack adjacent enemy (high priority)
	for enemy in adjacent_enemies:
		actions.append(AIAction.new("attack", enemy, [], 100.0))

	# Action: Move towards an enemy
	var all_enemies = ai_unit.get_units_in_range(targets, 999.0)
	for target in all_enemies:
		# Don't move towards an enemy that is already adjacent
		if adjacent_enemies.has(target):
			continue

		var target_pos = target.get_grid_location()
		var path = _find_path_to_adjacent(ai_unit, target_pos, terrain_map, threatened_hexes)

		if not path.is_empty():
			# Score based on distance (closer is better)
			var score = 50.0 - path.size()
			actions.append(AIAction.new("move_to_enemy", target, path, score))

func _find_goal_actions(ai_unit: Unit, _start_pos: Vector2i, terrain_map, actions: Array[AIAction], threatened_hexes: Dictionary = {}) -> void:
	if _goal_manager == null or terrain_map == null:
		return

	for i in range(_goal_manager.get_goal_count()):
		var goal_coord = _goal_manager.get_target(i)
		if goal_coord == Vector2i(-1, -1):
			continue
		# Don't move to an occupied goal
		if _unit_manager.is_occupied(goal_coord):
			continue

		var path = ai_unit.get_path_to_coord(goal_coord, terrain_map)
		if not path.is_empty():
			# Score based on distance
			var is_threatened = threatened_hexes.has(goal_coord)
			var score = 20.0 - path.size() - (5.0 if is_threatened else 0.0)
			var goal_coord_as_object = goal_coord # Pass Vector2i as Object
			actions.append(AIAction.new("move_to_goal", goal_coord_as_object, path, score))

func _find_move_to_loot_actions(ai_unit: Unit, _start_pos: Vector2i, terrain_map, actions: Array[AIAction], threatened_hexes: Dictionary = {}) -> void:
	if _loot_manager == null or terrain_map == null:
		return

	var all_loot = _loot_manager.get_all_loot()
	for i in range(all_loot.size()):
		var loot_item = all_loot[i]
		if loot_item == null:
			continue
		var loot_coord = _loot_manager.get_coord(i)
		if loot_coord == Vector2i(-1, -1):
			continue

		# Don't move to occupied loot
		if _unit_manager.is_occupied(loot_coord):
			continue

		var path = ai_unit.get_path_to_coord(loot_coord, terrain_map)
		if not path.is_empty():
			# Score based on distance
			var is_threatened = threatened_hexes.has(loot_coord)
			var score = 10.0 - path.size() - (5.0 if is_threatened else 0.0)
			actions.append(AIAction.new("move_to_loot", loot_item, path, score))

func _on_weather_effect_applied(weather_attribute: WeatherAttribute):
	_current_ai_modifier = weather_attribute.ai_modifier
	print("AIController received weather effect: ", weather_attribute.attribute_name, ". AI Modifier: ", _current_ai_modifier)
	# TODO: Refine AI behavior based on specific weather attributes (humidity, temperature, wind).
	# Example: If very wet, AI might avoid open areas or prioritize ranged attacks.
	# If windy, AI might use cover more effectively or move with the wind.
