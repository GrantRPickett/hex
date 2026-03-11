class_name UnitActionManager
extends RefCounted

const _CombatDiscovery = preload("res://Gameplay/targets/discovery/combat_discovery.gd")
const _LocationActionProvider = preload("res://Gameplay/targets/location_action_provider.gd")

static var _dialogue_service: DialogueActionService

static func set_dialogue_service(service: DialogueActionService) -> void:
	_dialogue_service = service

static func get_dialogue_service() -> DialogueActionService:
	return _dialogue_service

static func is_unit_stuck(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool:
	var availability_service = ActionAvailabilityService.new()
	return availability_service.is_unit_stuck(unit, terrain_map, unit_manager)

static func get_available_actions(unit: Unit, terrain_map, unit_manager: UnitManager) -> Array[UnitAction]:
	return _collect_actions(unit, terrain_map, unit_manager, null)

static func get_available_actions_with_weather(unit: Unit, terrain_map, unit_manager: UnitManager, weather_manager) -> Array[UnitAction]:
	return _collect_actions(unit, terrain_map, unit_manager, weather_manager)

static func _collect_actions(unit: Unit, terrain_map, unit_manager: UnitManager, weather_manager) -> Array[UnitAction]:
	var actions: Array[UnitAction] = []
	if not is_instance_valid(unit) or unit.willpower <= 0 or unit_manager == null: return actions

	var reach_state: ReachableState = ReachableStateCalculator.calculate(unit, terrain_map, unit_manager)
	var axis = _get_grid_axis(unit)

	if unit.res.has_action_available():
		_append_combat_actions(actions, unit, unit_manager, reach_state, axis)
		_append_task_action(actions, unit, reach_state.action_origin)
		_append_location_action(actions, unit, reach_state.action_origin)
		_append_loot_action(actions, unit, reach_state.action_origin, reach_state.coords, reach_state.lookup)
		_append_skill_actions(actions, unit, weather_manager)
		MoveAndInteractProvider.append_move_and_interact_actions(actions, unit, terrain_map, unit_manager, reach_state.lookup, axis)
		if _dialogue_service: _dialogue_service.append_dialogue_actions(actions, unit, unit_manager)

	_append_wait_action(actions)
	return actions

static func _get_grid_axis(unit: Unit) -> int:
	return unit.grid_map.tile_set.tile_offset_axis if unit.grid_map and unit.grid_map.tile_set else TileSet.TILE_OFFSET_AXIS_VERTICAL

static func _append_combat_actions(actions: Array[UnitAction], unit: Unit, unit_manager: UnitManager, reach_state: ReachableState, axis: int) -> void:
	CombatActionCalculator.new().append_combat_actions(actions, unit, unit_manager, reach_state, axis)
	
	# Add Convince for adjacent neutral units
	var _UnitDiscovery = preload("res://Gameplay/targets/discovery/unit_discovery.gd")
	var hostiles = _CombatDiscovery.get_all_targets(unit)["enemies"]
	for target in _UnitDiscovery.get_persuadable_neutrals(unit, hostiles, axis):
		var action = UnitAction.new(UnitAction.Type.CONVINCE)
		action.action_id = GameConstants.ActionIds.UNIT_OPPOSED
		action.label_params = {"unit": target.unit_name if "unit_name" in target else "Target"}
		action.available = true
		action.target = target
		action.needs_attribute = true
		actions.append(action)
		break

static func _append_task_action(actions: Array[UnitAction], unit: Unit, action_origin: Vector2i) -> void:
	TaskActionProvider.new().append_task_action(actions, unit, action_origin)

static func _append_location_action(actions: Array[UnitAction], unit: Unit, action_origin: Vector2i) -> void:
	LocationActionProvider.new().append_location_action(actions, unit, action_origin)

static func _append_loot_action(actions: Array[UnitAction], unit: Unit, action_origin: Vector2i, coords: Array[Vector2i], lookup: Dictionary) -> void:
	LootActionProvider.new().append_loot_action(actions, unit, action_origin, coords, lookup)

static func _append_skill_actions(actions: Array[UnitAction], unit: Unit, weather_manager) -> void:
	var skills: Array = unit.skills if unit.skills is Array else []
	for skill in skills:
		if not skill or skill.is_passive: continue
		if skill is WeatherChangeSkill:
			var can_channel = weather_manager.get_channeling_unit() == null if weather_manager and weather_manager.has_method("get_channeling_unit") else false
			var action = UnitAction.create(UnitAction.Type.SKILL, GameConstants.ActionIds.SKILL)
			action.label_params = {"skill_name": skill.skill_name}
			action.available = can_channel
			action.skill = skill
			actions.append(action)
		else:
			var action = UnitAction.new(UnitAction.Type.SKILL)
			action.label = skill.skill_name
			action.available = true
			action.skill = skill
			action.hint = skill.get_tooltip_text()
			actions.append(action)

static func _append_wait_action(actions: Array[UnitAction]) -> void:
	actions.append(UnitAction.create(UnitAction.Type.WAIT, GameConstants.ActionIds.WAIT))
