class_name GoalManager
extends Node

signal goal_updated(index: int)
signal goal_completed(index: int, faction: int)

# Goal class is auto-global in Godot 4

var _goal_targets: Array[Vector2i] = []
var _goals: Array[Goal] = []
var _grid: Node2D

# Progress tracking: _goal_progress[goal_index][faction_id] = accumulated_points
var _goal_progress: Array[Dictionary] = []

# Goal definitions derived from nodes or defaults
# { "type": String, "amount": int }
# Goal definitions derived from nodes or defaults
var _goal_definitions: Array[GoalDefinition] = []

func setup(goal_coords: Array[Vector2i], goals: Array[Goal], grid: Node2D) -> void:
	_goal_targets = goal_coords.duplicate()
	_goals.clear()
	for g in goals:
		if g is Goal:
			_goals.append(g)
		else:
			printerr("Warning: Non-Goal object passed to GoalManager.setup goals array.")
	_grid = grid

	_goal_progress.clear()
	_goal_definitions.clear()

	for i in range(goal_coords.size()):
		_goal_progress.append({}) # Dictionary[int, Dictionary] -> faction_id: { step_index, current_amount, completed }

		var def: GoalDefinition
		if i < _goals.size():
			var node = _goals[i]
			if node:
				if grid is TileMapLayer:
					node.grid_map = grid

				# Use node.definition if available, otherwise create from legacy props (which node._ready already does)
				if node.definition:
					def = node.definition
				else:
					# Fallback if _ready hasn't run or something is off
					node._create_default_definition()
					def = node.definition

		if not def:
			def = GoalDefinition.new() # Empty fallback

		_goal_definitions.append(def)

	# _update_visuals() # This function is not defined in GoalManager, likely intended for a visual component.

func _update_visuals() -> void:
	pass # Placeholder for visual updates, if any.

# ... (visuals code remains same) ...

func process_turn_progress(unit_manager: UnitManager) -> void:
	for i in range(_goal_targets.size()):
		var coord = _goal_targets[i]
		var unit_index = unit_manager.index_of_unit_at(coord)

		if unit_index != -1:
			var unit = unit_manager.get_unit(unit_index)
			if unit and unit.willpower > 0:
				_apply_progress(i, unit)

func apply_progress(goal_index: int, unit: Unit) -> void:
	_apply_progress(goal_index, unit)

func _apply_progress(goal_index: int, unit: Unit) -> void:
	if goal_index < 0 or goal_index >= _goal_definitions.size():
		return

	var def = _goal_definitions[goal_index]
	var faction = unit.faction

	# Initialize progress for this faction if missing
	if not _goal_progress[goal_index].has(faction):
		_goal_progress[goal_index][faction] = {
			"step_index": 0,
			"current_amount": 0,
			"completed": false
		}

	var progress = _goal_progress[goal_index][faction]
	if progress.completed:
		return

	# Check Common/Rare logic
	if def.goal_type == GoalDefinition.GoalType.RARE:
		# If completed by ANY other faction, cannot progress?
		# Or if completed by THIS faction, it's done (already checked above).
		# "rare gather tile can only be done once by a faction" - interpreting as "Once by ANY faction" for true rarity competition?
		# Or "Once per faction"? User said: "rare gather tile can only be done once by a faction" vs "common... usage... all factions can use"
		# Let's assume Rare means competitive (First to finish locks it?) OR per-faction limit?
		# Actually user said "common gather tile which doesnt go away... rare gather tile can only be done once by a faction".
		# This strongly implies Common = Infinite Farming, Rare = One-time completion.
		# If it's one time *by a faction*, then each faction can do it once.
		# If it's *competitive*, only one winner.
		# "progress is on faction so units can divide progress"
		# I will implement: Rare = Once it is completed by a faction, they can't do it again (checked by progress.completed).
		pass

	if progress.step_index >= def.steps.size():
		progress.completed = true
		return

	var step = def.steps[progress.step_index]
	var attr_type = step.required_attribute

	var amount = 0
	var attrs = unit.get_attributes()
	if attrs:
		amount = attrs.get_attribute(attr_type)

	if amount <= 0:
		amount = 1

	progress.current_amount += amount

	goal_updated.emit(goal_index)

	if progress.current_amount >= step.required_amount:
		# Step Complete
		progress.current_amount = 0 # specific overflow logic? usually lost or carry over? simplifying to reset.
		progress.step_index += 1

		# Give rewards for step? Or only final?
		# Usually rewards are on Goal completion or specific step?
		# Our definition has rewards on the GoalDefinition, not step. So on final completion.

		if progress.step_index >= def.steps.size():
			progress.completed = true
			goal_completed.emit(goal_index, faction)
			# Grant rewards here? Or let controller handle it?

