class_name AIController
extends Node

const TurnSystem := preload("res://Gameplay/turn_system.gd")
const HexNavigator := preload("res://Gameplay/hex_navigator.gd")
const UnitActionManager := preload("res://Gameplay/unit_action_manager.gd")

# Action Type Constants
const ACTION_ATTACK := "attack"
const ACTION_WORK_ON_GOAL := "work_on_goal"
const ACTION_LOOT := "loot"
const ACTION_AID_ALLY := "aid_ally"
const ACTION_MOVE_TO_ENEMY := "move_to_enemy"
const ACTION_MOVE_TO_GOAL := "move_to_goal"
const ACTION_MOVE_TO_LOOT := "move_to_loot"
const ACTION_MOVE_TO_CENTER := "move_to_center"
const ACTION_TALK := "talk"
const MoveToCoordCommand := preload("res://Gameplay/input_commands/move_to_coord_command.gd")

# Action Score Constants
const SCORE_ATTACK_BASE := 100.0
const SCORE_WORK_ON_GOAL_BASE := 80.0
const SCORE_LOOT_BASE := 70.0
const SCORE_AID_ALLY_BASE := 60.0
const SCORE_MOVE_TO_ENEMY_BASE := 50.0
const SCORE_MOVE_TO_GOAL_BASE := 20.0
const SCORE_MOVE_TO_LOOT_BASE := 10.0
const SCORE_MOVE_TO_CENTER_BASE := 5.0
const SCORE_TALK_BASE := 110.0

var _unit_manager: UnitManager
var _map_controller: MapController
var _combat_system: CombatSystem
var _unit_controller: UnitController
var _goal_manager: GoalManager
var _loot_manager: LootManager
var _turn_controller: TurnController
var _command_context: GameCommandContext

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

func _exit_tree() -> void:
	if is_instance_valid(weather_manager) and weather_manager.weather_effect_applied.is_connected(_on_weather_effect_applied):
		weather_manager.weather_effect_applied.disconnect(_on_weather_effect_applied)

func setup(
	unit_manager: UnitManager,
	map_controller: MapController,
	combat_system: CombatSystem,
	unit_controller: UnitController,
	goal_manager: GoalManager,
	loot_manager: LootManager,
	command_context: GameCommandContext = null
) -> void:
	_unit_manager = unit_manager
	_map_controller = map_controller
	_combat_system = combat_system
	_unit_controller = unit_controller
	_goal_manager = goal_manager
	_loot_manager = loot_manager
	_command_context = command_context

func set_turn_controller(controller: TurnController) -> void:
	_turn_controller = controller

func set_command_context(command_context: GameCommandContext) -> void:
	_command_context = command_context

func execute_turn(ai_unit: Unit) -> bool:
	if not is_instance_valid(ai_unit) or ai_unit.willpower <= 0:
		print_debug("AIController: skipping invalid unit")
		return false

	var terrain_map = _map_controller.get_terrain_map()
	var potential_actions = _gather_potential_actions(ai_unit, terrain_map)

	if potential_actions.is_empty():
		var goal_action = _fallback_goal_action(ai_unit, terrain_map)
		if goal_action:
			print_debug("AIController: no immediate actions; falling back to goal move for ", ai_unit.unit_name)
			return await _execute_action(ai_unit, goal_action, terrain_map)
		print_debug("AIController: no actions available for ", ai_unit.unit_name)
		return false

	potential_actions.sort_custom(func(a, b): return a.score > b.score)
	var best_action = potential_actions[0]
	print_debug("AIController: executing action", best_action.type, "score=", best_action.score, "unit=", ai_unit.unit_name)

	var did_act = await _execute_action(ai_unit, best_action, terrain_map)
	return did_act

