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

func append_dialogue_actions(
	actions: Array[UnitAction],
	unit: Unit,
	triggers: Array,
	active_flag: StringName
) -> void:
	if unit == null or _unit_manager == null or triggers.is_empty():
		return

	if not is_instance_valid(unit.res) or not unit.res.has_action_available():
		return

	var unit_index := _unit_manager.get_unit_index(unit)
	if unit_index == -1: return

	var unit_coord := _unit_manager.get_coord(unit_index)

	for trigger: DialogueTrigger in triggers:
		if not is_trigger_available(trigger, active_flag):
			continue

		if trigger.matches_initiator(unit):
			var partners := DialogueDiscovery.get_potential_partners(_unit_manager, trigger, unit, unit_coord, _grid_axis)

			if partners.is_empty():
				if can_proceed_without_partner(trigger):
					actions.append(build_dialogue_action(trigger, unit_index, unit_index, trigger.get_action_label("")))
			else:
				for partner in partners:
					var partner_index: int = _unit_manager.get_unit_index(partner)
					var label: String = trigger.get_action_label(partner.unit_name if partner else "")
					actions.append(build_dialogue_action(trigger, unit_index, partner_index, label))

		elif trigger.allows_partner_initiation() and trigger.matches_partner(unit):
			var initiators := DialogueDiscovery.get_potential_initiators(_unit_manager, trigger, unit, unit_coord, _grid_axis)
			for initiator in initiators:
				var initiator_idx: int = _unit_manager.get_unit_index(initiator)
				var label: String = trigger.get_action_label(initiator.unit_name if initiator else "")
				actions.append(build_dialogue_action(trigger, initiator_idx, unit_index, label))

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

func build_dialogue_action(trigger: DialogueTrigger, initiator_index: int, partner_index: int, label: String) -> UnitAction:
	var action: UnitAction = UnitAction.new(UnitAction.Type.TALK)
	action.label = label
	action.dialogue_id = String(trigger.get_dialogue_id())
	action.initiator_index = initiator_index
	action.target_index = partner_index
	action.hint = trigger.action_hint
	return action
