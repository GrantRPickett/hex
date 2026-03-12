class_name AIContext
extends RefCounted

## Provides all dependencies needed by AIActionEvaluators.
## Acts as a Parameter Object, avoiding long argument lists in evaluator methods.

var unit_manager: UnitManager
var task_manager: TaskManager
var loot_manager: LootManager
var command_context: GameCommandContext
var terrain_map: TerrainMap
var initial_max_willpower: Dictionary = {
	Unit.Faction.PLAYER: 0,
	Unit.Faction.ENEMY: 0,
	Unit.Faction.NEUTRAL: 0
}