func _gather_potential_actions(ai_unit: Unit, terrain_map) -> Array[AIAction]:
	var potential_actions: Array[AIAction] = []
	var start_pos = ai_unit.get_grid_location()

	var threatened_hexes: Dictionary = {}
	if ai_unit.movement_behavior:
		threatened_hexes = ai_unit.movement_behavior.get_threatened_hexes(_unit_manager, terrain_map)

	var is_neutral := false
	if ai_unit.has_method("faction"):
		is_neutral = ai_unit.faction == TurnSystem.Side.NEUTRAL

	_find_aid_ally_actions(ai_unit, start_pos, potential_actions)
	_find_loot_actions(ai_unit, start_pos, potential_actions)
	_find_work_on_goal_actions(ai_unit, start_pos, potential_actions)
	if not is_neutral:
		_find_enemy_actions(ai_unit, start_pos, terrain_map, potential_actions, threatened_hexes)
	_find_move_to_loot_actions(ai_unit, start_pos, terrain_map, potential_actions, threatened_hexes)
	_find_goal_actions(ai_unit, start_pos, terrain_map, potential_actions, threatened_hexes)
	_find_talk_actions(ai_unit, potential_actions)

	# Apply _current_ai_modifier to all action scores
	for action in potential_actions:
		action.score += _current_ai_modifier * 10.0 # Multiply by an arbitrary factor to make the effect noticeable

	if potential_actions.is_empty():
		var fallback_enemy := _fallback_enemy_action(ai_unit, terrain_map, threatened_hexes, is_neutral)
		if fallback_enemy:
			potential_actions.append(fallback_enemy)
		else:
			var fallback_goal := _fallback_goal_action(ai_unit, terrain_map)
			if fallback_goal:
				potential_actions.append(fallback_goal)
			else:
				var fallback_center := _fallback_center_action(ai_unit, terrain_map, threatened_hexes)
				if fallback_center:
					potential_actions.append(fallback_center)

	# TODO: Refine AI behavior based on specific weather attributes (humidity, temperature, wind).
	# Example: If very wet, AI might avoid open areas or prioritize ranged attacks.
	# If windy, AI might use cover more effectively or move with the wind.

	return potential_actions

func _execute_movement(ai_unit: Unit, path: Array, _terrain_map) -> bool:
	if path.is_empty():
		return false
	var target: Vector2i = path.back() if path.back() is Vector2i else path[-1]
	if target == ai_unit.get_grid_location():
		return false
	if _command_context == null or _command_context.move_controller == null:
		print_debug("AIController: moving via fallback path", ai_unit.unit_name, "path_len=", path.size())
		await ai_unit.move_along_path(path)
		return true
	var move_cmd := MoveToCoordCommand.new()
	var payload := {"coord": target}
	var result := move_cmd.execute(_command_context, payload)
	if result == null or result.is_failure():
		print_debug("AIController: move_to_coord failed", result and result.get_description())
		if _command_context.move_controller.has_method("cancel_move"):
			_command_context.move_controller.cancel_move()
		return false
	await get_tree().process_frame
	if _command_context.move_controller.has_method("confirm_move"):
		_command_context.move_controller.confirm_move()
	await get_tree().process_frame
	return true

func _execute_action(ai_unit: Unit, best_action: AIAction, terrain_map) -> bool:
	var performed := false
	if not best_action.path.is_empty() and terrain_map:
		performed = await _execute_movement(ai_unit, best_action.path, terrain_map) or performed
		if performed:
			_promote_move_action_followup(ai_unit, best_action)

	if ai_unit.has_action_available():
		performed = _execute_unit_interaction(ai_unit, best_action) or performed
	return performed

func _execute_unit_interaction(ai_unit: Unit, best_action: AIAction) -> bool:
	if _command_context == null:
		print_debug("AIController: missing command context for", best_action.type)
		return false

	var unit_index = _unit_manager.get_unit_index(ai_unit)
	if unit_index == -1:
		print_debug("AIController: unable to resolve unit index for", ai_unit.unit_name)
		return false

	var cmd_data: Dictionary = {}
	match best_action.type:
		ACTION_ATTACK:
			cmd_data = _handle_action_attack(unit_index, best_action)
		ACTION_WORK_ON_GOAL:
			cmd_data = _handle_action_work_on_goal(unit_index, best_action)
		ACTION_LOOT:
			cmd_data = _handle_action_loot(unit_index, best_action)
		ACTION_AID_ALLY:
			cmd_data = _handle_action_aid_ally(unit_index, best_action)
		ACTION_TALK:
			cmd_data = _handle_action_talk(unit_index, best_action)
		ACTION_MOVE_TO_ENEMY, ACTION_MOVE_TO_GOAL, ACTION_MOVE_TO_LOOT, ACTION_MOVE_TO_CENTER:
			return false
		_:
			print_debug("AIController: no interaction handler for action", best_action.type)
			return false

	if not cmd_data.is_empty():
		return _execute_command(cmd_data["cmd"], cmd_data["payload"])

	return false


