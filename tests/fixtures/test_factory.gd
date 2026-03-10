# Factory methods for quickly creating units, levels, and contexts.
# Helps reduce setup boilerplate in test suites.

const UnitScript := preload("res://Gameplay/targets/unit.gd")
const LevelScript := preload("res://level/Level.gd")
const InventoryItemScript := preload("res://Gameplay/targets/inventory_item.gd")
const LevelBuildContextScript := preload("res://level/level_build_context.gd")

static func create_unit(name: String = "Test Unit", faction: int = 0) -> Unit:
	var unit = UnitScript.new()
	unit.unit_name = name
	unit.faction = faction
	return unit

static func create_level() -> Level:
	return LevelScript.new()

static func create_level_build_context() -> LevelBuildContext:
	# Note: Most nodes here are created but not added to tree.
	# Tests should manage their lifecycle or use auto_free.
	return LevelBuildContextScript.new(
		null, # 1: game_state
		Node2D.new(), # 2: gameplay_root
		UnitManager.new(), # 3: unit_manager
		null, # 4: unit_controller
		TaskManager.new(), # 5: task_manager
		LootManager.new(), # 6: loot_manager
		CombatSystem.new(), # 7: combat_system
		Node2D.new(), # 8: grid
		Camera2D.new(), # 9: camera
		Node.new(), # 10: controls
		null, # 11: player_roster
		null, # 12: enemy_roster
		null, # 13: neutral_roster
		[], # 14: target_task_templates
		LevelScript.new(), # 15: level
		true, # 16: allow_loot_spawn
		null, # 17: dialogue_service
		null, # 18: animation_service
		"Scout" # 19: leader_unit_name
	)

static func cleanup_level_build_context(context: LevelBuildContext) -> void:
	if context == null:
		return
	var nodes: Array = [
		context.gameplay_root,
		context.unit_manager,
		context.loot_manager,
		context.combat_system,
		context.grid,
		context.camera,
		context.controls
	]
	for node in nodes:
		if node and node is Node:
			node.queue_free()
