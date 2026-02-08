class_name CombatPreviewState
extends "hover_state.gd"

func can_enter(controller: Node, cell: Vector2i) -> bool:
	if not controller._components or not is_instance_valid(controller._components.combat_preview):
		return false
	var selected_idx = controller._unit_manager.get_selected_index()
	if selected_idx == -1:
		return false
	var attacker = controller._unit_manager.get_unit(selected_idx)
	if not (attacker is Unit) or not controller._unit_manager.is_player_controlled(selected_idx):
		return false
	var target_idx = controller._unit_manager.index_of_unit_at(cell)
	if target_idx == -1 or target_idx == selected_idx:
		return false
	var defender = controller._unit_manager.get_unit(target_idx)
	if not (defender is Unit) or defender.faction == attacker.faction:
		return false
	return true

func update(controller: Node, cell: Vector2i) -> void:
	var selected_idx = controller._unit_manager.get_selected_index()
	var attacker = controller._unit_manager.get_unit(selected_idx)
	var target_idx = controller._unit_manager.index_of_unit_at(cell)
	var defender = controller._unit_manager.get_unit(target_idx)
	controller.combat_preview_shown.emit(attacker, defender)
	if not controller._components or not is_instance_valid(controller._components.combat_preview):
		return
	if controller._combat_system == null or attacker == null or defender == null:
		return
	var best_forecast: Dictionary = {}
	var best_damage := -INF
	for pair_idx in range(3):
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

func exit(controller: Node) -> void:
	controller.combat_preview_hidden.emit()
