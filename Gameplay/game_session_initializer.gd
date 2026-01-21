extends RefCounted
class_name GameSessionInitializer

func _init():
	pass # Constructor

func initialize_session(
	gameplay_coordinator_node: Node,
	grid: TileMapLayer,
	camera: Camera2D,
	camera_handler: CameraHandler,
	input_handler: InputHandler,
	controls_settings: Node,
	player_roster: PlayerRoster,
	enemy_roster: EnemyRoster
) -> GameState:
	# This will contain the extracted logic from GameplayCoordinator's _ready()
	# related to building the game state and initial setup.

	# Preload scripts (if not passed as dependencies)
	const GameSessionBuilderScript := preload("res://Gameplay/game_session_builder.gd")
	const InputMapperScript := preload("res://Autoloads/input_mapper.gd")

	var builder := GameSessionBuilderScript.new()
	var save_manager = gameplay_coordinator_node.get_tree().root.get_node_or_null("SaveManager")
	var current_player_roster = builder.load_player_roster(player_roster, save_manager)
	var current_enemy_roster = builder.load_enemy_roster(enemy_roster)

	if "player_roster" in gameplay_coordinator_node:
		gameplay_coordinator_node.player_roster = current_player_roster
	if "enemy_roster" in gameplay_coordinator_node:
		gameplay_coordinator_node.enemy_roster = current_enemy_roster

	# Build GameState
	var build_config := GameSessionBuilderScript.Config.new()
	build_config.grid = grid
	build_config.camera = camera
	build_config.camera_handler = camera_handler
	build_config.input_handler = input_handler
	build_config.controls = controls_settings
	build_config.input_mapper = gameplay_coordinator_node.get_tree().root.get_node_or_null("InputMapper")
	var game_state = builder.build(build_config)

	# Attach game state nodes to the gameplay_coordinator_node
	for node in game_state.get_tree_nodes():
		if node == null:
			continue
		gameplay_coordinator_node.add_child(node)

	# Configure tileset
	game_state.grid_controller.configure_tileset()

	# Ensure input actions are registered
	var mapper: Node = gameplay_coordinator_node.get_tree().root.get_node_or_null("InputMapper")
	if mapper == null:
		mapper = InputMapperScript.new() # Fallback, though InputMapper should be an Autoload
	var groups = [
		InputActions.MOVEMENT_DEFAULTS,
		InputActions.INTERACTION_DEFAULTS,
		InputActions.CAMERA_DEFAULTS,
		InputActions.SELECTION_DEFAULTS,
		InputActions.PAUSE_DEFAULTS,
	]
	for group in groups:
		var missing: Array = []
		for entry in group:
			var action_name: String = entry.get("action", "")
			if action_name == "":
				continue
			if not InputMap.has_action(action_name):
				missing.append(entry)
		if not missing.is_empty():
			mapper.apply_configs(missing, missing)

	# Initial camera setup
	game_state.camera_controller.center_on_selected()
	game_state.camera_controller.init_camera_snap()

	return game_state
