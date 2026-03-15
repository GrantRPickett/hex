class_name LootActionProvider
extends RefCounted

const _LootDiscovery = preload("res://Gameplay/targets/discovery/loot_discovery.gd")

const _TaskDiscovery = preload("res://Gameplay/targets/discovery/task_discovery.gd")

func append_loot_action(actions: Array[UnitAction], unit: Unit, action_origin: Vector2i, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary) -> void:
	var task_manager = unit.get_task_manager()
	var active_tasks = _TaskDiscovery.get_active_tasks(task_manager, unit.faction if is_instance_valid(unit) else GameConstants.INVALID_INDEX) if task_manager else []
	
	var immediate_loot := _find_immediate_loot(unit, action_origin)
	var reachable_loot := _find_reachable_loot(unit, reachable_coords, reachable_lookup, immediate_loot)
	
	_augment_loot_from_tasks(active_tasks, task_manager, action_origin, reachable_lookup, immediate_loot, reachable_loot)

	var target_to_task := _map_loot_to_tasks(active_tasks, task_manager)
	var split_loot := _split_trapped_and_gather(immediate_loot, reachable_loot)
	
	_add_categorized_loot_actions(actions, split_loot, reachable_lookup, target_to_task)

func _augment_loot_from_tasks(active_tasks: Array, task_manager: TaskManager, action_origin: Vector2i, reachable_lookup: Dictionary, immediate_loot: Node, reachable_loot: Array) -> void:
	for task in active_tasks:
		if task.target_kind != GameConstants.Tasks.KIND_ITEM:
			continue
			
		var target_coord = task.target_coord
		if target_coord == GameConstants.INVALID_COORD:
			continue
			
		var loot = task_manager.get_loot_at(target_coord)
		if loot == null:
			continue
			
		if target_coord == action_origin:
			if immediate_loot == null:
				immediate_loot = loot
		elif reachable_lookup.has(target_coord):
			if not reachable_loot.has(loot):
				reachable_loot.append(loot)

func _map_loot_to_tasks(active_tasks: Array, task_manager: TaskManager) -> Dictionary:
	var target_to_task: Dictionary = {}
	for task in active_tasks:
		if task.target_kind == GameConstants.Tasks.KIND_ITEM:
			var loot = task_manager.get_loot_at(task.target_coord)
			if loot:
				target_to_task[loot] = task.id
	return target_to_task

func _split_trapped_and_gather(immediate_loot: Node, reachable_loot: Array) -> Dictionary:
	var result := {
		"immediate_trapped": null,
		"immediate_gather": null,
		"reachable_trapped": [],
		"reachable_gather": []
	}
	
	if immediate_loot:
		if bool(immediate_loot.get("is_trapped")):
			result.immediate_trapped = immediate_loot
		else:
			result.immediate_gather = immediate_loot
			
	for loot in reachable_loot:
		if bool(loot.get("is_trapped")):
			result.reachable_trapped.append(loot)
		else:
			result.reachable_gather.append(loot)
	
	return result

func _add_categorized_loot_actions(actions: Array[UnitAction], split_loot: Dictionary, reachable_lookup: Dictionary, target_to_task: Dictionary) -> void:
	if split_loot.immediate_trapped or not split_loot.reachable_trapped.is_empty():
		_add_loot_action(actions, split_loot.immediate_trapped, split_loot.reachable_trapped, reachable_lookup, UnitAction.Type.TRAPPED, GameConstants.ActionIds.ITEM_OPPOSED, target_to_task)
		
	if split_loot.immediate_gather or not split_loot.reachable_gather.is_empty():
		_add_loot_action(actions, split_loot.immediate_gather, split_loot.reachable_gather, reachable_lookup, UnitAction.Type.GATHER, GameConstants.ActionIds.ITEM_UNOPPOSED, target_to_task)

func _find_immediate_loot(unit: Unit, action_origin: Vector2i) -> Node:
	return _LootDiscovery.get_immediate_loot(unit, action_origin, unit.get_loot_manager())

func _find_reachable_loot(unit: Unit, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary, immediate_loot: Node) -> Array:
	var reachable_loot: Array = []
	if reachable_coords.size() <= 1:
		return reachable_loot

	var potential_targets = _LootDiscovery.get_potential_loot_targets(unit, unit.get_loot_manager(), immediate_loot)
	for target in potential_targets:
		if reachable_lookup.has(target.coord):
			reachable_loot.append(target.item)
	return reachable_loot

func _add_loot_action(actions: Array[UnitAction], immediate_loot: Node, reachable_loot: Array, reachable_lookup: Dictionary, action_type: UnitAction.Type, action_id: String, target_to_task: Dictionary = {}) -> void:
	var loot_immediate_count = 1 if immediate_loot else 0
	var loot_reachable_count = reachable_loot.size()

	if loot_immediate_count > 0 or loot_reachable_count > 0:
		var loot_action = UnitAction.create(action_type, action_id)
		loot_action.label_params = {"near": loot_immediate_count, "far": loot_reachable_count, "imm_label": "near"}
		loot_action.available = loot_immediate_count > 0 or loot_reachable_count > 0
		loot_action.needs_attribute = true # Loot actions need targets/submenus
		loot_action.target_to_task = target_to_task
		
		if loot_immediate_count > 0:
			loot_action.target = immediate_loot
			loot_action.interact_target_coord = immediate_loot.get_grid_location()
		if loot_reachable_count > 0:
			loot_action.reachable_targets = reachable_loot
			
			# Rebuild move data to use Target keys and include coord property
			var move_data := {}
			for reach in reachable_loot:
				var coord = reach.get_grid_location()
				if reachable_lookup.has(coord):
					var data = reachable_lookup[coord]
					move_data[reach] = {
						"coord": coord,
						"cost": data.get("cost", 0)
					}
			loot_action.target_move_data = move_data
			# If no immediate, use first reachable as default target
			if loot_immediate_count == 0:
				loot_action.target = reachable_loot[0]
				loot_action.interact_target_coord = reachable_loot[0].get_grid_location()
		actions.append(loot_action)
