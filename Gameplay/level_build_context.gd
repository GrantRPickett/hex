class_name LevelBuildContext
extends RefCounted

var gameplay_root: Node2D
var unit_manager: UnitManager
var goal_manager: GoalManager
var loot_manager: LootManager
var combat_system: CombatSystem
var grid: Node2D
var camera: Camera2D
var controls: Node
var player_roster: PlayerRoster
var enemy_roster: EnemyRoster
var neutral_roster: NeutralRoster
var goal_templates: Array[Goal] = []
var level_path: String = ""
var allow_loot_spawn: bool = true
var dialogue_service: DialogueActionService

func _init(p_root: Node2D, p_unit_manager: UnitManager, p_goal_manager: GoalManager, p_loot_manager: LootManager, p_combat_system: CombatSystem, p_grid: Node2D, p_camera: Camera2D, p_controls: Node, p_player_roster: PlayerRoster, p_enemy_roster: EnemyRoster, p_neutral_roster: NeutralRoster = null, p_goal_templates: Array[Goal] = [], p_level_path: String = "", p_allow_loot_spawn: bool = true, p_dialogue_service: DialogueActionService = null) -> void:
	gameplay_root = p_root
	unit_manager = p_unit_manager
	goal_manager = p_goal_manager
	loot_manager = p_loot_manager
	combat_system = p_combat_system
	grid = p_grid
	camera = p_camera
	controls = p_controls
	player_roster = p_player_roster
	enemy_roster = p_enemy_roster
	neutral_roster = p_neutral_roster
	goal_templates = p_goal_templates
	level_path = p_level_path
	allow_loot_spawn = p_allow_loot_spawn
	dialogue_service = p_dialogue_service