func _execute_command(cmd: GameCommand, payload: Dictionary) -> bool:
	if cmd == null or _command_context == null:
		return false
	var result = cmd.execute(_command_context, payload)
	if result.is_failure():
		print_debug("AIController: command failed - ", result.get_description())
		return false
	return true


func _handle_action_attack(unit_index: int, action: AIAction) -> Dictionary:
	var enemy_target: Unit = action.target
	var target_index := _unit_manager.get_unit_index(enemy_target)
	if target_index == -1: return {}

	print_debug("AIController: attacking target", enemy_target.unit_name if enemy_target else "null")
	return {
		"cmd": AttackUnitCommand.new(),
		"payload": {
			"attacker_index": unit_index,
			"target_index": target_index
		}
	}


func _handle_action_work_on_goal(unit_index: int, action: AIAction) -> Dictionary:
	var goal_target: Goal = action.target
	var goal_index := _goal_manager.get_goal_node_index(goal_target) if _goal_manager else -1
	if goal_index == -1:
		print_debug("AIController: cannot resolve goal index for", goal_target)
		return {}

	print_debug("AIController: working on goal", goal_target)
	return {
		"cmd": WorkOnGoalCommand.new(),
		"payload": {
			"worker_index": unit_index,
			"goal_index": goal_index
		}
	}


func _handle_action_loot(unit_index: int, action: AIAction) -> Dictionary:
	var loot_coord = action.target as Vector2i
	print_debug("AIController: looting at", loot_coord)
	return {
		"cmd": LootCommand.new(),
		"payload": {
			"looter_index": unit_index,
			"loot_coord": loot_coord
		}
	}


func _handle_action_aid_ally(unit_index: int, action: AIAction) -> Dictionary:
	var ally_target: Unit = action.target
	var ally_index := _unit_manager.get_unit_index(ally_target)
	if ally_index == -1: return {}

	print_debug("AIController: aiding ally", ally_target.unit_name if ally_target else "null")
	return {
		"cmd": AidAllyCommand.new(),
		"payload": {
			"helper_index": unit_index,
			"target_index": ally_index
		}
	}


func _handle_action_talk(unit_index: int, action: AIAction) -> Dictionary:
	var talk_data: Dictionary = action.target if action.target is Dictionary else {}
	var initiator_index := int(talk_data.get("initiator_index", unit_index))
	var target_index := int(talk_data.get("target_index", -1))
	if target_index < 0: return {}

	var dialogue_id_value = talk_data.get("dialogue_id", StringName(""))
	var dialogue_id: StringName = dialogue_id_value if dialogue_id_value is StringName else StringName(dialogue_id_value)
	if String(dialogue_id).is_empty(): return {}

	print_debug("AIController: starting talk dialogue", String(dialogue_id))
	return {
		"cmd": TalkToUnitCommand.new(),
		"payload": {
			"initiator_index": initiator_index,
			"target_index": target_index,
			"dialogue_id": dialogue_id
		}
	}


func _fallback_goal_action(ai_unit: Unit, terrain_map) -> AIAction:
	if _goal_manager == null or terrain_map == null:
		return null
	var best_path: Array = []
	var best_score := INF
	var best_coord := Vector2i(-1, -1)
	for i in range(_goal_manager.get_goal_count()):
		var goal_coord = _goal_manager.get_target(i)
		if goal_coord == Vector2i(-1, -1):
			continue
		var path = ai_unit.get_path_to_coord(goal_coord, terrain_map)
		if path.is_empty():
			continue
		if best_path.is_empty() or path.size() < best_score:
			best_path = path
			best_score = path.size()
			best_coord = goal_coord
	if best_path.is_empty():
		return null
	return AIAction.new(ACTION_MOVE_TO_GOAL, best_coord, best_path, 0.0)

