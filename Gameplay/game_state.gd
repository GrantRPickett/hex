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
var grid_controller: GridController
var camera_controller: CameraController
var task_controller: TaskController
var turn_controller: TurnController
var map_controller: MapController
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
	self.player_roster = p_services.get("player_roster")
	self.grid = p_services.get("grid")
	self.camera_2d = p_services.get("camera_2d")
	self.unit_controller = p_services.get("unit_controller")
	self.unit_manager = p_services.get("unit_manager")
	self.task_manager = p_services.get("task_manager")
	self.journal_manager = p_services.get("journal_manager")
	self.achievement_manager = p_services.get("achievement_manager")
	self.save_manager = p_services.get("save_manager")
	self.weather_manager = p_services.get("weather_manager")
	self.loot_manager = p_services.get("loot_manager")
	self.hex_navigator = p_services.get("hex_navigator")
	self.hud = p_services.get("hud")
	self.grid_visuals = p_services.get("grid_visuals")
	self.hud_controller = p_services.get("hud_controller")
	self.input_controller = p_services.get("input_controller")
	self.move_controller = p_services.get("move_controller")
	self.animation_service = p_services.get("animation_service")
	self.grid_controller = p_services.get("grid_controller")
	self.camera_controller = p_services.get("camera_controller")
	self.task_controller = p_services.get("task_controller")
	self.turn_controller = p_services.get("turn_controller")
	self.map_controller = p_services.get("map_controller")
	self.ai_controller = p_services.get("ai_controller")
	self.combat_system = p_services.get("combat_system")
	self.checkpoint_manager = p_services.get("checkpoint_manager")
	self.dialogue_action_service = p_services.get("dialogue_action_service")
	self.level = p_services.get("level_resource")

	self.terrain_map = p_services.get("terrain_map")
	self.binding_service = p_services.get("binding_service")
	self.command_context = p_services.get("command_context")
	self.command_router = p_services.get("command_router")
	self.location_service = p_services.get("location_service")

	_tree_nodes = p_tree_nodes.duplicate()

func get_tree_nodes() -> Array[Node]:
	return _tree_nodes.duplicate()

func get_hud() -> Hud:
	return hud
