class_name DialogueDiscovery
extends RefCounted

## Unified target discovery for Dialogue. Used by both AI Evaluators and Human Action Providers.

## Returns a list of units that can act as partners for the given trigger and initiator.
static func get_potential_partners(unit_manager: UnitManager, trigger: DialogueTrigger, initiator: Unit, initiator_coord: Vector2i, grid_axis: int) -> Array[Unit]:
	var partners: Array[Unit] = []
	if not is_instance_valid(unit_manager) or not is_instance_valid(trigger) or not is_instance_valid(initiator):
		return partners

	for partner in unit_manager.get_units():
		if not is_instance_valid(partner) or partner == initiator:
			continue
		if not trigger.matches_partner(partner):
			continue
		if partner.willpower <= 0:
			continue

		if trigger.requires_near:
			var partner_coord := partner.get_grid_location()
			if HexLib.get_distance(initiator_coord, partner_coord, grid_axis) != 1:
				continue
		partners.append(partner)

	return partners

## Returns a list of units that can act as initiators for the given trigger and partner.
static func get_potential_initiators(unit_manager: UnitManager, trigger: DialogueTrigger, partner: Unit, partner_coord: Vector2i, grid_axis: int) -> Array[Unit]:
	var initiators: Array[Unit] = []
	if not is_instance_valid(unit_manager) or not is_instance_valid(trigger) or not is_instance_valid(partner):
		return initiators

	for initiator in unit_manager.get_units():
		if not is_instance_valid(initiator) or initiator == partner:
			continue
		if not trigger.matches_initiator(initiator):
			continue
		if initiator.willpower <= 0:
			continue

		if trigger.requires_near:
			var initiator_coord := initiator.get_grid_location()
			if HexLib.get_distance(initiator_coord, partner_coord, grid_axis) != 1:
				continue
		initiators.append(initiator)

	return initiators

## Returns true if the two units have an active dialogue trigger between them.
static func has_active_dialogue(initiator: Unit, partner: Unit, triggers: Array, active_flag: StringName) -> bool:
	if not is_instance_valid(initiator) or not is_instance_valid(partner):
		return false

	for trigger in triggers:
		if not is_instance_valid(trigger) or (trigger.seen and not trigger.repeatable):
			continue
		if active_flag == trigger.get_dialogue_id():
			continue

		if trigger.matches_initiator(initiator) and trigger.matches_partner(partner):
			return true
		if trigger.allows_partner_initiation() and trigger.matches_partner(initiator) and trigger.matches_initiator(partner):
			return true

	return false
