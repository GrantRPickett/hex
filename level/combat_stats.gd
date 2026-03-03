# level/combat_stats.gd
class_name CombatStats extends Resource

@export var grit: int = 6
@export var flow: int = 6
@export var gusto: int = 6
@export var focus: int = 6
@export var shine: int = 6
@export var shade: int = 6
@export var willpower: int = 10

func _init(p_grit := 6, p_flow := 6, p_gusto := 6, p_focus := 6, p_shine := 6, p_shade := 6, p_willpower := 10) -> void:
	grit = p_grit
	flow = p_flow
	gusto = p_gusto
	focus = p_focus
	shine = p_shine
	shade = p_shade
	willpower = p_willpower

func get_attribute(attr_name: String) -> int:
	match attr_name.to_lower():
		"grit": return grit
		"flow": return flow
		"gusto": return gusto
		"focus": return focus
		"shine": return shine
		"shade": return shade
		"willpower": return willpower
		_: return 0

func set_attribute(attr_name: String, value: int) -> void:
	match attr_name.to_lower():
		"grit": grit = value
		"flow": flow = value
		"gusto": gusto = value
		"focus": focus = value
		"shine": shine = value
		"shade": shade = value
		"willpower": willpower = value
