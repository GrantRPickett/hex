class_name CombatPreviewState
extends "hover_state.gd"

func can_enter(controller: Node, cell: Vector2i) -> bool:
	if not controller._components or not is_instance_valid(controller._components.combat_preview):
		return false
	var selected_idx: int = controller._unit_manager.get_selected_index()
	if selected_idx == -1:
		return false
	var attacker: Unit = controller._unit_manager.get_unit(selected_idx)
	if not (attacker is Unit) or not controller._unit_manager.is_player_controlled(selected_idx):
		return false
	
	var target = _get_combat_target_at(controller, cell)
	if target == null or target == attacker:
		return false
		
	# Only allow preview against non-allies
	if target is Unit and target.faction == attacker.faction:
		return false
		
	return true

func update(controller: Node, cell: Vector2i) -> void:
	var selected_idx: int = controller._unit_manager.get_selected_index()
	var attacker: Unit = controller._unit_manager.get_unit(selected_idx)
	var defender = _get_combat_target_at(controller, cell)
	
	controller.combat_preview_shown.emit(attacker, defender)
	if not controller._components or not is_instance_valid(controller._components.combat_preview):
		return
	if controller._combat_system == null or attacker == null or defender == null:
		return
		
	var best_forecast: Dictionary = {}
	var best_damage := -INF
	for pair_idx in range(GameConstants.Combat.PAIR_COUNT):
		var forecast: Dictionary = controller._combat_system.get_combat_forecast(attacker, defender, pair_idx)
		if forecast.is_empty():
			continue
		var damage := int(forecast.get("damage_to_target", 0))
		if damage > best_damage:
			best_damage = damage
			best_forecast = forecast
	if best_forecast.is_empty():
		return
	controller._components.combat_preview.show_forecast(attacker, defender, best_forecast)

func _get_combat_target_at(controller: Node, cell: Vector2i) -> Target:
	# Priority 1: Units (standardized coordinate check)
	for unit in controller._unit_manager.get_units():
		if is_instance_valid(unit) and unit.visible:
			if unit.get_grid_location() == cell:
				return unit
		
	# Priority 2: Trapped Loot
	if is_instance_valid(controller._loot_manager):
		var loot: Node = controller._loot_manager.get_loot_at(cell)
		if loot and loot.is_trapped:
			return loot
			
	# Priority 3: Locations
	if is_instance_valid(controller._task_manager):
		var location: Node = controller._task_manager.get_location_at(cell)
		if location:
			return location
			
	return null

func exit(controller: Node) -> void:
	controller.combat_preview_hidden.emit()