func _fallback_center_action(ai_unit: Unit, terrain_map, threatened_hexes: Dictionary = {}) -> AIAction:
	if _unit_manager == null or terrain_map == null:
		return null
	var width: int = terrain_map.grid_width
	var height: int = terrain_map.grid_height
	if width <= 0 or height <= 0:
		return null
	var center := Vector2i(max(1, int(round(width * 0.5))), max(1, int(round(height * 0.5))))
	var axis := TileSet.TILE_OFFSET_AXIS_VERTICAL
	if terrain_map.has_method("get_offset_axis"):
		axis = terrain_map.get_offset_axis()
	var candidates: Array[Vector2i] = []
	for x in range(1, width + 1):
		for y in range(1, height + 1):
			candidates.append(Vector2i(x, y))
	candidates.sort_custom(func(a: Vector2i, b: Vector2i):
		var da = HexNavigator.get_hex_distance(center, a, axis)
		var db = HexNavigator.get_hex_distance(center, b, axis)
		if da == db:
			if a.x == b.x:
				return a.y < b.y
			return a.x < b.x
		return da < db)
	for coord in candidates:
		if _unit_manager.is_occupied(coord):
			continue
		var path = ai_unit.get_path_to_coord(coord, terrain_map)
		if path.is_empty():
			continue
		var is_threatened = threatened_hexes.has(coord)
		var score = SCORE_MOVE_TO_CENTER_BASE - path.size() - (5.0 if is_threatened else 0.0)
		return AIAction.new(ACTION_MOVE_TO_CENTER, coord, path, score)
	return null

func _fallback_enemy_action(ai_unit: Unit, terrain_map, threatened_hexes: Dictionary = {}, is_neutral: bool = false) -> AIAction:
	if is_neutral or _unit_manager == null or terrain_map == null:
		return null
	var hostiles = ai_unit.get_hostile_units()
	for target in hostiles:
		if target == null:
			continue
		var target_pos = target.get_grid_location()
		var path = _find_path_to_adjacent(ai_unit, target_pos, terrain_map, threatened_hexes)
		if not path.is_empty():
			return AIAction.new(ACTION_MOVE_TO_ENEMY, target, path, 0.0)
	return null

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

func _promote_move_action_followup(ai_unit: Unit, action: AIAction) -> void:
	if ai_unit == null or action == null:
		return
	match action.type:
		ACTION_MOVE_TO_ENEMY:
			if is_instance_valid(action.target):
				action.type = ACTION_ATTACK
		ACTION_MOVE_TO_GOAL:
			if _goal_manager == null:
				return
			var goal = _goal_manager.get_goal_at_cell(ai_unit.get_grid_location())
			if goal and goal.can_be_worked_on_by(ai_unit):
				action.type = ACTION_WORK_ON_GOAL
				action.target = goal
		ACTION_MOVE_TO_LOOT:
			if _loot_manager == null:
				return
			var coord = ai_unit.get_grid_location()
			if _loot_manager.has_loot_at(coord):
				action.type = ACTION_LOOT
				action.target = coord
		_:
			return

func _find_work_on_goal_actions(ai_unit: Unit, start_pos: Vector2i, actions: Array[AIAction]) -> void:
	if _goal_manager == null or not ai_unit.has_action_available():
		return

	var goal = _goal_manager.get_goal_at_cell(start_pos)
	if goal and goal.can_be_worked_on_by(ai_unit):
		actions.append(AIAction.new(ACTION_WORK_ON_GOAL, goal, [], SCORE_WORK_ON_GOAL_BASE))

func _find_loot_actions(ai_unit: Unit, start_pos: Vector2i, actions: Array[AIAction]) -> void:
	if _loot_manager == null or not ai_unit.has_action_available():
		return

	if _loot_manager.has_loot_at(start_pos):
		actions.append(AIAction.new(ACTION_LOOT, start_pos, [], SCORE_LOOT_BASE))

func _find_aid_ally_actions(ai_unit: Unit, _start_pos: Vector2i, actions: Array[AIAction]) -> void:
	if not ai_unit.has_action_available():
		return

	var potential_allies = ai_unit.get_friendly_units()
	var adjacent_allies = ai_unit.get_units_in_range_without_full_willpower(potential_allies, 1.5)

	for ally in adjacent_allies:
		# Score based on how much health is missing
		var score = SCORE_AID_ALLY_BASE + (ally.max_willpower - ally.willpower)
		actions.append(AIAction.new(ACTION_AID_ALLY, ally, [], score))

