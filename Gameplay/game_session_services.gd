class_name GameSessionServices
extends RefCounted

var unit_controller: UnitController
var unit_manager: UnitManager
var goal_manager: GoalManager
var loot_manager: LootManager
var hex_navigator: HexNavigator
var hud: Info
var grid_visuals: GridVisuals
var hud_controller: HUDController
var input_controller: InputController
var move_controller: MoveController
var grid_controller: GridController
var camera_controller: CameraController
var goal_controller: GoalController
var turn_controller: TurnController
var map_controller: MapController
var ai_controller: AIController
var combat_system: CombatSystem
var checkpoint_manager: CheckpointManager
var terrain_map
var binding_service: InputBindingService
var command_context: GameCommandContext
var command_router: InputCommandRouter
