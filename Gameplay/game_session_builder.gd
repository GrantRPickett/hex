class_name GameSessionBuilder
extends RefCounted


const InputMapperScript := preload("res://Autoloads/input_mapper.gd")

class Config extends RefCounted:
	var grid: Node2D
	var camera: Camera2D
	var camera_handler: CameraHandler
	var input_handler: InputHandler
	var controls: Node
	var input_mapper: Node

func build(config: Config) -> GameState:
	assert(config != null, "GameSessionBuilder requires a config object.")
	assert(config.grid != null, "GameSessionBuilder requires a grid reference.")
	var unit_controller := UnitController.new()
	unit_controller.setup()
	var unit_manager := unit_controller.get_unit_manager()

	var goal_manager := GoalManager.new()
	var loot_manager := LootManager.new()
	var hex_navigator: HexNavigator = HexNavigator.new()
	var hud: Info = Info.new()
	var grid_visuals: GridVisuals = GridVisuals.new()
	var hud_controller: HUDController = HUDController.new()
	var input_controller: InputController = InputController.new()
	var move_controller: MoveController = MoveController.new()
	var grid_controller := GridController.new()
	var camera_controller := CameraController.new()
	var goal_controller := GoalController.new()
	var turn_controller := TurnController.new()
	var map_controller := MapController.new()
	var ai_controller := AIController.new()
	var combat_system := CombatSystem.new()
	var checkpoint_manager := CheckpointManager.new()

	grid_controller.setup(config.grid)
	map_controller.setup(config.grid)
	turn_controller.setup(unit_manager, ai_controller)
	camera_controller.setup(config.camera, config.camera_handler, unit_manager)
	goal_controller.setup(goal_manager, unit_manager)
	move_controller.setup(unit_manager, unit_controller, hex_navigator, turn_controller, goal_controller, map_controller, config.grid, hud)

	ai_controller.setup(unit_manager, map_controller, combat_system, unit_controller, goal_manager, loot_manager)

	var turn_system := turn_controller.get_turn_system()
	hud_controller.setup(hud, turn_system, unit_manager, goal_manager, config.grid, map_controller.get_terrain_map())
	input_controller.setup(
		config.input_handler,
		unit_manager,
		hex_navigator,
		camera_controller,
		move_controller,
		turn_controller,
		goal_controller,
		config.grid,
		config.controls,
		config.input_mapper if config.input_mapper != null else InputMapperScript.new(),
		grid_visuals,
		map_controller.get_terrain_map()
	)
	# Setup hud AFTER input_controller is configured
	hud.setup(unit_manager, turn_controller, input_controller, goal_manager)

	var tree_nodes: Array[Node] = [
		hud,
		grid_visuals,
		hud_controller,
		move_controller,
		loot_manager,
		ai_controller,
		combat_system,
		unit_controller,
		unit_manager,
		goal_manager,
		input_controller,
		grid_controller,
		camera_controller,
		goal_controller,
		turn_controller,
		map_controller
	]
	return GameState.new(
		unit_controller,
		goal_manager,
		loot_manager,
		hex_navigator,
		hud,
		grid_visuals,
		hud_controller,
		input_controller,
		move_controller,
		grid_controller,
		camera_controller,
		goal_controller,
		turn_controller,
		map_controller,
		ai_controller,
		combat_system,
		checkpoint_manager,
		tree_nodes
	)

func load_player_roster(provided_roster: PlayerRoster, save_manager: Node) -> PlayerRoster:
	if provided_roster:
		if not provided_roster.units.is_empty():
			print("[GameSessionBuilder] Using provided player roster with ", provided_roster.units.size(), " units.")
			return provided_roster
		else:
			print("[GameSessionBuilder] Provided player roster is empty. Falling back to default.")

	if save_manager and save_manager.has_method("has_saved_roster") and save_manager.has_saved_roster():
		var saved = save_manager.load_roster()
		if saved and not saved.units.is_empty():
			print("[GameSessionBuilder] Loaded saved player roster with ", saved.units.size(), " units.")
			return saved

	const DEFAULT_PATH = "res://Resources/default_player_roster.tres"
	if ResourceLoader.exists(DEFAULT_PATH):
		print("[GameSessionBuilder] Loading default player roster from ", DEFAULT_PATH)
		var loaded_roster_data = load(DEFAULT_PATH)
		if loaded_roster_data is PlayerRoster:
			print("[GameSessionBuilder] Default player roster loaded successfully with ", loaded_roster_data.units.size(), " units.")
			return loaded_roster_data
		else:
			printerr("[GameSessionBuilder] Error: ", DEFAULT_PATH, " is not a PlayerRoster resource. It is: ", loaded_roster_data)
	else:
		printerr("[GameSessionBuilder] Error: Default player roster not found at ", DEFAULT_PATH)

	print("[GameSessionBuilder] Returning new empty PlayerRoster.")
	return PlayerRoster.new()

func load_enemy_roster(provided_roster: EnemyRoster) -> EnemyRoster:
	if provided_roster:
		return provided_roster

	var roster = EnemyRoster.new()
	if ResourceLoader.exists("res://Resources/default_enemy_roster.tres"):
		var loaded_roster_data = load("res://Resources/default_enemy_roster.tres")
		if loaded_roster_data is EnemyRoster:
			roster.enemy_types.clear()
			for enemy_scene in loaded_roster_data.enemy_types:
				if enemy_scene is PackedScene:
					roster.enemy_types.append(enemy_scene)
				else:
					printerr("Warning: Element in default_enemy_roster.tres.enemy_types is not a PackedScene. Skipping.")
	return roster

func load_neutral_roster(provided_roster: EnemyRoster) -> EnemyRoster:
	if provided_roster:
		return provided_roster

	var roster = EnemyRoster.new()
	if ResourceLoader.exists("res://Resources/default_neutral_roster.tres"):
		var loaded_roster_data = load("res://Resources/default_neutral_roster.tres")
		if loaded_roster_data is EnemyRoster:
			roster.enemy_types.clear()
			for enemy_scene in loaded_roster_data.enemy_types:
				if enemy_scene is PackedScene:
					roster.enemy_types.append(enemy_scene)
				else:
					printerr("Warning: Element in default_neutral_roster.tres.enemy_types is not a PackedScene. Skipping.")
		else:
			printerr("Warning: res://Resources/default_neutral_roster.tres is not an EnemyRoster resource. Using an empty EnemyRoster.")
	return roster