func are_all_required_goals_completed() -> bool:
	for i in range(_goal_definitions.size()):
		var def = _goal_definitions[i]
		if def.is_optional:
			continue
		if not is_goal_reached(i, Unit.Faction.PLAYER):
			return false
	return true

func is_goal_reached(index: int, faction: int) -> bool:
	if index < 0 or index >= _goal_definitions.size():
		return false

	if not _goal_progress[index].has(faction):
		return false

	return _goal_progress[index][faction].completed

func get_progress(index: int, faction: int) -> int:
	if index < 0 or index >= _goal_progress.size():
		return 0

	if not _goal_progress[index].has(faction):
		return 0

	return _goal_progress[index][faction].current_amount

func get_total_required_goals_count() -> int:
	var count = 0
	for def in _goal_definitions:
		if not def.is_optional:
			count += 1
	return count

func get_completed_required_goals_count(faction: int) -> int:
	var count = 0
	for i in range(_goal_definitions.size()):
		var def = _goal_definitions[i]
		if def.is_optional:
			continue
		if is_goal_reached(i, faction):
			count += 1
	return count

func get_required_amount(index: int, faction: int = Unit.Faction.PLAYER) -> int:
	if index < 0 or index >= _goal_definitions.size():
		return 0

	var def = _goal_definitions[index]
	var step_idx = 0
	if _goal_progress[index].has(faction):
		step_idx = _goal_progress[index][faction].step_index

	if step_idx < def.steps.size():
		return def.steps[step_idx].required_amount
	return 0 # Completed? Or return last step?

func get_required_type(index: int, faction: int = Unit.Faction.PLAYER) -> String:
	if index < 0 or index >= _goal_definitions.size():
		return ""

	var def = _goal_definitions[index]
	var step_idx = 0
	if _goal_progress[index].has(faction):
		step_idx = _goal_progress[index][faction].step_index

	if step_idx < def.steps.size():
		return def.steps[step_idx].required_attribute
	return ""

func get_current_step_description(index: int, faction: int = Unit.Faction.PLAYER) -> String:
	if index < 0 or index >= _goal_definitions.size():
		return ""

	var def = _goal_definitions[index]
	var step_idx = 0
	if _goal_progress[index].has(faction):
		step_idx = _goal_progress[index][faction].step_index

	if step_idx < def.steps.size():
		return def.steps[step_idx].description
	return "Completed" # Or last step desc?

func get_goal_at_cell(cell: Vector2i) -> Goal:
	for i in range(_goal_targets.size()):
		if _goal_targets[i] == cell:
			return get_goal_node(i)
	return null

func get_goal_node(index: int) -> Goal:
	if index < 0 or index >= _goals.size():
		return null
	return _goals[index]

func get_goal_node_index(goal_node: Goal) -> int:
	return _goals.find(goal_node)

func get_goal_count() -> int:
	return _goal_targets.size()

func get_target(index: int) -> Vector2i:
	if index < 0 or index >= _goal_targets.size():
		return Vector2i(-1, -1)
	return _goal_targets[index]
func create_memento() -> Dictionary:
	return {
		"goal_progress": _goal_progress.duplicate(true),
		"goal_targets": _goal_targets.duplicate()
	}

func restore_from_memento(memento: Dictionary) -> void:
	_goal_progress = memento.get("goal_progress", _goal_progress)
	_goal_targets = memento.get("goal_targets", _goal_targets)
	_update_visuals()
