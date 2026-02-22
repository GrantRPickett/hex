class_name GameSessionServices
extends RefCounted

var unit_controller: UnitController
var unit_manager: UnitManager
var task_manager: TaskManager
var loot_manager: LootManager
var hex_navigator: HexNavigator
var hud: Hud
var grid_visuals: GridVisuals
var hud_controller: HUDController
var input_controller: InputController
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
var terrain_map : TerrainMap
var binding_service: InputBindingService
var command_context: GameCommandContext
var command_router: InputCommandRouter
var dialogue_action_service: DialogueActionService
var location_service: LocationService
