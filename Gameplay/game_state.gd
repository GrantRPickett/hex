class_name GameState
extends RefCounted

var unit_manager: UnitManager
var task_manager: TaskManager
var journal_manager: Node
var achievement_manager: Node
var save_manager: Node
var weather_manager: Node
var loot_manager: LootManager
var hex_navigator: HexNavigator
var hud: Hud
var grid_visuals: GridVisuals
var hud_controller: HUDController
var input_controller: InputController
var unit_controller: UnitController
var move_controller: MoveController
var animation_service: AnimationRequestService
var camera_controller: CameraController
var task_controller: TaskController
var turn_controller: TurnController
var map_controller: MapController
var grid_query_service: GridQueryService
var ai_controller: AIController
var combat_system: CombatSystem
var checkpoint_manager: CheckpointManager
var dialogue_action_service: DialogueActionService
var level: Level
var terrain_map: TerrainMap
var binding_service: InputBindingService
var command_context: GameCommandContext
var command_router: InputCommandRouter
var location_service: LocationService
var player_roster: PlayerRoster
var grid: TileMapLayer
var camera_2d: Camera2D

var _tree_nodes: Array[Node]

func _init(p_services: Dictionary, p_tree_nodes: Array[Node] = []) -> void:
	self.player_roster = p_services.get(GameConstants.ContextKeys.PLAYER_ROSTER)
	self.grid = p_services.get(GameConstants.ContextKeys.GRID)
	self.camera_2d = p_services.get(GameConstants.ContextKeys.CAMERA_2D)
	self.unit_controller = p_services.get(GameConstants.ContextKeys.UNIT_CONTROLLER)
	self.unit_manager = p_services.get(GameConstants.ContextKeys.UNIT_MANAGER)
	self.task_manager = p_services.get(GameConstants.ContextKeys.TASK_MANAGER)
	self.journal_manager = p_services.get(GameConstants.ContextKeys.JOURNAL_MANAGER)
	self.achievement_manager = p_services.get(GameConstants.ContextKeys.ACHIEVEMENT_MANAGER)
	self.save_manager = p_services.get(GameConstants.ContextKeys.SAVE_MANAGER)
	self.weather_manager = p_services.get(GameConstants.ContextKeys.WEATHER_MANAGER)
	self.loot_manager = p_services.get(GameConstants.ContextKeys.LOOT_MANAGER)
	self.hex_navigator = p_services.get(GameConstants.ContextKeys.HEX_NAVIGATOR)
	self.hud = p_services.get(GameConstants.ContextKeys.HUD)
	self.grid_visuals = p_services.get(GameConstants.ContextKeys.GRID_VISUALS)
	self.hud_controller = p_services.get(GameConstants.ContextKeys.HUD_CONTROLLER)
	self.input_controller = p_services.get(GameConstants.ContextKeys.INPUT_CONTROLLER)
	self.move_controller = p_services.get(GameConstants.ContextKeys.MOVE_CONTROLLER)
	self.animation_service = p_services.get(GameConstants.ContextKeys.ANIMATION_SERVICE)
	self.camera_controller = p_services.get(GameConstants.ContextKeys.CAMERA_CONTROLLER)
	self.task_controller = p_services.get(GameConstants.ContextKeys.TASK_CONTROLLER)
	self.turn_controller = p_services.get(GameConstants.ContextKeys.TURN_CONTROLLER)
	self.map_controller = p_services.get(GameConstants.ContextKeys.MAP_CONTROLLER)
	self.grid_query_service = p_services.get(GameConstants.ContextKeys.GRID_QUERY_SERVICE)
	self.ai_controller = p_services.get(GameConstants.ContextKeys.AI_CONTROLLER)
	self.combat_system = p_services.get(GameConstants.ContextKeys.COMBAT_SYSTEM)
	self.checkpoint_manager = p_services.get(GameConstants.ContextKeys.CHECKPOINT_MANAGER)
	self.dialogue_action_service = p_services.get(GameConstants.ContextKeys.DIALOGUE_ACTION_SERVICE)
	self.level = p_services.get(GameConstants.ContextKeys.LEVEL_RESOURCE)

	self.terrain_map = p_services.get(GameConstants.ContextKeys.TERRAIN_MAP)
	self.binding_service = p_services.get(GameConstants.ContextKeys.BINDING_SERVICE)
	self.command_context = p_services.get(GameConstants.ContextKeys.COMMAND_CONTEXT)
	self.command_router = p_services.get(GameConstants.ContextKeys.COMMAND_ROUTER)
	self.location_service = p_services.get(GameConstants.ContextKeys.LOCATION_SERVICE)

	_tree_nodes = p_tree_nodes.duplicate()

func get_tree_nodes() -> Array[Node]:
	return _tree_nodes.duplicate()

func get_hud() -> Hud:
	return hud
