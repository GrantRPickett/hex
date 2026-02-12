class_name GameState
extends RefCounted

var unit_manager: UnitManager
var location_manager: LocationManager
var loot_manager: LootManager
var hex_navigator: HexNavigator
var hud: Hud
var grid_visuals: GridVisuals
var hud_controller: HUDController
var input_controller: InputController
var unit_controller: UnitController
var move_controller: MoveController
var animation_service
var grid_controller: GridController
var camera_controller: CameraController
var task_controller: TaskController
var turn_controller: TurnController
var map_controller: MapController
var ai_controller: AIController
var combat_system: CombatSystem
var checkpoint_manager: CheckpointManager
var dialogue_action_service: DialogueActionService
var _tree_nodes: Array[Node]

func _init(
	p_unit_controller: UnitController,
	p_location_manager: LocationManager,
	p_loot_manager: LootManager,
	p_hex_navigator: HexNavigator,
	p_hud: Hud,
	p_grid_visuals: GridVisuals,
	p_hud_controller: HUDController,
	p_input_controller: InputController,
	p_move_controller: MoveController,
	p_animation_service,
	p_grid_controller: GridController,
	p_camera_controller: CameraController,
	p_task_controller: TaskController,
	p_turn_controller: TurnController,
	p_map_controller: MapController,
	p_ai_controller: AIController,
	p_combat_system: CombatSystem,
	p_checkpoint_manager: CheckpointManager,
	p_dialogue_action_service: DialogueActionService,
	p_tree_nodes: Array[Node] = []
) -> void:
	self.unit_controller = p_unit_controller
	self.unit_manager = p_unit_controller.get_unit_manager()
	self.location_manager = p_location_manager
	self.loot_manager = p_loot_manager
	self.hex_navigator = p_hex_navigator
	self.hud = p_hud
	self.grid_visuals = p_grid_visuals
	self.hud_controller = p_hud_controller
	self.input_controller = p_input_controller
	self.move_controller = p_move_controller
	self.animation_service = p_animation_service
	self.grid_controller = p_grid_controller
	self.camera_controller = p_camera_controller
	self.task_controller = p_task_controller
	self.turn_controller = p_turn_controller
	self.map_controller = p_map_controller
	self.ai_controller = p_ai_controller
	self.combat_system = p_combat_system
	self.checkpoint_manager = p_checkpoint_manager
	self.dialogue_action_service = p_dialogue_action_service
	_tree_nodes = p_tree_nodes.duplicate()

func get_tree_nodes() -> Array[Node]:
	return _tree_nodes.duplicate()

func get_hud() -> Hud:
	return hud
