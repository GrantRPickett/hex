class_name AIContext
extends RefCounted

## Provides all dependencies needed by AIActionEvaluators.
## Acts as a Parameter Object, avoiding long argument lists in evaluator methods.

var unit_manager: UnitManager
var task_manager: TaskManager
var loot_manager: LootManager
var command_context: GameCommandContext
var router: InputCommandRouter
var terrain_map: TerrainMap
var initial_max_willpower: Dictionary = {
	GameConstants.Faction.PLAYER: 0,
	GameConstants.Faction.ENEMY: 0,
	GameConstants.Faction.NEUTRAL: 0
}

var _discovery_cache: Dictionary = {} # Key -> Dictionary

func get_discovery_results(center: Vector2i, radius: float, types: Array, context_params: Dictionary) -> Dictionary:
	# Sort types to ensure consistent key
	var sorted_types = types.duplicate()
	sorted_types.sort()
	
	var key: String = "%s_%s_%s" % [center, radius, sorted_types]
	if _discovery_cache.has(key):
		return _discovery_cache[key]
		
	var results = TargetDiscoveryService.discover_nearby(center, radius, types, context_params)
	_discovery_cache[key] = results
	return results

var _near_units_cache: Dictionary = {} # Unit -> Dictionary

func get_near_units_categorized(unit: Unit) -> Dictionary:
	if _near_units_cache.has(unit):
		return _near_units_cache[unit]
	var res = unit.query.get_near_units_categorized()
	_near_units_cache[unit] = res
	return res
