class_name UnitAction
extends RefCounted

# Types of actions
enum Type {
	UNKNOWN,
	MOVE,
	WAIT,
	ATTACK,
	AID,
	VISIT,
	EXPLORE,
	TRAPPED,
	CONVINCE,
	GATHER,
	SKILL,
	TALK,
	OPEN_ATTACK_MENU,
	MOVE_AND_INTERACT,
	UNDO
}

var type: Type = Type.UNKNOWN
var action_id: String = "" # Localization key or ID
var label: String = "" # Fallback label
var label_params: Dictionary = {}
var available: bool = true
var needs_attribute: bool = false
var hint: String = ""

# Target information
var target: Object = null # Unit, Location, or Loot
var targets: Array = []
var reachable_targets: Array = []
var target_move_data: Dictionary = {} # target -> move_info
var target_to_task: Dictionary = {} # target -> task_id

# Interaction specific
var attribute_index: int = -1
var attribute_name: String = ""
var skill: Resource = null
var dialogue_id: String = ""
var target_index: int = -1 # For unit targets by index
var initiator_index: int = -1

# Move and Interact specific
var target_move_coord: Vector2i = GameConstants.INVALID_COORD
var interact_action_type: Type = Type.UNKNOWN
var interact_target_uid: int = -1
var interact_target_coord: Vector2i = GameConstants.INVALID_COORD
var movement_cost: int = 0
var action_cost: int = 1
var task_id: String = ""

func _init(p_type: Type = Type.UNKNOWN) -> void:
	type = p_type

static func create(p_type: Type, p_action_id: String = "") -> UnitAction:
	var action: UnitAction = UnitAction.new(p_type)
	action.action_id = p_action_id
	return action

func clone() -> UnitAction:
	var copy: UnitAction = UnitAction.new(type)
	copy.action_id = action_id
	copy.label = label
	copy.label_params = label_params.duplicate()
	copy.available = available
	copy.needs_attribute = needs_attribute
	copy.hint = hint
	copy.target = target
	copy.targets = targets.duplicate()
	copy.reachable_targets = reachable_targets.duplicate()
	copy.target_move_data = target_move_data.duplicate(true)
	copy.target_to_task = target_to_task.duplicate()
	copy.attribute_index = attribute_index
	copy.attribute_name = attribute_name
	copy.skill = skill
	copy.dialogue_id = dialogue_id
	copy.target_index = target_index
	copy.initiator_index = initiator_index
	copy.target_move_coord = target_move_coord
	copy.interact_action_type = interact_action_type
	copy.interact_target_uid = interact_target_uid
	copy.interact_target_coord = interact_target_coord
	copy.movement_cost = movement_cost
	copy.action_cost = action_cost
	copy.task_id = task_id
	return copy
