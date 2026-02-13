class_name GameState
extends RefCounted

var unit_manager: UnitManager
var task_manager: TaskManager
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

func _init(services: GameSessionServices, p_tree_nodes: Array[Node] = []) -> void:
	self.unit_controller = services.unit_controller
	self.unit_manager = services.unit_manager
	self.task_manager = services.task_manager
	self.loot_manager = services.loot_manager
	self.hex_navigator = services.hex_navigator
	self.hud = services.hud
	self.grid_visuals = services.grid_visuals
	self.hud_controller = services.hud_controller
	self.input_controller = services.input_controller
	self.move_controller = services.move_controller
	self.animation_service = services.animation_service
	self.grid_controller = services.grid_controller
	self.camera_controller = services.camera_controller
	self.task_controller = services.task_controller
	self.turn_controller = services.turn_controller
	self.map_controller = services.map_controller
	self.ai_controller = services.ai_controller
	self.combat_system = services.combat_system
	self.checkpoint_manager = services.checkpoint_manager
	self.dialogue_action_service = services.dialogue_action_service
	_tree_nodes = p_tree_nodes.duplicate()

func get_tree_nodes() -> Array[Node]:
	return _tree_nodes.duplicate()

func get_hud() -> Hud:
	return hud
