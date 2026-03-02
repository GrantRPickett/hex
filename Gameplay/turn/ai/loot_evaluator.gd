class_name LootEvaluator
extends AIActionEvaluator

## Finds loot and move-to-loot actions for the given unit.
## Priority:
##   - Loot at current position  → ACTION_LOOT (high score)
##   - Reachable loot coord      → ACTION_MOVE_TO_LOOT (closer = better)

const ACTION_LOOT := &"loot"
const ACTION_MOVE_TO_LOOT := &"move_to_loot"

const SCORE_LOOT_BASE := 70.0
const SCORE_MOVE_TO_LOOT := 10.0
const THREAT_PENALTY := 5.0

func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	if context.loot_manager == null or context.terrain_map == null:
		return []

	var profile = unit.get_combat_profile()
	var score_loot_base = float(profile.get_weight(&"objective")) * 14.0 if profile else SCORE_LOOT_BASE
	var score_move_to_loot = float(profile.get_weight(&"objective")) * 2.0 if profile else SCORE_MOVE_TO_LOOT

	var actions: Array[AIAction] = []
	var start_pos := unit.get_grid_location()

	# Can we loot right now?
	if unit.has_action_available() and context.loot_manager.has_loot_at(start_pos):
		actions.append(AIAction.new(ACTION_LOOT, start_pos, [], score_loot_base))

	# Find loot to move toward
	var threatened_hexes: Dictionary = _get_threatened_hexes(unit, context)
	var loot_count := context.loot_manager.get_loot_count()
	for i in range(loot_count):
		var loot_item = context.loot_manager.get_loot(i)
		if loot_item == null:
			continue
		var loot_coord: Vector2i = context.loot_manager.get_coord(i)
		if loot_coord == Vector2i(-1, -1) or loot_coord == Vector2i(-999, -999):
			continue
		if context.unit_manager.is_occupied(loot_coord):
			continue
		var path = unit.get_path_to_coord(loot_coord, context.terrain_map)
		if not path.is_empty():
			var is_threatened := threatened_hexes.has(loot_coord)
			var score: float = score_move_to_loot - path.size() - (THREAT_PENALTY if is_threatened else 0.0)
			actions.append(AIAction.new(ACTION_MOVE_TO_LOOT, loot_item, path, score))

	return actions

# -- helpers -------------------------------------------------------------------

func _get_threatened_hexes(unit: Unit, context: AIContext) -> Dictionary:
	if unit.movement_behavior:
		return unit.movement_behavior.get_threatened_hexes(context.unit_manager, context.terrain_map)
	return {}
