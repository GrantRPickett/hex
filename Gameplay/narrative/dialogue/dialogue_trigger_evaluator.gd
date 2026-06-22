class_name DialogueTriggerEvaluator
extends Object

var _unit_manager: UnitManager
var _grid_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL

func setup(unit_manager: UnitManager, grid_axis: int) -> void:
	_unit_manager = unit_manager
	_grid_axis = grid_axis

func set_grid_axis(axis: int) -> void:
	_grid_axis = axis

func is_trigger_available(trigger: DialogueTrigger, active_flag: StringName) -> bool:
	if trigger == null: return false
	if trigger.seen and not trigger.repeatable: return false
	if active_flag == trigger.get_dialogue_id(): return false
	return true

func collect_partner_indices(trigger: DialogueTrigger, initiator_index: int, initiator_coord: Vector2i) -> Array[int]:
	var initiator: Unit = _unit_manager.get_unit(initiator_index)
	var partners: Array[Unit]= DialogueDiscovery.get_potential_partners(_unit_manager, trigger, initiator, initiator_coord, _grid_axis)
	var indices: Array[int] = []
	for partner in partners:
		indices.append(_unit_manager.get_unit_index(partner))
	return indices

func collect_initiator_indices(trigger: DialogueTrigger, partner_index: int, partner_coord: Vector2i) -> Array[int]:
	var partner: Unit = _unit_manager.get_unit(partner_index)
	var initiators: Array[Unit]	= DialogueDiscovery.get_potential_initiators(_unit_manager, trigger, partner, partner_coord, _grid_axis)
	var indices: Array[int] = []
	for initiator in initiators:
		indices.append(_unit_manager.get_unit_index(initiator))
	return indices

func can_proceed_without_partner(trigger: DialogueTrigger) -> bool:
	return trigger == null or trigger.partner_name.is_empty()

func are_coords_near(a: Vector2i, b: Vector2i) -> bool:
	return HexLib.get_distance(a, b, _grid_axis) == 1
