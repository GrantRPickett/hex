class_name GameState
extends RefCounted

var unit_manager: UnitManager
var goal_manager: GoalManager
var loot_manager: LootManager
var hex_navigator: HexNavigator
var hud: Hud
var grid_visuals: GridVisuals
var hud_controller: HUDController
var input_controller: InputController
var unit_controller: UnitController
var move_controller: MoveController
var grid_controller: GridController
var camera_controller: CameraController
var goal_controller: GoalController
var turn_controller: TurnController
var map_controller: MapController
var ai_controller: AIController
var combat_system: CombatSystem
var checkpoint_manager: CheckpointManager
var hover_info_manager: HoverInfoManager
var _tree_nodes: Array[Node]

func _init(
	unit_controller: UnitController,
	goal_manager: GoalManager,
	loot_manager: LootManager,
	hex_navigator: HexNavigator,
	hud: Hud,
	grid_visuals: GridVisuals,
	hud_controller: HUDController,
	input_controller: InputController,
	move_controller: MoveController,
	grid_controller: GridController,
	camera_controller: CameraController,
	goal_controller: GoalController,
	turn_controller: TurnController,
	map_controller: MapController,
	ai_controller: AIController,
	combat_system: CombatSystem,
	checkpoint_manager: CheckpointManager,
	hover_info_manager: HoverInfoManager,
	tree_nodes: Array[Node] = []
) -> void:
	self.unit_controller = unit_controller
	self.unit_manager = unit_controller.get_unit_manager()
	self.goal_manager = goal_manager
	self.loot_manager = loot_manager
	self.hex_navigator = hex_navigator
	self.hud = hud
	self.grid_visuals = grid_visuals
	self.hud_controller = hud_controller
	self.input_controller = input_controller
	self.move_controller = move_controller
	self.grid_controller = grid_controller
	self.camera_controller = camera_controller
	self.goal_controller = goal_controller
	self.turn_controller = turn_controller
	self.map_controller = map_controller
	self.ai_controller = ai_controller
	self.combat_system = combat_system
	self.checkpoint_manager = checkpoint_manager
	self.hover_info_manager = hover_info_manager
	_tree_nodes = tree_nodes.duplicate()

func get_tree_nodes() -> Array[Node]:
	return _tree_nodes.duplicate()

func get_hud() -> Hud:
	return hud
