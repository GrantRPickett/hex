class_name PlayerAction
extends BaseAction

## UI-specific presentation data for player choices.
var action_id: String = "" # Localization key or unique ID
var ui_label: String = "" # Fallback label
var ui_label_params: Dictionary = {}
var ui_hint: String = ""
var available: bool = true

# UI Menu Logic: Used by ActionsPanel to handle sub-menus
var targets: Array = []
var needs_attribute: bool = false
var target_to_task: Dictionary = {} # target -> task_id

# Movement targets: Populated when an action can be performed after moving
var reachable_targets: Array = []
var target_move_data: Dictionary = {}

func _init(p_type: GameConstants.ActionType = GameConstants.ActionType.UNKNOWN) -> void:
	super(p_type)

static func create(p_type: GameConstants.ActionType, p_action_id: String = "") -> PlayerAction:
	var action: PlayerAction = PlayerAction.new(p_type)
	action.action_id = p_action_id
	return action

func clone() -> PlayerAction:
	var copy: PlayerAction = PlayerAction.new(type)
	copy.command_id = command_id
	copy.command_payload = command_payload.duplicate(true)
	copy.path = path.duplicate()
	copy.move_cost = move_cost
	copy.action_cost = action_cost
	copy.target_object = target_object
	
	copy.action_id = action_id
	copy.ui_label = ui_label
	copy.ui_label_params = ui_label_params.duplicate()
	copy.ui_hint = ui_hint
	copy.available = available
	
	copy.targets = targets.duplicate()
	copy.needs_attribute = needs_attribute
	copy.target_to_task = target_to_task.duplicate()
	
	copy.reachable_targets = reachable_targets.duplicate()
	copy.target_move_data = target_move_data.duplicate()
	return copy