func _find_enemy_actions(ai_unit: Unit, _start_pos: Vector2i, terrain_map, actions: Array[AIAction], threatened_hexes: Dictionary = {}) -> void:
	var targets = ai_unit.get_hostile_units()
	var adjacent_enemies = ai_unit.get_adjacent_units(targets, 1.5)

	# Action: Attack adjacent enemy (high priority)
	for enemy in adjacent_enemies:
		actions.append(AIAction.new(ACTION_ATTACK, enemy, [], SCORE_ATTACK_BASE))

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
			var score = SCORE_MOVE_TO_ENEMY_BASE - path.size()
			actions.append(AIAction.new(ACTION_MOVE_TO_ENEMY, target, path, score))

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
			var score = SCORE_MOVE_TO_GOAL_BASE - path.size() - (5.0 if is_threatened else 0.0)
			var goal_coord_as_object = goal_coord # Pass Vector2i as Object
			actions.append(AIAction.new(ACTION_MOVE_TO_GOAL, goal_coord_as_object, path, score))

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
			var score = SCORE_MOVE_TO_LOOT_BASE - path.size() - (5.0 if is_threatened else 0.0)
			actions.append(AIAction.new(ACTION_MOVE_TO_LOOT, loot_item, path, score))

func _find_talk_actions(ai_unit: Unit, actions: Array[AIAction]) -> void:
	if ai_unit == null or not ai_unit.has_action_available():
		return
	if _unit_manager == null:
		print_debug("AIController: missing unit manager; skipping talk actions")
		return
	var unit_name := ai_unit.unit_name if ai_unit and ai_unit.unit_name != "" else "Unknown"
	print_debug("AIController: evaluating talk actions for %s" % unit_name)
	var dialogue_service := _command_context.dialogue_action_service if _command_context else null
	if dialogue_service:
		print_debug("AIController: using context dialogue service for %s" % unit_name)
	if dialogue_service == null:
		dialogue_service = UnitActionManager.get_dialogue_service()
		if dialogue_service:
			print_debug("AIController: using global dialogue service fallback for %s" % unit_name)
	if dialogue_service == null:
		print_debug("AIController: no dialogue service available for %s" % unit_name)
		return
	var unit_index := _unit_manager.get_unit_index(ai_unit)
	if unit_index == -1:
		print_debug("AIController: unable to resolve unit index for %s" % unit_name)
		return
	var dialogue_actions: Array[Dictionary] = []
	dialogue_service.append_dialogue_actions(dialogue_actions, ai_unit, _unit_manager)
	var appended := 0
	for action_dict in dialogue_actions:
		if not action_dict.get("available", true):
			continue
		var target_index := int(action_dict.get("target_index", -1))
		if target_index < 0:
			continue
		var dialogue_id_value = action_dict.get("dialogue_id", StringName(""))
		var dialogue_id: StringName = dialogue_id_value if dialogue_id_value is StringName else StringName(dialogue_id_value)
		if String(dialogue_id).is_empty():
			continue
		var initiator_index := int(action_dict.get("initiator_index", unit_index))
		if initiator_index < 0:
			initiator_index = unit_index
		var payload := {
			"dialogue_id": dialogue_id,
			"initiator_index": initiator_index,
			"target_index": target_index
		}
		actions.append(AIAction.new(ACTION_TALK, payload, [], SCORE_TALK_BASE))
		appended += 1
	if appended == 0:
		print_debug("AIController: no talk actions available for %s" % unit_name)


func _on_weather_effect_applied(weather_attribute: WeatherAttribute):
	_current_ai_modifier = weather_attribute.ai_modifier
	print("AIController received weather effect: ", weather_attribute.attribute_name, ". AI Modifier: ", _current_ai_modifier)
	# TODO: Refine AI behavior based on specific weather attributes (humidity, temperature, wind).
	# Example: If very wet, AI might avoid open areas or prioritize ranged attacks.
	# If windy, AI might use cover more effectively or move with the wind.
