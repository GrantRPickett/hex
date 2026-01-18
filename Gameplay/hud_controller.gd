class_name HUDController
extends Node2D

var _hud: Info
var _turn_system: TurnSystem
var _unit_manager: UnitManager
var _goal_manager: GoalManager
var _grid: Node2D

func setup(hud: Info, turn_system: TurnSystem, unit_manager: UnitManager, goal_manager: GoalManager, grid: Node2D) -> void:
	_hud = hud
	_turn_system = turn_system
	_unit_manager = unit_manager
	_goal_manager = goal_manager
	_grid = grid

func _process(_delta: float) -> void:
	_update_hud()
	_update_combat_preview()

func _update_hud() -> void:
	if not is_instance_valid(_hud):
		return

	if is_instance_valid(_turn_system):
		_hud.update_round(_turn_system.get_current_round())
		_hud.update_turn(_turn_system.get_current_side() == TurnSystem.Side.PLAYER)

	if is_instance_valid(_goal_manager) and _hud.has_method("update_goals"):
		var goals_data = []
		for i in range(_goal_manager.get_goal_count()):
			goals_data.append({
				"player_progress": _goal_manager.get_progress(i, Unit.Faction.PLAYER),
				"enemy_progress": _goal_manager.get_progress(i, Unit.Faction.ENEMY),
				"max": _goal_manager.get_required_amount(i),
				"type": _goal_manager.get_required_type(i)
			})
		_hud.update_goals(goals_data)

	var selected_idx = _unit_manager.get_selected_index()
	if selected_idx != -1:
		var sprite = _unit_manager.get_unit(selected_idx)
		if sprite is Unit:
			_hud.update_unit_details(sprite)
	else:
		_hud.update_unit_details(null)

func _update_combat_preview() -> void:
	if not is_instance_valid(_hud) or not is_instance_valid(_unit_manager):
		return

	var selected_idx = _unit_manager.get_selected_index()
	if selected_idx == -1:
		_hud.hide_combat_preview()
		return

	var attacker = _unit_manager.get_unit(selected_idx)
	if not (attacker is Unit) or not _unit_manager.is_player_controlled(selected_idx):
		_hud.hide_combat_preview()
		return

	var mouse_pos = get_global_mouse_position()
	# Assumes _grid has local_to_map (TileMap or TileMapLayer)
	var cell = _grid.local_to_map(_grid.to_local(mouse_pos))
	var target_idx = _unit_manager.index_of_unit_at(cell)

	if target_idx == -1 or target_idx == selected_idx:
		_hud.hide_combat_preview()
		return

	var defender = _unit_manager.get_unit(target_idx)
	if not (defender is Unit):
		_hud.hide_combat_preview()
		return

	if defender.faction == attacker.faction:
		_hud.hide_combat_preview()
		return

	_hud.show_combat_preview(attacker, defender)
