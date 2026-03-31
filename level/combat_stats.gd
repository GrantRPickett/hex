# level/combat_stats.gd
class_name CombatStats extends Resource

@export var grit: int = 6
@export var flow: int = 6
@export var gusto: int = 6
@export var focus: int = 6
@export var shine: int = 6
@export var shade: int = 6
@export var movement_points: int = 6
@export var willpower: int = 10

func _init(p_grit := 6, p_flow := 6, p_gusto := 6, p_focus := 6, p_shine := 6, p_shade := 6, p_willpower := 10, p_movement_points := 6) -> void:
	grit = p_grit
	flow = p_flow
	gusto = p_gusto
	focus = p_focus
	shine = p_shine
	shade = p_shade
	willpower = p_willpower
	movement_points = p_movement_points

func get_attribute(idx: GameConstants.AttributeIndex) -> int:
	match idx:
		GameConstants.AttributeIndex.GRIT: return grit
		GameConstants.AttributeIndex.FLOW: return flow
		GameConstants.AttributeIndex.GUSTO: return gusto
		GameConstants.AttributeIndex.FOCUS: return focus
		GameConstants.AttributeIndex.SHINE: return shine
		GameConstants.AttributeIndex.SHADE: return shade
	return 0

## @deprecated: Use get_attribute(idx: AttributeIndex) instead
func get_attribute_by_name(attr_name: String) -> int:
	var idx = GameConstants.get_attribute_index(attr_name)
	return get_attribute(idx)

func set_attribute(idx: GameConstants.AttributeIndex, value: int) -> void:
	match idx:
		GameConstants.AttributeIndex.GRIT: grit = value
		GameConstants.AttributeIndex.FLOW: flow = value
		GameConstants.AttributeIndex.GUSTO: gusto = value
		GameConstants.AttributeIndex.FOCUS: focus = value
		GameConstants.AttributeIndex.SHINE: shine = value
		GameConstants.AttributeIndex.SHADE: shade = value

## @deprecated: Use set_attribute(idx: AttributeIndex, value: int) instead
func set_attribute_by_name(attr_name: String, value: int) -> void:
	var idx = GameConstants.get_attribute_index(attr_name)
	set_attribute(idx, value)
